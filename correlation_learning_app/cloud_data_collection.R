# Cloud Data Collection for Correlation Learning App
# This uses Google Sheets for data storage (works with Shinyapps.io)

library(googlesheets4)
library(dplyr)

# Function to save data to Google Sheets
save_to_cloud <- function(session_id, question_data, consent_given = TRUE) {
  tryCatch({
    # Google Sheets URL (you'll need to create this)
    sheet_url <- "YOUR_GOOGLE_SHEET_URL_HERE"
    
    # Prepare data row
    data_row <- data.frame(
      timestamp = Sys.time(),
      session_id = session_id,
      consent_given = consent_given,
      question_number = question_data$question_number,
      phase = question_data$phase,
      variable1 = question_data$variable1,
      variable2 = question_data$variable2,
      user_guess = question_data$user_guess,
      correct_answer = question_data$correct_answer,
      error = question_data$error
    )
    
    # Append to Google Sheet
    sheet_append(sheet_url, data_row)
    
    cat("Data saved to cloud successfully\n")
  }, error = function(e) {
    cat("Cloud save error:", e$message, "\n")
  })
}

# Function to read all data from Google Sheets
get_cloud_data <- function() {
  tryCatch({
    sheet_url <- "YOUR_GOOGLE_SHEET_URL_HERE"
    data <- read_sheet(sheet_url)
    return(data)
  }, error = function(e) {
    cat("Cloud read error:", e$message, "\n")
    return(data.frame())
  })
}

# Setup instructions
cat("=== CLOUD DATA COLLECTION SETUP ===\n\n")
cat("1. Create a Google Sheet:\n")
cat("   - Go to sheets.google.com\n")
cat("   - Create a new sheet\n")
cat("   - Share it with 'Anyone with link can edit'\n")
cat("   - Copy the URL\n\n")
cat("2. Update the sheet_url in this file\n")
cat("3. Install googlesheets4 package:\n")
cat("   install.packages('googlesheets4')\n\n")
cat("4. Authenticate with Google:\n")
cat("   gs4_auth()\n\n") 