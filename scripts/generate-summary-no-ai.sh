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
    local issue_labels=$(echo "$issue_context" | jq -r '.issue.labels[]? // empty' | head -n 10)
    local linked_prs=$(echo "$issue_context" | jq -c '.linked_pull_requests // []')
    local relevant_files=$(echo "$issue_context" | jq -r '.relevant_files[]? // empty')
    
    # Start building summary (use temp file to avoid subshell issues)
    local temp_summary=$(mktemp)
    echo "## 📋 Issue Context Summary" > "$temp_summary"
    echo "" >> "$temp_summary"
    
    # Add labels if present
    if [ -n "$issue_labels" ]; then
        local labels_formatted=$(echo "$issue_labels" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
        echo "**Labels:** $labels_formatted" >> "$temp_summary"
        echo "" >> "$temp_summary"
    fi
    
    # Process linked PRs
    local pr_count=$(echo "$linked_prs" | jq 'length')
    if [ "$pr_count" -gt 0 ]; then
        echo "### Linked Pull Requests ($pr_count)" >> "$temp_summary"
        echo "" >> "$temp_summary"
        
        echo "$linked_prs" | jq -c '.[]' | while IFS= read -r pr; do
            local pr_num=$(echo "$pr" | jq -r '.number')
            local pr_title=$(echo "$pr" | jq -r '.title')
            local pr_state=$(echo "$pr" | jq -r '.state')
            local pr_merged=$(echo "$pr" | jq -r '.merged')
            local pr_additions=$(echo "$pr" | jq -r '.additions // 0')
            local pr_deletions=$(echo "$pr" | jq -r '.deletions // 0')
            local pr_changed_files=$(echo "$pr" | jq -r '.changed_files // 0')
            
            echo "- **PR #$pr_num**: $pr_title" >> "$temp_summary"
            echo "  - Status: $pr_state$([ "$pr_merged" = "true" ] && echo " (merged)")" >> "$temp_summary"
            echo "  - Changes: +$pr_additions -$pr_deletions ($pr_changed_files files)" >> "$temp_summary"
            echo "" >> "$temp_summary"
        done
    fi
    
    # Add relevant files
    if [ -n "$relevant_files" ] && [ "$relevant_files" != "" ]; then
        local file_list=$(echo "$relevant_files" | head -n 20)
        local file_count=$(echo "$file_list" | grep -v '^$' | wc -l | tr -d ' ')
        if [ "$file_count" -gt 0 ]; then
            echo "### Relevant Files ($file_count)" >> "$temp_summary"
            echo "" >> "$temp_summary"
            echo "$file_list" | grep -v '^$' | while IFS= read -r file; do
                echo "- \`$file\`" >> "$temp_summary"
            done
            echo "" >> "$temp_summary"
        fi
    fi
    
    # Add issue details
    if [ -n "$issue_body" ] && [ "${#issue_body}" -gt 0 ]; then
        echo "### Issue Description" >> "$temp_summary"
        echo "" >> "$temp_summary"
        # Truncate if too long
        if [ "${#issue_body}" -gt 500 ]; then
            echo "$issue_body" | head -c 500 >> "$temp_summary"
            echo "..." >> "$temp_summary"
            echo "" >> "$temp_summary"
            echo "*[Full description available in issue body]*" >> "$temp_summary"
            echo "" >> "$temp_summary"
        else
            echo "$issue_body" >> "$temp_summary"
            echo "" >> "$temp_summary"
        fi
    fi
    
    echo "---" >> "$temp_summary"
    echo "*This summary was generated automatically from issue and PR metadata.*" >> "$temp_summary"
    
    cat "$temp_summary"
    rm -f "$temp_summary"
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

