#!/bin/bash
# Gather issue, PR, and code context for AI analysis

get_issue_context() {
    local issue_num="$1"
    local repo="${GITHUB_REPOSITORY}"
    local context_file="${2:-.github/issue-extender-context.json}"
    
    if [ -z "$issue_num" ] || [ -z "$repo" ]; then
        echo "Error: issue number and repository are required" >&2
        exit 1
    fi
    
    # Get issue details
    local issue=$(gh api "repos/$repo/issues/$issue_num" --jq '{
        number: .number,
        title: .title,
        body: .body,
        state: .state,
        labels: [.labels[].name],
        created_at: .created_at,
        updated_at: .updated_at
    }')
    
    # Get PRs linked to this issue (via "fixes #X", "closes #X", etc.)
    local linked_prs=$(gh api "repos/$repo/pulls?state=all" --jq ".[] | select(.body // \"\" | test(\"[#]${issue_num}\\b\"; \"i\")) | {
        number: .number,
        title: .title,
        body: .body,
        state: .state,
        merged: .merged,
        changed_files: .changed_files,
        additions: .additions,
        deletions: .deletions
    }" | jq -s '.')
    
    # Get changed files from linked PRs
    local pr_files="[]"
    if [ -n "$linked_prs" ] && [ "$linked_prs" != "[]" ]; then
        local pr_nums=$(echo "$linked_prs" | jq -r '.[].number')
        local all_files=()
        
        for pr_num in $pr_nums; do
            local files=$(gh api "repos/$repo/pulls/$pr_num/files" --jq '.[].filename' 2>/dev/null || echo "")
            if [ -n "$files" ]; then
                while IFS= read -r file; do
                    all_files+=("$file")
                done <<< "$files"
            fi
        done
        
        # Get unique files
        local unique_files=$(printf '%s\n' "${all_files[@]}" | sort -u)
        pr_files=$(echo "$unique_files" | jq -R '.' | jq -s '.')
    fi
    
    # Load repository context if available
    local repo_context="{}"
    if [ -f "$context_file" ]; then
        repo_context=$(cat "$context_file" | jq '.repository_overview // {}')
    fi
    
    # Build context summary
    local context=$(jq -n \
        --argjson issue "$issue" \
        --argjson linked_prs "$linked_prs" \
        --argjson pr_files "$pr_files" \
        --argjson repo_context "$repo_context" \
        '{
            issue: $issue,
            linked_pull_requests: $linked_prs,
            relevant_files: $pr_files,
            repository_context: $repo_context
        }')
    
    echo "$context"
}

# Extract relevant code files from issue and PRs
get_relevant_code_files() {
    local context_json="$1"
    local max_files="${2:-10}"
    
    if [ -z "$context_json" ]; then
        echo "Error: context_json is required" >&2
        exit 1
    fi
    
    # Get files from PRs
    local pr_files=$(echo "$context_json" | jq -r '.relevant_files[]? // empty' | head -n "$max_files")
    
    # Also check issue body for file mentions
    local issue_body=$(echo "$context_json" | jq -r '.issue.body // ""')
    
    # Extract file paths from issue body (simple pattern matching)
    local mentioned_files=$(echo "$issue_body" | grep -oE '[a-zA-Z0-9_/.-]+\.(py|js|ts|jsx|tsx|java|go|rs|cpp|c|h|hpp|rb|php|swift|kt|scala|sh|bash|yml|yaml|json|md|txt)' | sort -u | head -n "$max_files")
    
    # Combine and deduplicate
    local all_files=$(printf '%s\n' "$pr_files" "$mentioned_files" | grep -v '^$' | sort -u | head -n "$max_files")
    
    echo "$all_files" | jq -R '.' | jq -s '.'
}

main() {
    local issue_num="$1"
    local context_file="${2:-.github/issue-extender-context.json}"
    
    if [ -z "$issue_num" ]; then
        echo "Error: issue number is required" >&2
        echo "Usage: $0 <issue_number> [context_file]" >&2
        exit 1
    fi
    
    get_issue_context "$issue_num" "$context_file"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

