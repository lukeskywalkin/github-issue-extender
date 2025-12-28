#!/bin/bash
# Main script that orchestrates the issue analysis process

set -euo pipefail

# Configuration
CONTEXT_FILE="${CONTEXT_FILE:-.github/issue-extender-context.json}"
CONTEXT_SIZE_LIMIT="${CONTEXT_SIZE_LIMIT:-51200}"  # 50KB in bytes
AI_PROVIDER="${AI_PROVIDER:-openai}"
AI_MODEL="${AI_MODEL:-}"
REPO="${GITHUB_REPOSITORY}"
USE_AI="${USE_AI:-true}"  # Set to "false" to use non-AI summary mode

# Check if AI mode is enabled
if [ "$USE_AI" = "true" ] && [ -z "${AI_API_KEY:-}" ]; then
    echo "Error: AI_API_KEY environment variable is required when USE_AI=true" >&2
    echo "Set USE_AI=false to use non-AI summary mode, or provide AI_API_KEY" >&2
    exit 1
fi

# If AI is disabled, skip API key requirement
if [ "$USE_AI" = "false" ]; then
    echo "Running in non-AI mode (USE_AI=false)"
fi

if [ -z "$REPO" ]; then
    echo "Error: GITHUB_REPOSITORY environment variable is required" >&2
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure context file directory exists
mkdir -p "$(dirname "$CONTEXT_FILE")"

# Initialize context file if it doesn't exist
init_context_file() {
    if [ ! -f "$CONTEXT_FILE" ]; then
        cat > "$CONTEXT_FILE" <<EOF
{
  "repository_overview": {
    "summary": "",
    "important_files": [],
    "last_updated": null
  }
}
EOF
        echo "Initialized context file: $CONTEXT_FILE"
    fi
}

# Get repository overview from context file
get_repo_overview() {
    if [ -f "$CONTEXT_FILE" ]; then
        cat "$CONTEXT_FILE" | jq -r '.repository_overview // {}'
    else
        echo "{}"
    fi
}

# Generate or update repository overview using AI
generate_repo_overview() {
    local repo_files=$(find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" -o -name "*.rb" -o -name "*.php" -o -name "*.swift" -o -name "*.kt" \) \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./venv/*" \
        -not -path "./.venv/*" \
        -not -path "./__pycache__/*" \
        -not -path "./dist/*" \
        -not -path "./build/*" \
        2>/dev/null | head -n 50)
    
    # Get README if exists
    local readme_content=""
    if [ -f "README.md" ]; then
        readme_content=$(head -n 100 README.md)
    fi
    
    # Build prompt for AI
    local prompt=$(cat <<EOF
Analyze this GitHub repository and provide a high-level overview. Focus on:
1. What the repository does (purpose, main functionality)
2. Key components and architecture
3. Important files/functions (list top 10-15 most important ones with brief descriptions)

Repository files (sample):
$(echo "$repo_files" | head -n 30)

README excerpt:
$readme_content

Provide a concise overview (under 2000 characters) in JSON format:
{
  "summary": "Brief description of what the repo does and its main purpose",
  "important_files": [
    {"path": "path/to/file.py", "description": "Brief description of what this file does"},
    ...
  ]
}
EOF
)
    
    # Call AI provider (pass empty string for model if not set, so script can use default)
    local ai_response=""
    case "$AI_PROVIDER" in
        openai)
            ai_response=$("$SCRIPT_DIR/ai-providers/openai.sh" "$AI_API_KEY" "${AI_MODEL:-}" "$prompt")
            ;;
        anthropic)
            ai_response=$("$SCRIPT_DIR/ai-providers/anthropic.sh" "$AI_API_KEY" "${AI_MODEL:-}" "$prompt")
            ;;
        groq)
            ai_response=$("$SCRIPT_DIR/ai-providers/groq.sh" "$AI_API_KEY" "${AI_MODEL:-}" "$prompt")
            ;;
        *)
            echo "Error: Unknown AI provider: $AI_PROVIDER" >&2
            exit 1
            ;;
    esac
    
    # Extract JSON from response (handle cases where AI includes markdown code blocks)
    local json_content=$(echo "$ai_response" | grep -oE '\{.*\}' | head -n1 || echo "$ai_response" | sed -n '/\{/,/\}/p' | jq -s '.' | head -n1)
    
    # Try to parse as JSON, if it fails, create a simple structure
    if echo "$json_content" | jq empty 2>/dev/null; then
        echo "$json_content"
    else
        # Fallback: create basic structure from the text response
        jq -n \
            --arg summary "$ai_response" \
            '{
                summary: ($summary | split("\n") | .[0:5] | join(" ")),
                important_files: []
            }'
    fi
}

