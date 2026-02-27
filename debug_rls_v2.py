import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def debug_rls_v2():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Debugging RLS Deeply V2...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        # 1. Check profiles table RLS
        print("\n1. Checking profiles RLS status:")
        sql_prof = "SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'profiles';"
        cmd_prof = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_prof}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_prof)
        print(stdout.read().decode().strip())
        
        # 2. Get two users
        sql_users = "SELECT id FROM auth.users LIMIT 2;"
        cmd_users = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_users}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_users)
        output_users = stdout.read().decode().strip()
        
        users = []
        for line in output_users.split('\n'):
            if '-' in line and 'id' not in line:
                 uid = line.strip()
                 if len(uid) > 10:
                     users.append(uid)
                     
        if len(users) >= 2:
            victim = users[0]
            attacker = users[1]
            print(f"\n2. Simulating Attack: User {attacker} (Attacker) tries to view orders of User {victim} (Victim)")
            
            # Simulation SQL
            sql_sim = f"""
            BEGIN;
            -- Create a fake order for victim
            INSERT INTO public.orders (user_id, status, total) VALUES ('{victim}', 'pending', 10.00);
            
            -- Verify it exists as superuser
            RAISE NOTICE 'Superuser sees: %', (SELECT count(*) FROM public.orders WHERE user_id = '{victim}');
            
            -- Switch to attacker
            SET LOCAL role authenticated;
            SET LOCAL "request.jwt.claim.sub" = '{attacker}';
            
            -- Try to read victim's orders
            RAISE NOTICE 'Attacker sees: %', (SELECT count(*) FROM public.orders WHERE user_id = '{victim}');
            
            ROLLBACK;
            """
            
            sftp = ssh.open_sftp()
            with sftp.file("/root/test_rls_v2.sql", "w") as f:
                f.write(sql_sim)
            
            cmd_exec = f"cat /root/test_rls_v2.sql | docker exec -i {db_container} psql -U postgres -d postgres"
            stdin, stdout, stderr = ssh.exec_command(cmd_exec)
            print(stdout.read().decode().strip())
            print(stderr.read().decode().strip()) # Notices appear in stderr
            
            ssh.exec_command("rm /root/test_rls_v2.sql")
        else:
            print("Not enough users found.")

    ssh.close()

if __name__ == "__main__":
    debug_rls_v2()
