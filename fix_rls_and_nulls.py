
import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def fix_rls_and_nulls():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Fixing RLS policies and NULL values...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if not db_container:
        print("DB container not found.")
        return

    # 1. RLS Policies
    # List of tables that might need RLS for supabase_auth_admin
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
    
    sql_commands = []
    for table in tables:
        policy_sql = f"""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'auth' AND tablename = '{table}' AND policyname = 'Auth admin full access') THEN
                CREATE POLICY "Auth admin full access" ON auth.{table} FOR ALL TO supabase_auth_admin USING (true) WITH CHECK (true);
            END IF;
        END $$;
        """
        sql_commands.append(policy_sql)
    
    # 2. Fix NULLs for admin user
    # Set potentially problematic nullable text columns to empty string
    null_fix_sql = "UPDATE auth.users SET recovery_token = COALESCE(recovery_token, ''), confirmation_token = COALESCE(confirmation_token, ''), email_change_token_new = COALESCE(email_change_token_new, '') WHERE email = 'admin@sm.com';"
    sql_commands.append(null_fix_sql)

    full_sql = "\n".join(sql_commands)
    
    # We pipe the SQL because it's long and contains quotes
    cmd_exec = f'echo "{full_sql}" | docker exec -i {db_container} psql -U postgres -d postgres'
    
    print("Executing SQL fixes...")
    stdin, stdout, stderr = ssh.exec_command(cmd_exec)
    print(stdout.read().decode().strip())
    print(stderr.read().decode().strip())

    ssh.close()

if __name__ == "__main__":
    fix_rls_and_nulls()
