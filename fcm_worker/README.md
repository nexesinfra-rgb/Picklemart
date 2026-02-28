# FCM Worker Setup for VPS

This folder contains a worker service that runs on your VPS to handle Firebase Cloud Messaging (FCM) notifications reliably. This bypasses the Supabase Edge Functions which are failing in your self-hosted environment.

## Prerequisites

1.  **Firebase Service Account Key**: You need the JSON file for your Firebase Service Account.
    - Go to [Firebase Console](https://console.firebase.google.com/) -> Project Settings -> Service Accounts.
    - Click "Generate new private key".
    - Save the file as `service-account.json` in this `fcm_worker` folder.
    - **IMPORTANT**: Replace the placeholder `service-account.json` that is currently in this folder.

2.  **SSH Access**: You need SSH access to your VPS (`72.62.229.227`).
    - Make sure you have your private key file (e.g., `id_ed25519` or `id_rsa`) handy.

## Deployment (Recommended)

1.  Open PowerShell in this directory:
    ```powershell
    cd fcm_worker
    ```

2.  Run the PowerShell deployment script:
    ```powershell
    .\deploy.ps1
    ```
    - Or if you want to specify the key path:
    ```powershell
    .\deploy.ps1 -KeyPath "C:\path\to\your\key"
    ```

3.  Follow the prompts.

## Deployment (Alternative - requires Python)

If you prefer Python and have it installed:

1.  Install dependencies:
    ```powershell
    pip install paramiko
    ```

2.  Run the Python deployment script:
    ```powershell
    python deploy.py
    ```

## What this does

- Creates a folder `/opt/fcm-worker` on your VPS.
- Uploads the worker script and your service account JSON.
- Installs necessary Python dependencies in a virtual environment on the VPS.
- Sets up a systemd service `fcm-worker` that runs automatically and restarts on failure.
- The worker polls your database every 5 seconds for new notifications in `user_notifications` table that haven't been pushed yet.
- It sends them using the FCM v1 API directly from the VPS.

## Troubleshooting

To check logs on the VPS:
```bash
ssh root@72.62.229.227
journalctl -u fcm-worker -f
```
