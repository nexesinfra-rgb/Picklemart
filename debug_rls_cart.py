import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def debug_rls_cart():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Debugging RLS for Cart Items...")
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
            print(f"\nSimulating Attack: User {attacker} (Attacker) tries to view cart of User {victim} (Victim)")
            
            # Note: We need a valid product_id for the insert to work if there is an FK constraint.
            # Let's get a product id first.
            sql_prod = "SELECT id FROM public.products LIMIT 1;"
            cmd_prod = f'docker exec {db_container} psql -U postgres -d postgres -t -c "{sql_prod}"'
            stdin, stdout, stderr = ssh.exec_command(cmd_prod)
            product_id = stdout.read().decode().strip()
            
            if not product_id:
                print("No products found. Cannot simulate cart insert accurately with FK.")
                # We can try to insert without FK check if we are superuser, but RLS tests need real conditions usually.
                # Or we can insert a dummy product.
                product_id = '00000000-0000-0000-0000-000000000000' # Placeholder, might fail FK
            
            # Simulation SQL
            sql_sim = f"""
DO $$
DECLARE
    v_count_super INT;
    v_count_attack INT;
    v_prod_id UUID;
BEGIN
    -- Get or create a product for testing
    SELECT id INTO v_prod_id FROM public.products LIMIT 1;
    IF v_prod_id IS NULL THEN
        INSERT INTO public.products (name, price, stock_quantity, description, category_id, image_url)
        VALUES ('Test Product', 10.0, 100, 'Test', NULL, 'http://test.com')
        RETURNING id INTO v_prod_id;
    END IF;

    -- 1. Setup: Create cart item as superuser
    INSERT INTO public.cart_items (user_id, product_id, quantity) 
    VALUES ('{victim}', v_prod_id, 1);
    
    -- 2. Verify superuser visibility
    SELECT count(*) INTO v_count_super FROM public.cart_items WHERE user_id = '{victim}';
    RAISE NOTICE 'Superuser sees: % cart items', v_count_super;
    
    -- 3. Switch identity to Attacker
    PERFORM set_config('role', 'authenticated', true);
    PERFORM set_config('request.jwt.claim.sub', '{attacker}', true);
    
    -- 4. Attempt to access Victim's cart
    SELECT count(*) INTO v_count_attack FROM public.cart_items WHERE user_id = '{victim}';
    RAISE NOTICE 'Attacker sees: % cart items', v_count_attack;
    
    RAISE EXCEPTION 'Test Complete - Rolling Back';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '%', SQLERRM;
END $$;
"""
            
            sftp = ssh.open_sftp()
            with sftp.file("/root/test_rls_cart.sql", "w") as f:
                f.write(sql_sim)
            
            cmd_exec = f"cat /root/test_rls_cart.sql | docker exec -i {db_container} psql -U postgres -d postgres"
            stdin, stdout, stderr = ssh.exec_command(cmd_exec)
            print(stdout.read().decode().strip())
            print(stderr.read().decode().strip()) 
            
            ssh.exec_command("rm /root/test_rls_cart.sql")
        else:
            print("Not enough users found.")

    ssh.close()

if __name__ == "__main__":
    debug_rls_cart()
