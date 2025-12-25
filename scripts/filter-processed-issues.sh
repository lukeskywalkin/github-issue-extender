#!/bin/bash
# Filter out issues that the bot has already commented on

# This script is used by analyze-issues.sh to filter issues
# The actual filtering is done inline in analyze-issues.sh for simplicity
# This file is kept for potential future use or external calls

main() {
    local issues_json="$1"
    local bot_user="${2:-github-actions[bot]}"
    local repo="${GITHUB_REPOSITORY}"
    
    if [ -z "$issues_json" ] || [ -z "$repo" ]; then
        echo "Error: issues_json and GITHUB_REPOSITORY are required" >&2
        exit 1
    fi
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) is required" >&2
        exit 1
    fi
    
    # Process each issue and check if bot has commented
    local unprocessed_issues=$(echo "$issues_json" | jq -c '.[]' | while IFS= read -r issue; do
        local issue_num=$(echo "$issue" | jq -r '.number')
        
        # Get comments for this issue
        local comments=$(gh api "repos/$repo/issues/$issue_num/comments" --jq '.[].user.login' 2>/dev/null || echo "")
        
        # Check if bot user has commented
        if echo "$comments" | grep -q "^${bot_user}$"; then
            # Bot has commented, skip this issue
            continue
        fi
        
        # Bot has not commented, include this issue
        echo "$issue"
    done | jq -s '.')
    
    echo "$unprocessed_issues"
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

