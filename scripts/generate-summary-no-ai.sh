#!/bin/bash
# Generate issue summary without AI - formats existing information

generate_no_ai_summary() {
    local issue_context="$1"
    
    if [ -z "$issue_context" ]; then
        echo "Error: issue_context is required" >&2
        exit 1
    fi
    
    local issue_title=$(echo "$issue_context" | jq -r '.issue.title')
    local issue_body=$(echo "$issue_context" | jq -r '.issue.body // ""')
    local issue_labels=$(echo "$issue_context" | jq -r '.issue.labels[]? // empty' | sed 's/^/- /')
    local linked_prs=$(echo "$issue_context" | jq -c '.linked_pull_requests // []')
    local relevant_files=$(echo "$issue_context" | jq -r '.relevant_files[]? // empty')
    
    # Start building summary
    local summary="## 📋 Issue Context Summary\n\n"
    
    # Add labels if present
    if [ -n "$issue_labels" ]; then
        summary+="**Labels:** $(echo "$issue_labels" | tr '\n' ' ' | sed 's/- //g' | sed 's/ $//')\n\n"
    fi
    
    # Process linked PRs
    local pr_count=$(echo "$linked_prs" | jq 'length')
    if [ "$pr_count" -gt 0 ]; then
        summary+="### Linked Pull Requests ($pr_count)\n\n"
        
        echo "$linked_prs" | jq -c '.[]' | while IFS= read -r pr; do
            local pr_num=$(echo "$pr" | jq -r '.number')
            local pr_title=$(echo "$pr" | jq -r '.title')
            local pr_state=$(echo "$pr" | jq -r '.state')
            local pr_merged=$(echo "$pr" | jq -r '.merged')
            local pr_additions=$(echo "$pr" | jq -r '.additions // 0')
            local pr_deletions=$(echo "$pr" | jq -r '.deletions // 0')
            local pr_changed_files=$(echo "$pr" | jq -r '.changed_files // 0')
            
            summary+="- **PR #$pr_num**: $pr_title\n"
            summary+="  - Status: $pr_state"
            if [ "$pr_merged" = "true" ]; then
                summary+=" (merged)"
            fi
            summary+="\n"
            summary+="  - Changes: +$pr_additions -$pr_deletions ($pr_changed_files files)\n\n"
        done
    fi
    
    # Add relevant files
    if [ -n "$relevant_files" ] && [ "$relevant_files" != "" ]; then
        local file_count=$(echo "$relevant_files" | wc -l | tr -d ' ')
        summary+="### Relevant Files ($file_count)\n\n"
        echo "$relevant_files" | head -n 20 | while IFS= read -r file; do
            if [ -n "$file" ]; then
                summary+="- \`$file\`\n"
            fi
        done
        summary+="\n"
    fi
    
    # Add issue details
    if [ -n "$issue_body" ] && [ "${#issue_body}" -gt 0 ]; then
        summary+="### Issue Description\n\n"
        # Truncate if too long
        if [ "${#issue_body}" -gt 500 ]; then
            summary+="$(echo "$issue_body" | head -c 500)...\n\n"
            summary+="*[Full description available in issue body]*\n\n"
        else
            summary+="$issue_body\n\n"
        fi
    fi
    
    summary+="---\n*This summary was generated automatically from issue and PR metadata.*\n"
    
    echo -e "$summary"
}

main() {
    local issue_context="$1"
    
    if [ -z "$issue_context" ]; then
        echo "Error: issue_context JSON is required" >&2
        echo "Usage: $0 <issue_context_json>" >&2
        exit 1
    fi
    
    generate_no_ai_summary "$issue_context"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

