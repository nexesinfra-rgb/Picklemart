-- Add trigger to decrement product stock when order items are created
-- This ensures stock is always updated on the server side, independent of client permissions.

-- 1) Create function to handle stock decrement after an order item is inserted
CREATE OR REPLACE FUNCTION public.handle_order_item_insert()
RETURNS trigger AS $$
DECLARE
  v_pricing_options jsonb;
  v_pricing jsonb;
  v_index int;
  v_unit_input text;
  v_unit_normalized text;
BEGIN
  -- If variant is present, decrement variant stock
  IF NEW.variant_id IS NOT NULL THEN
    UPDATE public.product_variants
    SET stock = GREATEST(stock - NEW.quantity, 0)
    WHERE id = NEW.variant_id;

  -- Measurement-based products: decrement stock in product_measurements.pricing_options
  ELSIF NEW.measurement_unit IS NOT NULL THEN
    -- Normalize the unit coming from order_items.measurement_unit (short name) 
    -- to match the enum name stored in pricing_options->>'unit'
    v_unit_input := lower(trim(NEW.measurement_unit));

    v_unit_normalized := CASE v_unit_input
      WHEN 'kg' THEN 'kg'
      WHEN 'g' THEN 'gram'
      WHEN 'gram' THEN 'gram'
      WHEN 'l' THEN 'liter'
      WHEN 'liter' THEN 'liter'
      WHEN 'ml' THEN 'ml'
      WHEN 'pc' THEN 'piece'
      WHEN 'piece' THEN 'piece'
      WHEN 'dz' THEN 'dozen'
      WHEN 'dozen' THEN 'dozen'
      WHEN 'pack' THEN 'pack'
      WHEN 'box' THEN 'box'
      WHEN 'bag' THEN 'bag'
      WHEN 'bottle' THEN 'bottle'
      WHEN 'can' THEN 'can'
      WHEN 'roll' THEN 'roll'
      WHEN 'm' THEN 'meter'
      WHEN 'meter' THEN 'meter'
      WHEN 'cm' THEN 'cm'
      WHEN 'in' THEN 'inch'
      WHEN 'inch' THEN 'inch'
      WHEN 'ft' THEN 'foot'
      WHEN 'foot' THEN 'foot'
      WHEN 'yd' THEN 'yard'
      WHEN 'yard' THEN 'yard'
      ELSE v_unit_input
    END;

    -- Lock the measurement row for update to avoid race conditions
    SELECT pricing_options
    INTO v_pricing_options
    FROM public.product_measurements
    WHERE product_id = NEW.product_id
    FOR UPDATE;

    IF v_pricing_options IS NOT NULL THEN
      -- Iterate over pricing_options array and decrement stock for matching unit
      FOR v_index IN 0 .. COALESCE(jsonb_array_length(v_pricing_options), 0) - 1 LOOP
        v_pricing := v_pricing_options -> v_index;

        IF (v_pricing ->> 'unit') = v_unit_normalized THEN
          v_pricing_options :=
            jsonb_set(
              v_pricing_options,
              ARRAY[v_index::text, 'stock'],
              to_jsonb(
                GREATEST(
                  COALESCE((v_pricing ->> 'stock')::int, 0) - NEW.quantity,
                  0
                )
              )
            );
          EXIT;
        END IF;
      END LOOP;

      UPDATE public.product_measurements
      SET pricing_options = v_pricing_options
      WHERE product_id = NEW.product_id;
    END IF;

  -- Simple products: decrement base product stock
  ELSE
    UPDATE public.products
    SET stock = GREATEST(stock - NEW.quantity, 0)
    WHERE id = NEW.product_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2) Create AFTER INSERT trigger on order_items to call the function
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'order_items_after_insert_stock'
  ) THEN
    CREATE TRIGGER order_items_after_insert_stock
    AFTER INSERT ON public.order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_order_item_insert();
  END IF;
END;
$$;


