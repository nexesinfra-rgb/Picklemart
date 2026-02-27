-- ============================================================================
-- Add Rating ID to Notifications and Create Rating Reply Notification Trigger
-- ============================================================================

-- Step 1: Add rating_id column to user_notifications table
ALTER TABLE PUBLIC.USER_NOTIFICATIONS
ADD COLUMN IF NOT EXISTS RATING_ID UUID REFERENCES PUBLIC.PRODUCT_RATINGS(ID) ON DELETE CASCADE;

-- Step 2: Create index for rating_id
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_RATING_ID ON PUBLIC.USER_NOTIFICATIONS(RATING_ID) WHERE RATING_ID IS NOT NULL;

-- Step 3: Update CHECK constraint to allow rating_reply type
DO $$
BEGIN
    -- Drop existing constraint if it exists
    ALTER TABLE PUBLIC.USER_NOTIFICATIONS
    DROP CONSTRAINT IF EXISTS user_notifications_type_check;
    
    -- Add new constraint with rating_reply type
    ALTER TABLE PUBLIC.USER_NOTIFICATIONS
    ADD CONSTRAINT user_notifications_type_check
    CHECK (TYPE IN ('order_placed', 'order_status_changed', 'chat_message', 'rating_reply'));
END $$;

-- Step 4: Function to create notification on new rating reply
CREATE OR REPLACE FUNCTION PUBLIC.NOTIFY_RATING_REPLY()
RETURNS TRIGGER AS $$
DECLARE
    v_rating_owner_id UUID;
    v_reply_author_name TEXT;
    v_product_name TEXT;
    v_rating_id UUID;
    v_parent_reply_user_id UUID;
    v_notified_user_ids UUID[];
BEGIN
    v_rating_id := NEW.RATING_ID;
    
    -- Get rating owner (the person who wrote the original feedback)
    SELECT USER_ID INTO v_rating_owner_id
    FROM PUBLIC.PRODUCT_RATINGS
    WHERE ID = v_rating_id;
    
    -- Get reply author name
    SELECT COALESCE(NAME, EMAIL, 'Someone') INTO v_reply_author_name
    FROM PUBLIC.PROFILES
    WHERE ID = NEW.USER_ID;
    
    -- Get product name for notification
    SELECT P.NAME INTO v_product_name
    FROM PUBLIC.PRODUCT_RATINGS PR
    JOIN PUBLIC.PRODUCTS P ON P.ID = PR.PRODUCT_ID
    WHERE PR.ID = v_rating_id;
    
    -- Initialize array with rating owner
    v_notified_user_ids := ARRAY[v_rating_owner_id];
    
    -- If this is a reply to another reply, also notify the parent reply author
    IF NEW.PARENT_REPLY_ID IS NOT NULL THEN
        SELECT USER_ID INTO v_parent_reply_user_id
        FROM PUBLIC.RATING_REPLIES
        WHERE ID = NEW.PARENT_REPLY_ID;
        
        -- Add parent reply author to notification list if different from current user
        IF v_parent_reply_user_id IS NOT NULL AND v_parent_reply_user_id != NEW.USER_ID THEN
            v_notified_user_ids := array_append(v_notified_user_ids, v_parent_reply_user_id);
        END IF;
    END IF;
    
    -- Notify all relevant users (excluding the reply author)
    FOR i IN 1..array_length(v_notified_user_ids, 1) LOOP
        IF v_notified_user_ids[i] IS NOT NULL AND v_notified_user_ids[i] != NEW.USER_ID THEN
            -- Create notification
            INSERT INTO PUBLIC.USER_NOTIFICATIONS (
                USER_ID,
                TYPE,
                TITLE,
                MESSAGE,
                RATING_ID,
                IS_READ,
                CREATED_AT
            ) VALUES (
                v_notified_user_ids[i],
                'rating_reply',
                CASE 
                    WHEN NEW.PARENT_REPLY_ID IS NOT NULL THEN 
                        v_reply_author_name || ' replied to your comment'
                    ELSE 
                        v_reply_author_name || ' replied to your feedback'
                END,
                COALESCE(v_product_name, 'Product') || ': ' || 
                CASE 
                    WHEN LENGTH(NEW.REPLY_TEXT) > 100 THEN 
                        LEFT(NEW.REPLY_TEXT, 100) || '...'
                    ELSE 
                        NEW.REPLY_TEXT
                END,
                v_rating_id,
                FALSE,
                NOW()
            );
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

-- Step 5: Create trigger
DROP TRIGGER IF EXISTS TRIGGER_NOTIFY_RATING_REPLY ON PUBLIC.RATING_REPLIES;
CREATE TRIGGER TRIGGER_NOTIFY_RATING_REPLY
    AFTER INSERT ON PUBLIC.RATING_REPLIES
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.NOTIFY_RATING_REPLY();

-- Step 6: Add comments
COMMENT ON COLUMN PUBLIC.USER_NOTIFICATIONS.RATING_ID IS 'References product rating for rating reply notifications';
COMMENT ON FUNCTION PUBLIC.NOTIFY_RATING_REPLY() IS 'Automatically creates notifications when replies are added to product ratings. Notifies the original feedback author and parent reply authors.';

