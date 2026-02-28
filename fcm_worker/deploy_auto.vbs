Set WshShell = WScript.CreateObject("WScript.Shell")
VPS_IP = "72.62.229.227"
VPS_USER = "root"
PASSWORD = "Nexes@123456"

' Warning
MsgBox "I will now open a terminal and type the commands for you automatically." & vbCrLf & "Please DO NOT touch your keyboard or mouse until it finishes!", 64, "Starting Deployment"

' Start cmd.exe
WshShell.Run "cmd.exe"
WScript.Sleep 1000

' Change directory
Path = "C:\Users\Shiva\Downloads\Pickle mart(25-02-2026)\Pickle mart(25-02-2026)\sm\fcm_worker"
WshShell.SendKeys "cd /d """ & Path & """"
WshShell.SendKeys "{ENTER}"
WScript.Sleep 500

' 1. Mkdir
WshShell.SendKeys "ssh " & VPS_USER & "@" & VPS_IP & " ""mkdir -p /opt/fcm-worker"""
WshShell.SendKeys "{ENTER}"
WScript.Sleep 5000 ' Wait for password prompt
WshShell.SendKeys PASSWORD
WshShell.SendKeys "{ENTER}"
WScript.Sleep 2000

' 2. SCP Files
WshShell.SendKeys "scp fcm_worker.py requirements.txt service-account.json fcm-worker.service " & VPS_USER & "@" & VPS_IP & ":/opt/fcm-worker/"
WshShell.SendKeys "{ENTER}"
WScript.Sleep 5000
WshShell.SendKeys PASSWORD
WshShell.SendKeys "{ENTER}"
WScript.Sleep 8000 ' Upload takes time

' 3. Setup and Start Service (Split into two parts to avoid buffer issues)
' Part 1: Install
WshShell.SendKeys "ssh " & VPS_USER & "@" & VPS_IP & " ""apt-get update && apt-get install -y python3-pip python3-venv && cd /opt/fcm-worker && python3 -m venv venv && /opt/fcm-worker/venv/bin/pip install -r requirements.txt"""
WshShell.SendKeys "{ENTER}"
WScript.Sleep 5000
WshShell.SendKeys PASSWORD
WshShell.SendKeys "{ENTER}"
WScript.Sleep 20000 ' Wait for install

' Part 2: Service Config
WshShell.SendKeys "ssh " & VPS_USER & "@" & VPS_IP & " ""cp /opt/fcm-worker/fcm-worker.service /etc/systemd/system/ && systemctl daemon-reload && systemctl enable fcm-worker && systemctl restart fcm-worker && systemctl status fcm-worker --no-pager"""
WshShell.SendKeys "{ENTER}"
WScript.Sleep 3000
WshShell.SendKeys PASSWORD
WshShell.SendKeys "{ENTER}"

MsgBox "Deployment Completed! Check the terminal window for 'active (running)' status.", 64, "Finished"
