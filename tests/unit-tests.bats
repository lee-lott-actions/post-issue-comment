#!/usr/bin/env bats

# Load the Bash script containing the post_comment function
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  local output_file="response.json"

  # Copy the mock response to the specified output file to mimic curl -o response.json
  cp "$response_file" "$output_file"
  # Output only the HTTP status code to mimic curl -w "%{http_code}"
  echo "$http_code"
}


# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  rm -f response.json "$GITHUB_OUTPUT" mock_response.json
}

@test "unit: post_comment succeeds with HTTP 201" {
  echo '{"id": 123, "body": "Test comment"}' > mock_response.json
  curl() { mock_curl "201" mock_response.json; }
  export -f curl

  run post_comment "1" "Test comment" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=success" ]
}

@test "unit: post_comment fails with HTTP 403" {
  echo '{"message": "Forbidden"}' > mock_response.json
  curl() { mock_curl "403" mock_response.json; }
  export -f curl

  run post_comment "1" "Test comment" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Failed to post comment to issue #1.  Status: 403" ]
}

@test "unit: post_comment fails with HTTP 404" {
  echo '{"message": "Issue not found"}' > mock_response.json
  curl() { mock_curl "404" mock_response.json; }
  export -f curl

  run post_comment "1" "Test comment" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Failed to post comment to issue #1.  Status: 404" ]
}

@test "unit: post_comment fails with empty issue_number" {
  run post_comment "" "Test comment" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided." ]
}

@test "unit: post_comment fails with empty message" {
  run post_comment "1" "" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided." ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
}

@test "unit: post_comment fails with empty token" {
  run post_comment "1" "Test comment" "" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided." ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
}

@test "unit: post_comment fails with empty owner" {
  run post_comment "1" "Test comment" "fake-token" "" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided." ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
}

@test "unit: post_comment fails with empty repo_name" {
  run post_comment "1" "Test comment" "fake-token" "test-owner" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided." ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
}
