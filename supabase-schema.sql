-- Assessment Library Database Schema
-- Location: /Users/ccastille/Documents/GitHub/Website/supabase-schema.sql
-- Purpose: Complete database schema for the assessment library system
-- Why: Provides research-grade data storage for all assessments with proper relationships
-- RELEVANT FILES: static/assessments/shared/supabase-client.js, scripts/export_assessment_data.R

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Assessment metadata table
CREATE TABLE IF NOT EXISTS assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('conjoint', 'personality', 'ei', 'cognitive-load', 'fit')),
  version TEXT DEFAULT '1.0',
  config JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Phase 1: Labs table (organization-based, starting with PAL)
CREATE TABLE IF NOT EXISTS labs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  admin_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Phase 1: Users table (linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  lab_id UUID REFERENCES labs(id) ON DELETE SET NULL,
  role TEXT NOT NULL DEFAULT 'participant' CHECK (role IN ('participant', 'researcher', 'admin')),
  research_opt_in BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Participants table (anonymous by default, supports both anonymous and authenticated users)
-- Add new columns if table already exists
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'participants') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'participants' AND column_name = 'user_id') THEN
      ALTER TABLE participants ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'participants' AND column_name = 'participant_id') THEN
      ALTER TABLE participants ADD COLUMN participant_id TEXT;
    END IF;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  participant_id TEXT, -- CANDIDATE-XXXX-XXXX format for research tagging (never stored with names)
  demographics JSONB DEFAULT '{}',
  consent_data_sharing BOOLEAN DEFAULT false,
  consent_ai_coaching BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual question responses
CREATE TABLE IF NOT EXISTS responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_id UUID REFERENCES participants(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('mcq', 'multiple_answer', 'likert', 'conjoint_choice', 'text')),
  response_data JSONB NOT NULL,
  response_time_ms INTEGER,
  is_correct BOOLEAN NULL, -- for assessments with right/wrong answers
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assessment completion and final scores
CREATE TABLE IF NOT EXISTS results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_id UUID REFERENCES participants(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  scores JSONB NOT NULL,
  feedback TEXT,
  completion_time_ms INTEGER,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Phase 2: Lab assessments (access control)
CREATE TABLE IF NOT EXISTS lab_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lab_id UUID REFERENCES labs(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  access_level TEXT DEFAULT 'full' CHECK (access_level IN ('full', 'limited', 'demo')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(lab_id, assessment_id)
);

-- Phase 2: Individual user permissions (optional override)
CREATE TABLE IF NOT EXISTS user_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES users(id) ON DELETE SET NULL,
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, assessment_id)
);

-- Phase 3: Enhanced AI coaching sessions
-- Add new columns to existing coaching_sessions if it exists
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'coaching_sessions') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'coaching_sessions' AND column_name = 'assessment_result_id') THEN
      ALTER TABLE coaching_sessions ADD COLUMN assessment_result_id UUID REFERENCES results(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'coaching_sessions' AND column_name = 'coaching_type') THEN
      ALTER TABLE coaching_sessions ADD COLUMN coaching_type TEXT DEFAULT 'general';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'coaching_sessions' AND column_name = 'insights') THEN
      ALTER TABLE coaching_sessions ADD COLUMN insights JSONB;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'coaching_sessions' AND column_name = 'recommendations') THEN
      ALTER TABLE coaching_sessions ADD COLUMN recommendations JSONB;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'coaching_sessions' AND column_name = 'user_feedback') THEN
      ALTER TABLE coaching_sessions ADD COLUMN user_feedback JSONB;
    END IF;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS coaching_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_id UUID REFERENCES participants(id) ON DELETE CASCADE,
  assessment_result_id UUID REFERENCES results(id) ON DELETE SET NULL,
  session_type TEXT NOT NULL,
  coaching_type TEXT DEFAULT 'general',
  session_data JSONB NOT NULL,
  insights JSONB,
  recommendations JSONB,
  user_feedback JSONB,
  ai_model TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Phase 3: Coaching preferences
CREATE TABLE IF NOT EXISTS coaching_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  enabled BOOLEAN DEFAULT true,
  coaching_style TEXT DEFAULT 'supportive' CHECK (coaching_style IN ('supportive', 'directive', 'collaborative')),
  frequency TEXT DEFAULT 'on_completion' CHECK (frequency IN ('on_completion', 'weekly', 'monthly', 'manual')),
  topics JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Phase 4: SONA studies (study metadata)
