# Automated Screenshots for Correlation Learning App

This directory contains tools to automatically capture high-quality screenshots of the Correlation Learning App for use in blog posts, documentation, and presentations.

## Quick Start

1. **Setup** (one-time):
   ```bash
   ./setup_screenshots.sh
   ```

2. **Run Screenshots**:
   ```bash
   python3 take_screenshots.py
   ```

3. **Find Results**:
   Check the `screenshots/` directory for your images.

## What Screenshots Are Taken

The script automatically captures 8 key screenshots:

1. **Main Interface** (`main_interface.png`) - App overview and controls
2. **Phase 1: Intuitive** (`phase1_height_weight.png`) - Height vs Weight example
3. **Phase 2: Medical** (`phase2_medical_example.png`) - Medical intervention effects
4. **Phase 3: Business** (`phase3_business_example.png`) - Organizational psychology examples
5. **BESD Visualization** (`besd_visualization.png`) - Effect size display
6. **Trend Lines** (`trend_line_example.png`) - Prediction vs true correlation lines
7. **Hover Information** (`hover_information.png`) - Interactive data point details
8. **Feedback & Scoring** (`feedback_scoring.png`) - Accuracy feedback system

## Technical Requirements

- **Python 3.7+**
- **Chrome/Chromium browser**
- **ChromeDriver** (automatically installed by setup script)
- **Internet connection** (to access the deployed app)

## Customization

### Modify Screenshot Parameters

Edit `take_screenshots.py` to customize:
- **App URL**: Change `app_url` in the constructor
- **Resolution**: Modify `--window-size` in `setup_driver()`
- **Correlation values**: Adjust the correlation guesses in each screenshot function
- **Wait times**: Modify `time.sleep()` values for different app loading speeds

### Add New Screenshots

To add a new screenshot:

1. Create a new method in the `CorrelationAppScreenshots` class:
   ```python
   def screenshot_9_new_feature(self):
       """Screenshot 9: New Feature Description"""
       print("\n=== Taking Screenshot 9: New Feature ===")
       # Your screenshot logic here
       self.take_screenshot("new_feature.png", "Description of new feature")
   ```

2. Add it to the `run_all_screenshots()` method:
   ```python
   self.screenshot_9_new_feature()
   ```

## Troubleshooting

### Common Issues

**"ChromeDriver not found"**
- Run `./setup_screenshots.sh` to install automatically
- Or manually: `brew install chromedriver` (macOS)

**"Element not found" errors**
- The app interface may have changed
- Check element IDs in the script against the current app
- Increase wait times if the app loads slowly

**"Permission denied" on setup script**
- Run: `chmod +x setup_screenshots.sh`

**Screenshots are blank or incomplete**
- Increase wait times in the script
- Check if the app is accessible at the URL
- Verify Chrome is installed and working

### Debug Mode

To see the browser while taking screenshots (for debugging):
1. Comment out `chrome_options.add_argument("--headless")` in `setup_driver()`
2. Run the script to see what's happening

## Output Format

Screenshots are saved as PNG files with:
- **Resolution**: 1920x1080 (high quality)
- **Format**: PNG (lossless)
- **Naming**: Descriptive filenames (e.g., `phase1_height_weight.png`)
- **Location**: `screenshots/` directory

## Integration with Blog Post

The screenshots follow the guide in `screenshot_guide.md` and are designed to:
- Show the learning progression through phases
- Demonstrate key features and interactions
- Provide visual examples for the blog post
- Maintain consistent quality and composition

## Performance

- **Total time**: ~2-3 minutes for all screenshots
- **Individual screenshots**: 10-30 seconds each
- **Dependencies**: Requires stable internet connection
- **Resource usage**: Moderate (headless Chrome instance)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify the app is accessible at the URL
3. Ensure all dependencies are installed
4. Try running in debug mode to see what's happening 