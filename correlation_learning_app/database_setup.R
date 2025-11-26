# Database Setup for Correlation Learning App
# This script sets up a SQLite database to store user data

# Install required packages
if (!require("RSQLite")) install.packages("RSQLite")
if (!require("DBI")) install.packages("DBI")

library(RSQLite)
library(DBI)

# Create database connection
db_path <- "correlation_app_data.db"
con <- dbConnect(SQLite(), db_path)

# Create tables
dbExecute(con, "
CREATE TABLE IF NOT EXISTS user_sessions (
  session_id TEXT PRIMARY KEY,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  consent_given BOOLEAN,
  total_questions INTEGER,
  accuracy_percentage REAL,
  avg_error REAL,
  ip_address TEXT,
  user_agent TEXT
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
  timestamp TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES user_sessions(session_id)
)
")

dbExecute(con, "
CREATE TABLE IF NOT EXISTS app_usage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT,
  action TEXT,
  timestamp TIMESTAMP,
  details TEXT,
  FOREIGN KEY (session_id) REFERENCES user_sessions(session_id)
)
")

# Create indexes for better performance
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_session_id ON user_guesses(session_id)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_timestamp ON user_guesses(timestamp)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_phase ON user_guesses(phase)")

# Create admin view for easy data access
dbExecute(con, "
CREATE VIEW IF NOT EXISTS session_summary AS
SELECT 
  us.session_id,
  us.start_time,
  us.end_time,
  us.consent_given,
  us.total_questions,
  us.accuracy_percentage,
  us.avg_error,
  COUNT(ug.id) as guesses_made,
  AVG(ug.error) as avg_guess_error
FROM user_sessions us
LEFT JOIN user_guesses ug ON us.session_id = ug.session_id
GROUP BY us.session_id
")

# Test the setup
cat("Database setup complete!\n")
cat("Database file:", db_path, "\n")
cat("Tables created: user_sessions, user_guesses, app_usage\n")
cat("View created: session_summary\n")

# Show table structure
cat("\nTable structure:\n")
cat("user_sessions: session tracking\n")
cat("user_guesses: individual correlation guesses\n")
cat("app_usage: detailed usage analytics\n")

dbDisconnect(con) 