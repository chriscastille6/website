# Data Download Script for Correlation Learning App
# Use this script to download and analyze user data

library(RSQLite)
library(DBI)
library(dplyr)
library(ggplot2)

# Connect to database
db_path <- "correlation_app_data.db"
con <- dbConnect(SQLite(), db_path)

# Function to download all data
download_all_data <- function() {
  # Get session summary
  sessions <- dbGetQuery(con, "SELECT * FROM session_summary")
  
  # Get all guesses
  guesses <- dbGetQuery(con, "SELECT * FROM user_guesses")
  
  # Get usage analytics
  usage <- dbGetQuery(con, "SELECT * FROM app_usage")
  
  # Create comprehensive dataset
  full_data <- guesses %>%
    left_join(sessions, by = "session_id")
  
  return(list(
    sessions = sessions,
    guesses = guesses,
    usage = usage,
    full_data = full_data
  ))
}

# Function to export data to CSV
export_data <- function(data, prefix = "correlation_app") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Export each table
  write.csv(data$sessions, paste0(prefix, "_sessions_", timestamp, ".csv"), row.names = FALSE)
  write.csv(data$guesses, paste0(prefix, "_guesses_", timestamp, ".csv"), row.names = FALSE)
  write.csv(data$usage, paste0(prefix, "_usage_", timestamp, ".csv"), row.names = FALSE)
  write.csv(data$full_data, paste0(prefix, "_full_data_", timestamp, ".csv"), row.names = FALSE)
  
  cat("Data exported with timestamp:", timestamp, "\n")
}

# Function to get summary statistics
get_summary_stats <- function(data) {
  cat("=== CORRELATION LEARNING APP DATA SUMMARY ===\n\n")
  
  # Session statistics
  cat("SESSIONS:\n")
  cat("Total sessions:", nrow(data$sessions), "\n")
  cat("Sessions with consent:", sum(data$sessions$consent_given, na.rm = TRUE), "\n")
  cat("Average questions per session:", mean(data$sessions$total_questions, na.rm = TRUE), "\n")
  cat("Average accuracy:", mean(data$sessions$accuracy_percentage, na.rm = TRUE), "%\n")
  cat("Average error:", mean(data$sessions$avg_error, na.rm = TRUE), "\n\n")
  
  # Guess statistics by phase
  cat("GUESSES BY PHASE:\n")
  phase_stats <- data$guesses %>%
    group_by(phase) %>%
    summarise(
      count = n(),
      avg_error = mean(error, na.rm = TRUE),
      avg_guess = mean(user_guess, na.rm = TRUE),
      avg_correct = mean(correct_answer, na.rm = TRUE)
    )
  print(phase_stats)
  cat("\n")
  
  # Time-based statistics
  cat("TIME PERIOD:\n")
  if (nrow(data$guesses) > 0) {
    data$guesses$timestamp <- as.POSIXct(data$guesses$timestamp)
    cat("First guess:", min(data$guesses$timestamp), "\n")
    cat("Last guess:", max(data$guesses$timestamp), "\n")
    cat("Total days:", as.numeric(difftime(max(data$guesses$timestamp), min(data$guesses$timestamp), units = "days")), "\n")
  }
}

# Function to create visualizations
create_plots <- function(data) {
  # Error by phase
  p1 <- ggplot(data$guesses, aes(x = phase, y = error)) +
    geom_boxplot() +
    labs(title = "Error Distribution by Learning Phase", 
         x = "Phase", y = "Absolute Error") +
    theme_minimal()
  
  # Learning progression
  p2 <- ggplot(data$guesses, aes(x = question_number, y = error)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "loess") +
    labs(title = "Learning Progression: Error Over Questions",
         x = "Question Number", y = "Absolute Error") +
    theme_minimal()
  
  # Accuracy by phase
  p3 <- ggplot(data$sessions, aes(x = accuracy_percentage)) +
    geom_histogram(bins = 20) +
    labs(title = "Distribution of Session Accuracy",
         x = "Accuracy (%)", y = "Count") +
    theme_minimal()
  
  return(list(error_by_phase = p1, learning_progression = p2, accuracy_dist = p3))
}

# Main execution
cat("Downloading correlation learning app data...\n")
data <- download_all_data()

# Show summary
get_summary_stats(data)

# Export data
export_data(data)

# Create plots
plots <- create_plots(data)

cat("\n=== PLOTS CREATED ===\n")
cat("1. Error by Phase\n")
cat("2. Learning Progression\n")
cat("3. Accuracy Distribution\n")

# Disconnect from database
dbDisconnect(con)

cat("\nData download complete!\n")
cat("Check your working directory for CSV files.\n") 