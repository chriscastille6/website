#!/usr/bin/env python3
"""
Simplified Screenshot Script for Correlation Learning App
Takes basic screenshots of the app interface.
"""

import os
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options

class SimpleScreenshots:
    def __init__(self, app_url="https://christopher-m-castille.shinyapps.io/correlation-learning-app/"):
        self.app_url = app_url
        self.screenshot_dir = "screenshots"
        self.driver = None
        
        # Create screenshots directory if it doesn't exist
        if not os.path.exists(self.screenshot_dir):
            os.makedirs(self.screenshot_dir)
    
    def setup_driver(self):
        """Set up Chrome driver with appropriate options for screenshots."""
        chrome_options = Options()
        chrome_options.add_argument("--headless")  # Run in headless mode
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--window-size=1920,1080")  # High resolution
        chrome_options.add_argument("--disable-gpu")
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.driver.set_window_size(1920, 1080)
        
    def take_screenshot(self, filename, description=""):
        """Take a screenshot and save it with description."""
        filepath = os.path.join(self.screenshot_dir, filename)
        self.driver.save_screenshot(filepath)
        print(f"✓ Screenshot saved: {filename} - {description}")
        return filepath
    
    def screenshot_main_interface(self):
        """Take screenshot of the main interface."""
        print("\n=== Taking Screenshot: Main Interface ===")
        self.driver.get(self.app_url)
        time.sleep(10)  # Wait for app to load
        
        # Handle consent if needed
        try:
            consent_yes = self.driver.find_element(By.ID, "consent_yes")
            consent_yes.click()
            time.sleep(3)
            print("Consent given")
        except:
            print("No consent modal found")
        
        self.take_screenshot("main_interface.png", "Main app interface")
    
    def screenshot_with_correlation(self, correlation_value, filename, description):
        """Take screenshot with a specific correlation value."""
        print(f"\n=== Taking Screenshot: {description} ===")
        
        # Set correlation value
        try:
            slider = self.driver.find_element(By.ID, "user_correlation")
            self.driver.execute_script(f"arguments[0].value = '{correlation_value}';", slider)
            time.sleep(1)
            
            # Generate plot
            generate_btn = self.driver.find_element(By.ID, "generate_plot")
            generate_btn.click()
            time.sleep(5)  # Wait for plot to generate
            
            # Submit guess
            submit_btn = self.driver.find_element(By.ID, "submit_guess")
            submit_btn.click()
            time.sleep(3)  # Wait for feedback
            
            self.take_screenshot(filename, description)
            
        except Exception as e:
            print(f"Error taking screenshot: {e}")
            # Take screenshot anyway
            self.take_screenshot(filename, f"{description} (error occurred)")
    
    def run_screenshots(self):
        """Run all screenshot functions."""
        try:
            self.setup_driver()
            print("Starting simplified screenshots...")
            print(f"App URL: {self.app_url}")
            print(f"Screenshots will be saved to: {self.screenshot_dir}/")
            
            # Take main interface screenshot
            self.screenshot_main_interface()
            
            # Take screenshots with different correlation values
            self.screenshot_with_correlation(0.65, "phase1_height_weight.png", "Phase 1: Height vs Weight example")
            self.screenshot_with_correlation(0.30, "phase2_medical_example.png", "Phase 2: Medical intervention example")
            self.screenshot_with_correlation(0.40, "phase3_business_example.png", "Phase 3: Business psychology example")
            self.screenshot_with_correlation(0.70, "trend_line_example.png", "Trend line visualization")
            self.screenshot_with_correlation(0.67, "feedback_scoring.png", "Feedback and scoring system")
            
            # Take screenshot of BESD section if available
            try:
                besd_section = self.driver.find_element(By.ID, "besd_section")
                self.driver.execute_script("arguments[0].scrollIntoView();", besd_section)
                time.sleep(2)
                self.take_screenshot("besd_visualization.png", "BESD visualization")
            except:
                print("BESD section not found")
            
            # Take screenshot of hover information
            try:
                plot_area = self.driver.find_element(By.ID, "scatter_plot")
                self.driver.execute_script("arguments[0].scrollIntoView();", plot_area)
                time.sleep(2)
                self.take_screenshot("hover_information.png", "Interactive hover information")
            except:
                print("Plot area not found")
            
            print(f"\n✅ All screenshots completed! Check the '{self.screenshot_dir}/' directory.")
            
        except Exception as e:
            print(f"❌ Error during screenshot process: {e}")
            import traceback
            traceback.print_exc()
        finally:
            if self.driver:
                self.driver.quit()

if __name__ == "__main__":
    try:
        screenshotter = SimpleScreenshots()
        screenshotter.run_screenshots()
    except Exception as e:
        print(f"❌ Setup error: {e}")
        print("\nTo install required dependencies:")
        print("pip install selenium") 