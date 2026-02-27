# Quick Fix: Apply user_notifications Table Migration

## ⚠️ URGENT: The `user_notifications` table is missing!

This is causing notification creation to fail when orders are placed.

## ✅ Solution: Run the SQL Migration

### Step 1: Open Supabase SQL Editor

1. Go to your Supabase Dashboard: https://okjuhvgavbcbbnzvvyxc.supabase.co
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**

### Step 2: Copy and Run the Migration SQL

Copy the **ENTIRE contents** of the file: `CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql`

Or copy this essential SQL:

```sql
-- Create user_notifications Table
CREATE TABLE IF NOT EXISTS public.user_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('order_placed', 'order_status_changed')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON public.user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_is_read ON public.user_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_user_notifications_created_at ON public.user_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_notifications_order_id ON public.user_notifications(order_id) WHERE order_id IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE public.user_notifications ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can SELECT their own notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.user_notifications;
CREATE POLICY "Users can view their own notifications" ON public.user_notifications
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Policy 2: Users can UPDATE their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.user_notifications;
CREATE POLICY "Users can update their own notifications" ON public.user_notifications
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy 3: Users can INSERT their own notifications (for triggers)
DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.user_notifications;
CREATE POLICY "Users can insert their own notifications" ON public.user_notifications
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Policy 4: Admins can INSERT notifications for any user (CRITICAL)
DROP POLICY IF EXISTS "Admins can insert notifications for any user" ON public.user_notifications;
CREATE POLICY "Admins can insert notifications for any user" ON public.user_notifications
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Create Trigger Function for Order Placed Notifications
CREATE OR REPLACE FUNCTION public.create_order_placed_notification()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.user_notifications (
        user_id,
        type,
        title,
        message,
        order_id,
        is_read,
        created_at
    ) VALUES (
        NEW.user_id,
        'order_placed',
        'Order Placed Successfully',
        'Your order ' || NEW.order_number || ' has been placed successfully. We will process it soon.',
        NEW.id,
        FALSE,
        NOW()
    );
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating order placed notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Create Trigger Function for Order Status Changed Notifications
CREATE OR REPLACE FUNCTION public.create_order_status_notification()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    status_label TEXT;
BEGIN
    -- Only create notification if status actually changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    -- Map status to user-friendly label
    CASE NEW.status
        WHEN 'confirmed' THEN status_label := 'Confirmed';
        WHEN 'processing' THEN status_label := 'Processing';
        WHEN 'shipped' THEN status_label := 'Shipped';
        WHEN 'delivered' THEN status_label := 'Delivered';
        WHEN 'cancelled' THEN status_label := 'Cancelled';
        WHEN 'pending' THEN status_label := 'Pending';
        ELSE status_label := initcap(REPLACE(NEW.status, '_', ' '));
    END CASE;

    INSERT INTO public.user_notifications (
        user_id,
        type,
        title,
        message,
        order_id,
        is_read,
        created_at
    ) VALUES (
        NEW.user_id,
        'order_status_changed',
        'Order Status Updated',
        'Your order ' || NEW.order_number || ' status has been updated to: ' || status_label,
        NEW.id,
        FALSE,
        NOW()
    );
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating order status notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Trigger for order placed notifications
DROP TRIGGER IF EXISTS trigger_order_placed_notification ON public.orders;
CREATE TRIGGER trigger_order_placed_notification
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.create_order_placed_notification();

-- Trigger for order status changed notifications
DROP TRIGGER IF EXISTS trigger_order_status_notification ON public.orders;
CREATE TRIGGER trigger_order_status_notification
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.create_order_status_notification();

-- Grant Permissions
GRANT EXECUTE ON FUNCTION public.create_order_status_notification() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_order_placed_notification() TO authenticated;

-- Add Table Comment
COMMENT ON TABLE public.user_notifications IS 'Stores user notifications for order events and status changes.';
```

### Step 3: Click "Run" or Press Ctrl+Enter

The migration should complete successfully. You'll see confirmation messages.

### Step 4: Verify the Migration (Optional)

Run this verification query to confirm the table was created:

```sql
SELECT 
    '✅ Table Status' AS check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN 'PASS: user_notifications table exists'
        ELSE 'FAIL: user_notifications table missing'
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name = 'user_notifications';
```

## ✅ What This Fixes

- ✅ Creates the `user_notifications` table
- ✅ Sets up proper indexes for performance
- ✅ Configures RLS policies for security
- ✅ Creates database triggers for automatic notifications
- ✅ Allows notifications to be created when orders are placed

## 🎯 After Running This

Notifications will work automatically:
- When an order is placed → Notification created automatically via trigger
- When order status changes → Notification created automatically via trigger
- App code can also create notifications directly (via admin policy)

---

**⚠️ IMPORTANT**: Run this migration NOW to fix the notification errors!
