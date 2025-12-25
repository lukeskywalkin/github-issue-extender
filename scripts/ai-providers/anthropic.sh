#!/bin/bash
# Anthropic/Claude API integration

source "$(dirname "$0")/base.sh"

# Default model
DEFAULT_MODEL="claude-3-5-sonnet-20241022"

call_anthropic_api() {
    local api_key="${1:-$AI_API_KEY}"
    local model="${2}"
    if [ -z "$model" ]; then
        model="${AI_MODEL:-$DEFAULT_MODEL}"
    fi
    local prompt="$3"
    
    if [ -z "$api_key" ]; then
        echo "Error: AI_API_KEY is required for Anthropic provider" >&2
        exit 1
    fi
    
    # Prepare the request - Anthropic requires system message in a specific format
    local request_body=$(jq -n \
        --arg model "$model" \
        --arg content "You are a helpful assistant that analyzes GitHub issues and provides detailed elaborations based on code context, pull requests, and repository information.\n\n$prompt" \
        '{
            model: $model,
            max_tokens: 2000,
            messages: [
                {
                    role: "user",
                    content: $content
                }
            ]
        }')
    
    # Make the API call
    local response=$(curl -s -w "\n%{http_code}" -X POST 'https://api.anthropic.com/v1/messages' \
        -H 'Content-Type: application/json' \
        -H "x-api-key: $api_key" \
        -H 'anthropic-version: 2023-06-01' \
        -d "$request_body" 2>&1)
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ne 200 ] 2>/dev/null; then
        handle_api_error "$http_code" "$body"
        return 1
    fi
    
    # Extract the content from the response
    echo "$body" | jq -r '.content[0].text'
}

# Main entry point when script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    call_anthropic_api "$@"
fi
