# Assessment Library Modernization - Demo Guide
# Location: /Users/ccastille/Documents/GitHub/Website/ASSESSMENT_LIBRARY_DEMO.md
# Purpose: Step-by-step guide to demo and test the new assessment library features
# Why: Provides clear instructions for testing user accounts, access control, and SONA integration
# RELEVANT FILES: ASSESSMENT_LIBRARY_ROADMAP.md, supabase-schema.sql

## Prerequisites

1. **Supabase Project Setup**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Note your project URL and anon key
   - Run the database schema from `supabase-schema.sql`

2. **Configure Supabase Credentials**
   - Update `static/assessments/shared/supabase-client.js` with your Supabase URL and anon key
   - Update all assessment HTML files that use Supabase

3. **Enable Supabase Auth**
   - In Supabase dashboard: Authentication → Settings
   - Enable Email authentication
   - Configure email templates (optional)

4. **Start Hugo Server**
   ```bash
   hugo server
   ```

---

## Demo Flow

### 1. Anonymous Access (Backward Compatibility)

**Test that anonymous sessions still work:**

1. Open browser in incognito/private mode
2. Navigate to: `http://localhost:1313/assessments/library/`
3. You should see all three assessments (backward compatibility)
4. Click "Quick Launch" on any assessment
5. Complete the assessment - data should save with session-based participant ID

**Expected Result:** Anonymous users can still access and complete assessments.

---

### 2. User Registration & Authentication

**Create a new user account:**

1. Navigate to: `http://localhost:1313/assessments/auth/register.html`
2. Fill in the registration form:
   - Full Name: "Demo User"
   - Email: "demo@example.com"
   - Password: "demo123456" (min 6 characters)
   - Confirm Password: "demo123456"
3. Click "Create Account"
4. Check your email for verification link (if email verification is enabled)
5. After verification, go to: `http://localhost:1313/assessments/auth/login.html`
6. Sign in with your credentials

**Expected Result:** User account created, assigned to PAL lab by default.

---

### 3. User Dashboard

**View user dashboard:**

1. After logging in, navigate to: `http://localhost:1313/assessments/dashboard/`
2. You should see:
   - Profile information (name, email, lab, role)
   - Assessment history (empty initially)
   - Research Participation section

**Test Research Opt-In:**

1. In the dashboard, find "Research Participation" section
2. Toggle "Opt into research participation" ON
3. If prompted, enter your full name
4. A participant ID should be generated (CANDIDATE-XXXX-XXXX format)
5. The participant ID should be displayed
6. Toggle OFF - participant ID should be removed

**Expected Result:** User can opt into research and generate participant ID.

---

### 4. Assessment Access Control

**Test lab-based access:**

