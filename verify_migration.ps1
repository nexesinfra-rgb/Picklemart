# Supabase Edge Function Verification Script
$VPS_IP = "72.62.229.227"
$BASE_URL = "http://supabasekong-ogw8kswcww8swko0c8gswsks.$VPS_IP.sslip.io/functions/v1"
$ANON_KEY = "eyJ0eXAiOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs"

$functions = @(
    "create-customer-account",
    "delete-customer-account",
    "reverse-geocode",
    "send-admin-fcm-notification",
    "send-user-fcm-notification",
    "update-customer-account",
    "hello"
)

Write-Host "Verifying Edge Functions Migration on VPS..."
Write-Host "============================================================"

foreach ($func in $functions) {
    $url = "$BASE_URL/$func"
    if ($func -eq "send-admin-fcm-notification" -or $func -eq "send-user-fcm-notification") {
        $body = @{
            type = "test"
            title = "Test Notification"
            message = "This is a test verification message"
        } | ConvertTo-Json
        try {
            $response = Invoke-WebRequest -Uri $url -Method POST -Headers @{ "Authorization" = "Bearer $ANON_KEY"; "Content-Type" = "application/json" } -Body $body -ErrorAction SilentlyContinue
            $status = $response.StatusCode
            # Capture the response content for debugging 500 errors
            if ($status -eq 500) {
                 $errorContent = $response.Content
                 Write-Host "    Response Content: $errorContent" -ForegroundColor Yellow
            }
        } catch {
            if ($_.Exception.Response) {
                $status = $_.Exception.Response.StatusCode.value__
                # Read error response body
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $errorContent = $reader.ReadToEnd()
                Write-Host "    Error Content: $errorContent" -ForegroundColor Yellow
            } else {
                $status = "Error"
                Write-Host "    Exception: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } else {
        try {
            $response = Invoke-WebRequest -Uri $url -Method POST -Headers @{ "Authorization" = "Bearer $ANON_KEY" } -ErrorAction SilentlyContinue
            $status = $response.StatusCode
        } catch {
            if ($_.Exception.Response) {
                $status = $_.Exception.Response.StatusCode.value__
            } else {
                $status = "Error"
            }
        }
    }

    if ($status -eq 200) {
        Write-Host "PASSED: $func (Status: 200 OK)" -ForegroundColor Green
    } elseif ($status -eq 401) {
        Write-Host "PASSED: $func (Status: 401 Unauthorized - Function exists)" -ForegroundColor Green
    } elseif ($status -eq 400) {
        Write-Host "PASSED: $func (Status: 400 Bad Request - Function exists)" -ForegroundColor Green
    } else {
        Write-Host "FAILED: $func (Status: $status)" -ForegroundColor Red
    }
}

Write-Host "============================================================"
Write-Host "Note: 401 Unauthorized is GOOD. It means the function is active."
