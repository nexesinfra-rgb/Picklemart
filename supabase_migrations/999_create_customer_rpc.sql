-- Create Customer Account RPC Function
-- This function allows admins to create customer accounts directly via RPC, bypassing Edge Functions.
-- Run this in Supabase SQL Editor to enable the fallback mechanism.

-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create the RPC function
CREATE OR REPLACE FUNCTION create_customer_account_rpc(
  name text,
  mobile text,
  password text,
  gst_number text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with privileges of the creator (usually postgres/admin)
AS $$
DECLARE
  new_user_id uuid;
  email_val text;
  encrypted_pw text;
  check_role text;
  admin_record RECORD;
BEGIN
  -- 1. Check if the caller is an admin
  -- We check public.profiles for the role of the invoking user (auth.uid())
  SELECT role INTO check_role FROM public.profiles WHERE id = auth.uid();
  
  IF check_role NOT IN ('admin', 'manager', 'support') THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  -- 2. Validate inputs
  IF char_length(mobile) != 10 THEN
    RAISE EXCEPTION 'Invalid mobile number. Must be 10 digits.';
  END IF;

  IF char_length(password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters.';
  END IF;

  -- 3. Prepare data
  email_val := '91' || mobile || '@phone.local';
  encrypted_pw := crypt(password, gen_salt('bf'));
  new_user_id := gen_random_uuid();

  -- 4. Check if user already exists
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = email_val) THEN
    RAISE EXCEPTION 'User with this mobile number already exists.';
  END IF;

  -- 5. Insert into auth.users
  -- Note: We use a default instance_id (00000000-0000-0000-0000-000000000000) which is standard for Supabase
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    phone,
    confirmation_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    new_user_id,
    'authenticated',
    'authenticated',
    email_val,
    encrypted_pw,
    now(), -- Auto-confirm the user
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object('name', name, 'mobile', mobile),
    now(),
    now(),
    NULL, -- We use email as the identifier for phone-based auth in this app
    encode(gen_random_bytes(16), 'hex') -- Dummy confirmation token
  );

  -- 6. Insert into public.profiles
  INSERT INTO public.profiles (
    id,
    name,
    email,
    mobile,
    display_mobile,
    role,
    gst_number,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    name,
    email_val,
    mobile,
    mobile,
    'user', -- Default role is user
    gst_number,
    now(),
    now()
  );

  -- 7. TRIGGER NOTIFICATIONS FOR ADMINS
  -- This ensures the "send-admin-fcm-notification" Edge Function is eventually triggered
  -- via the existing database triggers on user_notifications table.
  BEGIN
    FOR admin_record IN 
        SELECT id FROM public.profiles WHERE role IN ('admin', 'manager', 'support')
    LOOP
        INSERT INTO public.user_notifications (
            user_id, type, title, message, is_read, created_at
        ) VALUES (
            admin_record.id,
            'customer_created',
            'New Customer Registered',
            'New customer ' || name || ' has been registered.',
            FALSE,
            now()
        );
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    -- Ignore notification errors, don't fail the transaction
    RAISE NOTICE 'Failed to create notifications: %', SQLERRM;
  END;

  -- 8. Return success response compatible with Edge Function response
  RETURN json_build_object(
    'success', true,
    'user', json_build_object(
      'id', new_user_id,
      'name', name,
      'mobile', mobile,
      'email', email_val,
      'password', password -- Return password so admin can see it (one-time)
    ),
    'message', 'Customer account created successfully via RPC'
  );
EXCEPTION
  WHEN OTHERS THEN
    -- Rollback is automatic in PL/PGSQL exceptions
    RAISE EXCEPTION 'Failed to create account: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users (so admins can call it)
GRANT EXECUTE ON FUNCTION create_customer_account_rpc(text, text, text, text) TO authenticated;

-- Comment
COMMENT ON FUNCTION create_customer_account_rpc IS 'Creates a new user account (auth + profile). Admin only. Bypass for Edge Function.';
