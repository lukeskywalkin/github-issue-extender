#!/bin/bash
# Groq API integration - Fast inference with free tier

source "$(dirname "$0")/base.sh"

# Default model - Groq supports various models like llama-3.1-70b-versatile, mixtral-8x7b-32768
DEFAULT_MODEL="llama-3.1-70b-versatile"

call_groq_api() {
    local api_key="${1:-$AI_API_KEY}"
    local model="${2}"
    if [ -z "$model" ]; then
        model="${AI_MODEL:-$DEFAULT_MODEL}"
    fi
    local prompt="$3"
    
    if [ -z "$api_key" ]; then
        echo "Error: AI_API_KEY is required for Groq provider" >&2
        exit 1
    fi
    
    # Prepare the request - Groq uses OpenAI-compatible API format
    local request_body=$(jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        '{
            model: $model,
            messages: [
                {
                    role: "system",
                    content: "You are a helpful assistant that analyzes GitHub issues and provides detailed elaborations based on code context, pull requests, and repository information."
                },
                {
                    role: "user",
                    content: $content
                }
            ],
            temperature: 0.7,
            max_tokens: 2000
        }')
    
    # Make the API call - Groq uses OpenAI-compatible endpoint
    local response=$(curl -s -w "\n%{http_code}" -X POST 'https://api.groq.com/openai/v1/chat/completions' \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $api_key" \
        -d "$request_body" 2>&1)
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ne 200 ] 2>/dev/null; then
        handle_api_error "$http_code" "$body"
        return 1
    fi
    
    # Extract the content from the response (OpenAI-compatible format)
    echo "$body" | jq -r '.choices[0].message.content'
}

# Main entry point when script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    call_groq_api "$@"
fi

