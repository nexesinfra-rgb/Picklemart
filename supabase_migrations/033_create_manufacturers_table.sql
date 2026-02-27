-- Create Manufacturers Table
-- This migration creates the manufacturers table with full GST details

-- Step 1: Create manufacturers table
CREATE TABLE IF NOT EXISTS PUBLIC.MANUFACTURERS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    NAME TEXT NOT NULL,
    GST_NUMBER TEXT NOT NULL UNIQUE,
    BUSINESS_NAME TEXT NOT NULL,
    BUSINESS_ADDRESS TEXT NOT NULL,
    CITY TEXT NOT NULL,
    STATE TEXT NOT NULL,
    PINCODE TEXT NOT NULL,
    EMAIL TEXT,
    PHONE TEXT,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for optimization
CREATE INDEX IF NOT EXISTS IDX_MANUFACTURERS_NAME ON PUBLIC.MANUFACTURERS(NAME);
CREATE INDEX IF NOT EXISTS IDX_MANUFACTURERS_GST_NUMBER ON PUBLIC.MANUFACTURERS(GST_NUMBER);
CREATE INDEX IF NOT EXISTS IDX_MANUFACTURERS_IS_ACTIVE ON PUBLIC.MANUFACTURERS(IS_ACTIVE);
CREATE INDEX IF NOT EXISTS IDX_MANUFACTURERS_CREATED_AT ON PUBLIC.MANUFACTURERS(CREATED_AT DESC);

-- Composite index for optimized active manufacturers queries
CREATE INDEX IF NOT EXISTS IDX_MANUFACTURERS_ACTIVE_CREATED ON PUBLIC.MANUFACTURERS(IS_ACTIVE, CREATED_AT DESC)
WHERE IS_ACTIVE = TRUE;

-- Step 3: Create updated_at trigger
DROP TRIGGER IF EXISTS SET_UPDATED_AT_MANUFACTURERS ON PUBLIC.MANUFACTURERS;
CREATE TRIGGER SET_UPDATED_AT_MANUFACTURERS BEFORE
UPDATE ON PUBLIC.MANUFACTURERS FOR EACH ROW EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Step 4: Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.MANUFACTURERS ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies for manufacturers table
-- Admins can SELECT all manufacturers
DROP POLICY IF EXISTS "Admins can view all manufacturers" ON PUBLIC.MANUFACTURERS;
CREATE POLICY "Admins can view all manufacturers" ON PUBLIC.MANUFACTURERS FOR
SELECT
    TO AUTHENTICATED
    USING (
        EXISTS (
            SELECT
                1
            FROM
                PUBLIC.PROFILES
            WHERE
                ID = AUTH.UID()
                AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Admins can INSERT manufacturers
DROP POLICY IF EXISTS "Admins can insert manufacturers" ON PUBLIC.MANUFACTURERS;
CREATE POLICY "Admins can insert manufacturers" ON PUBLIC.MANUFACTURERS FOR INSERT TO AUTHENTICATED WITH CHECK (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Admins can UPDATE manufacturers
DROP POLICY IF EXISTS "Admins can update manufacturers" ON PUBLIC.MANUFACTURERS;
CREATE POLICY "Admins can update manufacturers" ON PUBLIC.MANUFACTURERS FOR
UPDATE TO AUTHENTICATED USING (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
) WITH CHECK (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Admins can DELETE manufacturers
DROP POLICY IF EXISTS "Admins can delete manufacturers" ON PUBLIC.MANUFACTURERS;
CREATE POLICY "Admins can delete manufacturers" ON PUBLIC.MANUFACTURERS FOR
DELETE TO AUTHENTICATED USING (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Step 6: Verify table was created
SELECT
    '✅ Manufacturers table created successfully' AS STATUS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'manufacturers'
    ) AS MANUFACTURERS_TABLE_EXISTS;

