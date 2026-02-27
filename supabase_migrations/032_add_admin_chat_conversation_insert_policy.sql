-- Add Admin INSERT Policy for Chat Conversations
-- This allows admins to create conversations on behalf of customers
-- Run this in Supabase SQL Editor

-- Admins can INSERT conversations for any user
-- This is needed so admins can initiate chats with customers from the customer management screen
DROP POLICY IF EXISTS "Admins can create conversations for any user" ON PUBLIC.CHAT_CONVERSATIONS;
CREATE POLICY "Admins can create conversations for any user" ON PUBLIC.CHAT_CONVERSATIONS
    FOR INSERT
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Verify the policy was created
SELECT 
    '✅ RLS policy created successfully' AS STATUS,
    schemaname,
    tablename,
    policyname
FROM pg_policies
WHERE tablename = 'chat_conversations'
AND policyname = 'Admins can create conversations for any user';

