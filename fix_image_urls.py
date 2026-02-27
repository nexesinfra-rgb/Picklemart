import paramiko
import time

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

# The old and new domains
OLD_DOMAIN = "https://bgqcuykvsiejgqeiefpi.supabase.co"
NEW_DOMAIN = "https://db.picklemart.cloud"

def fix_image_urls():
    print(f"Connecting to {VPS_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)
        print("Connected.")

        # Get database container ID
        cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
        stdin, stdout, stderr = ssh.exec_command(cmd_db)
        db_container = stdout.read().decode().strip()
        
        if not db_container:
            print("Error: Could not find Supabase DB container.")
            return

        print(f"Found DB Container: {db_container}")

        # SQL commands to run
        # We use a DO block to run multiple updates transactionally
        sql = f"""
DO $$
DECLARE
    updated_hero INT;
    updated_cat INT;
    updated_prod_url INT;
    updated_prod_imgs INT;
    updated_prof INT;
BEGIN
    -- 1. Hero Images
    UPDATE public.hero_images
    SET image_url = REPLACE(image_url, '{OLD_DOMAIN}', '{NEW_DOMAIN}')
    WHERE image_url LIKE '%{OLD_DOMAIN}%';
    GET DIAGNOSTICS updated_hero = ROW_COUNT;
    RAISE NOTICE 'Updated % hero images', updated_hero;

    -- 2. Categories
    UPDATE public.categories
    SET image_url = REPLACE(image_url, '{OLD_DOMAIN}', '{NEW_DOMAIN}')
    WHERE image_url LIKE '%{OLD_DOMAIN}%';
    GET DIAGNOSTICS updated_cat = ROW_COUNT;
    RAISE NOTICE 'Updated % categories', updated_cat;

    -- 3. Products (image_url)
    UPDATE public.products
    SET image_url = REPLACE(image_url, '{OLD_DOMAIN}', '{NEW_DOMAIN}')
    WHERE image_url LIKE '%{OLD_DOMAIN}%';
    GET DIAGNOSTICS updated_prod_url = ROW_COUNT;
    RAISE NOTICE 'Updated % products (primary image)', updated_prod_url;

    -- 4. Products (images array)
    -- We cast to text, replace, and cast back to text[]
    UPDATE public.products
    SET images = (REPLACE(images::text, '{OLD_DOMAIN}', '{NEW_DOMAIN}'))::text[]
    WHERE images::text LIKE '%{OLD_DOMAIN}%';
    GET DIAGNOSTICS updated_prod_imgs = ROW_COUNT;
    RAISE NOTICE 'Updated % products (images array)', updated_prod_imgs;

    -- 5. Profiles (avatar_url)
    UPDATE public.profiles
    SET avatar_url = REPLACE(avatar_url, '{OLD_DOMAIN}', '{NEW_DOMAIN}')
    WHERE avatar_url LIKE '%{OLD_DOMAIN}%';
    GET DIAGNOSTICS updated_prof = ROW_COUNT;
    RAISE NOTICE 'Updated % profiles', updated_prof;
    
    -- 6. Product Variants (images - handling as JSONB or Text[] based on typical usage)
    -- Attempting generic update on JSONB/Array columns if they exist
    BEGIN
        UPDATE public.product_variants
        SET images = (REPLACE(images::text, '{OLD_DOMAIN}', '{NEW_DOMAIN}'))::jsonb
        WHERE images::text LIKE '%{OLD_DOMAIN}%';
        RAISE NOTICE 'Updated product variants (if any)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Skipping product_variants update (table or column might differ)';
    END;

END $$;
"""
        # Write SQL to a temp file on the VPS
        sftp = ssh.open_sftp()
        with sftp.file("/root/fix_urls.sql", "w") as f:
            f.write(sql)
        sftp.close()
            
        # Execute the SQL file inside the docker container
        print("Executing fix script...")
        cmd_exec = f"cat /root/fix_urls.sql | docker exec -i {db_container} psql -U postgres -d postgres"
        stdin, stdout, stderr = ssh.exec_command(cmd_exec)
        
        output = stdout.read().decode().strip()
        error = stderr.read().decode().strip()
        
        if output: print(output)
        if error: print(error)
        
        # Cleanup
        ssh.exec_command("rm /root/fix_urls.sql")
        print("Done.")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    fix_image_urls()
