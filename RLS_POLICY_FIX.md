# 🔐 Fix RLS Policies - Permission Denied Error

## The Problem
```
❌ permission denied for table users, code: 42501
```

This means **Row-Level Security (RLS) policies** are blocking unauthenticated users from inserting into the `workers` table.

During registration, users aren't authenticated yet, so they need permission to create a worker record.

---

## ✅ Solution: Update RLS Policies

### Go to Supabase Dashboard
1. URL: https://supabase.com/dashboard
2. Select your project
3. Click: **Authentication** → **Policies** (left sidebar)
4. OR click: **SQL Editor** (left sidebar)

---

## Option 1: Using SQL Editor (Easiest)

Go to **SQL Editor** and run this:

```sql
-- Disable RLS temporarily for registration (allows unauthenticated insert)
ALTER TABLE workers DISABLE ROW LEVEL SECURITY;
```

Then click **Run**.

**Note**: This disables all RLS security. After testing, you can re-enable with:
```sql
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
```

---

## Option 2: Update RLS Policies (Better)

Keep RLS enabled but allow unauthenticated inserts:

```sql
-- Enable RLS
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow ANYONE to insert (for registration)
CREATE POLICY "Allow insert for registration" ON workers
  FOR INSERT
  WITH CHECK (true);

-- Policy 2: Allow authenticated users to select own records
CREATE POLICY "Allow select own records" ON workers
  FOR SELECT
  USING (auth.uid() = auth_id OR auth_id IS NULL);

-- Policy 3: Allow authenticated users to update own records
CREATE POLICY "Allow update own records" ON workers
  FOR UPDATE
  USING (auth.uid() = auth_id);
```

---

## 🚀 Steps to Apply

1. **Open**: https://supabase.com/dashboard
2. **Select**: Your project (daily_work_report)
3. **Click**: SQL Editor (left menu)
4. **Paste**: One of the SQL solutions above
5. **Click**: Run (blue button)
6. **Wait**: For "Success" message

---

## ⏱️ Expected Timeline

- Go to dashboard: 1 min
- Find SQL Editor: 1 min
- Paste SQL: 1 min
- Run: 30 seconds
- **Total: ~4 minutes**

---

## 🧪 After Applying Fix

1. Close Flutter app
2. Run: `flutter clean && flutter pub get && flutter run -d chrome`
3. Try registration again
4. Expected: ✅ "Registration successful!"

---

## ✅ Checklist

- [ ] Opened Supabase Dashboard
- [ ] Went to SQL Editor
- [ ] Pasted SQL (Option 1 or 2)
- [ ] Clicked Run
- [ ] Saw success message
- [ ] Closed Flutter app
- [ ] Rebuilt app
- [ ] Tested registration

---

**Go fix the RLS policies NOW! This is the final blocker!** 🚀
