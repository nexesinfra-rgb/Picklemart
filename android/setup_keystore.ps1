# Keystore Setup Script for Pickle Mart
# This script helps you generate the keystore file needed for release signing

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pickle Mart - Keystore Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if keystore already exists
$keystorePath = "app\upload-keystore.jks"
if (Test-Path $keystorePath) {
    Write-Host "WARNING: Keystore file already exists at: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "Keystore generation cancelled." -ForegroundColor Yellow
        exit
    }
}

Write-Host "This script will generate a keystore file for signing your Android app." -ForegroundColor Green
Write-Host ""
Write-Host "You will be prompted to enter:" -ForegroundColor Yellow
Write-Host "  - Keystore password (choose a strong password)" -ForegroundColor Yellow
Write-Host "  - Key password (can be same as keystore password)" -ForegroundColor Yellow
Write-Host "  - Your name or company name" -ForegroundColor Yellow
Write-Host "  - Organization unit (optional)" -ForegroundColor Yellow
Write-Host "  - Organization name" -ForegroundColor Yellow
Write-Host "  - City" -ForegroundColor Yellow
Write-Host "  - State/Province" -ForegroundColor Yellow
Write-Host "  - Country code (2 letters, e.g., US, IN, GB)" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: Save your passwords securely! You'll need them to sign future releases." -ForegroundColor Red
Write-Host ""

$continue = Read-Host "Press Enter to continue or Ctrl+C to cancel"
Write-Host ""

# Generate keystore
Write-Host "Generating keystore..." -ForegroundColor Green
Write-Host ""

$keytoolCommand = "keytool -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias upload"

try {
    Invoke-Expression $keytoolCommand
    
    if (Test-Path $keystorePath) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Keystore generated successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Copy 'key.properties.example' to 'key.properties'" -ForegroundColor White
        Write-Host "2. Open 'key.properties' and fill in your keystore passwords" -ForegroundColor White
        Write-Host "3. Verify the setup by running: flutter build appbundle --release" -ForegroundColor White
        Write-Host ""
        Write-Host "Remember: Never commit key.properties or the keystore file to version control!" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Keystore file was not created. Please check the error messages above." -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to generate keystore." -ForegroundColor Red
    Write-Host "Make sure Java JDK is installed and 'keytool' is in your PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "You can also generate the keystore manually by running:" -ForegroundColor Yellow
    Write-Host "  keytool -genkey -v -keystore app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload" -ForegroundColor White
}

