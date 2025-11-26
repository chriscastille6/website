# Assessment Library Modernization Roadmap
# Location: /Users/ccastille/Documents/GitHub/Website/ASSESSMENT_LIBRARY_ROADMAP.md
# Purpose: Comprehensive plan for building a modernized assessment library with user accounts, access control, and AI coaching
# Why: Revisit and update existing plans to include user authentication, lab access management, and AI coaching integration
# RELEVANT FILES: ASSESSMENT_LIBRARY_SETUP.md, supabase-schema.sql, static/assessments/shared/supabase-client.js

## Executive Summary

This roadmap outlines the modernization of the assessment library platform to support:
1. **User accounts** with lab-based access control
2. **Assessment access management** (permissions for specific assessments)
3. **AI coaching integration** (scores shared with AI for personalized coaching)

The current system uses anonymous session-based participation. This roadmap extends it to support authenticated users while maintaining backward compatibility.

---

## Current State Analysis

### What Exists Now

**✅ Assessment Infrastructure**
- Three assessments: Occupational Fit, Personality Test, EI Test
- Supabase backend with PostgreSQL database
- React-based frontend interfaces
- Hugo integration via shortcodes
- R analysis pipeline for data export

**✅ Database Schema**
- `assessments` table (metadata)
- `participants` table (anonymous, session-based)
- `responses` table (individual question responses)
- `results` table (final scores)
- `coaching_sessions` table (placeholder for future AI coaching)
- Row Level Security (RLS) policies for data isolation

**✅ Current Features**
- Anonymous participation (session-based)
- Optional consent for data sharing
- Optional consent for AI coaching (flag exists, not implemented)
- Response time tracking
- Score calculation and storage

### What's Missing

**❌ User Authentication**
- No user accounts system
- No login/registration
- No password management
- No email verification

**❌ Access Control**
- No lab/organization management
- No assessment permissions
- No role-based access (admin, researcher, participant)
- All assessments currently public

**❌ AI Coaching Integration**
- `coaching_sessions` table exists but unused
- No AI API integration
- No score-to-AI pipeline
- No coaching interface

**❌ User Dashboard**
- No user profile page
- No assessment history view
- No score tracking over time
- No coaching session management

---

## Phase 1: User Accounts & Authentication

### Goals
- Enable users to create accounts with your lab
- Secure authentication using Supabase Auth
- Email verification and password reset
- User profile management

### Database Changes

