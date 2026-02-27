# Force Delete Build Directory
# This script finds and stops processes locking the build directory, then deletes it

$buildPath = Join-Path $PSScriptRoot "build"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Force Delete Build Directory" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $buildPath)) {
    Write-Host "Build directory does not exist: $buildPath" -ForegroundColor Yellow
    exit 0
}

Write-Host "Build directory found: $buildPath" -ForegroundColor Green
Write-Host ""

# Method 1: Try to find processes using files in the directory
Write-Host "Checking for processes that might be locking files..." -ForegroundColor Cyan

# Get all file handles (requires admin or Handle.exe from Sysinternals)
$lockedFiles = @()

# Try using openfiles command (requires admin)
try {
    $openFiles = openfiles /query /fo csv 2>$null | ConvertFrom-Csv -ErrorAction SilentlyContinue
    if ($openFiles) {
        $lockedFiles = $openFiles | Where-Object { $_.'Accessed By' -and $_.'Files' -like "*$buildPath*" }
    }
} catch {
    Write-Host "Note: openfiles requires admin privileges. Trying alternative method..." -ForegroundColor Yellow
}

# Alternative: Check common processes that might lock files
$commonLockingProcesses = @(
    "dart",
    "flutter",
    "java",
    "gradle",
    "adb",
    "Code",  # VS Code
    "Cursor", # Cursor IDE
    "explorer"
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
    Write-Host "Found $($foundProcesses.Count) potentially locking process(es)." -ForegroundColor Yellow
    $response = Read-Host "Do you want to stop these processes? (Y/N)"
    
    if ($response -eq 'Y' -or $response -eq 'y') {
        foreach ($proc in $foundProcesses) {
            try {
                Write-Host "Stopping $($proc.ProcessName) (PID: $($proc.Id))..." -ForegroundColor Cyan
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Host "  Stopped successfully" -ForegroundColor Green
            } catch {
                Write-Host "  Failed to stop: $_" -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 2
    }
} else {
    Write-Host "No common locking processes found." -ForegroundColor Green
}

Write-Host ""
Write-Host "Attempting to delete build directory..." -ForegroundColor Cyan

# Try multiple deletion methods
$deleted = $false

# Method 1: Standard deletion
try {
    Remove-Item -Path $buildPath -Recurse -Force -ErrorAction Stop
    Write-Host "✓ Build directory deleted successfully!" -ForegroundColor Green
    $deleted = $true
} catch {
    Write-Host "✗ Standard deletion failed: $_" -ForegroundColor Red
    
    # Method 2: Delete files individually, then directory
    Write-Host "Trying to delete files individually..." -ForegroundColor Yellow
    try {
        Get-ChildItem -Path $buildPath -Recurse -Force | Remove-Item -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $buildPath -Force -ErrorAction Stop
        Write-Host "✓ Build directory deleted successfully (method 2)!" -ForegroundColor Green
        $deleted = $true
    } catch {
        Write-Host "✗ Individual file deletion failed: $_" -ForegroundColor Red
        
        # Method 3: Use robocopy to empty directory, then delete
        Write-Host "Trying robocopy method..." -ForegroundColor Yellow
        try {
            $emptyDir = Join-Path $env:TEMP "empty_build_$(Get-Random)"
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            robocopy $emptyDir $buildPath /MIR /R:0 /W:0 /NFL /NDL /NJH /NJS | Out-Null
            Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $buildPath -Force -ErrorAction Stop
            Write-Host "✓ Build directory deleted successfully (method 3)!" -ForegroundColor Green
            $deleted = $true
        } catch {
            Write-Host "✗ Robocopy method failed: $_" -ForegroundColor Red
        }
    }
}

if (-not $deleted) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Failed to delete build directory" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual steps to try:" -ForegroundColor Yellow
    Write-Host "1. Close all IDE windows (VS Code, Cursor, Android Studio)" -ForegroundColor White
    Write-Host "2. Close all file explorer windows" -ForegroundColor White
    Write-Host "3. Restart your computer" -ForegroundColor White
    Write-Host "4. Run this script again with administrator privileges" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use Handle.exe from Sysinternals to find the exact process:" -ForegroundColor Yellow
    Write-Host "  Download: https://docs.microsoft.com/en-us/sysinternals/downloads/handle" -ForegroundColor White
    Write-Host "  Usage: handle.exe -p [PID] | findstr build" -ForegroundColor White
    exit 1
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Success! Build directory deleted." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    exit 0
}

