import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def debug_rls_v4():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Debugging RLS Deeply V4...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        # 1. Get two valid users
        sql_users = "SELECT id FROM auth.users WHERE id::text ~ '^[0-9a-f-]{36}$' LIMIT 2;"
        cmd_users = f'docker exec {db_container} psql -U postgres -d postgres -t -c "{sql_users}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_users)
        output_users = stdout.read().decode().strip()
        
        users = [line.strip() for line in output_users.split('\n') if line.strip()]
        
        if len(users) >= 2:
            victim = users[0]
            attacker = users[1]
            print(f"\nSimulating Attack: User {attacker} (Attacker) tries to view orders of User {victim} (Victim)")
            
            # Simulation SQL using DO block for better control
            sql_sim = f"""
DO $$
DECLARE
    v_count_super INT;
    v_count_attack INT;
BEGIN
    -- 1. Setup: Create dummy order as superuser
    INSERT INTO public.orders (user_id, status, total, subtotal, shipping, tax, delivery_address, order_number) 
    VALUES ('{victim}', 'pending', 10.00, 10.00, 0, 0, '{{}}', 'TEST-' || floor(random()*100000)::text);
    
    -- 2. Verify superuser visibility
    SELECT count(*) INTO v_count_super FROM public.orders WHERE user_id = '{victim}';
    RAISE NOTICE 'Superuser sees: % orders', v_count_super;
    
    -- 3. Switch identity to Attacker
    PERFORM set_config('role', 'authenticated', true);
    PERFORM set_config('request.jwt.claim.sub', '{attacker}', true);
    
    -- 4. Attempt to access Victim's data
    SELECT count(*) INTO v_count_attack FROM public.orders WHERE user_id = '{victim}';
    RAISE NOTICE 'Attacker sees: % orders', v_count_attack;
    
    RAISE EXCEPTION 'Test Complete - Rolling Back';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '%', SQLERRM;
END $$;
"""
            
            sftp = ssh.open_sftp()
            with sftp.file("/root/test_rls_v4.sql", "w") as f:
                f.write(sql_sim)
            
            cmd_exec = f"cat /root/test_rls_v4.sql | docker exec -i {db_container} psql -U postgres -d postgres"
            stdin, stdout, stderr = ssh.exec_command(cmd_exec)
            print(stdout.read().decode().strip())
            print(stderr.read().decode().strip()) 
            
            ssh.exec_command("rm /root/test_rls_v4.sql")
        else:
            print("Not enough users found.")

    ssh.close()

if __name__ == "__main__":
    debug_rls_v4()
