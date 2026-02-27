-- Add conversation_id column to user_notifications table for chat notifications
-- Run this in Supabase SQL Editor

-- Step 1: Add conversation_id column
ALTER TABLE PUBLIC.USER_NOTIFICATIONS
ADD COLUMN IF NOT EXISTS CONVERSATION_ID UUID REFERENCES PUBLIC.CHAT_CONVERSATIONS(ID) ON DELETE CASCADE;

-- Step 2: Create index for conversation_id
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_CONVERSATION_ID ON PUBLIC.USER_NOTIFICATIONS(CONVERSATION_ID) WHERE CONVERSATION_ID IS NOT NULL;

-- Step 3: Update CHECK constraint to allow chat_message type
-- Note: This assumes the table already has a CHECK constraint on TYPE
-- If it doesn't exist, you may need to add it
DO $$
BEGIN
    -- Check if the constraint exists and alter it
    IF EXISTS (
        SELECT 1
        FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
        WHERE TABLE_SCHEMA = 'public'
        AND TABLE_NAME = 'user_notifications'
        AND COLUMN_NAME = 'type'
    ) THEN
        -- Drop existing constraint if it exists
        ALTER TABLE PUBLIC.USER_NOTIFICATIONS
        DROP CONSTRAINT IF EXISTS user_notifications_type_check;
        
        -- Add new constraint with chat_message type
        ALTER TABLE PUBLIC.USER_NOTIFICATIONS
        ADD CONSTRAINT user_notifications_type_check
        CHECK (TYPE IN ('order_placed', 'order_status_changed', 'chat_message'));
    END IF;
END $$;

-- Step 4: Add comment
COMMENT ON COLUMN PUBLIC.USER_NOTIFICATIONS.CONVERSATION_ID IS 'References chat conversation for chat message notifications';