# Update context file with new overview (respecting size limit)
update_context_file() {
    local new_overview="$1"
    
    # Update the context file
    local temp_file=$(mktemp)
    cat "$CONTEXT_FILE" | jq --argjson overview "$new_overview" '.repository_overview = $overview | .repository_overview.last_updated = (now | todateiso8601)' > "$temp_file"
    
    # Check size
    local file_size=$(wc -c < "$temp_file" | tr -d ' ')
    if [ "$file_size" -gt "$CONTEXT_SIZE_LIMIT" ]; then
        # Trim oldest entries from important_files
        cat "$temp_file" | jq '.repository_overview.important_files = (.repository_overview.important_files | .[0:10])' > "${temp_file}.trimmed"
        mv "${temp_file}.trimmed" "$temp_file"
    fi
    
    mv "$temp_file" "$CONTEXT_FILE"
    echo "Updated context file: $CONTEXT_FILE"
}

# Build AI prompt for issue analysis
build_issue_prompt() {
    local issue_context="$1"
    local repo_overview="$2"
    
    local issue_title=$(echo "$issue_context" | jq -r '.issue.title')
    local issue_body=$(echo "$issue_context" | jq -r '.issue.body // ""')
    local linked_prs=$(echo "$issue_context" | jq -c '.linked_pull_requests // []')
    local relevant_files=$(echo "$issue_context" | jq -r '.relevant_files[]? // empty' | head -n 10)
    
    local repo_summary=$(echo "$repo_overview" | jq -r '.summary // "No repository overview available"')
    local important_files=$(echo "$repo_overview" | jq -c '.important_files // []')
    
    cat <<EOF
You are analyzing a GitHub issue to provide detailed elaboration and context.

Repository Overview:
$repo_summary

Issue Details:
Title: $issue_title
Description:
$issue_body

Linked Pull Requests:
$(echo "$linked_prs" | jq -r '.[] | "- PR #\(.number): \(.title) (state: \(.state), merged: \(.merged))"' || echo "None")

Relevant Files:
$(echo "$relevant_files" | head -n 10 | sed 's/^/- /')

Important Repository Files:
$(echo "$important_files" | jq -r '.[] | "- \(.path): \(.description)"' || echo "None")

Based on the repository context, issue details, and any linked pull requests, provide a detailed elaboration on this issue. Include:
1. Analysis of what the issue is asking for
2. Relevant context from the codebase or pull requests
3. Any additional details that would be helpful for understanding or addressing the issue

Be concise but thorough. Focus on actionable information.
EOF
}

