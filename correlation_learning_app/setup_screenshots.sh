#!/bin/bash

# Setup script for automated screenshots of the Correlation Learning App

echo "=== Correlation Learning App Screenshot Setup ==="
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip3 first."
    exit 1
fi

echo "✓ pip3 found"

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
pip3 install -r requirements_screenshots.txt

if [ $? -eq 0 ]; then
    echo "✓ Python dependencies installed successfully"
else
    echo "❌ Failed to install Python dependencies"
    exit 1
fi

# Check if Chrome is installed
if ! command -v google-chrome &> /dev/null && ! command -v chromium-browser &> /dev/null; then
    echo ""
    echo "⚠️  Chrome/Chromium not found. Please install Chrome or Chromium."
    echo "   On macOS: brew install --cask google-chrome"
    echo "   On Ubuntu: sudo apt install chromium-browser"
    echo "   On Windows: Download from https://www.google.com/chrome/"
fi

# Check if ChromeDriver is installed
if ! command -v chromedriver &> /dev/null; then
    echo ""
    echo "⚠️  ChromeDriver not found. Installing via webdriver-manager..."
    python3 -c "from webdriver_manager.chrome import ChromeDriverManager; ChromeDriverManager().install()"
    
    if [ $? -eq 0 ]; then
        echo "✓ ChromeDriver installed successfully"
    else
        echo "❌ Failed to install ChromeDriver"
        echo "   Manual installation: brew install chromedriver (macOS)"
        echo "   Or download from: https://chromedriver.chromium.org/"
    fi
else
    echo "✓ ChromeDriver found: $(chromedriver --version)"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To run the screenshot automation:"
echo "  python3 take_screenshots.py"
echo ""
echo "Screenshots will be saved to the 'screenshots/' directory."
echo "" 