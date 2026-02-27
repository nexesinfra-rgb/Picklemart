# Run Profiles Table Migration

## Quick Steps to Run SQL Migration

### Option 1: Using Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project: `okjuhvgavbcbbnzvvyxc`

2. **Open SQL Editor**
   - Click on **SQL Editor** in the left sidebar
   - Click **New Query**

3. **Copy and Paste SQL**
   - Open the file: `supabase_migrations/001_create_profiles_table.sql`
   - Copy the entire contents
   - Paste into the SQL Editor

4. **Run the Migration**
   - Click **Run** button (or press Ctrl+Enter)
   - Wait for the query to complete
   - You should see "Success. No rows returned"

5. **Verify Table Creation**
   - Go to **Table Editor** in the left sidebar
   - You should see the `profiles` table listed
   - Click on it to view the structure

### Option 2: Using Supabase CLI (If Installed)

```bash
# If you have Supabase CLI installed
supabase db push supabase_migrations/001_create_profiles_table.sql
```

### Option 3: Direct SQL Execution

If you have direct database access, you can execute the SQL directly using any PostgreSQL client.

## Verification

After running the migration, verify:

1. **Table exists**: Check Table Editor → `profiles` table
2. **RLS enabled**: Go to Authentication → Policies → Check `profiles` policies
3. **Indexes created**: Check that indexes exist on email, mobile, and role columns
4. **Trigger exists**: The `update_profiles_updated_at` trigger should be active

## Troubleshooting

### If you get permission errors:
- Ensure you're logged in as the project owner
- Check that RLS policies are correctly created

### If table already exists:
- The migration uses `CREATE TABLE IF NOT EXISTS`, so it's safe to run again
- If you need to recreate, first drop the table: `DROP TABLE IF EXISTS public.profiles CASCADE;`

### If RLS policies fail:
- Check that the policies are created correctly
- Verify `auth.uid()` function is available
- Ensure the authenticated role has proper permissions

## Next Steps

After successful migration:
1. Test profile creation from the app
2. Verify data appears in Supabase Table Editor
3. Test profile updates and reads
4. Check RLS policies are working correctly














