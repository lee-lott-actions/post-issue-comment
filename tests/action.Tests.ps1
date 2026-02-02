Describe "Add-IssueComment" {
    BeforeAll {
        $script:IssueNumber = "1"
        $script:Message     = "Test comment"
        $script:Token       = "fake-token"
        $script:Owner       = "test-owner"
        $script:RepoName    = "test-repo"
        $script:MockApiUrl  = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
    BeforeEach {
        $env:GITHUB_OUTPUT = "$PSScriptRoot/github_output.temp"
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        $env:MOCK_API = $script:MockApiUrl
    }
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Variable -Name MOCK_API -Scope Global -ErrorAction SilentlyContinue
    }

    It "succeeds with HTTP 201" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 201; Content = '{"id": 123, "body": "Test comment"}' }
        }
        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=success"
    }

    It "fails with HTTP 403" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 403; Content = '{"message": "Forbidden"}' }
        }
        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Error: Failed to post comment to issue #1. HTTP Status: 403"
    }

    It "fails with HTTP 404" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 404; Content = '{"message": "Issue not found"}' }
        }
        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Error: Failed to post comment to issue #1. HTTP Status: 404"
    }

    It "fails with empty issue_number" {
        Add-IssueComment -IssueNumber "" -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
        $output | Should -Contain "result=failure"
    }

    It "fails with empty message" {
        Add-IssueComment -IssueNumber $IssueNumber -Message "" -Token $Token -Owner $Owner -RepoName $RepoName
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
        $output | Should -Contain "result=failure"
    }

    It "fails with empty token" {
        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token "" -Owner $Owner -RepoName $RepoName
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
        $output | Should -Contain "result=failure"
    }

    It "fails with empty owner" {
        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner "" -RepoName $RepoName
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
        $output | Should -Contain "result=failure"
    }

    It "fails with empty repo_name" {
        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName ""
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
        $output | Should -Contain "result=failure"
    }
	
	It "writes result=failure and error-message on exception" {
		Mock Invoke-WebRequest { throw "API Error" }

		try {
			Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
		} catch {}

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Where-Object { $_ -match "^error-message=Error: Failed to post comment to issue #$IssueNumber\. Exception:" } |
			Should -Not -BeNullOrEmpty
	}	
}