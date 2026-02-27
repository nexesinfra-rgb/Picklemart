-- Create trigger to auto-send notifications on new chat messages
-- Run this in Supabase SQL Editor

-- Step 1: Function to create notification on new chat message
CREATE OR REPLACE FUNCTION PUBLIC.NOTIFY_CHAT_MESSAGE()
RETURNS TRIGGER AS $$
DECLARE
    v_recipient_id UUID;
    v_sender_name TEXT;
    v_conversation_id UUID;
BEGIN
    v_conversation_id := NEW.CONVERSATION_ID;
    
    -- Only notify if admin sent message (admin -> user)
    -- User messages don't trigger notifications (admin sees them in chat list)
    IF NEW.SENDER_ROLE = 'user' THEN
        RETURN NEW;
    END IF;
    
    -- Admin sent message, notify user
    SELECT USER_ID INTO v_recipient_id
    FROM PUBLIC.CHAT_CONVERSATIONS
    WHERE ID = v_conversation_id;
    
    IF v_recipient_id IS NOT NULL THEN
        -- Get sender name
        SELECT NAME INTO v_sender_name
        FROM PUBLIC.PROFILES
        WHERE ID = NEW.SENDER_ID;
        
        IF v_sender_name IS NULL THEN
            v_sender_name := 'Admin';
        END IF;
        
        -- Create notification
        INSERT INTO PUBLIC.USER_NOTIFICATIONS (
            USER_ID,
            TYPE,
            TITLE,
            MESSAGE,
            CONVERSATION_ID,
            IS_READ,
            CREATED_AT
        ) VALUES (
            v_recipient_id,
            'chat_message',
            'New message from ' || v_sender_name,
            COALESCE(NEW.CONTENT, 'New message'),
            v_conversation_id,
            FALSE,
            NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Step 2: Create trigger
DROP TRIGGER IF EXISTS TRIGGER_NOTIFY_CHAT_MESSAGE ON PUBLIC.CHAT_MESSAGES;
CREATE TRIGGER TRIGGER_NOTIFY_CHAT_MESSAGE
    AFTER INSERT ON PUBLIC.CHAT_MESSAGES
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.NOTIFY_CHAT_MESSAGE();

-- Step 3: Add comment
COMMENT ON FUNCTION PUBLIC.NOTIFY_CHAT_MESSAGE() IS 'Automatically creates a notification when an admin sends a chat message to a user';

