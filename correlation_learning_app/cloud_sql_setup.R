# Cloud SQL Setup for Shinyapps.io
# This uses Dropbox to store the SQLite database in the cloud

library(RSQLite)
library(DBI)
library(rdrop2)

# ============================================================================
# SETUP DROPBOX INTEGRATION
# ============================================================================

setup_dropbox_integration <- function() {
  cat("=== CLOUD SQL SETUP WITH DROPBOX ===\n\n")
  
  # Install rdrop2 if not already installed
  if (!require("rdrop2")) {
    install.packages("rdrop2")
  }
  
  cat("1. First time setup:\n")
  cat("   - Run: drop_auth()\n")
  cat("   - This will open your browser\n")
  cat("   - Authorize the app to access your Dropbox\n\n")
  
  cat("2. Create a folder in Dropbox:\n")
  cat("   - Go to dropbox.com\n")
  cat("   - Create a folder called 'correlation_app_data'\n")
  cat("   - Note the path (e.g., '/correlation_app_data')\n\n")
  
  cat("3. Upload your database:\n")
  cat("   - The database file will be uploaded automatically\n")
  cat("   - It will sync between your app and local access\n\n")
}

# ============================================================================
# CLOUD DATABASE FUNCTIONS
# ============================================================================

# Function to get database from Dropbox
get_cloud_database <- function(dropbox_path = "/correlation_app_data/correlation_app_data.db") {
  tryCatch({
    # Download database from Dropbox
    drop_download(dropbox_path, local_path = "temp_db.db", overwrite = TRUE)
    
    # Connect to the downloaded database
    con <- dbConnect(SQLite(), "temp_db.db")
    
    cat("✓ Downloaded database from Dropbox\n")
    return(con)
  }, error = function(e) {
    cat("Error downloading database:", e$message, "\n")
    cat("Creating new local database...\n")
    
    # Create new database if download fails
    con <- dbConnect(SQLite(), "correlation_app_data.db")
    return(con)
  })
}

# Function to save database to Dropbox
save_cloud_database <- function(con, dropbox_path = "/correlation_app_data/correlation_app_data.db") {
  tryCatch({
    # Disconnect from database
    dbDisconnect(con)
    
    # Upload to Dropbox
    drop_upload("temp_db.db", path = dirname(dropbox_path), mode = "overwrite")
    
    cat("✓ Uploaded database to Dropbox\n")
  }, error = function(e) {
    cat("Error uploading to Dropbox:", e$message, "\n")
    cat("Database saved locally only\n")
  })
}

# Function to save data to cloud database
save_to_cloud_db <- function(session_id, question_data, consent_given = TRUE) {
  tryCatch({
    # Get database from cloud
    con <- get_cloud_database()
    
    # Save session if it doesn't exist
    session_exists <- dbGetQuery(con, "SELECT COUNT(*) as count FROM users WHERE session_id = ?", list(session_id))
    if (session_exists$count == 0) {
      dbExecute(con, "INSERT INTO users (session_id, consent_given) VALUES (?, ?)", 
               list(session_id, consent_given))
    }
    
    # Save guess data
    dbExecute(con, "
      INSERT INTO guesses 
      (session_id, question_number, phase, variable1, variable2, user_guess, correct_answer, error)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ", list(
      session_id,
      question_data$question_number,
      question_data$phase,
      question_data$variable1,
      question_data$variable2,
      question_data$user_guess,
      question_data$correct_answer,
      question_data$error
    ))
    
    # Save back to cloud
    save_cloud_database(con)
    
    cat("✓ Data saved to cloud database\n")
  }, error = function(e) {
    cat("Cloud database error:", e$message, "\n")
  })
}

# ============================================================================
# SQL LEARNING FUNCTIONS
# ============================================================================

# Function to practice SQL queries on your data
practice_sql_queries <- function() {
  cat("\n=== SQL PRACTICE WITH YOUR DATA ===\n\n")
  
  # Get database from cloud
  con <- get_cloud_database()
  
  cat("Try these SQL queries on your data:\n\n")
  
  # Query 1: Basic counting
  cat("1. Count total users:\n")
  cat("   SELECT COUNT(*) FROM users;\n")
  result <- dbGetQuery(con, "SELECT COUNT(*) as total_users FROM users")
  print(result)
  cat("\n")
  
  # Query 2: Average performance
  cat("2. Average accuracy:\n")
  cat("   SELECT AVG(accuracy_percentage) FROM users WHERE consent_given = 1;\n")
  result <- dbGetQuery(con, "SELECT AVG(accuracy_percentage) as avg_accuracy FROM users WHERE consent_given = 1")
  print(result)
  cat("\n")
  
  # Query 3: Performance by phase
  cat("3. Performance by learning phase:\n")
  cat("   SELECT phase, AVG(error) FROM guesses GROUP BY phase;\n")
  result <- dbGetQuery(con, "SELECT phase, AVG(error) as avg_error FROM guesses GROUP BY phase")
  print(result)
  cat("\n")
  
  # Query 4: Learning progression
  cat("4. Learning progression (error over questions):\n")
  cat("   SELECT question_number, AVG(error) FROM guesses GROUP BY question_number ORDER BY question_number;\n")
  result <- dbGetQuery(con, "SELECT question_number, AVG(error) as avg_error FROM guesses GROUP BY question_number ORDER BY question_number")
  print(result)
  cat("\n")
  
  # Query 5: Top performers
  cat("5. Top 5 performers:\n")
  cat("   SELECT session_id, accuracy_percentage FROM users ORDER BY accuracy_percentage DESC LIMIT 5;\n")
  result <- dbGetQuery(con, "SELECT session_id, accuracy_percentage FROM users ORDER BY accuracy_percentage DESC LIMIT 5")
  print(result)
  cat("\n")
  
  dbDisconnect(con)
  
  cat("=== CREATE YOUR OWN QUERIES ===\n")
  cat("Now try writing your own SQL queries!\n")
  cat("Examples:\n")
  cat("- Find users who improved over time\n")
  cat("- Compare performance between phases\n")
  cat("- Find the most challenging questions\n")
  cat("- Analyze learning patterns\n")
}

# ============================================================================
# MAIN SETUP
# ============================================================================

cat("=== CLOUD SQL SETUP FOR CORRELATION LEARNING APP ===\n\n")

# Setup instructions
setup_dropbox_integration()

cat("=== NEXT STEPS ===\n")
cat("1. Run: drop_auth() to authenticate with Dropbox\n")
cat("2. Create the Dropbox folder\n")
cat("3. Run: practice_sql_queries() to analyze your data\n")
cat("4. Modify your app to use save_to_cloud_db()\n\n")

cat("=== SQL LEARNING TIPS ===\n")
cat("- Start with simple SELECT queries\n")
cat("- Use WHERE to filter data\n")
cat("- Use GROUP BY to aggregate data\n")
cat("- Use ORDER BY to sort results\n")
cat("- Practice with your real data!\n\n")

cat("=== USEFUL SQL COMMANDS ===\n")
cat("SELECT * FROM users;                    -- See all users\n")
cat("SELECT * FROM guesses LIMIT 10;         -- See first 10 guesses\n")
cat("SELECT DISTINCT phase FROM guesses;     -- See all phases\n")
cat("SELECT COUNT(*) FROM guesses;           -- Count total guesses\n")
cat("SELECT AVG(error) FROM guesses;         -- Average error\n") 