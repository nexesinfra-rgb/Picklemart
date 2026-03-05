-- Trigger to automatically delete cash_book entry when a payment_receipt is deleted
CREATE OR REPLACE FUNCTION public.delete_cash_book_entry_for_receipt()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete the corresponding cash book entry where related_id matches the deleted receipt ID
  DELETE FROM public.cash_book WHERE related_id = OLD.id::text;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_payment_receipt_delete ON public.payment_receipts;
CREATE TRIGGER on_payment_receipt_delete
AFTER DELETE ON public.payment_receipts
FOR EACH ROW EXECUTE FUNCTION public.delete_cash_book_entry_for_receipt();


-- Trigger to automatically delete cash_book entry when a credit_transaction is deleted
CREATE OR REPLACE FUNCTION public.delete_cash_book_entry_for_credit_txn()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete the corresponding cash book entry where related_id matches the deleted transaction ID
  DELETE FROM public.cash_book WHERE related_id = OLD.id::text;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_credit_transaction_delete ON public.credit_transactions;
CREATE TRIGGER on_credit_transaction_delete
AFTER DELETE ON public.credit_transactions
FOR EACH ROW EXECUTE FUNCTION public.delete_cash_book_entry_for_credit_txn();
