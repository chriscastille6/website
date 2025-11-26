# Assessment Library Setup Guide

## Overview

This guide walks you through setting up the complete assessment library system for your Hugo academic website. The system includes three core assessments with modern React interfaces, Supabase backend, and seamless Hugo integration.

> **📋 Modernization Roadmap**: For plans on adding user accounts, lab access control, and AI coaching integration, see [ASSESSMENT_LIBRARY_ROADMAP.md](./ASSESSMENT_LIBRARY_ROADMAP.md)

## Architecture

```
Assessment Library System
├── React Library Catalog (/static/assessments/library/)
├── Individual Assessments
│   ├── Occupational Fit (/static/assessments/occupational-fit/)
│   ├── Personality Test (/static/assessments/personality-test/)
│   └── EI Test (/static/assessments/ei-test/)
├── Shared Components (/static/assessments/shared/)
├── Supabase Database (PostgreSQL)
├── Hugo Shortcode Integration
└── R Analysis Pipeline (/scripts/export_assessment_data.R)
```

## Setup Steps

### 1. Supabase Database Setup

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create new project
   - Note your project URL and anon key

2. **Run Database Schema**
   ```sql
   -- Execute the contents of supabase-schema.sql in your Supabase SQL editor
   -- This creates all necessary tables, indexes, and security policies
   ```

3. **Configure Environment Variables**
   ```bash
   # Add to your environment or .env file
   SUPABASE_URL=your_project_url
   SUPABASE_ANON_KEY=your_anon_key
   SUPABASE_SERVICE_KEY=your_service_role_key
   SUPABASE_DB_HOST=db.your-project.supabase.co
   SUPABASE_DB_PASSWORD=your_db_password
   ```

### 2. Update Supabase Configuration

Edit the following files to include your actual Supabase credentials:

**`/static/assessments/library/index.html`** (line 33-34):
```javascript
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
```

**`/static/assessments/shared/supabase-client.js`** (line 8-11):
```javascript
const SUPABASE_CONFIG = {
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY'
};
```

**`/scripts/export_assessment_data.R`** (line 19-26):
```r
SUPABASE_CONFIG <- list(
  url = "YOUR_SUPABASE_URL",
  service_key = "YOUR_SUPABASE_SERVICE_KEY",
  db_host = "db.your-project.supabase.co",
  db_port = 5432,
  db_name = "postgres",
  db_user = "postgres",
  db_password = "YOUR_DB_PASSWORD"
)
```

### 3. Test the System

1. **Start Hugo Server**
   ```bash
   hugo server
   ```

2. **Visit Assessment Library**
   - Go to `http://localhost:1313/assessments/library/`
   - Should see catalog with three assessments

3. **Test Individual Assessments**
   - Occupational Fit: `http://localhost:1313/assessments/occupational-fit/`
   - Personality Test: `http://localhost:1313/assessments/personality-test/`
   - EI Test: `http://localhost:1313/assessments/ei-test/`

### 4. Embed in Hugo Content

Use the shortcode to embed assessments in your content:

```markdown
<!-- In any .md file -->
{{< assessment "occupational-fit" >}}

<!-- With custom height -->
{{< assessment "personality-test" "600px" >}}

<!-- With custom title -->
{{< assessment "ei-test" "800px" "Emotional Intelligence Assessment" >}}
```

## Usage Examples

### Example Content Page

Create `/content/post/assessment-demo/index.md`:

```markdown
---
title: "Interactive Assessments Demo"
date: 2025-10-10
summary: "Demonstration of the assessment library system"
---

# Research Assessment Library

Our assessment library provides research-grade psychological measurements for academic research and organizational applications.

## Available Assessments

### 1. Occupational Fit Assessment

Based on Slade et al. (2002) methodology, this adaptive conjoint analysis determines individual preferences for workplace benefits and compensation.

{{< assessment "occupational-fit" >}}

### 2. Big Five Personality Inventory

Research-validated personality assessment measuring the five major dimensions of personality with workplace applications.

{{< assessment "personality-test" >}}

### 3. Emotional Intelligence Assessment

Ability-based EI measurement using the four-branch model (coming soon - currently shows framework and sample questions).

{{< assessment "ei-test" >}}

## Research Applications

These assessments are designed for:
- Academic research in organizational psychology
- HR analytics and talent management
- Individual development and coaching
- Longitudinal studies of personality and preferences
```

