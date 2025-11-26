# Simple Data Collection for Shinyapps.io
# This approach works with hosted Shiny apps

# Add this to your app to collect data in the session
# The data will be available for download during the session

library(shiny)

# In your server function, add this reactive value to store all data
all_user_data <- reactiveVal(data.frame())

# Function to add data to the collection
add_user_data <- function(session_id, question_data) {
  current_data <- all_user_data()
  
  new_row <- data.frame(
    timestamp = Sys.time(),
    session_id = session_id,
    question_number = question_data$question_number,
    phase = question_data$phase,
    variable1 = question_data$variable1,
    variable2 = question_data$variable2,
    user_guess = question_data$user_guess,
    correct_answer = question_data$correct_answer,
    error = question_data$error
  )
  
  updated_data <- rbind(current_data, new_row)
  all_user_data(updated_data)
}

# Add this download button to your UI
# downloadButton("download_all_data", "Download All Session Data (CSV)")

# Add this to your server function
# output$download_all_data <- downloadHandler(
#   filename = function() {
#     paste0("correlation_app_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
#   },
#   content = function(file) {
#     write.csv(all_user_data(), file, row.names = FALSE)
#   }
# )

cat("=== SIMPLE DATA COLLECTION SETUP ===\n\n")
cat("This approach collects data during each user session.\n")
cat("Users can download their own data, and you can see patterns.\n\n")
cat("To implement:\n")
cat("1. Add the reactive value to your server function\n")
cat("2. Call add_user_data() when a guess is submitted\n")
cat("3. Add the download button to your UI\n")
cat("4. Add the download handler to your server\n\n")
cat("This works with Shinyapps.io and doesn't require external storage.\n") 