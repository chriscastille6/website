# SQL Learning Setup for Correlation Learning App
# This teaches you SQL while making data collection work with Shinyapps.io

library(RSQLite)
library(DBI)
library(rdrop2)  # For Dropbox integration

# ============================================================================
# STEP 1: SETUP CLOUD DATABASE
# ============================================================================

setup_cloud_database <- function() {
  cat("=== SQL LEARNING: CLOUD DATABASE SETUP ===\n\n")
  
  # Create local database first
  db_path <- "correlation_app_data.db"
  con <- dbConnect(SQLite(), db_path)
  
  # Create tables with SQL (this is where you learn!)
  cat("Creating tables with SQL...\n")
  
  # Users table - stores information about each user session
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS users (
      session_id TEXT PRIMARY KEY,
      start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      consent_given BOOLEAN DEFAULT 0,
      total_questions INTEGER DEFAULT 0,
      accuracy_percentage REAL DEFAULT 0,
      avg_error REAL DEFAULT 0
    )
  ")
  cat("✓ Created 'users' table\n")
  
  # Guesses table - stores each correlation guess
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS guesses (
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
      FOREIGN KEY (session_id) REFERENCES users(session_id)
    )
  ")
  cat("✓ Created 'guesses' table\n")
  
  # Learning_progress table - tracks improvement over time
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS learning_progress (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id TEXT,
      phase TEXT,
      questions_attempted INTEGER,
      avg_error REAL,
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (session_id) REFERENCES users(session_id)
    )
  ")
  cat("✓ Created 'learning_progress' table\n")
  
  # Create indexes for better performance
  dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_session_id ON guesses(session_id)")
  dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_phase ON guesses(phase)")
  dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_timestamp ON guesses(timestamp)")
  cat("✓ Created indexes for better performance\n")
  
  dbDisconnect(con)
  
  cat("\n=== SQL CONCEPTS LEARNED ===\n")
  cat("1. CREATE TABLE - Making new tables\n")
  cat("2. PRIMARY KEY - Unique identifiers\n")
  cat("3. FOREIGN KEY - Relationships between tables\n")
  cat("4. INDEX - Making queries faster\n")
  cat("5. DATA TYPES - TEXT, INTEGER, REAL, BOOLEAN, TIMESTAMP\n\n")
  
  return(db_path)
}

# ============================================================================
# STEP 2: SQL QUERIES FOR DATA ANALYSIS
# ============================================================================

# Function to get user statistics
get_user_stats <- function(con) {
  cat("\n=== SQL QUERY: User Statistics ===\n")
  
  # This SQL query counts total users and calculates averages
  query <- "
    SELECT 
      COUNT(*) as total_users,
      AVG(accuracy_percentage) as avg_accuracy,
      AVG(avg_error) as avg_error,
      SUM(total_questions) as total_questions
    FROM users
    WHERE consent_given = 1
  "
  
  result <- dbGetQuery(con, query)
  print(result)
  
  cat("\nSQL CONCEPTS:\n")
  cat("- SELECT: Choosing columns to display\n")
  cat("- COUNT(): Counting rows\n")
  cat("- AVG(): Calculating averages\n")
  cat("- SUM(): Adding up values\n")
  cat("- WHERE: Filtering data\n")
  
  return(result)
}

# Function to get performance by phase
get_phase_performance <- function(con) {
  cat("\n=== SQL QUERY: Performance by Phase ===\n")
  
  # This SQL query groups data by phase and calculates statistics
  query <- "
    SELECT 
      phase,
      COUNT(*) as total_guesses,
      AVG(error) as avg_error,
      AVG(user_guess) as avg_user_guess,
      AVG(correct_answer) as avg_correct_answer
    FROM guesses
    GROUP BY phase
    ORDER BY avg_error DESC
  "
  
  result <- dbGetQuery(con, query)
  print(result)
  
  cat("\nSQL CONCEPTS:\n")
  cat("- GROUP BY: Grouping data by categories\n")
  cat("- ORDER BY: Sorting results\n")
  cat("- DESC: Descending order\n")
  
  return(result)
}

# Function to get learning progression
get_learning_progression <- function(con) {
  cat("\n=== SQL QUERY: Learning Progression ===\n")
  
  # This SQL query shows how error changes over questions
  query <- "
    SELECT 
      question_number,
      AVG(error) as avg_error,
      COUNT(*) as attempts
    FROM guesses
    GROUP BY question_number
    ORDER BY question_number
  "
  
  result <- dbGetQuery(con, query)
  print(result)
  
  cat("\nSQL CONCEPTS:\n")
  cat("- Multiple aggregations in one query\n")
  cat("- Time-based analysis\n")
  
  return(result)
}

# ============================================================================
# STEP 3: ADVANCED SQL QUERIES
# ============================================================================

# Function to find best performing users
get_top_performers <- function(con, limit = 5) {
  cat("\n=== SQL QUERY: Top Performers ===\n")
  
  query <- "
    SELECT 
      session_id,
      accuracy_percentage,
      avg_error,
      total_questions
    FROM users
    WHERE consent_given = 1
    ORDER BY accuracy_percentage DESC, avg_error ASC
    LIMIT ?
  "
  
  result <- dbGetQuery(con, query, list(limit))
  print(result)
  
  cat("\nSQL CONCEPTS:\n")
  cat("- LIMIT: Restricting number of results\n")
  cat("- Multiple ORDER BY criteria\n")
  cat("- Parameterized queries (?) for security\n")
  
  return(result)
}

# Function to analyze phase transitions
get_phase_transitions <- function(con) {
  cat("\n=== SQL QUERY: Phase Transition Analysis ===\n")
  
  query <- "
    SELECT 
      g1.phase as from_phase,
      g2.phase as to_phase,
      AVG(g2.error - g1.error) as error_change,
      COUNT(*) as transitions
    FROM guesses g1
    JOIN guesses g2 ON g1.session_id = g2.session_id 
      AND g1.question_number + 1 = g2.question_number
    WHERE g1.phase != g2.phase
    GROUP BY g1.phase, g2.phase
    ORDER BY error_change DESC
  "
  
  result <- dbGetQuery(con, query)
  print(result)
  
  cat("\nSQL CONCEPTS:\n")
  cat("- JOIN: Combining data from multiple tables\n")
  cat("- Self-join: Comparing rows within same table\n")
  cat("- Complex WHERE conditions\n")
  
  return(result)
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

cat("=== SQL LEARNING FOR CORRELATION LEARNING APP ===\n\n")

# Setup database
db_path <- setup_cloud_database()

# Connect to database
con <- dbConnect(SQLite(), db_path)

# Run example queries (will show "no data" until you have data)
cat("\n=== RUNNING EXAMPLE QUERIES ===\n")
get_user_stats(con)
get_phase_performance(con)
get_learning_progression(con)
get_top_performers(con)
get_phase_transitions(con)

# Disconnect
dbDisconnect(con)

cat("\n=== NEXT STEPS ===\n")
cat("1. Set up cloud storage (Dropbox/Google Drive)\n")
cat("2. Modify your app to use this database\n")
cat("3. Practice these SQL queries with real data\n")
cat("4. Create your own custom queries!\n\n")

cat("=== SQL LEARNING RESOURCES ===\n")
cat("- SQLite Tutorial: https://www.sqlitetutorial.net/\n")
cat("- W3Schools SQL: https://www.w3schools.com/sql/\n")
cat("- Practice with your own data!\n") 