#!/bin/bash
echo "=== HUGO BUILD ERROR FIX SCRIPT ==="

cd /workspace

# Check which directories are Hugo sites
echo "Checking for Hugo sites..."
for dir in Website PAL-of-the-Bayou fresh-website; do
    if [ -d "$dir" ]; then
        echo "Processing Hugo site: $dir"
        cd "/workspace/$dir"
        
        # Fix 1: Update Go modules if present
        if [ -f "go.mod" ]; then
            echo "  - Updating Go modules..."
            go mod tidy 2>/dev/null
            go mod download 2>/dev/null
        fi
        
        # Fix 2: Check theme configuration
        if [ -d "themes" ] && [ -d "themes/hugo-academic" ]; then
            echo "  - Hugo Academic theme detected"
            # Convert to modern Wowchemy if needed
            if ! grep -q "wowchemy" config/_default/hugo.yaml 2>/dev/null; then
                echo "  - Converting to Wowchemy theme..."
                # Backup old config
                cp config/_default/hugo.yaml config/_default/hugo.yaml.backup 2>/dev/null
                
                # Update theme reference
                sed -i 's/theme:.*/theme: "github.com\/wowchemy\/wowchemy-hugo-themes\/modules\/wowchemy\/v5"/' config/_default/hugo.yaml 2>/dev/null
            fi
        fi
        
        # Fix 3: Clean public directory
        if [ -d "public" ]; then
            echo "  - Cleaning public directory..."
            rm -rf public/*
        fi
        
        # Fix 4: Ensure resources directory exists
        mkdir -p resources
        
        # Fix 5: Try Hugo build and capture errors
        echo "  - Attempting Hugo build..."
        if hugo --verbose > "/tmp/build_${dir}.log" 2>&1; then
            echo "  ✅ Build successful for $dir"
        else
            echo "  ❌ Build failed for $dir"
            echo "  Error details:"
            head -10 "/tmp/build_${dir}.log"
            
            # Common fixes based on error patterns
            if grep -q "theme not found" "/tmp/build_${dir}.log"; then
                echo "  - Theme not found - initializing Hugo modules..."
                hugo mod init "github.com/example/site" 2>/dev/null
                echo 'imports:
  - path: github.com/wowchemy/wowchemy-hugo-themes/modules/wowchemy-plugin-hugo
  - path: github.com/wowchemy/wowchemy-hugo-themes/modules/wowchemy/v5' > config/_default/module.yaml
                hugo mod get 2>/dev/null
            fi
            
            if grep -q "config file not found" "/tmp/build_${dir}.log"; then
                echo "  - Creating basic config..."
                mkdir -p config/_default
                echo 'baseURL: "https://example.com"
languageCode: "en-us"
title: "My Academic Site"
theme: "github.com/wowchemy/wowchemy-hugo-themes/modules/wowchemy/v5"' > config/_default/hugo.yaml
            fi
            
            # Retry build
            echo "  - Retrying build after fixes..."
            if hugo --verbose > "/tmp/build_retry_${dir}.log" 2>&1; then
                echo "  ✅ Build successful after fixes for $dir"
            else
                echo "  ❌ Build still failing for $dir"
                echo "  Full error log saved to /tmp/build_retry_${dir}.log"
            fi
        fi
        
        cd /workspace
        echo ""
    fi
done

echo "=== FIX COMPLETE ==="
echo "Check /tmp/build_*.log files for detailed error information"