# Process a single issue
process_issue() {
    local issue_num="$1"
    
    echo "Processing issue #$issue_num..."
    
    # Get issue context
    local issue_context=$("$SCRIPT_DIR/get-issue-context.sh" "$issue_num" "$CONTEXT_FILE")
    
    # Get repository overview
    local repo_overview=$(get_repo_overview)
    
    # If repo overview is empty, generate it
    if [ -z "$repo_overview" ] || [ "$repo_overview" = "{}" ] || [ "$(echo "$repo_overview" | jq -r '.summary // ""')" = "" ]; then
        echo "Generating initial repository overview..."
        repo_overview=$(generate_repo_overview)
        update_context_file "$repo_overview"
    fi
    
    # Generate elaboration (AI or non-AI mode)
    local elaboration=""
    local comment_header=""
    
    if [ "$USE_AI" = "true" ]; then
        # AI mode: Build prompt and call AI provider
        local prompt=$(build_issue_prompt "$issue_context" "$repo_overview")
        
        case "$AI_PROVIDER" in
            openai)
                elaboration=$("$SCRIPT_DIR/ai-providers/openai.sh" "$AI_API_KEY" "${AI_MODEL:-}" "$prompt")
                ;;
            anthropic)
                elaboration=$("$SCRIPT_DIR/ai-providers/anthropic.sh" "$AI_API_KEY" "${AI_MODEL:-}" "$prompt")
                ;;
            groq)
                elaboration=$("$SCRIPT_DIR/ai-providers/groq.sh" "$AI_API_KEY" "${AI_MODEL:-}" "$prompt")
                ;;
            *)
                echo "Error: Unknown AI provider: $AI_PROVIDER" >&2
                return 1
                ;;
        esac
        
        if [ -z "$elaboration" ]; then
            echo "Warning: Empty elaboration received from AI for issue #$issue_num" >&2
            return 1
        fi
        
        comment_header="## 🤖 AI-Generated Issue Elaboration"
    else
        # Non-AI mode: Generate summary from existing data
        elaboration=$("$SCRIPT_DIR/generate-summary-no-ai.sh" "$issue_context")
        comment_header="## 📋 Issue Context Summary"
    fi
    
    # Format the comment
    local comment_body=$(cat <<EOF
$comment_header

$elaboration
EOF
)
    
    # Post comment
    "$SCRIPT_DIR/post-comment.sh" "$issue_num" "$comment_body"
    
    echo "Posted elaboration to issue #$issue_num"
}

# Main execution
main() {
    echo "Starting issue extender analysis..."
    
    # Initialize context file
    init_context_file
    
    # Get all open issues
    echo "Fetching open issues..."
    local open_issues=$(gh api "repos/$REPO/issues?state=open&per_page=100" --jq '.[] | select(.pull_request == null) | {
        number: .number,
        title: .title,
        state: .state
    }' | jq -s '.')
    
    local issue_count=$(echo "$open_issues" | jq 'length')
    echo "Found $issue_count open issue(s)"
    
    if [ "$issue_count" -eq 0 ]; then
        echo "No open issues to process."
        exit 0
    fi
    
    # Filter out issues already commented on by bot
    echo "Filtering issues already processed by bot..."
    local unprocessed_issues=$(echo "$open_issues" | jq -c '.[]' | while IFS= read -r issue; do
        local issue_num=$(echo "$issue" | jq -r '.number')
        
        # Check if bot has commented on this issue
        # When using GITHUB_TOKEN, comments are posted as github-actions[bot]
        local comments=$(gh api "repos/$REPO/issues/$issue_num/comments" --jq '.[].user.login' 2>/dev/null || echo "")
        local bot_user="github-actions[bot]"
        
        # Check if bot user appears in comments (handle special characters in username)
        if echo "$comments" | grep -Fxq "$bot_user"; then
            echo "Skipping issue #$issue_num (already commented by bot)" >&2
            continue
        fi
        
        echo "$issue"
    done | jq -s '.')
    
    local unprocessed_count=$(echo "$unprocessed_issues" | jq 'length')
    echo "Found $unprocessed_count unprocessed issue(s)"
    
    if [ "$unprocessed_count" -eq 0 ]; then
        echo "All issues have already been processed."
        exit 0
    fi
    
    # Process each unprocessed issue
    echo "$unprocessed_issues" | jq -c '.[]' | while IFS= read -r issue; do
        local issue_num=$(echo "$issue" | jq -r '.number')
        process_issue "$issue_num" || echo "Failed to process issue #$issue_num" >&2
        sleep 2  # Rate limiting: wait between issues
    done
    
    echo "Issue extender analysis complete!"
}

# Run main function
main "$@"