**New Table: `users`**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  lab_id UUID REFERENCES labs(id),
  role TEXT NOT NULL DEFAULT 'participant' CHECK (role IN ('participant', 'researcher', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**New Table: `labs`**
```sql
CREATE TABLE labs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  admin_user_id UUID REFERENCES auth.users(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Update: `participants` table**
```sql
-- Add user_id column (nullable for backward compatibility)
ALTER TABLE participants ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- Update RLS policies to support both anonymous and authenticated users
```

### Implementation Tasks

1. **Supabase Auth Setup**
   - Enable email authentication in Supabase dashboard
   - Configure email templates
   - Set up password reset flow

2. **Frontend Authentication**
   - Create login page (`/static/assessments/auth/login.html`)
   - Create registration page (`/static/assessments/auth/register.html`)
   - Create password reset page
   - Update `supabase-client.js` to handle auth state

3. **User Profile**
   - Create user dashboard (`/static/assessments/dashboard/index.html`)
   - Display assessment history
   - Show completed assessments and scores
   - Link to AI coaching (when available)

4. **Backward Compatibility**
   - Maintain anonymous session support
   - Allow users to link anonymous sessions to accounts
   - Migrate existing session data to user accounts

### Files to Create/Modify

- `supabase-schema.sql` - Add users, labs tables and updated RLS
- `static/assessments/auth/login.html` - Login interface
- `static/assessments/auth/register.html` - Registration interface
- `static/assessments/dashboard/index.html` - User dashboard
- `static/assessments/shared/supabase-client.js` - Add auth methods
- `static/assessments/shared/auth-manager.js` - New auth utility class

---

## Phase 2: Access Control & Lab Management

### Goals
- Lab-based access control
- Assessment permissions per lab
- Role-based access (participant, researcher, admin)
- Admin dashboard for lab management

### Database Changes

**New Table: `lab_assessments`**
```sql
CREATE TABLE lab_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lab_id UUID REFERENCES labs(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  access_level TEXT DEFAULT 'full' CHECK (access_level IN ('full', 'limited', 'demo')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(lab_id, assessment_id)
);
```

**New Table: `user_assessments`** (for individual permissions)
```sql
CREATE TABLE user_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, assessment_id)
);
```

### Implementation Tasks

1. **Lab Management Interface**
   - Admin dashboard for creating/managing labs
   - Assign assessments to labs
   - Invite users to labs
   - Manage lab members

2. **Assessment Access Control**
   - Check user's lab membership
   - Check lab's assessment permissions
   - Check individual user permissions
   - Show/hide assessments based on access

3. **Registration Flow**
   - User selects or creates lab during registration
   - Admin approval for lab creation (optional)
   - Email invitation system for lab members

4. **Assessment Library Updates**
   - Filter assessments by access
   - Show "Request Access" for unavailable assessments
   - Display lab-specific assessment catalogs

### Files to Create/Modify

- `supabase-schema.sql` - Add access control tables
- `static/assessments/admin/labs.html` - Lab management interface
- `static/assessments/admin/users.html` - User management
- `static/assessments/library/index.html` - Add access filtering
- `static/assessments/shared/access-control.js` - New access checking utilities

---

## Phase 3: AI Coaching Integration

### Goals
- Share assessment scores with AI tool
- Generate personalized coaching insights
- Store coaching sessions
- Provide coaching interface for users

### Database Changes

**Update: `coaching_sessions` table** (already exists, enhance it)
```sql
-- Add more fields to existing coaching_sessions table
ALTER TABLE coaching_sessions ADD COLUMN IF NOT EXISTS assessment_result_id UUID REFERENCES results(id);
ALTER TABLE coaching_sessions ADD COLUMN IF NOT EXISTS coaching_type TEXT DEFAULT 'general';
ALTER TABLE coaching_sessions ADD COLUMN IF NOT EXISTS insights JSONB;
ALTER TABLE coaching_sessions ADD COLUMN IF NOT EXISTS recommendations JSONB;
ALTER TABLE coaching_sessions ADD COLUMN IF NOT EXISTS user_feedback JSONB;
```

**New Table: `coaching_preferences`**
```sql
CREATE TABLE coaching_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  enabled BOOLEAN DEFAULT true,
  coaching_style TEXT DEFAULT 'supportive' CHECK (coaching_style IN ('supportive', 'directive', 'collaborative')),
  frequency TEXT DEFAULT 'on_completion' CHECK (frequency IN ('on_completion', 'weekly', 'monthly', 'manual')),
  topics JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Implementation Tasks

1. **AI Integration**
   - Choose AI provider (OpenAI, Anthropic, or self-hosted)
   - Create API wrapper for AI calls
   - Design prompt templates for coaching
   - Handle API rate limiting and errors

2. **Score-to-Coaching Pipeline**
   - Trigger coaching generation on assessment completion
   - Combine multiple assessment scores for holistic coaching
   - Generate personalized insights based on scores
   - Create actionable recommendations

3. **Coaching Interface**
   - Display coaching insights to users
   - Show recommendations with action items
   - Allow users to provide feedback
   - Track coaching effectiveness

4. **Privacy & Consent**
   - Respect `consent_ai_coaching` flag
   - Allow users to opt-in/opt-out
   - Store consent history
   - Provide data deletion options

### Files to Create/Modify

- `supabase-schema.sql` - Enhance coaching tables
- `static/assessments/coaching/dashboard.html` - Coaching interface
- `static/assessments/coaching/insights.html` - View coaching insights
- `scripts/ai_coaching_generator.R` - R script for AI coaching (optional)
- `static/assessments/shared/ai-coaching.js` - Frontend AI integration
- `scripts/coaching_pipeline.py` or `.R` - Backend coaching generation

### AI Provider Options

**Option 1: OpenAI API**
- Pros: Easy integration, good quality, reasonable pricing
- Cons: External dependency, data privacy considerations
- Best for: Quick implementation, high-quality coaching

**Option 2: Anthropic Claude API**
- Pros: Strong privacy focus, excellent for coaching conversations
- Cons: Similar to OpenAI
- Best for: Privacy-conscious implementations

**Option 3: Self-Hosted LLM**
- Pros: Full control, no external API costs, complete privacy
- Cons: Requires infrastructure, lower quality than commercial APIs
- Best for: Maximum privacy, long-term cost savings

**Recommendation**: Start with OpenAI or Anthropic for MVP, consider self-hosted for production if privacy/control is critical.

---

## Implementation Timeline

### Phase 1: User Accounts (Weeks 1-3)
- Week 1: Database schema updates, Supabase Auth setup
- Week 2: Frontend authentication pages, user dashboard
- Week 3: Testing, backward compatibility, migration tools

### Phase 2: Access Control (Weeks 4-6)
- Week 4: Lab management tables, admin interfaces
- Week 5: Access control logic, assessment filtering
- Week 6: Testing, user invitations, documentation

### Phase 3: AI Coaching (Weeks 7-10)
- Week 7: AI provider selection, API integration
- Week 8: Coaching pipeline, prompt engineering
- Week 9: Coaching interface, user feedback
- Week 10: Testing, optimization, documentation

---

## Technical Considerations

### Security
- Use Supabase RLS for all data access
- Implement proper authentication checks
- Sanitize all user inputs
- Use HTTPS for all communications
- Regular security audits

### Privacy
- GDPR compliance considerations
- Data retention policies
- User data export/deletion
- Consent management
- Anonymization options

### Performance
- Index database tables properly
- Cache assessment metadata
- Optimize AI API calls (batch, cache)
- Use CDN for static assets
- Monitor query performance

### Scalability
- Design for multiple labs
- Support thousands of users
- Efficient AI API usage
- Database connection pooling
- Background job processing for coaching

---

## Migration Strategy

### Existing Data
- Anonymous sessions remain valid
- Users can link sessions to accounts
- No data loss during migration
- Gradual rollout option

### Backward Compatibility
- Anonymous access still works
- Existing assessments unchanged
- R analysis scripts still function
- No breaking changes to API

---

## Success Metrics

### Phase 1 Metrics
- User registration rate
- Login success rate
- Account activation rate
- User retention

### Phase 2 Metrics
- Labs created
- Assessments assigned to labs
- Access control effectiveness
- Admin usage

### Phase 3 Metrics
- Coaching sessions generated
- User engagement with coaching
- Coaching feedback scores
- AI API costs

---

## Next Steps

1. **Review this roadmap** - Confirm priorities and timeline
2. **Set up development environment** - Supabase project, local testing
3. **Begin Phase 1** - Start with database schema updates
4. **Iterate and test** - Build incrementally, test thoroughly
5. **Deploy gradually** - Start with beta users, expand gradually

---

## Questions to Resolve

1. **Lab Structure**: Should labs be organization-based, research-group-based, or both?
2. **Access Model**: Free for all lab members, or tiered access?
3. **AI Provider**: Which AI provider should we use? Budget considerations?
4. **Coaching Style**: Automated on completion, or user-requested?
5. **Pricing**: Will this be free for academic use, or have pricing tiers?
6. **Admin Roles**: Who can create labs? Who can manage assessments?

---

## Related Files

- `ASSESSMENT_LIBRARY_SETUP.md` - Current setup guide (needs update after implementation)
- `supabase-schema.sql` - Database schema (needs updates for all phases)
- `static/assessments/shared/supabase-client.js` - Client library (needs auth additions)
- `content/assessments.md` - Public-facing content page
- `content/post/assessment-library-demo/` - Demo post

---

*Last Updated: 2025-01-XX*
*Status: Planning Phase*
*Next Review: After Phase 1 completion*





