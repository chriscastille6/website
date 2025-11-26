#!/usr/bin/env python3
"""
Debug version of the screenshot script to inspect app structure
"""

import os
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options

class AppInspector:
    def __init__(self, app_url="https://christopher-m-castille.shinyapps.io/correlation-learning-app/"):
        self.app_url = app_url
        self.driver = None
        
    def setup_driver(self):
        """Set up Chrome driver in non-headless mode for debugging."""
        chrome_options = Options()
        # chrome_options.add_argument("--headless")  # Commented out for debugging
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--disable-gpu")
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.driver.set_window_size(1920, 1080)
        
    def inspect_app(self):
        """Inspect the app structure to find element IDs and structure."""
        try:
            self.setup_driver()
            print("Loading app for inspection...")
            self.driver.get(self.app_url)
            
            # Wait for page to load
            time.sleep(10)
            
            print("\n=== APP INSPECTION RESULTS ===")
            print(f"Page title: {self.driver.title}")
            print(f"Current URL: {self.driver.current_url}")
            
            # Find all input elements
            print("\n--- INPUT ELEMENTS ---")
            inputs = self.driver.find_elements(By.TAG_NAME, "input")
            for i, inp in enumerate(inputs):
                print(f"Input {i+1}: type={inp.get_attribute('type')}, id={inp.get_attribute('id')}, name={inp.get_attribute('name')}, class={inp.get_attribute('class')}")
            
            # Find all button elements
            print("\n--- BUTTON ELEMENTS ---")
            buttons = self.driver.find_elements(By.TAG_NAME, "button")
            for i, btn in enumerate(buttons):
                print(f"Button {i+1}: text='{btn.text}', id={btn.get_attribute('id')}, class={btn.get_attribute('class')}")
            
            # Find all div elements with IDs
            print("\n--- DIV ELEMENTS WITH IDS ---")
            divs_with_ids = self.driver.find_elements(By.XPATH, "//div[@id]")
            for i, div in enumerate(divs_with_ids[:20]):  # Limit to first 20
                print(f"Div {i+1}: id={div.get_attribute('id')}, class={div.get_attribute('class')}")
            
            # Find all elements with 'correlation' in ID or class
            print("\n--- CORRELATION-RELATED ELEMENTS ---")
            correlation_elements = self.driver.find_elements(By.XPATH, "//*[contains(@id, 'correlation') or contains(@class, 'correlation')]")
            for i, elem in enumerate(correlation_elements):
                print(f"Correlation element {i+1}: tag={elem.tag_name}, id={elem.get_attribute('id')}, class={elem.get_attribute('class')}")
            
            # Find all elements with 'slider' in ID or class
            print("\n--- SLIDER-RELATED ELEMENTS ---")
            slider_elements = self.driver.find_elements(By.XPATH, "//*[contains(@id, 'slider') or contains(@class, 'slider')]")
            for i, elem in enumerate(slider_elements):
                print(f"Slider element {i+1}: tag={elem.tag_name}, id={elem.get_attribute('id')}, class={elem.get_attribute('class')}")
            
            # Find all elements with 'plot' in ID or class
            print("\n--- PLOT-RELATED ELEMENTS ---")
            plot_elements = self.driver.find_elements(By.XPATH, "//*[contains(@id, 'plot') or contains(@class, 'plot')]")
            for i, elem in enumerate(plot_elements):
                print(f"Plot element {i+1}: tag={elem.tag_name}, id={elem.get_attribute('id')}, class={elem.get_attribute('class')}")
            
            # Take a screenshot of the current state
            if not os.path.exists("debug"):
                os.makedirs("debug")
            self.driver.save_screenshot("debug/app_loaded.png")
            print("\nScreenshot saved to: debug/app_loaded.png")
            
            # Get page source for further inspection
            with open("debug/page_source.html", "w", encoding="utf-8") as f:
                f.write(self.driver.page_source)
            print("Page source saved to: debug/page_source.html")
            
            print("\n=== INSPECTION COMPLETE ===")
            print("Check the debug/ directory for screenshots and page source.")
            print("Press Enter to close the browser...")
            input()
            
        except Exception as e:
            print(f"❌ Error during inspection: {e}")
            import traceback
            traceback.print_exc()
        finally:
            if self.driver:
                self.driver.quit()

if __name__ == "__main__":
    inspector = AppInspector()
    inspector.inspect_app() 