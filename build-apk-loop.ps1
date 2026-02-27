# Build APK in loop until compilation errors are resolved
# This script will continuously attempt to build the APK until it succeeds

$ErrorActionPreference = "Continue"
$maxAttempts = 1000  # Maximum number of build attempts
$attempt = 0
$buildSuccess = $false

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "APK Build Loop - Starting..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure we're in the project root directory
$projectRoot = $PSScriptRoot
Set-Location $projectRoot

# Check if Flutter is available
$flutterCheck = & flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter is not installed or not in PATH!" -ForegroundColor Red
    exit 1
}

Write-Host "Flutter version:" -ForegroundColor Cyan
Write-Host $flutterCheck
Write-Host ""

while (-not $buildSuccess -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "Build Attempt #$attempt" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host ""
    
    # Run Flutter clean first (only on first attempt)
    if ($attempt -eq 1) {
        Write-Host "Cleaning build cache..." -ForegroundColor Cyan
        & flutter clean 2>&1 | Out-Null
        Write-Host ""
    }
    
    # Run the build command and capture output
    Write-Host "Building APK..." -ForegroundColor Cyan
    $buildOutput = & flutter build apk --release 2>&1 | Tee-Object -Variable buildOutputVar
    
    # Check the exit code
    $exitCode = $LASTEXITCODE
    
    # Convert output to string for pattern matching
    $buildOutputString = $buildOutput | Out-String
    
    # Check for compilation errors in output
    $hasCompilationErrors = $false
    $hasBuildErrors = $false
    
    # Check for common compilation error patterns
    if ($buildOutputString -match "error:|Error:|ERROR:|compilation error|Compilation error|FAILURE|BUILD FAILED|Exception:|Exception in|Failed to|failed to compile|Compilation failed") {
        $hasCompilationErrors = $true
    }
    
    # Check exit code
    if ($exitCode -ne 0) {
        $hasBuildErrors = $true
    }
    
    # Check if build succeeded
    if ($buildOutputString -match "Built build.*app-release\.apk" -or $buildOutputString -match "✓ Built" -or ($exitCode -eq 0 -and -not $hasCompilationErrors -and -not $hasBuildErrors)) {
        $buildSuccess = $true
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host ""
        
        # Find the APK location
        $apkPath = Get-ChildItem -Path "build\app\outputs\flutter-apk" -Filter "app-release.apk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($apkPath) {
            Write-Host "APK Location: $($apkPath.FullName)" -ForegroundColor Green
        } else {
            Write-Host "APK Location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
        }
        Write-Host ""
        Write-Host "Total attempts: $attempt" -ForegroundColor Cyan
        break
    } else {
        Write-Host ""
        Write-Host "Build failed with compilation errors. Retrying..." -ForegroundColor Red
        Write-Host ""
        
        # Show last few lines of error output for debugging
        $errorLines = $buildOutputString -split "`n" | Select-Object -Last 10
        Write-Host "Last error lines:" -ForegroundColor Yellow
        $errorLines | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        Write-Host ""
        
        # Wait a bit before retrying
        Start-Sleep -Seconds 3
    }
}

if (-not $buildSuccess) {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "BUILD FAILED after $attempt attempts" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the errors above and fix them manually." -ForegroundColor Yellow
    exit 1
}

# Return to original directory
Set-Location $projectRoot

