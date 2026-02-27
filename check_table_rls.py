import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def check_table_rls():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Checking RLS status for cart_items and orders...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        # Check if RLS is enabled
        sql_status = "SELECT relname, relrowsecurity FROM pg_class WHERE relname IN ('cart_items', 'orders');"
        cmd_status = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_status}"'
        print("\nRLS Status (t=true/enabled, f=false/disabled):")
        stdin, stdout, stderr = ssh.exec_command(cmd_status)
        print(stdout.read().decode().strip())
        
        # Check existing policies
        sql_policies = "SELECT schemaname, tablename, policyname, cmd, qual, with_check FROM pg_policies WHERE tablename IN ('cart_items', 'orders');"
        cmd_policies = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_policies}"'
        print("\nExisting Policies:")
        stdin, stdout, stderr = ssh.exec_command(cmd_policies)
        print(stdout.read().decode().strip())

        # Check column types for user_id to ensure correct policy syntax
        sql_columns = "SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_name IN ('cart_items', 'orders') AND column_name = 'user_id';"
        cmd_columns = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_columns}"'
        print("\nColumn Types:")
        stdin, stdout, stderr = ssh.exec_command(cmd_columns)
        print(stdout.read().decode().strip())

    ssh.close()

if __name__ == "__main__":
    check_table_rls()
