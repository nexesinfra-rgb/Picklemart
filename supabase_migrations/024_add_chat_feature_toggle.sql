-- Add Chat Feature Toggle to admin_features table
-- Run this in Supabase SQL Editor

-- Step 1: Insert chat_enabled feature if it doesn't exist
-- Using NOT EXISTS pattern for compatibility
INSERT INTO PUBLIC.ADMIN_FEATURES (
    FEATURE_KEY,
    FEATURE_VALUE,
    DESCRIPTION,
    CREATED_AT,
    UPDATED_AT
)
SELECT
    'chat_enabled',
    true,
    'Enable chat feature between users and admin',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1
    FROM PUBLIC.ADMIN_FEATURES
    WHERE FEATURE_KEY = 'chat_enabled'
);

-- Step 2: Verify feature was added
SELECT
    '✅ Chat feature toggle added successfully' AS STATUS,
    FEATURE_KEY,
    FEATURE_VALUE,
    DESCRIPTION
FROM PUBLIC.ADMIN_FEATURES
WHERE FEATURE_KEY = 'chat_enabled';

