@echo off
REM Build APK in loop until compilation errors are resolved

setlocal enabledelayedexpansion
set MAX_ATTEMPTS=1000
set ATTEMPT=0
set BUILD_SUCCESS=0

echo =========================================
echo APK Build Loop - Starting...
echo =========================================
echo.

REM Check if Flutter is available
flutter --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not installed or not in PATH!
    exit /b 1
)

echo Flutter version:
flutter --version
echo.

:BUILD_LOOP
set /a ATTEMPT+=1

echo ----------------------------------------
echo Build Attempt #%ATTEMPT%
echo ----------------------------------------
echo.

REM Clean on first attempt
if %ATTEMPT% EQU 1 (
    echo Cleaning build cache...
    flutter clean >nul 2>&1
    echo.
)

echo Building APK...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =========================================
    echo BUILD SUCCESSFUL!
    echo =========================================
    echo.
    echo APK Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Total attempts: %ATTEMPT%
    set BUILD_SUCCESS=1
    goto :END
) else (
    echo.
    echo Build failed with compilation errors. Retrying...
    echo.
    timeout /t 3 /nobreak >nul
)

if %ATTEMPT% LSS %MAX_ATTEMPTS% (
    goto :BUILD_LOOP
)

:END
if %BUILD_SUCCESS% EQU 0 (
    echo.
    echo =========================================
    echo BUILD FAILED after %ATTEMPT% attempts
    echo =========================================
    echo.
    echo Please check the errors above and fix them manually.
    exit /b 1
)

