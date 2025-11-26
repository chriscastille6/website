# Complete Setup for Correlation Learning App with Database
# Run this script to set up everything

cat("=== CORRELATION LEARNING APP - COMPLETE SETUP ===\n\n")

# Install required packages
cat("Installing required packages...\n")
packages <- c("shiny", "plotly", "ggplot2", "RSQLite", "DBI", "dplyr", "DT")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    cat("Installed:", pkg, "\n")
  } else {
    cat("Package already installed:", pkg, "\n")
  }
}

# Load libraries
library(RSQLite)
library(DBI)

# Create database
cat("\nSetting up database...\n")
db_path <- "correlation_app_data.db"
con <- dbConnect(SQLite(), db_path)

# Create tables
dbExecute(con, "
CREATE TABLE IF NOT EXISTS user_sessions (
  session_id TEXT PRIMARY KEY,
  start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  end_time TIMESTAMP,
  consent_given BOOLEAN DEFAULT 0,
  total_questions INTEGER DEFAULT 0,
  accuracy_percentage REAL DEFAULT 0,
  avg_error REAL DEFAULT 0
)
")

dbExecute(con, "
CREATE TABLE IF NOT EXISTS user_guesses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT,
  question_number INTEGER,
  phase TEXT,
  variable1 TEXT,
  variable2 TEXT,
  user_guess REAL,
  correct_answer REAL,
  error REAL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES user_sessions(session_id)
)
")

# Create indexes
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_session_id ON user_guesses(session_id)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_timestamp ON user_guesses(timestamp)")

dbDisconnect(con)

cat("Database setup complete!\n")
cat("Database file:", db_path, "\n\n")

# Instructions
cat("=== SETUP COMPLETE ===\n\n")
cat("Your correlation learning app now has automatic data collection!\n\n")
cat("TO RUN THE MAIN APP:\n")
cat("1. Deploy to Shinyapps.io:\n")
cat("   source('deploy_app.R')\n\n")
cat("2. Or run locally:\n")
cat("   shiny::runApp()\n\n")
cat("TO ACCESS USER DATA:\n")
cat("1. Run the admin dashboard:\n")
cat("   shiny::runApp('admin_dashboard.R')\n\n")
cat("2. Or download data directly:\n")
cat("   source('download_data.R')\n\n")
cat("WHAT HAPPENS NOW:\n")
cat("- Every user who consents will have their data saved\n")
cat("- You can view all data in the admin dashboard\n")
cat("- Data is automatically saved to correlation_app_data.db\n")
cat("- You can download CSV files anytime\n\n")
cat("Database file location:", normalizePath(db_path), "\n") 