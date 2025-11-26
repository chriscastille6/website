# Running the Database Schema in Supabase

## Quick Steps

1. **Open Supabase Dashboard**
   - Go to [supabase.com](https://supabase.com)
   - Select your project
   - Click "SQL Editor" in the left sidebar

2. **Create New Query**
   - Click "New query" button

3. **Copy the Schema**
   - Open `supabase-schema.sql` in your project
   - Select all (Cmd+A / Ctrl+A)
   - Copy (Cmd+C / Ctrl+C)

4. **Paste and Run**
   - Paste into the SQL Editor
   - Click "Run" button (or press Cmd+Enter / Ctrl+Enter)

5. **Verify Success**
   - You should see "Success. No rows returned" or similar
   - Go to "Table Editor" to verify tables were created
   - You should see: assessments, participants, users, labs, etc.

## What Gets Created

- **Tables:** All database tables for the assessment library
- **Initial Data:**
  - 3 assessments (occupational-fit, personality-test, ei-test)
  - PAL lab
  - Lab assignments (linking PAL to all assessments)
- **Security:** Row Level Security (RLS) policies
- **Indexes:** Performance indexes on key columns

## Troubleshooting

**Error: "relation already exists"**
- Some tables might already exist
- This is okay - the schema uses `CREATE TABLE IF NOT EXISTS`
- Continue running the rest

**Error: "permission denied"**
- Make sure you're using the SQL Editor (not restricted access)
- Check that you have admin access to the project

**Tables not showing up**
- Refresh the Table Editor page
- Check the SQL Editor for any error messages
- Verify you ran the entire schema (not just part of it)

## After Running Schema

1. **Check Table Editor:**
   - `assessments` table should have 3 rows
   - `labs` table should have 1 row (PAL)
   - `lab_assessments` should have 3 rows

2. **Enable Authentication:**
   - Go to Authentication → Settings
   - Enable "Email" provider
   - Set Site URL: `http://localhost:1313`

3. **Test:**
   - Visit: `http://localhost:1313/assessments/auth/register.html`
   - Try creating an account



