-- ============================================
-- FIX RLS POLICIES - SIMPLIFY AND ALLOW ACCESS
-- ============================================

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Workers can view own reports" ON reports;
DROP POLICY IF EXISTS "Workers can insert own reports" ON reports;
DROP POLICY IF EXISTS "Workers can update own reports" ON reports;
DROP POLICY IF EXISTS "Workers can delete own reports" ON reports;
DROP POLICY IF EXISTS "Admins can see all reports" ON reports;
DROP POLICY IF EXISTS "Admins can insert any reports" ON reports;
DROP POLICY IF EXISTS "Admins can update any reports" ON reports;
DROP POLICY IF EXISTS "Admins can delete any reports" ON reports;

-- Drop worker table policies too
DROP POLICY IF EXISTS "Users can view own worker data" ON workers;
DROP POLICY IF EXISTS "Users can update own worker data" ON workers;
DROP POLICY IF EXISTS "Users can delete own worker data" ON workers;
DROP POLICY IF EXISTS "Admins can see all workers" ON workers;
DROP POLICY IF EXISTS "Admins can update any worker" ON workers;
DROP POLICY IF EXISTS "Anyone can insert workers" ON workers;

-- Disable RLS temporarily to get everything working
ALTER TABLE workers DISABLE ROW LEVEL SECURITY;
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;

-- ============================================
-- SIMPLIFIED RLS POLICIES (Auth-based)
-- ============================================

-- Re-enable RLS
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- WORKERS TABLE POLICIES
-- Allow anonymous to insert (registration)
CREATE POLICY "allow_insert_workers" ON workers
FOR INSERT WITH CHECK (true);

-- Allow authenticated users to see their own worker record
CREATE POLICY "allow_select_own_worker" ON workers
FOR SELECT USING (
  auth.uid()::text = auth_id
);

-- Allow authenticated users to update their own worker record
CREATE POLICY "allow_update_own_worker" ON workers
FOR UPDATE USING (
  auth.uid()::text = auth_id
);

-- REPORTS TABLE POLICIES
-- Allow authenticated users to insert their own reports
CREATE POLICY "allow_insert_own_reports" ON reports
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM workers
    WHERE workers.id = reports.worker_id
    AND workers.auth_id = auth.uid()::text
  )
);

-- Allow authenticated users to see their own reports
CREATE POLICY "allow_select_own_reports" ON reports
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM workers
    WHERE workers.id = reports.worker_id
    AND workers.auth_id = auth.uid()::text
  )
);

-- Allow authenticated users to update their own reports
CREATE POLICY "allow_update_own_reports" ON reports
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM workers
    WHERE workers.id = reports.worker_id
    AND workers.auth_id = auth.uid()::text
  )
);

-- Allow authenticated users to delete their own reports
CREATE POLICY "allow_delete_own_reports" ON reports
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM workers
    WHERE workers.id = reports.worker_id
    AND workers.auth_id = auth.uid()::text
  )
);

-- ============================================
-- VERIFICATION
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '================================';
  RAISE NOTICE '✅ RLS POLICIES FIXED!';
  RAISE NOTICE '================================';
  RAISE NOTICE 'Workers table: RLS enabled with insert/select/update policies';
  RAISE NOTICE 'Reports table: RLS enabled with insert/select/update/delete policies';
  RAISE NOTICE '================================';
END $$;
