import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def fix_fcm_function():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Fixing send_fcm_push_notification function...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        # We need to escape single quotes in the SQL string for the python string, 
        # and then for the shell command.
        # It's safer to write to a file and execute.
        
        sql_func = """
CREATE OR REPLACE FUNCTION public.send_fcm_push_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_role TEXT;
    v_supabase_url TEXT;
    v_function_name TEXT;
    v_payload JSONB;
    v_response_id BIGINT;
    v_order_number TEXT;
BEGIN
    -- Get user role from profile
    SELECT role INTO v_user_role
    FROM PUBLIC.PROFILES
    WHERE id = NEW.USER_ID
    LIMIT 1;
    
    -- If profile not found, skip FCM
    IF v_user_role IS NULL THEN
        RAISE WARNING 'User profile not found for user_id: %', NEW.USER_ID;
        RETURN NEW;
    END IF;
    
    -- Get Supabase URL
    v_supabase_url := 'https://db.picklemart.cloud';
    
    -- Determine which edge function to call based on user role
    IF v_user_role = 'admin' OR v_user_role = 'manager' OR v_user_role = 'support' THEN
        v_function_name := 'send-admin-fcm-notification';
    ELSE
        v_function_name := 'send-user-fcm-notification';
    END IF;
    
    -- Get order number if order_id exists
    IF NEW.ORDER_ID IS NOT NULL THEN
        SELECT o.order_number INTO v_order_number
        FROM PUBLIC.ORDERS o
        WHERE o.id = NEW.ORDER_ID
        LIMIT 1;
    END IF;
    
    -- Build payload for edge function
    v_payload := jsonb_build_object(
        'type', NEW.TYPE,
        'title', NEW.TITLE,
        'message', NEW.MESSAGE,
        'order_id', COALESCE(NEW.ORDER_ID::TEXT, NULL),
        'order_number', v_order_number,
        'conversation_id', COALESCE(NEW.CONVERSATION_ID::TEXT, NULL)
    );
    
    -- For user notifications, include user_id to ensure we target the right user's devices
    -- The Edge Function will handle looking up the FCM tokens
    v_payload := v_payload || jsonb_build_object('user_id', NEW.USER_ID);
    
    -- Call the Edge Function via pg_net
    -- Note: We use the anon key because:
    -- 1. The edge functions handle authentication internally via service role key from environment
    -- 2. Edge functions validate the request and use service role key for FCM operations
    -- 3. The anon key is already public and used for client-side operations
    BEGIN
        SELECT net.http_post(
            url := v_supabase_url || '/functions/v1/' || v_function_name,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs',
                'apikey', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs'
            ),
            body := v_payload::text
        ) INTO v_response_id;
        
        -- Log the request ID for debugging
        RAISE NOTICE '[FCM] Queued HTTP request ID: % for notification % (user: %, type: %)', 
            v_response_id, NEW.ID, NEW.USER_ID, NEW.TYPE;
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING '[FCM] Failed to queue HTTP request for notification %: %', NEW.ID, SQLERRM;
    END;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error sending FCM push notification for notification % (user_id: %, type: %): %', 
            NEW.ID, NEW.USER_ID, NEW.TYPE, SQLERRM;
        RETURN NEW;
END;
$function$
"""
        sftp = ssh.open_sftp()
        with sftp.file("/root/fix_fcm.sql", "w") as f:
            f.write(sql_func)
            
        cmd_exec = f"cat /root/fix_fcm.sql | docker exec -i {db_container} psql -U postgres -d postgres"
        stdin, stdout, stderr = ssh.exec_command(cmd_exec)
        print(stdout.read().decode().strip())
        print(stderr.read().decode().strip())
        
        ssh.exec_command("rm /root/fix_fcm.sql")

    ssh.close()

if __name__ == "__main__":
    fix_fcm_function()
