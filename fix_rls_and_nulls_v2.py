
import paramiko
import os

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def fix_rls_and_nulls_v2():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Generating SQL file...")
    tables = [
        "one_time_tokens",
        "mfa_factors", 
        "mfa_challenges", 
        "mfa_amr_claims", 
        "sso_providers", 
        "sso_domains", 
        "saml_providers", 
        "saml_relay_states", 
        "flow_state"
    ]
    
    sql_lines = []
    for table in tables:
        sql_lines.append(f"""
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'auth' AND tablename = '{table}' AND policyname = 'Auth admin full access') THEN
        CREATE POLICY "Auth admin full access" ON auth.{table} FOR ALL TO supabase_auth_admin USING (true) WITH CHECK (true);
    END IF;
END $$;
""")
    
    # Fix NULLs
    sql_lines.append("UPDATE auth.users SET recovery_token = COALESCE(recovery_token, ''), confirmation_token = COALESCE(confirmation_token, ''), email_change_token_new = COALESCE(email_change_token_new, '') WHERE email = 'admin@sm.com';")
    
    full_sql = "\n".join(sql_lines)
    
    # Write to local temp file
    local_file = "temp_fix_rls.sql"
    with open(local_file, "w") as f:
        f.write(full_sql)
        
    print("Uploading SQL file to VPS...")
    sftp = ssh.open_sftp()
    sftp.put(local_file, "/root/temp_fix_rls.sql")
    sftp.close()
    
    # Execute
    print("Executing SQL on DB container...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        cmd_exec = f"cat /root/temp_fix_rls.sql | docker exec -i {db_container} psql -U postgres -d postgres"
        stdin, stdout, stderr = ssh.exec_command(cmd_exec)
        print(stdout.read().decode().strip())
        print(stderr.read().decode().strip())
        
        # Cleanup
        ssh.exec_command("rm /root/temp_fix_rls.sql")
    else:
        print("DB container not found.")

    ssh.close()
    os.remove(local_file)

if __name__ == "__main__":
    fix_rls_and_nulls_v2()
