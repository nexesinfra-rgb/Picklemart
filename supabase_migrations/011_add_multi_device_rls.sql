-- ============================================================================
-- Multi-Device Tracking RLS Policies
-- ============================================================================
-- This migration ensures proper RLS policies for multi-device tracking
-- Admins can query sessions across all users
-- Users can only query their own sessions
-- ============================================================================

-- Ensure user_sessions table has RLS enabled
ALTER TABLE IF EXISTS public.user_sessions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS user_sessions_select_own ON public.user_sessions;
DROP POLICY IF EXISTS user_sessions_select_admin ON public.user_sessions;
DROP POLICY IF EXISTS user_sessions_insert_own ON public.user_sessions;
DROP POLICY IF EXISTS user_sessions_update_own ON public.user_sessions;
DROP POLICY IF EXISTS user_sessions_delete_own ON public.user_sessions;
DROP POLICY IF EXISTS user_sessions_delete_admin ON public.user_sessions;

-- RLS Policy: Users can SELECT their own sessions
CREATE POLICY user_sessions_select_own ON public.user_sessions
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS Policy: Admins can SELECT all sessions
CREATE POLICY user_sessions_select_admin ON public.user_sessions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager', 'support')
        )
    );

-- RLS Policy: Users can INSERT their own sessions
CREATE POLICY user_sessions_insert_own ON public.user_sessions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can UPDATE their own sessions
CREATE POLICY user_sessions_update_own ON public.user_sessions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can DELETE their own sessions
CREATE POLICY user_sessions_delete_own ON public.user_sessions
    FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policy: Admins can DELETE any sessions
CREATE POLICY user_sessions_delete_admin ON public.user_sessions
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager', 'support')
        )
    );

-- Ensure user_locations table has RLS enabled
ALTER TABLE IF EXISTS public.user_locations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS user_locations_select_own ON public.user_locations;
DROP POLICY IF EXISTS user_locations_select_admin ON public.user_locations;
DROP POLICY IF EXISTS user_locations_insert_own ON public.user_locations;
DROP POLICY IF EXISTS user_locations_delete_own ON public.user_locations;
DROP POLICY IF EXISTS user_locations_delete_admin ON public.user_locations;

-- RLS Policy: Users can SELECT their own locations
CREATE POLICY user_locations_select_own ON public.user_locations
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS Policy: Admins can SELECT all locations
CREATE POLICY user_locations_select_admin ON public.user_locations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager', 'support')
        )
    );

-- RLS Policy: Users can INSERT their own locations
CREATE POLICY user_locations_insert_own ON public.user_locations
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can DELETE their own locations
CREATE POLICY user_locations_delete_own ON public.user_locations
    FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policy: Admins can DELETE any locations
CREATE POLICY user_locations_delete_admin ON public.user_locations
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager', 'support')
        )
    );

-- Create index for better query performance on phone number lookups
CREATE INDEX IF NOT EXISTS idx_profiles_mobile_lookup ON public.profiles(mobile) WHERE mobile IS NOT NULL;

-- Create index for user_sessions user_id lookups
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id_lookup ON public.user_sessions(user_id);

-- Create index for user_locations user_id lookups
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id_lookup ON public.user_locations(user_id);

