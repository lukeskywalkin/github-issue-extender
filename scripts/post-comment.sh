#!/bin/bash
# Post a comment to a GitHub issue

post_issue_comment() {
    local issue_num="$1"
    local comment_body="$2"
    local repo="${GITHUB_REPOSITORY}"
    
    if [ -z "$issue_num" ] || [ -z "$comment_body" ] || [ -z "$repo" ]; then
        echo "Error: issue number, comment body, and repository are required" >&2
        exit 1
    fi
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) is required" >&2
        exit 1
    fi
    
    # Post comment using gh CLI
    echo "$comment_body" | gh api "repos/$repo/issues/$issue_num/comments" \
        --method POST \
        --field body=@- \
        --jq '.html_url' 2>/dev/null
    
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo "Error: Failed to post comment to issue #$issue_num" >&2
        exit 1
    fi
}

main() {
    local issue_num="$1"
    local comment_body="$2"
    
    if [ -z "$issue_num" ] || [ -z "$comment_body" ]; then
        echo "Error: issue number and comment body are required" >&2
        echo "Usage: $0 <issue_number> <comment_body>" >&2
        exit 1
    fi
    
    post_issue_comment "$issue_num" "$comment_body"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi




