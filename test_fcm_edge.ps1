$anon = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs"

$body = @{
    type = "order_placed"
    title = "TEST PUSH"
    message = "If you receive this, FCM is working"
    user_id = "9cd38a94-e639-4586-9d35-e4f088a76fb2"
} | ConvertTo-Json

$response = Invoke-RestMethod `
    -Method Post `
    -Uri "https://db.picklemart.cloud/functions/v1/send-user-fcm-notification" `
    -Headers @{
        apikey = $anon
        Authorization = "Bearer $anon"
        "Content-Type" = "application/json"
    } `
    -Body $body

$response | ConvertTo-Json -Depth 10

