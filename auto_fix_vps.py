import paramiko
import time
import sys

VPS_IP = "72.62.229.227"
VPS_USER = "root"
VPS_PASS = "Nexes@123456"
SSH_PUB_KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJa3EdpUv8EUVNA/UF1BSqnHxS6pGb0VhZ+NjfDuA4Z venky@VH"

# Container suffix found from debug
SUFFIX = "ogw8kswcww8swko0c8gswsks"
DB_CONTAINER = f"supabase-db-{SUFFIX}"
AUTH_CONTAINER = f"supabase-auth-{SUFFIX}"

def run_command(ssh, cmd, description):
    print(f"\n[Running] {description}...")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    
    if exit_status == 0:
        print(f"[Success] {description}")
        if out: print(f"Output: {out}")
    else:
        print(f"[Error] {description} failed with exit code {exit_status}")
        if out: print(f"Output: {out}")
        print(f"Stderr: {err}")
    return exit_status, out

def main():
    try:
        print(f"Connecting to {VPS_IP}...")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, password=VPS_PASS)
        print("Connected successfully!")

        # 1. Setup SSH Key & Directory
        setup_key_cmd = (
            f"mkdir -p ~/.ssh && "
            f"echo '{SSH_PUB_KEY}' >> ~/.ssh/authorized_keys && "
            f"chmod 600 ~/.ssh/authorized_keys && "
            f"chmod 700 ~/.ssh && "
            f"mkdir -p /root/sm"
        )
        run_command(ssh, setup_key_cmd, "Setting up SSH Key & Project Directory")

        # 2. Upload RLS Fix Script
        rls_sql_content = """
DO $$
BEGIN
    -- Fix users
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'auth' AND tablename = 'users' AND policyname = 'Auth admin full access') THEN
        CREATE POLICY "Auth admin full access" ON auth.users FOR ALL TO supabase_auth_admin USING (true) WITH CHECK (true);
    END IF;

    -- Fix audit_log_entries
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'auth' AND tablename = 'audit_log_entries' AND policyname = 'Auth admin full access') THEN
        CREATE POLICY "Auth admin full access" ON auth.audit_log_entries FOR ALL TO supabase_auth_admin USING (true) WITH CHECK (true);
    END IF;

    -- Fix sessions
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'auth' AND tablename = 'sessions' AND policyname = 'Auth admin full access') THEN
        CREATE POLICY "Auth admin full access" ON auth.sessions FOR ALL TO supabase_auth_admin USING (true) WITH CHECK (true);
    END IF;

    -- Fix refresh_tokens
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'auth' AND tablename = 'refresh_tokens' AND policyname = 'Auth admin full access') THEN
        CREATE POLICY "Auth admin full access" ON auth.refresh_tokens FOR ALL TO supabase_auth_admin USING (true) WITH CHECK (true);
    END IF;
    
    -- Fix identities
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'auth' AND tablename = 'identities' AND policyname = 'Auth admin full access') THEN
        CREATE POLICY "Auth admin full access" ON auth.identities FOR ALL TO supabase_auth_admin USING (true) WITH CHECK (true);
    END IF;
END $$;
"""
        print("\n[Uploading] fix_rls_policies.sql via SFTP...")
        sftp = ssh.open_sftp()
        with sftp.file("/root/sm/fix_rls_policies.sql", "w") as f:
            f.write(rls_sql_content)
        print("[Success] Uploaded fix_rls_policies.sql")

        # 3. Upload Verification Script (generate_hash_v2.sh)
        gen_hash_content = f"""
# Get the IP of the auth container
AUTH_IP=$(docker inspect -f '{{{{range .NetworkSettings.Networks}}}}{{{{.IPAddress}}}}{{{{end}}}}' {AUTH_CONTAINER})
ANON_KEY=$(docker exec {AUTH_CONTAINER} printenv SUPABASE_ANON_KEY)

echo "Auth IP: $AUTH_IP"
echo "Anon Key: $ANON_KEY"

# Signup temp user
curl -X POST "http://$AUTH_IP:9999/signup" \\
  -H "apikey: $ANON_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{{
    "email": "temp_fix_admin@sm.com",
    "password": "admin123"
  }}'

echo "\\nSignup request sent."
"""
        print("\n[Uploading] generate_hash_v2.sh via SFTP...")
        with sftp.file("/root/sm/generate_hash_v2.sh", "w") as f:
            f.write(gen_hash_content)
        print("[Success] Uploaded generate_hash_v2.sh")
        
        # 4. Apply RLS Fix
        apply_rls_cmd = f"cat /root/sm/fix_rls_policies.sql | docker exec -i {DB_CONTAINER} psql -U postgres -d postgres"
        run_command(ssh, apply_rls_cmd, "Applying RLS Fix")

        # 5. Disable Email Confirmation
        # Robust finding logic
        disable_email_cmd = f"""
# Try 1: Find via Mounts
SERVICE_DIR=$(docker inspect -f '{{{{range .Mounts}}}}{{{{.Source}}}}\\n{{{{end}}}}' {AUTH_CONTAINER} | grep "coolify" | head -n 1 | sed 's|/volumes.*||')
echo "Debug: Method 1 found: '$SERVICE_DIR'"

if [ -z "$SERVICE_DIR" ]; then
    # Try 2: Find via filesystem search (assuming coolify structure)
    echo "Debug: Method 1 failed, trying find..."
    SERVICE_DIR=$(find /data/coolify/services -maxdepth 2 -name ".env" -exec grep -l "GOTRUE" {{}} + | head -n 1 | xargs dirname)
    echo "Debug: Method 2 found: '$SERVICE_DIR'"
fi

if [ -z "$SERVICE_DIR" ]; then
    echo "Could not locate Coolify service directory."
    exit 1
fi

ENV_FILE="$SERVICE_DIR/.env"
echo "Target Env File: $ENV_FILE"

if [ -f "$ENV_FILE" ]; then
    if grep -q "GOTRUE_MAILER_AUTOCONFIRM" "$ENV_FILE"; then
        sed -i 's/GOTRUE_MAILER_AUTOCONFIRM=.*/GOTRUE_MAILER_AUTOCONFIRM=true/' "$ENV_FILE"
        echo "Updated existing variable."
    else
        echo "GOTRUE_MAILER_AUTOCONFIRM=true" >> "$ENV_FILE"
        echo "Appended new variable."
    fi
    docker restart {AUTH_CONTAINER}
else
    echo "Env file does not exist at $ENV_FILE"
    ls -la "$SERVICE_DIR"
    exit 1
fi
"""
        run_command(ssh, disable_email_cmd, "Disabling Email Confirmation")

        # 6. Verify Fix
        verify_cmd = "bash /root/sm/generate_hash_v2.sh"
        run_command(ssh, verify_cmd, "Verifying with generate_hash_v2.sh")

        ssh.close()
        print("\nAll operations completed.")

    except Exception as e:
        print(f"\n[Fatal Error] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
