#!/bin/bash
# Start Hugo server from the PAL-of-the-Bayou directory
# This ensures Hugo builds from the correct project directory

echo "Starting Hugo server for PAL-of-the-Bayou..."
echo "Server will be available at: http://localhost:1314"
echo "Press Ctrl+C to stop the server"
echo ""

# Kill any existing Hugo processes
pkill -f hugo 2>/dev/null

# Start Hugo server with explicit source directory
hugo server --port 1314 --bind 0.0.0.0 --source . 