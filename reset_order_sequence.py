import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def reset_sequence():
    print(f"Connecting to {VPS_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Connected. Finding database container...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()

    if db_container:
        print(f"Found container: {db_container}")
        
        # SQL to delete all orders and reset sequence
        # We use TRUNCATE to clear the table efficiently and CASCADE to handle foreign keys
        sql = """
DO $$
BEGIN
    -- 1. Truncate orders table (clears all data)
    TRUNCATE TABLE public.orders CASCADE;
    
    -- 2. Reset the sequence to 4700
    ALTER SEQUENCE public.order_number_seq RESTART WITH 4700;
    
    RAISE NOTICE '✅ Orders table truncated and sequence reset to 4700.';
END $$;
"""
        # Write SQL to a temp file on the VPS
        sftp = ssh.open_sftp()
        with sftp.file("/root/reset_seq.sql", "w") as f:
            f.write(sql)
        sftp.close()
            
        # Execute the SQL file inside the docker container
        print("Executing reset script...")
        cmd_exec = f"cat /root/reset_seq.sql | docker exec -i {db_container} psql -U postgres -d postgres"
        stdin, stdout, stderr = ssh.exec_command(cmd_exec)
        
        output = stdout.read().decode().strip()
        error = stderr.read().decode().strip()
        
        if output: print(output)
        if error: print(error)
        
        # Cleanup
        ssh.exec_command("rm /root/reset_seq.sql")
        print("Done.")
    else:
        print("Error: Database container not found")
    
    ssh.close()

if __name__ == "__main__":
    reset_sequence()
