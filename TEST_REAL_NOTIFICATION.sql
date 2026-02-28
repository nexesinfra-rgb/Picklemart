-- ============================================================================
-- TEST: CREATE A FAKE ORDER TO TRIGGER NOTIFICATION
-- ============================================================================
-- This will insert a test order into the orders table.
-- The database trigger should fire and create a user_notification.
-- The FCM worker should pick up that notification and send it.
-- ============================================================================

DO $$
DECLARE
    -- 1. SET YOUR ADMIN ID HERE (or any user ID you want to test with)
    -- Using the one from previous logs: d341eb0b-d8f1-4bc1-89ef-06da050aa6af
    test_user_id UUID := 'd341eb0b-d8f1-4bc1-89ef-06da050aa6af';
    
    new_order_id UUID;
    new_order_num TEXT;
BEGIN
    -- Generate a random order number
    new_order_num := 'TEST-' || floor(random() * 10000)::text;

    -- 2. Insert Test Order
    INSERT INTO public.orders (
        user_id,
        order_number,
        status,
        total,
        subtotal,
        shipping,
        tax,
        delivery_address,
        created_at
    ) VALUES (
        test_user_id,
        new_order_num,
        'processing',
        100.00,
        90.00,
        5.00,
        5.00,
        '{"name": "Test User", "address": "123 Test St"}',
        NOW()
    ) RETURNING id INTO new_order_id;

    RAISE NOTICE '✅ Created Test Order: % (ID: %)', new_order_num, new_order_id;

    -- 3. Wait a moment for trigger to fire
    PERFORM pg_sleep(1);

    -- 4. Check if notification was created
    IF EXISTS (
        SELECT 1 FROM public.user_notifications 
        WHERE order_id = new_order_id 
        AND type = 'order_placed'
    ) THEN
        RAISE NOTICE '✅ SUCCESS: Notification record created in DB!';
    ELSE
        RAISE NOTICE '❌ FAILURE: No notification record found!';
    END IF;

END $$;
