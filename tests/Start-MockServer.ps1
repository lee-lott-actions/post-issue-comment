param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

function GetJsonBody($request) {
    $reader = New-Object System.IO.StreamReader($request.InputStream)
    $body = $reader.ReadToEnd()
    $reader.Close()
    if ($body) {
        try { return $body | ConvertFrom-Json } catch { return $null }
    } else {
        return $null
    }
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path   = $request.Url.LocalPath
        $method = $request.HttpMethod

        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $responseJson = $null
        $statusCode = 200

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # POST /repos/:owner/:repo/issues/:issue_number/comments
        elseif ($method -eq "POST" -and $path -match '^/repos/([^/]+)/([^/]+)/issues/([^/]+)/comments$') {
            $owner        = $Matches[1]
            $repo         = $Matches[2]
            $issue_number = $Matches[3]
            $bodyObj = GetJsonBody $request

            Write-Host "Request body: $(if ($bodyObj) { $bodyObj | ConvertTo-Json -Compress } else { '[null]' })"
            Write-Host "Request headers: $($request.Headers | Out-String)"

            if ($bodyObj -and $bodyObj.body -and ($bodyObj.body -is [string])) {
                if ($owner -eq "test-owner" -and $repo -eq "test-repo" -and $issue_number -eq "1") {
                    $statusCode = 201
                    $responseJson = @{ id = 123; body = $bodyObj.body } | ConvertTo-Json
                } else {
                    $statusCode = 404
                    $responseJson = @{ message = "Issue not found" } | ConvertTo-Json
                }
            }
            else {
                $statusCode = 400
                $responseJson = @{ message = "Invalid request: body must be a non-empty string" } | ConvertTo-Json
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json
        }

        # Send response
        $response.StatusCode = $statusCode
        $response.ContentType = "application/json"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}