#!/bin/bash

post_comment() {
  local issue_number="$1"
  local message="$2"
  local token="$3"
  local owner="$4"
  local repo_name="$5"

  # Validate required inputs
  if [ -z "$issue_number" ] || [ -z "$repo_name" ] || [ -z "$owner" ] || [ -z "$token" ] || [ -z "$message" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided." >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  echo "Attempting to post comment to issue #$issue_number in $repo_name"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"
  
  RESPONSE=$(curl -s -o response.json -w "%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    "$api_base_url/repos/$owner/$repo_name/issues/$issue_number/comments" \
    -d "{\"body\": \"$message\"}")

  echo "API Response Code: $RESPONSE"  
  cat response.json
    
  if [ "$RESPONSE" -eq 201 ]; then
    echo "result=success" >> $GITHUB_OUTPUT
  else
    echo "result=failure" >> $GITHUB_OUTPUT
    echo "error-message=Failed to post comment to issue #$issue_number.  Status: $RESPONSE" >> $GITHUB_OUTPUT
    echo "Error:  Failed to post comment to issue #$issue_number.  Status: $RESPONSE"
  fi

  rm -f response.json
}
