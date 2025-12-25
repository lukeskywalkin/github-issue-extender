#!/bin/bash
# Base utilities for AI provider scripts

# Common error handling
handle_api_error() {
    local status_code=$1
    local response=$2
    
    case $status_code in
        401)
            echo "Error: Authentication failed. Check your API key." >&2
            exit 1
            ;;
        429)
            echo "Error: Rate limit exceeded. Please try again later." >&2
            exit 1
            ;;
        500|502|503|504)
            echo "Error: API server error (status $status_code). Please try again later." >&2
            exit 1
            ;;
        *)
            echo "Error: API request failed with status $status_code" >&2
            echo "Response: $response" >&2
            exit 1
            ;;
    esac
}

# Retry logic for API calls
# Note: This is a simplified retry wrapper - actual retry should be handled by calling code
# For now, we'll rely on curl's built-in retry or handle at a higher level
retry_api_call() {
    # For simplicity, just execute the command once
    # In production, you might want to implement actual retry logic here
    eval "$1"
}

