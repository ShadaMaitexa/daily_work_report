# 🔧 Database Schema Fix Required

## The Issue

Your `workers` table has `auth_id` set to `NOT NULL`, but we're creating workers WITHOUT auth initially.

### Current Schema (WRONG):
```sql
CREATE TABLE workers (
  id BIGSERIAL PRIMARY KEY,
  auth_id UUID NOT NULL,  ← ❌ Can't be NULL
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Required Schema (CORRECT):
```sql
CREATE TABLE workers (
  id BIGSERIAL PRIMARY KEY,
  auth_id UUID,           ← ✅ Can be NULL (optional)
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

---

## ✅ How to Fix

### Option 1: Using Supabase SQL Editor (Easiest)

1. Go to: **Supabase Dashboard** → **SQL Editor**
2. Paste this SQL:

```sql
-- Make auth_id optional (nullable)
ALTER TABLE workers
ALTER COLUMN auth_id DROP NOT NULL;
```

3. Click **Run**
4. You should see: "Success" ✅

### Option 2: Drop and Recreate Table

If Option 1 doesn't work, delete the table and recreate:

```sql
-- Drop old table
DROP TABLE IF EXISTS workers CASCADE;

-- Create new table with optional auth_id
CREATE TABLE workers (
  id BIGSERIAL PRIMARY KEY,
  auth_id UUID,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow insert" ON workers
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow select all" ON workers
  FOR SELECT
  USING (true);

CREATE POLICY "Allow update" ON workers
  FOR UPDATE
  USING (true);
```

---

## ⏱️ Steps to Apply

1. Open: https://supabase.com/dashboard
2. Select your project
3. Go to: **SQL Editor** (left sidebar)
4. Paste the SQL above
5. Click: **Run** (blue button)
6. Wait for confirmation
7. Close and come back to test

---

## 🧪 After Applying SQL Fix

Then in Flutter:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

Try registration again - should now work! ✅

---

## Expected Flow After Fix

```
1. User registers with email/password/name/phone
   ↓
2. STEP 1: Create worker record (without auth_id)
   ↓
3. STEP 2: Create Supabase auth user
   ↓
4. STEP 3: Link auth_id to worker record
   ↓
5. Success! Redirect to login
```

---

**Go apply this SQL fix NOW, then rebuild the app!**
