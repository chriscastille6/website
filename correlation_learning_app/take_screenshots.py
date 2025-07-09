#!/usr/bin/env python3
"""
Automated Screenshot Script for Correlation Learning App
Takes screenshots according to the screenshot guide for the blog post.
"""

import os
import time
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains

class CorrelationAppScreenshots:
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
        chrome_options.add_argument("--remote-debugging-port=9222")
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.driver.set_window_size(1920, 1080)
        
    def take_screenshot(self, filename, description=""):
        """Take a screenshot and save it with description."""
        filepath = os.path.join(self.screenshot_dir, filename)
        self.driver.save_screenshot(filepath)
        print(f"✓ Screenshot saved: {filename} - {description}")
        return filepath
    
    def wait_for_element(self, by, value, timeout=10):
        """Wait for an element to be present and visible."""
        return WebDriverWait(self.driver, timeout).until(
            EC.presence_of_element_located((by, value))
        )
    
    def wait_for_app_load(self):
        """Wait for the app to fully load."""
        print("Waiting for app to load...")
        time.sleep(5)  # Initial load time
        self.wait_for_element(By.ID, "user_correlation", timeout=30)
        print("App loaded successfully!")
    
    def handle_consent(self):
        """Handle the consent modal if it appears."""
        try:
            consent_yes = self.driver.find_element(By.ID, "consent_yes")
            consent_yes.click()
            time.sleep(2)
            print("Consent given")
        except:
            print("No consent modal found or already handled")
    
    def screenshot_1_main_interface(self):
        """Screenshot 1: App Main Interface"""
        print("\n=== Taking Screenshot 1: Main Interface ===")
        self.driver.get(self.app_url)
        self.wait_for_app_load()
        
        # Handle consent if needed
        self.handle_consent()
        
        # Wait for the main interface elements
        self.wait_for_element(By.TAG_NAME, "h1")
        self.wait_for_element(By.ID, "user_correlation")
        
        time.sleep(2)  # Let animations settle
        self.take_screenshot("main_interface.png", "Main app interface showing title and controls")
    
    def screenshot_2_phase1_intuitive(self):
        """Screenshot 2: Phase 1 - Intuitive Examples"""
        print("\n=== Taking Screenshot 2: Phase 1 - Intuitive Examples ===")
        
        # Set correlation guess using the correct slider ID
        slider = self.wait_for_element(By.ID, "user_correlation")
        self.driver.execute_script("arguments[0].value = '0.65';", slider)
        
        # Generate plot
        generate_btn = self.wait_for_element(By.ID, "generate_plot")
        generate_btn.click()
        time.sleep(3)  # Wait for plot to generate
        
        # Submit guess
        submit_btn = self.wait_for_element(By.ID, "submit_guess")
        submit_btn.click()
        time.sleep(2)  # Wait for feedback
        
        self.take_screenshot("phase1_height_weight.png", "Phase 1: Height vs Weight correlation example")
    
    def screenshot_3_phase2_medical(self):
        """Screenshot 3: Phase 2 - Medical Interventions"""
        print("\n=== Taking Screenshot 3: Phase 2 - Medical Interventions ===")
        
        # Set correlation guess (students typically overestimate)
        slider = self.wait_for_element(By.ID, "user_correlation")
        self.driver.execute_script("arguments[0].value = '0.30';", slider)
        
        # Generate plot
        generate_btn = self.wait_for_element(By.ID, "generate_plot")
        generate_btn.click()
        time.sleep(3)
        
        # Submit guess
        submit_btn = self.wait_for_element(By.ID, "submit_guess")
        submit_btn.click()
        time.sleep(2)
        
        self.take_screenshot("phase2_medical_example.png", "Phase 2: Medical intervention example with small correlation")
    
    def screenshot_4_phase3_business(self):
        """Screenshot 4: Phase 3 - Business & Organizational Psychology"""
        print("\n=== Taking Screenshot 4: Phase 3 - Business & Organizational Psychology ===")
        
        # Set correlation guess
        slider = self.wait_for_element(By.ID, "user_correlation")
        self.driver.execute_script("arguments[0].value = '0.40';", slider)
        
        # Generate plot
        generate_btn = self.wait_for_element(By.ID, "generate_plot")
        generate_btn.click()
        time.sleep(3)
        
        # Submit guess
        submit_btn = self.wait_for_element(By.ID, "submit_guess")
        submit_btn.click()
        time.sleep(2)
        
        self.take_screenshot("phase3_business_example.png", "Phase 3: Business psychology example")
    
    def screenshot_5_besd_visualization(self):
        """Screenshot 5: BESD Visualization"""
        print("\n=== Taking Screenshot 5: BESD Visualization ===")
        
        # Make sure we have a plot with feedback
        if not self.driver.find_elements(By.ID, "feedback_text"):
            # Generate a plot first
            slider = self.wait_for_element(By.ID, "user_correlation")
            self.driver.execute_script("arguments[0].value = '0.50';", slider)
            generate_btn = self.wait_for_element(By.ID, "generate_plot")
            generate_btn.click()
            time.sleep(3)
            submit_btn = self.wait_for_element(By.ID, "submit_guess")
            submit_btn.click()
            time.sleep(2)
        
        # Look for BESD section
        try:
            besd_section = self.driver.find_element(By.ID, "besd_section")
            # Scroll to BESD section
            self.driver.execute_script("arguments[0].scrollIntoView();", besd_section)
            time.sleep(2)
        except:
            print("BESD section not found, taking screenshot of current view")
        
        self.take_screenshot("besd_visualization.png", "BESD (Binomial Effect Size Display) visualization")
    
    def screenshot_6_trend_lines(self):
        """Screenshot 6: Trend Line Visualization"""
        print("\n=== Taking Screenshot 6: Trend Line Visualization ===")
        
        # Check the "Show trend line" option
        try:
            trend_checkbox = self.driver.find_element(By.ID, "show_trendline")
            if not trend_checkbox.is_selected():
                trend_checkbox.click()
                time.sleep(1)
        except:
            print("Trend line checkbox not found")
        
        # Generate a new plot with trend lines
        slider = self.wait_for_element(By.ID, "user_correlation")
        self.driver.execute_script("arguments[0].value = '0.70';", slider)
        generate_btn = self.wait_for_element(By.ID, "generate_plot")
        generate_btn.click()
        time.sleep(3)
        
        submit_btn = self.wait_for_element(By.ID, "submit_guess")
        submit_btn.click()
        time.sleep(2)
        
        self.take_screenshot("trend_line_example.png", "Trend line visualization showing prediction vs true correlation")
    
    def screenshot_7_hover_information(self):
        """Screenshot 7: Hover Information"""
        print("\n=== Taking Screenshot 7: Hover Information ===")
        
        # Generate a plot first
        slider = self.wait_for_element(By.ID, "user_correlation")
        self.driver.execute_script("arguments[0].value = '0.60';", slider)
        generate_btn = self.wait_for_element(By.ID, "generate_plot")
        generate_btn.click()
        time.sleep(3)
        
        # Try to hover over a data point
        try:
            plot_area = self.driver.find_element(By.ID, "scatter_plot")
            actions = ActionChains(self.driver)
            actions.move_to_element(plot_area).perform()
            time.sleep(1)
        except:
            print("Could not simulate hover, taking screenshot of plot area")
        
        self.take_screenshot("hover_information.png", "Interactive hover information on data points")
    
    def screenshot_8_feedback_scoring(self):
        """Screenshot 8: Feedback and Scoring"""
        print("\n=== Taking Screenshot 8: Feedback and Scoring ===")
        
        # Make a very accurate guess to show "Correct!" feedback
        slider = self.wait_for_element(By.ID, "user_correlation")
        self.driver.execute_script("arguments[0].value = '0.67';", slider)  # Close to height/weight correlation
        
        generate_btn = self.wait_for_element(By.ID, "generate_plot")
        generate_btn.click()
        time.sleep(3)
        
        submit_btn = self.wait_for_element(By.ID, "submit_guess")
        submit_btn.click()
        time.sleep(2)
        
        self.take_screenshot("feedback_scoring.png", "Feedback and scoring system showing accuracy")
    
    def run_all_screenshots(self):
        """Run all screenshot functions in sequence."""
        try:
            self.setup_driver()
            print("Starting automated screenshots...")
            print(f"App URL: {self.app_url}")
            print(f"Screenshots will be saved to: {self.screenshot_dir}/")
            
            self.screenshot_1_main_interface()
            self.screenshot_2_phase1_intuitive()
            self.screenshot_3_phase2_medical()
            self.screenshot_4_phase3_business()
            self.screenshot_5_besd_visualization()
            self.screenshot_6_trend_lines()
            self.screenshot_7_hover_information()
            self.screenshot_8_feedback_scoring()
            
            print(f"\n✅ All screenshots completed! Check the '{self.screenshot_dir}/' directory.")
            
        except Exception as e:
            print(f"❌ Error during screenshot process: {e}")
            import traceback
            traceback.print_exc()
        finally:
            if self.driver:
                self.driver.quit()

if __name__ == "__main__":
    # Check if Chrome driver is available
    try:
        screenshotter = CorrelationAppScreenshots()
        screenshotter.run_all_screenshots()
    except Exception as e:
        print(f"❌ Setup error: {e}")
        print("\nTo install required dependencies:")
        print("pip install selenium requests")
        print("\nYou may also need to install ChromeDriver:")
        print("brew install chromedriver  # on macOS")
        print("Or download from: https://chromedriver.chromium.org/") 