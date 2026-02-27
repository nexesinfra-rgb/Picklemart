-- Create the cash_book table if it doesn't exist
create table if not exists public.cash_book (
  id uuid not null default gen_random_uuid(),
  amount double precision not null,
  entry_type text not null check (entry_type in ('payin', 'payout')),
  category text not null,
  description text not null default '',
  transaction_date timestamp with time zone not null default now(),
  related_id text,
  payment_method text not null,
  created_by uuid references auth.users(id),
  created_at timestamp with time zone default now(),
  
  constraint cash_book_pkey primary key (id)
);

-- Enable RLS
alter table public.cash_book enable row level security;

-- Policies
-- Drop existing policies if they exist to avoid errors
drop policy if exists "Enable read access for admins" on public.cash_book;
drop policy if exists "Enable insert access for admins" on public.cash_book;
drop policy if exists "Enable update access for admins" on public.cash_book;

create policy "Enable read access for admins"
  on public.cash_book for select
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

create policy "Enable insert access for admins"
  on public.cash_book for insert
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

create policy "Enable update access for admins"
  on public.cash_book for update
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Create index for faster querying
create index if not exists cash_book_transaction_date_idx on public.cash_book(transaction_date);
create index if not exists cash_book_entry_type_idx on public.cash_book(entry_type);
