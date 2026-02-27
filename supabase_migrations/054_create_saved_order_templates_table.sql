-- Create Saved Order Templates Table
-- IMPORTANT: Run this SQL in your Supabase SQL Editor
-- Go to: Supabase Dashboard > SQL Editor > New Query > Paste this > Run

-- Step 1: Create saved_order_templates table
CREATE TABLE IF NOT EXISTS PUBLIC.saved_order_templates (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    user_id UUID NOT NULL REFERENCES PUBLIC.profiles(id) ON DELETE CASCADE,
    template_name TEXT NOT NULL,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, template_name)
);

-- Step 2: Create indexes for saved_order_templates table
CREATE INDEX IF NOT EXISTS idx_saved_order_templates_user_id ON PUBLIC.saved_order_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_order_templates_created_at ON PUBLIC.saved_order_templates(created_at DESC);

-- Step 3: Create updated_at trigger (if handle_updated_at function exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_updated_at') THEN
        CREATE TRIGGER set_updated_at_saved_order_templates 
            BEFORE UPDATE ON PUBLIC.saved_order_templates 
            FOR EACH ROW 
            EXECUTE FUNCTION PUBLIC.handle_updated_at();
    END IF;
END $$;

-- Step 4: Enable RLS
ALTER TABLE PUBLIC.saved_order_templates ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies if they exist (for re-running)
DROP POLICY IF EXISTS "Users can view their own templates" ON PUBLIC.saved_order_templates;
DROP POLICY IF EXISTS "Users can insert their own templates" ON PUBLIC.saved_order_templates;
DROP POLICY IF EXISTS "Users can update their own templates" ON PUBLIC.saved_order_templates;
DROP POLICY IF EXISTS "Users can delete their own templates" ON PUBLIC.saved_order_templates;
DROP POLICY IF EXISTS "Admins can view all templates" ON PUBLIC.saved_order_templates;

-- Step 6: Create RLS policies
-- Policy: Users can view their own templates
CREATE POLICY "Users can view their own templates"
    ON PUBLIC.saved_order_templates
    FOR SELECT
    USING (user_id = AUTH.UID());

-- Policy: Users can insert their own templates
CREATE POLICY "Users can insert their own templates"
    ON PUBLIC.saved_order_templates
    FOR INSERT
    WITH CHECK (user_id = AUTH.UID());

-- Policy: Users can update their own templates
CREATE POLICY "Users can update their own templates"
    ON PUBLIC.saved_order_templates
    FOR UPDATE
    USING (user_id = AUTH.UID())
    WITH CHECK (user_id = AUTH.UID());

-- Policy: Users can delete their own templates
CREATE POLICY "Users can delete their own templates"
    ON PUBLIC.saved_order_templates
    FOR DELETE
    USING (user_id = AUTH.UID());

-- Policy: Admins can view all templates
CREATE POLICY "Admins can view all templates"
    ON PUBLIC.saved_order_templates
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.profiles
            WHERE id = AUTH.UID()
            AND role = 'admin'
        )
    );
