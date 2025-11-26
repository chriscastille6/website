# Simple Database Setup for Correlation Learning App
# Run this in R to set up the database

# Install and load required packages
if (!require("RSQLite")) install.packages("RSQLite")
if (!require("DBI")) install.packages("DBI")

library(RSQLite)
library(DBI)

# Create database
db_path <- "correlation_app_data.db"
con <- dbConnect(SQLite(), db_path)

# Create tables
cat("Creating database tables...\n")

# User sessions table
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

# User guesses table
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

cat("Database setup complete!\n")
cat("Database file:", db_path, "\n")
cat("Tables created: user_sessions, user_guesses\n")

dbDisconnect(con) 