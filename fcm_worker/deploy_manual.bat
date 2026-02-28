@echo off
set VPS_IP=72.62.229.227
set VPS_USER=root

echo ==================================================================
echo FCM Worker Manual Deployment
echo ==================================================================
echo.
echo Please try password: Nexes@123456
echo If that fails, try:  Nexes@12345
echo.
echo You will be asked for the password multiple times.
echo ==================================================================
echo.

cd /d "%~dp0"

echo [1/4] Creating directory on VPS...
ssh %VPS_USER%@%VPS_IP% "mkdir -p /opt/fcm-worker"
if %errorlevel% neq 0 (
    echo Error connecting. Please check password.
    pause
    exit /b
)

echo.
echo [2/4] Uploading files...
echo Uploading fcm_worker.py...
scp fcm_worker.py %VPS_USER%@%VPS_IP%:/opt/fcm-worker/
echo Uploading requirements.txt...
scp requirements.txt %VPS_USER%@%VPS_IP%:/opt/fcm-worker/
echo Uploading service-account.json...
scp service-account.json %VPS_USER%@%VPS_IP%:/opt/fcm-worker/
echo Uploading service file...
scp fcm-worker.service %VPS_USER%@%VPS_IP%:/opt/fcm-worker/

echo.
echo [3/4] Installing dependencies on VPS (This might take a minute)...
ssh %VPS_USER%@%VPS_IP% "apt-get update && apt-get install -y python3-pip python3-venv && cd /opt/fcm-worker && python3 -m venv venv && /opt/fcm-worker/venv/bin/pip install -r requirements.txt"

echo.
echo [4/4] Starting the service...
ssh %VPS_USER%@%VPS_IP% "cp /opt/fcm-worker/fcm-worker.service /etc/systemd/system/ && systemctl daemon-reload && systemctl enable fcm-worker && systemctl restart fcm-worker && systemctl status fcm-worker --no-pager"

echo.
echo ==================================================================
echo Deployment Completed! 
echo Check the status above. If it says 'active (running)', you are good!
echo ==================================================================
pause
