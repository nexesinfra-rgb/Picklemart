import paramiko
import time
import re

hostname = "72.62.229.227"
username = "root"
password = "Nexes@123456"

def run_command(ssh, command):
    print(f"Running: {command}")
    stdin, stdout, stderr = ssh.exec_command(command)
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if out:
        print(f"Output:\n{out}")
    if err:
        print(f"Error:\n{err}")
    return exit_status, out

try:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Connecting to {hostname}...")
    # Force password authentication by disabling key search and agent
    client.connect(hostname, username=username, password=password, look_for_keys=False, allow_agent=False)
    print("Connected!")

    # 1. List all containers to find the DB
    print("\n--- Listing All Containers ---")
    run_command(client, "docker ps --format '{{.ID}}\t{{.Image}}\t{{.Names}}'")
    
    # 1. Find the Postgres container (attempt)
    print("\n--- Finding Postgres Container ---")
    # Try finding by name containing 'postgres' or 'db'
    cmd = "docker ps -q --filter name=postgres | head -n 1"
    status, db_container_id = run_command(client, cmd)
    
    if not db_container_id:
         cmd = "docker ps -q --filter name=db | head -n 1"
         status, db_container_id = run_command(client, cmd)
    
    if not db_container_id:
        # Try finding by image name if name filter fails
        cmd = "docker ps -q --filter ancestor=supabase/postgres | head -n 1"
        status, db_container_id = run_command(client, cmd)

    if not db_container_id:
        print("No postgres container found automatically. Please check the list above.")
        client.close()
        exit(1)
        
    print(f"Found Postgres container ID: {db_container_id}")
    
    # 5. Search for docker-compose.yml
    print("\n--- Searching for docker-compose.yml ---")
    
    # Search in common Coolify paths
    cmd = "find /data/coolify -name docker-compose.yml | xargs grep -l 'supabase/gotrue'"
    status, paths = run_command(client, cmd)
    
    if paths:
        print(f"Found compose files:\n{paths}")
        # Take the first one
        compose_file = paths.splitlines()[0]
        print(f"Editing {compose_file}...")
        
        # Read content
        status, content = run_command(client, f"cat {compose_file}")
        
        # Check image line
        print(f"\n--- Checking image definition in {compose_file} ---")
        # Handle potential quotes in image definition
        match = re.search(r"image:\s*['\"]?supabase/gotrue:([^'\"]+)['\"]?", content)
        if match:
            current_tag = match.group(1)
            print(f"Current tag in file: {current_tag}")
            
            # Downgrade to v2.158.1 to resolve schema mismatch
            new_tag = "v2.158.1"
            
            if current_tag != new_tag:
                print(f"Downgrading to {new_tag}...")
                
                # Backup
                run_command(client, f"cp {compose_file} {compose_file}.bak")
                
                # Replace with sed (handling quotes if present)
                # We use a flexible regex in sed to capture the version and replace it
                sed_cmd = f"sed -i \"s|image: 'supabase/gotrue:{current_tag}'|image: 'supabase/gotrue:{new_tag}'|g\" {compose_file}"
                run_command(client, sed_cmd)
                # Also try without quotes just in case
                sed_cmd_no_quotes = f"sed -i \"s|image: supabase/gotrue:{current_tag}|image: supabase/gotrue:{new_tag}|g\" {compose_file}"
                run_command(client, sed_cmd_no_quotes)
                
                # Apply changes
                dir_path = compose_file.rsplit('/', 1)[0]
                print(f"Applying changes in {dir_path}...")
                
                # Try docker compose
                cmd = f"cd {dir_path} && docker compose up -d --force-recreate"
                status, out = run_command(client, cmd)
                if status != 0:
                     print("docker compose failed, trying docker-compose...")
                     cmd = f"cd {dir_path} && docker-compose up -d --force-recreate"
                     run_command(client, cmd)
                     
                # Wait for it to come up
                print("Waiting for container to restart...")
                time.sleep(10)
                
                # Check status
                run_command(client, f"docker ps --filter name=auth")
            else:
                print("Already on target version.")
        else:
            print("Could not find image tag in compose file (regex failed).")
            run_command(client, f"grep 'supabase/gotrue' {compose_file}")

    else:
        print("No docker-compose.yml found containing supabase/gotrue.")

    client.close()

except Exception as e:
    print(f"An error occurred: {e}")
