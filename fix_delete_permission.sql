-- COPY AND PASTE THIS INTO YOUR SUPABASE SQL EDITOR TO FIX THE DELETE ERROR

-- 1. This ensures the table has security enabled
ALTER TABLE cash_book ENABLE ROW LEVEL SECURITY;

-- 2. This rule allows logged-in users to delete their own data
--    If this fails saying "policy already exists", that's fine.
CREATE POLICY "Users can delete their own entries"
ON cash_book
FOR DELETE
TO authenticated
USING (auth.uid() = created_by);

-- NOTE: If you are an Admin and want to delete ANYONE'S data, 
-- you can run this command instead (use only one):
/*
CREATE POLICY "Admins can delete any entry"
ON cash_book
FOR DELETE
TO authenticated
USING (true);
*/
