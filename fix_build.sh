#!/bin/bash
echo "=== Hugo Build Fix Starting ==="
pwd

# Check and try to build in main directories
for dir in Website PAL-of-the-Bayou fresh-website; do
    if [ -d "$dir" ]; then
        echo "=== Processing $dir ==="
        cd "/workspace/$dir"
        
        # Check if themes exist
        if [ ! -d "themes" ] || [ -z "$(ls -A themes 2>/dev/null)" ]; then
            echo "Missing themes in $dir - creating themes directory"
            mkdir -p themes
        fi
        
        # Try basic build
        echo "Building $dir..."
        hugo --verbose 2>&1 | tee build.log
        
        cd /workspace
    fi
done
