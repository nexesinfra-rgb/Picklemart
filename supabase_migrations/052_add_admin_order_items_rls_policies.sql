-- Add RLS policies for admins to manage order_items
-- This allows admins to INSERT, UPDATE, and DELETE order items for order modification

-- Admins can INSERT order items for any order
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

-- Admins can UPDATE order items for any order
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

-- Admins can DELETE order items for any order
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

