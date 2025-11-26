# Setup Next Steps - Assessment Library
# Location: /Users/ccastille/Documents/GitHub/Website/SETUP_NEXT_STEPS.md
# Purpose: Step-by-step guide to complete Supabase setup and port first assessment
# Why: Provides clear instructions for getting the system operational
# RELEVANT FILES: supabase-schema.sql, static/assessments/shared/supabase-client.js

## Step 1: Update Supabase Credentials

1. **Get your Supabase credentials:**
   - Go to your Supabase project dashboard
   - Settings → API
   - Copy your "Project URL" and "anon public" key

2. **Update the configuration file:**
   - Open: `static/assessments/shared/supabase-client.js`
   - Replace `YOUR_SUPABASE_URL` with your Project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your anon public key

3. **Also update in auth-manager.js:**
   - Open: `static/assessments/shared/auth-manager.js`
   - Update the same credentials there (lines 8-9)

## Step 2: Run Database Schema

1. **In Supabase Dashboard:**
   - Go to SQL Editor
   - Click "New query"

2. **Copy and paste the entire schema:**
   - Open: `supabase-schema.sql`
   - Copy all contents
   - Paste into SQL Editor
   - Click "Run" (or press Cmd+Enter)

3. **Verify tables were created:**
   - Go to Table Editor
   - You should see these tables:
     - assessments
     - participants
     - users
     - labs
     - responses
     - results
     - lab_assessments
     - user_assessments
     - coaching_sessions
     - coaching_preferences
     - sona_studies
     - study_assessments
     - study_participants
     - irb_access_log

4. **Check initial data:**
   - `assessments` table should have 3 assessments
   - `labs` table should have PAL lab
   - `lab_assessments` should have assignments linking PAL to all assessments

## Step 3: Enable Supabase Auth

1. **In Supabase Dashboard:**
   - Go to Authentication → Settings
   - Enable "Email" provider
   - Configure email templates (optional for now)
   - Set site URL to: `http://localhost:1313`

2. **Test authentication:**
   - Visit: `http://localhost:1313/assessments/auth/register.html`
   - Try creating an account
   - Check Supabase Auth → Users to see if user was created

## Step 4: Port Your First Assessment

### Assessment Structure

Your assessment should be placed in:
```
static/assessments/your-assessment-name/index.html
```

### Required Components

1. **HTML Structure:**
   ```html
   <!DOCTYPE html>
   <html lang="en">
   <head>
       <!-- Assessment Name -->
       <!-- Location: /static/assessments/your-assessment-name/index.html -->
       <!-- Purpose: Description of what this assessment does -->
       <!-- Why: Why this assessment exists -->
       <!-- RELEVANT FILES: static/assessments/shared/supabase-client.js -->
       
       <meta charset="UTF-8">
       <meta name="viewport" content="width=device-width, initial-scale=1.0">
       <title>Your Assessment Name - PAL of the Bayou</title>
       
       <!-- Include Supabase and shared components -->
       <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
       <script src="../shared/supabase-client.js"></script>
       <script src="../shared/participant-id-generator.js"></script>
   </head>
   <body>
       <!-- Your assessment UI here -->
   </body>
   </html>
   ```

2. **Use AssessmentData class:**
   ```javascript
   const assessmentData = new AssessmentData('your-assessment-name');
   await assessmentData.initialize();
   
   // Save responses
   await assessmentData.saveResponse(questionId, questionType, responseData, responseTime);
   
   // Save final results
   await assessmentData.saveResult(scores, feedback);
   ```

3. **Register in database:**
   - The assessment should already be in the `assessments` table
   - If not, add it via SQL or admin interface

### Adding Assessment to Database

If your assessment isn't in the database yet, run this SQL:

```sql
INSERT INTO assessments (name, title, description, type, config) VALUES 
(
  'your-assessment-name',
  'Your Assessment Title',
  'Description of your assessment',
  'your-type',  -- Options: 'conjoint', 'personality', 'ei', 'cognitive-load'
  '{
    "key": "value"
  }'::jsonb
);
```

Then assign it to PAL lab:

```sql
INSERT INTO lab_assessments (lab_id, assessment_id, access_level, is_active)
SELECT 
    l.id,
    a.id,
    'full',
    true
FROM labs l, assessments a
WHERE l.name = 'PAL' AND a.name = 'your-assessment-name';
```

## Step 5: Test Your Assessment

1. **Visit the assessment:**
   - `http://localhost:1313/assessments/your-assessment-name/`

2. **Check data collection:**
   - Complete the assessment
   - Check Supabase → Table Editor → `responses` table
   - Check `results` table for final scores

3. **Test with authenticated user:**
   - Create account and log in
   - Complete assessment while logged in
   - Check that `participants.user_id` is set

## Common Issues

### "Supabase client not initialized"
- Check that credentials are updated in `supabase-client.js`
- Make sure Supabase URL starts with `https://`
- Verify anon key is correct

### "Assessment not found"
- Check that assessment is in `assessments` table
- Verify `name` field matches the folder name
- Check that `is_active = true`

### "Access denied"
- Check that assessment is assigned to PAL lab in `lab_assessments` table
- Verify user is in PAL lab (check `users.lab_id`)

### Data not saving
- Check browser console for errors
- Verify RLS policies are set correctly
- Check that participant was created in `participants` table

## Next Steps After Setup

1. **Test user registration and login**
2. **Test assessment completion**
3. **Verify data in Supabase tables**
4. **Test admin dashboards** (make yourself admin first)
5. **Register a SONA study** (if needed)

---

*Ready to port your assessment? Share the assessment details and I can help create the HTML file!*



