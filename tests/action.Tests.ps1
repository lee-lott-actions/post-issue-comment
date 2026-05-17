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
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
	    It "unit: Add-IssueComment succeeds with HTTP 201" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 201; Content = '{"id": 123, "body": "Test comment"}' }
	        }
	        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }
	}

	Context "HTTP Failure Cases" {
	    It "unit: Add-IssueComment fails with HTTP 404" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 404; Content = '{"message": "Issue not found"}' }
	        }
	        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Error: Failed to post comment to issue #1. HTTP Status: 404"
	    }	
	}

	Context "Parameter Validation Failure Cases" {
	    It "unit: Add-IssueComment fails with empty IssueNumber" {
	        Add-IssueComment -IssueNumber "" -Message $Message -Token $Token -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
	        $output | Should -Contain "result=failure"
	    }
	
	    It "unit: Add-IssueComment fails with empty Message" {
	        Add-IssueComment -IssueNumber $IssueNumber -Message "" -Token $Token -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
	        $output | Should -Contain "result=failure"
	    }
	
	    It "unit: Add-IssueComment fails with empty Token" {
	        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token "" -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
	        $output | Should -Contain "result=failure"
	    }
	
	    It "unit: Add-IssueComment fails with empty Owner" {
	        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner "" -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
	        $output | Should -Contain "result=failure"
	    }
	
	    It "unit: Add-IssueComment fails with empty RepoName" {
	        Add-IssueComment -IssueNumber $IssueNumber -Message $Message -Token $Token -Owner $Owner -RepoName ""
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, message, owner, and token must be provided."
	        $output | Should -Contain "result=failure"
	    }	
	}
	
	Context "Exception Failure Cases" {
		It "unit: Add-IssueComment fails with exception" {
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
}
