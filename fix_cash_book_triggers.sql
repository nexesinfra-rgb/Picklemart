-- Fix triggers to handle both new (reference_id) and legacy (related_id) linking
-- This ensures cascading deletion works for ALL transactions (old and new)

-- Function to handle Payment Receipt (Payment In) deletion
CREATE OR REPLACE FUNCTION public.handle_payment_receipt_delete()
RETURNS TRIGGER AS $$
DECLARE
  deleted_count int;
BEGIN
  -- 1. Try deleting by explicit reference (Modern) OR related_id (Legacy)
  -- reference_id matches Transaction ID
  -- related_id matches Transaction ID (in legacy data)
  DELETE FROM public.cash_book 
  WHERE (reference_id = OLD.id::text AND reference_type = 'payment_in')
     OR (related_id = OLD.id::text);
     
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  -- 2. If nothing deleted, try fuzzy match (Fallback for broken links)
  -- This handles cases where related_id = Customer ID (Modern) but reference_id was missing
  IF deleted_count = 0 THEN
    DELETE FROM public.cash_book
    WHERE related_id = OLD.customer_id::text 
      AND amount = OLD.amount 
      AND transaction_date::date = OLD.payment_date::date;
  END IF;
  
  -- 3. Cleanup link table if exists (just in case)
  BEGIN
    DELETE FROM public.payment_cashbook_links WHERE payment_id = OLD.id::text;
  EXCEPTION WHEN undefined_table THEN
    -- Ignore if table doesn't exist
    NULL;
  END;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger for Payment Receipts
DROP TRIGGER IF EXISTS on_payment_receipt_delete ON public.payment_receipts;
CREATE TRIGGER on_payment_receipt_delete
AFTER DELETE ON public.payment_receipts
FOR EACH ROW EXECUTE FUNCTION public.handle_payment_receipt_delete();


-- Function to handle Credit Transaction (Payment Out) deletion
CREATE OR REPLACE FUNCTION public.handle_credit_transaction_delete()
RETURNS TRIGGER AS $$
DECLARE
  deleted_count int;
BEGIN
  -- 1. Try deleting by explicit reference (Modern) OR related_id (Legacy)
  DELETE FROM public.cash_book 
  WHERE (reference_id = OLD.id::text AND reference_type = 'payment_out')
     OR (related_id = OLD.id::text);
     
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  -- 2. If nothing deleted, try fuzzy match
  IF deleted_count = 0 THEN
    -- Match manufacturer_id (if present)
    IF OLD.manufacturer_id IS NOT NULL THEN
      DELETE FROM public.cash_book
      WHERE related_id = OLD.manufacturer_id::text 
        AND amount = OLD.amount 
        AND transaction_date::date = OLD.transaction_date::date;
    END IF;
  END IF;

  -- 3. Cleanup link table if exists
  BEGIN
    DELETE FROM public.payment_cashbook_links WHERE payment_id = OLD.id::text;
  EXCEPTION WHEN undefined_table THEN
    -- Ignore if table doesn't exist
    NULL;
  END;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger for Credit Transactions
DROP TRIGGER IF EXISTS on_credit_transaction_delete ON public.credit_transactions;
CREATE TRIGGER on_credit_transaction_delete
AFTER DELETE ON public.credit_transactions
FOR EACH ROW EXECUTE FUNCTION public.handle_credit_transaction_delete();
