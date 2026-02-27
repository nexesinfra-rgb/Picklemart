-- ============================================================================
-- Admin Order Policies
-- ============================================================================
-- This migration adds RLS policies to allow admins to create and manage orders
-- for any user.
-- ============================================================================

-- Admins can INSERT orders for any user
DROP POLICY IF EXISTS "Admins can insert orders" ON PUBLIC.ORDERS;
CREATE POLICY "Admins can insert orders" ON PUBLIC.ORDERS
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Admins can DELETE orders
DROP POLICY IF EXISTS "Admins can delete orders" ON PUBLIC.ORDERS;
CREATE POLICY "Admins can delete orders" ON PUBLIC.ORDERS
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Admins can INSERT order items
DROP POLICY IF EXISTS "Admins can insert order items" ON PUBLIC.ORDER_ITEMS;
CREATE POLICY "Admins can insert order items" ON PUBLIC.ORDER_ITEMS
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Admins can UPDATE order items
DROP POLICY IF EXISTS "Admins can update order items" ON PUBLIC.ORDER_ITEMS;
CREATE POLICY "Admins can update order items" ON PUBLIC.ORDER_ITEMS
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Admins can DELETE order items
DROP POLICY IF EXISTS "Admins can delete order items" ON PUBLIC.ORDER_ITEMS;
CREATE POLICY "Admins can delete order items" ON PUBLIC.ORDER_ITEMS
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );
