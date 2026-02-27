-- Fix RLS Policy for Chat Messages Read Receipts
-- This allows users to mark received messages (from admin) as read
-- Run this in Supabase SQL Editor

-- Allow users to update read_at on messages they received (for read receipts)
-- This is needed because users need to mark admin messages as read
DROP POLICY IF EXISTS "Users can mark received messages as read" ON PUBLIC.CHAT_MESSAGES;
CREATE POLICY "Users can mark received messages as read" ON PUBLIC.CHAT_MESSAGES
    FOR UPDATE
    USING (
        -- User must be part of the conversation
        EXISTS (
            SELECT 1
            FROM PUBLIC.CHAT_CONVERSATIONS
            WHERE CHAT_CONVERSATIONS.ID = CHAT_MESSAGES.CONVERSATION_ID
            AND CHAT_CONVERSATIONS.USER_ID = AUTH.UID()
        )
        -- User can only update messages they didn't send (received messages)
        AND SENDER_ID != AUTH.UID()
    )
    WITH CHECK (
        -- Same conditions for the updated row
        EXISTS (
            SELECT 1
            FROM PUBLIC.CHAT_CONVERSATIONS
            WHERE CHAT_CONVERSATIONS.ID = CHAT_MESSAGES.CONVERSATION_ID
            AND CHAT_CONVERSATIONS.USER_ID = AUTH.UID()
        )
        AND SENDER_ID != AUTH.UID()
    );

-- Verify the policy was created
SELECT 
    '✅ RLS policy created successfully' AS STATUS,
    schemaname,
    tablename,
    policyname
FROM pg_policies
WHERE tablename = 'chat_messages'
AND policyname = 'Users can mark received messages as read';