CREATE TABLE IF NOT EXISTS sona_studies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sona_study_id TEXT NOT NULL UNIQUE,
  irb_approval_number TEXT NOT NULL,
  title TEXT NOT NULL,
  principal_investigator TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Phase 4: Study assessments (links studies to assessments used)
CREATE TABLE IF NOT EXISTS study_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  study_id UUID REFERENCES sona_studies(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  is_required BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(study_id, assessment_id)
);

-- Phase 4: Study participants (links participants to studies)
CREATE TABLE IF NOT EXISTS study_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  study_id UUID REFERENCES sona_studies(id) ON DELETE CASCADE,
  participant_id UUID REFERENCES participants(id) ON DELETE CASCADE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(study_id, participant_id)
);

-- Phase 4: IRB access log (audit trail)
CREATE TABLE IF NOT EXISTS irb_access_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  study_id UUID REFERENCES sona_studies(id) ON DELETE SET NULL,
  accessed_by TEXT,
  access_type TEXT CHECK (access_type IN ('view', 'export', 'report')),
  accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance (create if not exists)
CREATE INDEX IF NOT EXISTS idx_responses_participant_assessment ON responses(participant_id, assessment_id);
CREATE INDEX IF NOT EXISTS idx_responses_created_at ON responses(created_at);
CREATE INDEX IF NOT EXISTS idx_results_participant_assessment ON results(participant_id, assessment_id);
CREATE INDEX IF NOT EXISTS idx_participants_session_id ON participants(session_id);
CREATE INDEX IF NOT EXISTS idx_participants_user_id ON participants(user_id);
CREATE INDEX IF NOT EXISTS idx_participants_participant_id ON participants(participant_id);
CREATE INDEX IF NOT EXISTS idx_assessments_active ON assessments(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_users_lab_id ON users(lab_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_lab_assessments_lab ON lab_assessments(lab_id);
CREATE INDEX IF NOT EXISTS idx_lab_assessments_assessment ON lab_assessments(assessment_id);
CREATE INDEX IF NOT EXISTS idx_user_assessments_user ON user_assessments(user_id);
CREATE INDEX IF NOT EXISTS idx_coaching_sessions_result ON coaching_sessions(assessment_result_id);
CREATE INDEX IF NOT EXISTS idx_sona_studies_irb ON sona_studies(irb_approval_number);
CREATE INDEX IF NOT EXISTS idx_sona_studies_sona_id ON sona_studies(sona_study_id);
CREATE INDEX IF NOT EXISTS idx_study_participants_study ON study_participants(study_id);
CREATE INDEX IF NOT EXISTS idx_study_participants_participant ON study_participants(participant_id);
CREATE INDEX IF NOT EXISTS idx_irb_access_study ON irb_access_log(study_id);

-- Row Level Security (RLS) policies
ALTER TABLE labs ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE results ENABLE ROW LEVEL SECURITY;
ALTER TABLE coaching_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE coaching_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE sona_studies ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE irb_access_log ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can view own profile" ON users;
  DROP POLICY IF EXISTS "Users can update own profile" ON users;
  DROP POLICY IF EXISTS "Users can view own lab" ON labs;
  DROP POLICY IF EXISTS "Participants can view own data" ON participants;
  DROP POLICY IF EXISTS "Participants can insert own data" ON participants;
  DROP POLICY IF EXISTS "Participants can update own data" ON participants;
  DROP POLICY IF EXISTS "Participants can view own responses" ON responses;
  DROP POLICY IF EXISTS "Participants can insert own responses" ON responses;
  DROP POLICY IF EXISTS "Participants can view own results" ON results;
  DROP POLICY IF EXISTS "Participants can insert own results" ON results;
  DROP POLICY IF EXISTS "Participants can view own coaching sessions" ON coaching_sessions;
  DROP POLICY IF EXISTS "Participants can insert own coaching sessions" ON coaching_sessions;
  DROP POLICY IF EXISTS "Users can view lab assessments" ON lab_assessments;
  DROP POLICY IF EXISTS "Users can view own permissions" ON user_assessments;
  DROP POLICY IF EXISTS "Users can view accessible assessments" ON assessments;
  DROP POLICY IF EXISTS "Users can view own coaching preferences" ON coaching_preferences;
  DROP POLICY IF EXISTS "Users can update own coaching preferences" ON coaching_preferences;
  DROP POLICY IF EXISTS "Users can insert own coaching preferences" ON coaching_preferences;
  DROP POLICY IF EXISTS "Researchers can view studies" ON sona_studies;
  DROP POLICY IF EXISTS "Researchers can view study assessments" ON study_assessments;
  DROP POLICY IF EXISTS "Researchers can view study participants" ON study_participants;
  DROP POLICY IF EXISTS "IRB can view access log" ON irb_access_log;
END $$;

-- Phase 1: Users can view own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Phase 1: Labs - users can view labs they belong to, admins can view all
CREATE POLICY "Users can view own lab" ON labs
  FOR SELECT USING (
    id IN (SELECT lab_id FROM users WHERE id = auth.uid()) OR
    id IN (SELECT lab_id FROM users WHERE role = 'admin')
  );

-- Phase 1: Participants - support both anonymous (session_id) and authenticated (user_id) access
CREATE POLICY "Participants can view own data" ON participants
  FOR SELECT USING (
    session_id = current_setting('app.session_id', true) OR
    user_id = auth.uid()
  );

CREATE POLICY "Participants can insert own data" ON participants
  FOR INSERT WITH CHECK (
    session_id = current_setting('app.session_id', true) OR
    user_id = auth.uid()
  );

CREATE POLICY "Participants can update own data" ON participants
  FOR UPDATE USING (
    session_id = current_setting('app.session_id', true) OR
    user_id = auth.uid()
  );

-- Responses: participants can only access their own (supports both anonymous and authenticated)
CREATE POLICY "Participants can view own responses" ON responses
  FOR SELECT USING (
    participant_id IN (
      SELECT id FROM participants 
      WHERE session_id = current_setting('app.session_id', true) OR user_id = auth.uid()
    )
  );

CREATE POLICY "Participants can insert own responses" ON responses
  FOR INSERT WITH CHECK (
    participant_id IN (
      SELECT id FROM participants 
      WHERE session_id = current_setting('app.session_id', true) OR user_id = auth.uid()
    )
  );

-- Results: participants can only access their own (supports both anonymous and authenticated)
CREATE POLICY "Participants can view own results" ON results
  FOR SELECT USING (
    participant_id IN (
      SELECT id FROM participants 
      WHERE session_id = current_setting('app.session_id', true) OR user_id = auth.uid()
    )
  );

CREATE POLICY "Participants can insert own results" ON results
  FOR INSERT WITH CHECK (
    participant_id IN (
      SELECT id FROM participants 
      WHERE session_id = current_setting('app.session_id', true) OR user_id = auth.uid()
    )
  );

-- Coaching sessions: participants can only access their own (supports both anonymous and authenticated)
CREATE POLICY "Participants can view own coaching sessions" ON coaching_sessions
  FOR SELECT USING (
    participant_id IN (
      SELECT id FROM participants 
      WHERE session_id = current_setting('app.session_id', true) OR user_id = auth.uid()
    )
  );

CREATE POLICY "Participants can insert own coaching sessions" ON coaching_sessions
  FOR INSERT WITH CHECK (
    participant_id IN (
      SELECT id FROM participants 
      WHERE session_id = current_setting('app.session_id', true) OR user_id = auth.uid()
    )
  );

-- Phase 2: Lab assessments - users can view assessments for their lab
CREATE POLICY "Users can view lab assessments" ON lab_assessments
  FOR SELECT USING (
    lab_id IN (SELECT lab_id FROM users WHERE id = auth.uid())
  );

-- Phase 2: User assessments - users can view their own permissions
CREATE POLICY "Users can view own permissions" ON user_assessments
  FOR SELECT USING (user_id = auth.uid());

-- Phase 2: Assessments - check lab membership for access
CREATE POLICY "Users can view accessible assessments" ON assessments
  FOR SELECT USING (
    is_active = true AND (
      -- Public access (no lab restrictions) OR
      id IN (
        SELECT assessment_id FROM lab_assessments 
        WHERE lab_id IN (SELECT lab_id FROM users WHERE id = auth.uid())
      ) OR
      -- Individual user permission override
      id IN (
        SELECT assessment_id FROM user_assessments 
        WHERE user_id = auth.uid() AND (expires_at IS NULL OR expires_at > NOW())
      )
    )
  );

-- Phase 3: Coaching preferences - users can manage their own
CREATE POLICY "Users can view own coaching preferences" ON coaching_preferences
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own coaching preferences" ON coaching_preferences
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can insert own coaching preferences" ON coaching_preferences
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Phase 4: SONA studies - admins and researchers can view
CREATE POLICY "Researchers can view studies" ON sona_studies
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'researcher'))
  );

