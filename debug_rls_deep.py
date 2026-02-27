import paramiko
import json

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def debug_rls_deep():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Debugging RLS Deeply...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        # 1. Get definition of is_admin function
        print("\n1. Definition of is_admin function:")
        sql_func = "SELECT pg_get_functiondef('public.is_admin'::regproc);"
        cmd_func = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_func}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_func)
        print(stdout.read().decode().strip())

        # 2. List all profiles and their roles
        print("\n2. Profiles and Roles:")
        sql_profiles = "SELECT id, role FROM public.profiles LIMIT 10;"
        cmd_profiles = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_profiles}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_profiles)
        output_profiles = stdout.read().decode().strip()
        print(output_profiles)

        # Parse profiles to find two different users
        lines = output_profiles.split('\n')
        users = []
        for line in lines:
            if '-' in line and '|' in line and 'id' not in line: # Simple parsing
                parts = line.split('|')
                if len(parts) >= 2:
                    uid = parts[0].strip()
                    role = parts[1].strip()
                    if len(uid) > 10: # Valid UUIDish
                        users.append({'id': uid, 'role': role})
        
        if len(users) >= 2:
            victim = users[0]['id']
            attacker = users[1]['id']
            print(f"\n3. Simulating Attack: User {attacker} tries to view orders of User {victim}")
            
            # Simulation SQL
            # We use SET LOCAL request.jwt.claim.sub to simulate Supabase Auth
            sql_sim = f"""
            BEGIN;
            -- Create a fake order for victim if none exists (just for test, rollback later)
            INSERT INTO public.orders (user_id, status, total_amount) VALUES ('{victim}', 'pending', 999.99);
            
            -- Switch to attacker
            SET LOCAL role authenticated;
            SET LOCAL "request.jwt.claim.sub" = '{attacker}';
            
            -- Try to read victim's orders
            SELECT count(*) FROM public.orders WHERE user_id = '{victim}';
            
            ROLLBACK;
            """
            
            # Need to escape the SQL properly for bash/docker exec
            # We'll write to a file on VPS to avoid quoting hell
            sftp = ssh.open_sftp()
            with sftp.file("/root/test_rls.sql", "w") as f:
                f.write(sql_sim)
            
            cmd_exec = f"cat /root/test_rls.sql | docker exec -i {db_container} psql -U postgres -d postgres"
            stdin, stdout, stderr = ssh.exec_command(cmd_exec)
            print(stdout.read().decode().strip())
            print(stderr.read().decode().strip())
            
            ssh.exec_command("rm /root/test_rls.sql")
        else:
            print("Not enough users found in profiles to simulate attack.")

    ssh.close()

if __name__ == "__main__":
    debug_rls_deep()
