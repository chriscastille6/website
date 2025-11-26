#!/bin/bash
# Supabase Setup Script
# Location: /Users/ccastille/Documents/GitHub/Website/setup_supabase.sh
# Purpose: Interactive script to configure Supabase credentials
# Why: Automates the setup process for Supabase integration
# RELEVANT FILES: static/assessments/shared/supabase-client.js, static/assessments/shared/auth-manager.js

echo "=========================================="
echo "Supabase Configuration Setup"
echo "=========================================="
echo ""
echo "This script will help you configure Supabase credentials."
echo "You'll need:"
echo "  1. Your Supabase Project URL (from Settings → API)"
echo "  2. Your Supabase anon public key (from Settings → API)"
echo ""

# Get Supabase URL
read -p "Enter your Supabase Project URL: " SUPABASE_URL

# Validate URL format
if [[ ! $SUPABASE_URL =~ ^https://.*\.supabase\.co$ ]]; then
    echo "Warning: URL doesn't look like a Supabase URL. Continuing anyway..."
fi

# Get Supabase anon key
read -p "Enter your Supabase anon public key: " SUPABASE_ANON_KEY

# Validate key format (should be a long string)
if [ ${#SUPABASE_ANON_KEY} -lt 50 ]; then
    echo "Warning: Key seems too short. Make sure you're using the 'anon public' key, not the service role key."
fi

echo ""
echo "Updating configuration files..."

# Update supabase-client.js
if [ -f "static/assessments/shared/supabase-client.js" ]; then
    # Use sed to replace the values (works on macOS)
    sed -i '' "s|url: 'YOUR_SUPABASE_URL'|url: '${SUPABASE_URL}'|g" static/assessments/shared/supabase-client.js
    sed -i '' "s|anonKey: 'YOUR_SUPABASE_ANON_KEY'|anonKey: '${SUPABASE_ANON_KEY}'|g" static/assessments/shared/supabase-client.js
    echo "✓ Updated static/assessments/shared/supabase-client.js"
else
    echo "✗ Error: supabase-client.js not found"
fi

# Update auth-manager.js (fallback values)
if [ -f "static/assessments/shared/auth-manager.js" ]; then
    # Update the fallback values in auth-manager.js constructor
    sed -i '' "s|'YOUR_SUPABASE_URL'|'${SUPABASE_URL}'|g" static/assessments/shared/auth-manager.js
    sed -i '' "s|'YOUR_SUPABASE_ANON_KEY'|'${SUPABASE_ANON_KEY}'|g" static/assessments/shared/auth-manager.js
    echo "✓ Updated static/assessments/shared/auth-manager.js"
else
    echo "✗ Error: auth-manager.js not found"
fi

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Go to your Supabase dashboard → SQL Editor"
echo "2. Open the file: supabase-schema.sql"
echo "3. Copy all contents and paste into SQL Editor"
echo "4. Click 'Run' to execute the schema"
echo ""
echo "After running the schema, you can test by visiting:"
echo "  http://localhost:1313/assessments/auth/register.html"
echo ""