-- Phase 4: Study assessments - researchers can view
CREATE POLICY "Researchers can view study assessments" ON study_assessments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'researcher'))
  );

-- Phase 4: Study participants - researchers can view (anonymized)
CREATE POLICY "Researchers can view study participants" ON study_participants
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'researcher'))
  );

-- Phase 4: IRB access log - IRB role can view (to be configured)
CREATE POLICY "IRB can view access log" ON irb_access_log
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'researcher'))
  );

-- Note: Assessment access now controlled by lab_assessments and user_assessments policies above

-- Insert initial assessment metadata (skip if already exists)
INSERT INTO assessments (name, title, description, type, config) VALUES 
(
  'occupational-fit',
  'Occupational Fit Assessment',
  'Adaptive conjoint analysis to determine individual preferences for job attributes and compensation packages. Based on Slade et al. (2002) methodology.',
  'conjoint',
  '{
    "num_tasks": 8,
    "attributes": ["base_pay", "learning", "manager_effectiveness", "internal_job_market", "health_care"],
    "adaptive": true,
    "show_best_package": true
  }'
),
(
  'personality-test',
  'Research Personality Inventory',
  'Comprehensive personality assessment based on the Big Five model with domain-specific workplace traits.',
  'personality',
  '{
    "num_items": 75,
    "scales": ["openness", "conscientiousness", "extraversion", "agreeableness", "neuroticism"],
    "adaptive": false,
    "show_profile": true
  }'
),
(
  'ei-test',
  'Emotional Intelligence Assessment',
  'Ability-based emotional intelligence measurement using the four-branch model (perceiving, using, understanding, managing emotions).',
  'ei',
  '{
    "num_scenarios": 20,
    "branches": ["perceiving", "using", "understanding", "managing"],
    "scoring": "ability_based",
    "show_feedback": true
  }'
),
(
  'people-analytics-fit',
  'People Analyst Fit Assessment',
  'Comprehensive assessment measuring fit with People Analyst role across five key domains: Interests, Work Values, Knowledge, Skills, and Personality. Based on Liu et al. (2024) Integrative Fit Assessment Framework.',
  'fit',
  '{
    "num_items": 159,
    "domains": ["interests", "work_values", "knowledge", "skills", "personality"],
    "scale": "likert",
    "show_profile": true,
    "estimated_time": "15-20 minutes"
  }'
)
ON CONFLICT (name) DO NOTHING;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop triggers if they exist, then recreate
DROP TRIGGER IF EXISTS update_assessments_updated_at ON assessments;
DROP TRIGGER IF EXISTS update_participant_activity ON responses;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_coaching_preferences_updated_at ON coaching_preferences;
DROP TRIGGER IF EXISTS update_sona_studies_updated_at ON sona_studies;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_assessments_updated_at BEFORE UPDATE ON assessments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update participant last_active
CREATE OR REPLACE FUNCTION update_participant_last_active()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE participants 
  SET last_active = NOW() 
  WHERE id = NEW.participant_id;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update last_active when responses are inserted
CREATE TRIGGER update_participant_activity AFTER INSERT ON responses
  FOR EACH ROW EXECUTE FUNCTION update_participant_last_active();

-- Trigger to update users updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update coaching_preferences updated_at
CREATE TRIGGER update_coaching_preferences_updated_at BEFORE UPDATE ON coaching_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update sona_studies updated_at
CREATE TRIGGER update_sona_studies_updated_at BEFORE UPDATE ON sona_studies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert initial PAL lab
INSERT INTO labs (name, description, is_active) VALUES 
('PAL', 'Personality and Individual Differences at Work Lab', true)
ON CONFLICT (name) DO NOTHING;

-- Assign existing assessments to PAL lab (for backward compatibility)
INSERT INTO lab_assessments (lab_id, assessment_id, access_level, is_active)
SELECT 
    l.id,
    a.id,
    'full',
    true
FROM labs l
CROSS JOIN assessments a
WHERE l.name = 'PAL'
ON CONFLICT (lab_id, assessment_id) DO NOTHING;
