# Force Delete Build Directory (Non-Interactive)
# This script automatically tries multiple methods to delete the build directory

$buildPath = Join-Path $PSScriptRoot "build"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Force Delete Build Directory (Auto)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $buildPath)) {
    Write-Host "Build directory does not exist: $buildPath" -ForegroundColor Yellow
    exit 0
}

Write-Host "Build directory found: $buildPath" -ForegroundColor Green
Write-Host ""

# Check for common processes that might lock files
$commonLockingProcesses = @(
    "dart",
    "flutter",
    "java",
    "gradle",
    "adb"
)

Write-Host "Checking for common file-locking processes..." -ForegroundColor Cyan
$foundProcesses = @()

foreach ($procName in $commonLockingProcesses) {
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($proc in $procs) {
            $foundProcesses += $proc
            Write-Host "  Found: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Yellow
        }
    }
}

if ($foundProcesses.Count -gt 0) {
    Write-Host ""
    Write-Host "Stopping $($foundProcesses.Count) potentially locking process(es)..." -ForegroundColor Yellow
    foreach ($proc in $foundProcesses) {
        try {
            Write-Host "  Stopping $($proc.ProcessName) (PID: $($proc.Id))..." -ForegroundColor Cyan
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "  Failed to stop $($proc.ProcessName): $_" -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Host "No common locking processes found." -ForegroundColor Green
}

Write-Host ""
Write-Host "Attempting to delete build directory..." -ForegroundColor Cyan

# Try multiple deletion methods
$deleted = $false

# Method 1: Standard deletion
Write-Host "Method 1: Standard deletion..." -ForegroundColor Cyan
try {
    Remove-Item -Path $buildPath -Recurse -Force -ErrorAction Stop
    Write-Host "  ✓ Build directory deleted successfully!" -ForegroundColor Green
    $deleted = $true
} catch {
    Write-Host "  ✗ Failed: $_" -ForegroundColor Red
    
    # Method 2: Delete files individually, then directory
    Write-Host "Method 2: Deleting files individually..." -ForegroundColor Cyan
    try {
        Get-ChildItem -Path $buildPath -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Remove-Item -Path $buildPath -Force -ErrorAction Stop
        Write-Host "  ✓ Build directory deleted successfully!" -ForegroundColor Green
        $deleted = $true
    } catch {
        Write-Host "  ✗ Failed: $_" -ForegroundColor Red
        
        # Method 3: Use robocopy to empty directory, then delete
        Write-Host "Method 3: Using robocopy to empty directory..." -ForegroundColor Cyan
        try {
            $emptyDir = Join-Path $env:TEMP "empty_build_$(Get-Random)"
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            robocopy $emptyDir $buildPath /MIR /R:0 /W:0 /NFL /NDL /NJH /NJS | Out-Null
            Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Remove-Item -Path $buildPath -Force -ErrorAction Stop
            Write-Host "  ✓ Build directory deleted successfully!" -ForegroundColor Green
            $deleted = $true
        } catch {
            Write-Host "  ✗ Failed: $_" -ForegroundColor Red
        }
    }
}

Write-Host ""

if (-not $deleted) {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Failed to delete build directory" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "The build directory is still locked. Try:" -ForegroundColor Yellow
    Write-Host "1. Close all IDE windows (VS Code, Cursor, Android Studio)" -ForegroundColor White
    Write-Host "2. Close all file explorer windows showing the build folder" -ForegroundColor White
    Write-Host "3. Restart your computer" -ForegroundColor White
    Write-Host "4. Run: flutter clean (this may work even if manual deletion fails)" -ForegroundColor White
    exit 1
} else {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Success! Build directory deleted." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    exit 0
}


