-- ============================================
-- COMPLETE DATABASE SETUP FOR DAILY WORK REPORT
-- ============================================

-- ============================================
-- 1. DROP EXISTING TABLES IF NEEDED
-- ============================================
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS workers CASCADE;
DROP FUNCTION IF EXISTS register_worker CASCADE;
DROP FUNCTION IF EXISTS handle_new_user CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;

-- ============================================
-- 2. CREATE WORKERS TABLE
-- ============================================
CREATE TABLE workers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auth_id TEXT UNIQUE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. CREATE REPORTS TABLE
-- ============================================
CREATE TABLE reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  worker_name TEXT,
  completed TEXT,
  inprogress TEXT,
  nextsteps TEXT,
  issues TEXT,
  students JSONB DEFAULT '[]'::jsonb,
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'submitted'
);

-- ============================================
-- 4. CREATE INDEXES
-- ============================================
CREATE INDEX idx_workers_email ON workers(email);
CREATE INDEX idx_workers_auth_id ON workers(auth_id);
CREATE INDEX idx_workers_created_at ON workers(created_at);
CREATE INDEX idx_reports_worker_id ON reports(worker_id);
CREATE INDEX idx_reports_date ON reports(date);
CREATE INDEX idx_reports_created_at ON reports(created_at);
CREATE INDEX idx_reports_status ON reports(status);

-- ============================================
-- 5. ENABLE RLS
-- ============================================
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 6. CREATE RLS POLICIES FOR WORKERS TABLE
-- ============================================

-- Policy 1: Anyone can insert workers (for registration)
CREATE POLICY "Anyone can insert workers" ON workers
FOR INSERT WITH CHECK (true);

-- Policy 2: Users can view their own data
CREATE POLICY "Users can view own worker data" ON workers
FOR SELECT USING (auth_id = auth.uid()::text);

-- Policy 3: Users can update their own data
CREATE POLICY "Users can update own worker data" ON workers
FOR UPDATE USING (auth_id = auth.uid()::text);

-- Policy 4: Users can delete their own data
CREATE POLICY "Users can delete own worker data" ON workers
FOR DELETE USING (auth_id = auth.uid()::text);

-- Policy 5: Admin can see all workers
CREATE POLICY "Admins can see all workers" ON workers
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid()::uuid
    AND auth.users.email = 'acadeno@gmail.com'
  )
);

-- Policy 6: Admin can update any worker
CREATE POLICY "Admins can update any worker" ON workers
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid()::uuid
    AND auth.users.email = 'acadeno@gmail.com'
  )
);

-- ============================================
-- 7. CREATE RLS POLICIES FOR REPORTS TABLE
-- ============================================

-- Policy 1: Workers can insert their own reports
CREATE POLICY "Workers can insert own reports" ON reports
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM workers 
    WHERE workers.id = reports.worker_id 
    AND workers.auth_id = auth.uid()::text
  )
);

-- Policy 2: Workers can view their own reports
CREATE POLICY "Workers can view own reports" ON reports
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM workers 
    WHERE workers.id = reports.worker_id 
    AND workers.auth_id = auth.uid()::text
  )
);

-- Policy 3: Workers can update their own reports
CREATE POLICY "Workers can update own reports" ON reports
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM workers 
    WHERE workers.id = reports.worker_id 
    AND workers.auth_id = auth.uid()::text
  )
);

-- Policy 4: Workers can delete their own reports
CREATE POLICY "Workers can delete own reports" ON reports
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM workers 
    WHERE workers.id = reports.worker_id 
    AND workers.auth_id = auth.uid()::text
  )
);

-- Policy 5: Admin can see all reports
CREATE POLICY "Admins can see all reports" ON reports
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid()::uuid
    AND auth.users.email = 'acadeno@gmail.com'
  )
);

-- Policy 6: Admin can insert any report
CREATE POLICY "Admins can insert any reports" ON reports
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid()::uuid
    AND auth.users.email = 'acadeno@gmail.com'
  )
);

-- Policy 7: Admin can update any report
CREATE POLICY "Admins can update any reports" ON reports
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid()::uuid
    AND auth.users.email = 'acadeno@gmail.com'
  )
);

-- Policy 8: Admin can delete any report
CREATE POLICY "Admins can delete any reports" ON reports
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid()::uuid
    AND auth.users.email = 'acadeno@gmail.com'
  )
);