1. As a logged-in user, navigate to: `http://localhost:1313/assessments/library/`
2. You should see all assessments (because you're in PAL lab and assessments are assigned to PAL)
3. Sign out
4. Create a new user account (different email)
5. This user should also see all assessments (PAL lab default)

**Test admin access:**

1. In Supabase dashboard, go to SQL Editor
2. Run this to make a user an admin:
   ```sql
   UPDATE users 
   SET role = 'admin' 
   WHERE email = 'your-email@example.com';
   ```
3. Log in as that user
4. Navigate to: `http://localhost:1313/assessments/admin/labs.html`
5. You should see the lab management interface

**Expected Result:** Users see assessments based on lab membership.

---

### 5. Admin - Lab Management

**View and manage labs:**

1. As admin, go to: `http://localhost:1313/assessments/admin/labs.html`
2. You should see:
   - PAL lab listed
   - Number of assessments assigned
3. Click "Assign Assessment" section
4. Select PAL lab
5. Select an assessment
6. Choose access level (full, limited, demo)
7. Click "Assign Assessment"

**Expected Result:** Assessments can be assigned to labs with different access levels.

---

### 6. Admin - Assessment Assignment

**View assessment assignments:**

1. As admin, go to: `http://localhost:1313/assessments/admin/assessments.html`
2. You should see all assessments with their assigned labs
3. Click "Assign to Labs" for any assessment
4. Assign it to PAL lab

**Expected Result:** Can view and manage which labs have access to which assessments.

---

### 7. SONA Study Registration

**Register a study:**

1. As admin/researcher, go to: `http://localhost:1313/assessments/admin/sona-studies.html`
2. Fill in the registration form:
   - SONA Study ID: "STUDY-2025-001"
   - IRB Approval Number: "IRB-2025-001"
   - Study Title: "Demo Study"
   - Principal Investigator: "Dr. Demo"
   - Select assessments: Choose one or more assessments
3. Click "Register Study"
4. The study should appear in the "Registered Studies" table

**Expected Result:** Studies can be registered and linked to assessments.

---

### 8. Participant-Study Linking

**Link participant to study (simulated):**

This happens automatically when a participant completes an assessment for a study. To test:

1. Complete an assessment while logged in
2. The system should link your participant record to any active studies using that assessment
3. Check in Supabase: `study_participants` table should have a record

**Note:** In production, this would be triggered by study-specific assessment links.

---

### 9. IRB Dashboard

**View IRB access:**

1. As admin/researcher, go to: `http://localhost:1313/assessments/admin/irb-dashboard.html`
2. You should see all registered studies
3. Use filters:
   - Filter by IRB Approval Number
   - Filter by SONA Study ID
   - Filter by Status
4. Click "View Details" on any study
5. You should see:
   - Study information
   - Number of participants
   - Assessments used

**Expected Result:** IRB can view study records and assessment usage.

---

### 10. Data Export for IRB

**Export study data:**

1. In R, load the export script:
   ```r
   source("scripts/export_sona_data.R")
   ```
2. Connect to Supabase:
   ```r
   con <- connect_supabase()
   ```
3. Export a specific study:
   ```r
   # Get study ID first
   study_id <- "your-study-uuid-here"
   export_study_data(study_id, "irb_exports")
   ```
4. Check the `irb_exports` folder for CSV files:
   - Study information
   - Participants (anonymized - participant IDs only)
   - Assessment results
   - Assessments used

**Expected Result:** Can export anonymized study data for IRB review.

---

## Testing Checklist

### Authentication
- [ ] User can register new account
- [ ] User receives email verification (if enabled)
- [ ] User can log in
- [ ] User can reset password
- [ ] User can log out
- [ ] Anonymous sessions still work

### User Dashboard
- [ ] Profile information displays correctly
- [ ] Assessment history shows completed assessments
- [ ] Research opt-in toggle works
- [ ] Participant ID generates correctly
- [ ] Participant ID persists after page reload

### Access Control
- [ ] Anonymous users see all assessments (backward compatibility)
- [ ] Logged-in users see assessments based on lab membership
- [ ] Admin can access admin dashboards
- [ ] Non-admin users cannot access admin dashboards

### Lab Management
- [ ] Admin can view labs
- [ ] Admin can assign assessments to labs
- [ ] Access levels work (full, limited, demo)
- [ ] Assessments appear in library based on lab access

### SONA Integration
- [ ] Admin can register studies
- [ ] Studies can be linked to assessments
- [ ] Participant-study linking works
- [ ] IRB dashboard shows study records
- [ ] IRB can filter studies
- [ ] IRB access is logged

### Data Security
- [ ] Participant IDs are generated client-side
- [ ] Names are never stored with participant IDs
- [ ] Anonymous sessions work without authentication
- [ ] RLS policies prevent unauthorized access

---

## Common Issues & Solutions

### Issue: "Supabase client not initialized"
**Solution:** Make sure Supabase URL and anon key are configured in `supabase-client.js`

### Issue: "Access denied" on admin pages
**Solution:** Update user role to 'admin' in Supabase:
```sql
UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';
```

### Issue: Assessments not showing in library
**Solution:** Assign assessments to PAL lab in admin dashboard or run:
```sql
INSERT INTO lab_assessments (lab_id, assessment_id, access_level, is_active)
SELECT l.id, a.id, 'full', true
FROM labs l, assessments a
WHERE l.name = 'PAL';
```

### Issue: Participant ID not generating
**Solution:** Check browser console for errors. Make sure `participant-id-generator.js` is loaded.

### Issue: Email verification not working
**Solution:** Check Supabase Auth settings. Email templates may need configuration.

---

## Next Steps

1. **Configure Production Supabase**
   - Set up production Supabase project
   - Update all configuration files with production credentials
   - Enable email authentication
   - Configure email templates

2. **Test with Real Data**
   - Create test users
   - Complete assessments
   - Test SONA study registration
   - Verify IRB dashboard

3. **Deploy**
   - Deploy Hugo site to Netlify
   - Configure environment variables
   - Test in production environment

4. **Enable AI Coaching (Future)**
   - When ready, configure OpenAI API key
   - Enable coaching in `ai-coaching.js`
   - Test coaching generation

---

*Last Updated: 2025-01-XX*
*Status: Ready for Testing*



