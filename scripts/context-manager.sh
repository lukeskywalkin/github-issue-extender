#!/bin/bash
# Manage context storage in a GitHub issue instead of a file

CONTEXT_ISSUE_LABEL="issue-extender-context"
CONTEXT_ISSUE_TITLE="Issue Extender Context"

# Get or create context issue
get_context_issue() {
    local repo="${GITHUB_REPOSITORY}"
    
    if [ -z "$repo" ]; then
        echo "Error: GITHUB_REPOSITORY is required" >&2
        exit 1
    fi
    
    # Try to find existing context issue by label
    local issue_num=$(gh api "repos/$repo/issues?labels=$CONTEXT_ISSUE_LABEL&state=all&per_page=1" --jq '.[0].number // empty' 2>/dev/null || echo "")
    
    if [ -n "$issue_num" ]; then
        echo "$issue_num"
        return 0
    fi
    
    # If not found, create a new one
    local new_issue=$(gh api "repos/$repo/issues" \
        --method POST \
        --field title="$CONTEXT_ISSUE_TITLE" \
        --field body="This issue is used by the Issue Extender workflow to store repository context. Please do not close or modify this issue manually." \
        --field labels[]="$CONTEXT_ISSUE_LABEL" \
        --jq '.number' 2>/dev/null || echo "")
    
    if [ -n "$new_issue" ]; then
        echo "$new_issue"
        return 0
    fi
    
    echo "Error: Failed to get or create context issue" >&2
    exit 1
}

# Read context from issue
read_context_from_issue() {
    local issue_num="$1"
    local repo="${GITHUB_REPOSITORY}"
    
    if [ -z "$issue_num" ] || [ -z "$repo" ]; then
        echo "{}"
        return 0
    fi
    
    # Get issue body and extract JSON from code block
    local issue_body=$(gh api "repos/$repo/issues/$issue_num" --jq '.body // ""' 2>/dev/null || echo "")
    
    if [ -z "$issue_body" ]; then
        echo "{}"
        return 0
    fi
    
    # Try to extract JSON from markdown code block
    local json_content=$(echo "$issue_body" | grep -oP '(?<=```json\s)[\s\S]*(?=\s```)' || echo "$issue_body" | grep -oP '(?<=```\s)[\s\S]*(?=\s```)' || echo "")
    
    # If no code block found, try to parse the whole body as JSON
    if [ -z "$json_content" ]; then
        json_content="$issue_body"
    fi
    
    # Try to parse as JSON, if it fails return empty object
    if echo "$json_content" | jq empty 2>/dev/null; then
        echo "$json_content"
    else
        echo "{}"
    fi
}

# Write context to issue
write_context_to_issue() {
    local issue_num="$1"
    local context_json="$2"
    local repo="${GITHUB_REPOSITORY}"
    
    if [ -z "$issue_num" ] || [ -z "$context_json" ] || [ -z "$repo" ]; then
        echo "Error: issue number, context JSON, and repository are required" >&2
        return 1
    fi
    
    # Format the issue body with JSON in a code block
    local issue_body=$(cat <<EOF
This issue is used by the Issue Extender workflow to store repository context.

Please do not close or modify this issue manually.

\`\`\`json
$context_json
\`\`\`
EOF
)
    
    # Update the issue
    gh api "repos/$repo/issues/$issue_num" \
        --method PATCH \
        --field body="$issue_body" \
        >/dev/null 2>&1
    
    return $?
}

# Get repository overview from context issue
get_repo_overview_from_issue() {
    local issue_num="$1"
    
    if [ -z "$issue_num" ]; then
        echo "{}"
        return 0
    fi
    
    local context=$(read_context_from_issue "$issue_num")
    echo "$context" | jq -r '.repository_overview // {}'
}

# Update context in issue (called from analyze-issues.sh)
update_context_issue() {
    local issue_num="$1"
    local new_overview="$2"
    local repo="${GITHUB_REPOSITORY}"
    
    if [ -z "$issue_num" ] || [ -z "$new_overview" ]; then
        echo "Error: issue number and overview are required" >&2
        return 1
    fi
    
    # Read existing context
    local existing_context=$(read_context_from_issue "$issue_num")
    
    # If existing context is empty, initialize it
    if [ -z "$existing_context" ] || [ "$existing_context" = "{}" ]; then
        existing_context='{"repository_overview": {}}'
    fi
    
    # Update repository overview
    local updated_context=$(echo "$existing_context" | jq --argjson overview "$new_overview" '.repository_overview = $overview | .repository_overview.last_updated = (now | todateiso8601)')
    
    # Check size limit (50KB)
    local context_size=$(echo "$updated_context" | wc -c | tr -d ' ')
    local size_limit="${CONTEXT_SIZE_LIMIT:-51200}"
    
    if [ "$context_size" -gt "$size_limit" ]; then
        # Trim oldest entries from important_files
        updated_context=$(echo "$updated_context" | jq '.repository_overview.important_files = (.repository_overview.important_files | .[0:10])')
    fi
    
    # Write back to issue
    write_context_to_issue "$issue_num" "$updated_context"
}

main() {
    local command="${1:-get_issue}"
    
    case "$command" in
        get_issue)
            get_context_issue
            ;;
        read)
            local issue_num="$2"
            read_context_from_issue "$issue_num"
            ;;
        write)
            local issue_num="$2"
            local context_json="$3"
            write_context_to_issue "$issue_num" "$context_json"
            ;;
        update)
            local issue_num="$2"
            local new_overview="$3"
            update_context_issue "$issue_num" "$new_overview"
            ;;
        *)
            echo "Usage: $0 {get_issue|read <issue_num>|write <issue_num> <json>|update <issue_num> <json>}" >&2
            exit 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