-- ============================================
-- 8. CREATE FUNCTION FOR REGISTRATION
-- ============================================
CREATE OR REPLACE FUNCTION register_worker(
  p_name TEXT,
  p_email TEXT,
  p_phone TEXT,
  p_auth_id TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_worker_id UUID;
  v_lower_email TEXT;
BEGIN
  -- Convert email to lowercase for consistency
  v_lower_email := LOWER(TRIM(p_email));
  
  -- Check if email already exists
  IF EXISTS (SELECT 1 FROM workers WHERE LOWER(email) = v_lower_email) THEN
    RAISE EXCEPTION 'Email already registered';
  END IF;

  -- Check if auth_id already exists (only if not null)
  IF p_auth_id IS NOT NULL AND EXISTS (SELECT 1 FROM workers WHERE auth_id = p_auth_id) THEN
    RAISE EXCEPTION 'User already registered';
  END IF;

  -- Insert new worker
  INSERT INTO workers (name, email, phone, auth_id)
  VALUES (p_name, v_lower_email, p_phone, p_auth_id)
  RETURNING id INTO v_worker_id;

  RETURN v_worker_id;
END;
$$;

-- ============================================
-- 9. CREATE FUNCTION TO AUTO-CREATE WORKER FROM AUTH USER
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if worker already exists with this email
  IF NOT EXISTS (
    SELECT 1 FROM workers 
    WHERE LOWER(email) = LOWER(NEW.email)
  ) THEN
    -- Create new worker record
    INSERT INTO workers (
      auth_id,
      name,
      email,
      phone,
      created_at,
      updated_at
    ) VALUES (
      NEW.id::text,
      COALESCE(NEW.raw_user_meta_data->>'full_name', 
               SPLIT_PART(NEW.email, '@', 1)),
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'phone', ''),
      NOW(),
      NOW()
    );
  ELSE
    -- Update existing worker with auth_id
    UPDATE workers 
    SET 
      auth_id = NEW.id::text,
      updated_at = NOW()
    WHERE LOWER(email) = LOWER(NEW.email)
    AND (auth_id IS NULL OR auth_id = '');
  END IF;
  
  RETURN NEW;
END;
$$;

-- ============================================
-- 10. CREATE TRIGGER FOR AUTO-CREATING WORKERS
-- ============================================
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================
-- 11. CREATE FUNCTION TO UPDATE UPDATED_AT TIMESTAMP
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Create triggers for updated_at
CREATE TRIGGER update_workers_updated_at
  BEFORE UPDATE ON workers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at
  BEFORE UPDATE ON reports
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 12. CREATE FUNCTION FOR MIGRATING EXISTING USERS
-- ============================================
CREATE OR REPLACE FUNCTION migrate_existing_worker(
  p_worker_email TEXT,
  p_auth_id TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_worker_id UUID;
BEGIN
  -- Find worker by email
  SELECT id INTO v_worker_id 
  FROM workers 
  WHERE LOWER(email) = LOWER(p_worker_email)
  LIMIT 1;
  
  IF v_worker_id IS NULL THEN
    RAISE EXCEPTION 'Worker not found with email: %', p_worker_email;
  END IF;
  
  -- Check if auth_id is already used
  IF EXISTS (SELECT 1 FROM workers WHERE auth_id = p_auth_id AND id != v_worker_id) THEN
    RAISE EXCEPTION 'Auth ID already in use';
  END IF;
  
  -- Update worker with auth_id
  UPDATE workers 
  SET 
    auth_id = p_auth_id,
    updated_at = NOW()
  WHERE id = v_worker_id;
  
  RETURN v_worker_id;
END;
$$;

-- ============================================
-- 13. GRANT PERMISSIONS
-- ============================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON workers TO anon, authenticated, service_role;
GRANT ALL ON reports TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION register_worker TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION migrate_existing_worker TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION handle_new_user TO service_role;
GRANT EXECUTE ON FUNCTION update_updated_at_column TO service_role;

-- ============================================
-- 14. INSERT TEST DATA (OPTIONAL)
-- ============================================
-- Uncomment if you want test data
/*
INSERT INTO workers (auth_id, name, email, phone) VALUES
('test_auth_id_1', 'John Doe', 'john@example.com', '1234567890'),
('test_auth_id_2', 'Jane Smith', 'jane@example.com', '0987654321')
ON CONFLICT (email) DO NOTHING;
*/

-- ============================================
-- 15. VERIFICATION
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '================================';
  RAISE NOTICE '✅ DATABASE SETUP COMPLETE!';
  RAISE NOTICE '================================';
  RAISE NOTICE '1. workers table created (auth_id NULLABLE)';
  RAISE NOTICE '2. reports table created';
  RAISE NOTICE '3. RLS policies created (allows anonymous inserts)';
  RAISE NOTICE '4. register_worker function ready';
  RAISE NOTICE '5. handle_new_user trigger created';
  RAISE NOTICE '6. Auto-update timestamps configured';
  RAISE NOTICE '7. Permissions granted';
  RAISE NOTICE '================================';
  RAISE NOTICE '🚀 Ready for registration & login!';
  RAISE NOTICE '================================';
  RAISE NOTICE 'Tables:';
  RAISE NOTICE '  - workers (% rows)', (SELECT COUNT(*) FROM workers);
  RAISE NOTICE '  - reports (% rows)', (SELECT COUNT(*) FROM reports);
  RAISE NOTICE '================================';
END $$;

-- Show table structure
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('workers', 'reports')
ORDER BY table_name, ordinal_position;

-- Show RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('workers', 'reports')
ORDER BY tablename, policyname;