## Data Analysis with R

### Export Assessment Data

```r
# Load the export functions
source("scripts/export_assessment_data.R")

# Connect to Supabase
con <- connect_supabase()

# Export conjoint data for existing analysis pipeline
conjoint_data <- export_conjoint_data(con)

# Use with existing analysis.R from cnjoint analysis folder
source("cnjoint analysis/analysis.R")
# The exported data format is compatible with existing analysis

# Export personality data
personality_data <- export_personality_data(con)

# Generate summary report
summary <- generate_summary_report(con)
print(summary)

# Export all data to CSV files
export_to_csv("assessment_exports")

# Close connection
dbDisconnect(con)
```

### Integration with Existing Analysis

The exported data formats are designed to work with your existing R analysis pipelines:

- **Conjoint data** → Compatible with `cnjoint analysis/analysis.R`
- **Personality data** → Standard psychometric analysis format
- **All data** → CSV exports for any analysis tool

## Security and Privacy

### Row Level Security (RLS)

The database uses RLS policies to ensure:
- Participants can only access their own data
- Anonymous sessions are properly isolated
- No cross-participant data leakage

### Data Consent

The system supports:
- Anonymous participation (default)
- Optional data sharing consent
- Future AI coaching consent
- Demographic data collection (optional)

### HIPAA Compliance

For research requiring HIPAA compliance:
- Supabase offers HIPAA-compliant hosting
- Additional security configurations available
- Audit logging and encryption at rest

## Customization

### Adding New Assessments

1. **Create Assessment Directory**
   ```
   /static/assessments/your-assessment/
   └── index.html
   ```

2. **Add to Database**
   ```sql
   INSERT INTO assessments (name, title, description, type, config) 
   VALUES ('your-assessment', 'Your Assessment Title', 'Description...', 'your_type', '{}');
   ```

3. **Use Shared Components**
   ```javascript
   // Load shared components
   <script src="../shared/supabase-client.js"></script>
   <script src="../shared/assessment-runner.js"></script>
   
   // Use AssessmentData class for database operations
   const assessmentData = new AssessmentData('your-assessment');
   ```

### Modifying Existing Assessments

- **Occupational Fit**: Edit attributes in `/static/assessments/occupational-fit/index.html`
- **Personality Test**: Modify items in `/static/assessments/personality-test/index.html`
- **EI Test**: Complete the placeholder framework

### Custom Styling

All assessments use Tailwind CSS classes. Customize by:
- Modifying existing classes
- Adding custom CSS in `<style>` sections
- Creating shared stylesheets in `/static/assessments/shared/`

## Deployment

### Netlify Deployment

The system works with your existing Netlify deployment:
- No additional configuration needed
- Static files served directly
- Supabase handles all dynamic functionality

### Environment Variables in Production

Set these in your Netlify environment variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_KEY`

## Troubleshooting

### Common Issues

1. **"Assessment not loading"**
   - Check Supabase credentials
   - Verify database schema is applied
   - Check browser console for errors

2. **"Data not saving"**
   - Verify RLS policies are active
   - Check network connectivity
   - Ensure assessment exists in database

3. **"R export failing"**
   - Install required R packages
   - Check database connection credentials
   - Verify PostgreSQL access

### Debug Mode

Enable debug logging:
```javascript
// In any assessment file
window.AssessmentLibrary.DEBUG = true;
```

## Support and Development

### File Structure Reference

```
Website/
├── static/assessments/
│   ├── library/index.html              # Main catalog
│   ├── shared/
│   │   ├── supabase-client.js          # Database client
│   │   └── assessment-runner.js        # Shared components
│   ├── occupational-fit/index.html     # Conjoint analysis
│   ├── personality-test/index.html     # Big Five inventory
│   └── ei-test/index.html              # EI framework
├── layouts/shortcodes/assessment.html  # Hugo shortcode
├── scripts/export_assessment_data.R    # R analysis integration
├── supabase-schema.sql                 # Database schema
└── ASSESSMENT_LIBRARY_SETUP.md         # This guide
```

### Next Steps

1. Set up Supabase project and configure credentials
2. Test all three assessments locally
3. Create content pages using the shortcode
4. Deploy to production
5. Begin collecting research data
6. Use R scripts for analysis

The system is designed to be research-grade while remaining simple to use and maintain. All components are modular and can be extended as your research needs evolve.
