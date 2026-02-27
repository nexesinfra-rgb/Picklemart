-- Backfill Cash Book with existing Payment Receipts
-- This ensures that past payments appear in the Cash Book

insert into public.cash_book (
  amount,
  entry_type,
  category,
  description,
  transaction_date,
  related_id,
  payment_method,
  created_by
)
select
  amount,
  'payin',
  'Order Payment',
  coalesce(description, 'Payment Receipt ' || receipt_number),
  payment_date,
  id::text,
  payment_type,
  created_by::uuid
from public.payment_receipts
where not exists (
  select 1 from public.cash_book
  where cash_book.related_id = payment_receipts.id::text
);
