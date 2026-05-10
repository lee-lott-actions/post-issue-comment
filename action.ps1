function Add-IssueComment {
    param(
        [string]$IssueNumber,
        [string]$Message,
        [string]$Token,
        [string]$Owner,
        [string]$RepoName
    )

    # Validate required parameters
    if ([string]::IsNullOrEmpty($IssueNumber) -or
        [string]::IsNullOrEmpty($RepoName) -or
        [string]::IsNullOrEmpty($Owner) -or
        [string]::IsNullOrEmpty($Token) -or
        [string]::IsNullOrEmpty($Message)) {
        Write-Host "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    Write-Host "Attempting to post comment to issue #$IssueNumber in $RepoName"

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/repos/$Owner/$RepoName/issues/$IssueNumber/comments"

    $headers = @{
        Authorization = "Bearer $Token"
        Accept = "application/vnd.github.v3+json"
		"X-GitHub-Api-Version" = "2026-03-10"
        "Content-Type" = "application/json"
    }

    $jsonBody = @{
        body = $Message
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $jsonBody

        Write-Host "API Response Code: $($response.StatusCode)"
        Write-Host $response.Content

        if ($response.StatusCode -eq 201) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
			$errorMsg = "Error: Failed to post comment to issue #$IssueNumber. HTTP Status: $($response.StatusCode)"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
            Write-Host $errorMsg
        }
    } catch {
		$errorMsg = "Error: Failed to post comment to issue #$IssueNumber. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
    }
}
