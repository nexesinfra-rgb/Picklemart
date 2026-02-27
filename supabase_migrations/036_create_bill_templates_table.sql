-- Create Bill Templates Table
-- Run this in Supabase SQL Editor

-- Step 1: Create bill_templates table
CREATE TABLE IF NOT EXISTS PUBLIC.BILL_TEMPLATES (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    TEMPLATE_TYPE TEXT NOT NULL CHECK (TEMPLATE_TYPE IN ('user', 'manufacturer')),
    TEMPLATE_NAME TEXT NOT NULL,
    IMAGE_URL TEXT NOT NULL,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for bill_templates table
CREATE INDEX IF NOT EXISTS IDX_BILL_TEMPLATES_TEMPLATE_TYPE ON PUBLIC.BILL_TEMPLATES(TEMPLATE_TYPE);
CREATE INDEX IF NOT EXISTS IDX_BILL_TEMPLATES_IS_ACTIVE ON PUBLIC.BILL_TEMPLATES(IS_ACTIVE);
CREATE INDEX IF NOT EXISTS IDX_BILL_TEMPLATES_TYPE_ACTIVE ON PUBLIC.BILL_TEMPLATES(TEMPLATE_TYPE, IS_ACTIVE) WHERE IS_ACTIVE = TRUE;

-- Step 3: Create updated_at trigger
CREATE TRIGGER SET_UPDATED_AT_BILL_TEMPLATES 
    BEFORE UPDATE ON PUBLIC.BILL_TEMPLATES 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Step 4: Enable RLS
ALTER TABLE PUBLIC.BILL_TEMPLATES ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
-- Policy: Everyone can view active templates
CREATE POLICY "Everyone can view active templates"
    ON PUBLIC.BILL_TEMPLATES
    FOR SELECT
    USING (IS_ACTIVE = TRUE);

-- Policy: Admins can view all templates
CREATE POLICY "Admins can view all templates"
    ON PUBLIC.BILL_TEMPLATES
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Policy: Admins can insert templates
CREATE POLICY "Admins can insert templates"
    ON PUBLIC.BILL_TEMPLATES
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Policy: Admins can update templates
CREATE POLICY "Admins can update templates"
    ON PUBLIC.BILL_TEMPLATES
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Policy: Admins can delete templates
CREATE POLICY "Admins can delete templates"
    ON PUBLIC.BILL_TEMPLATES
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Step 6: Add comments
COMMENT ON TABLE PUBLIC.BILL_TEMPLATES IS 'Stores bill format template images for user and manufacturer bills';
COMMENT ON COLUMN PUBLIC.BILL_TEMPLATES.TEMPLATE_TYPE IS 'Type of template: user or manufacturer';
COMMENT ON COLUMN PUBLIC.BILL_TEMPLATES.IMAGE_URL IS 'URL to the uploaded template image in Supabase storage';

