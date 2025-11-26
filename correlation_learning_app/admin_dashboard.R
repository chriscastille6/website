# Admin Dashboard for Correlation Learning App
# Run this to view and download all user data

library(shiny)
library(RSQLite)
library(DBI)
library(dplyr)
library(ggplot2)
library(DT)

ui <- fluidPage(
  titlePanel("Correlation Learning App - Admin Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Data Overview"),
      verbatimTextOutput("summary_stats"),
      br(),
      h4("Download Data"),
      downloadButton("download_sessions", "Download Sessions (CSV)"),
      br(), br(),
      downloadButton("download_guesses", "Download All Guesses (CSV)"),
      br(), br(),
      downloadButton("download_summary", "Download Summary Report (CSV)"),
      br(), br(),
      actionButton("refresh_data", "Refresh Data", class = "btn-primary")
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel("Sessions", 
                 h3("User Sessions"),
                 DT::dataTableOutput("sessions_table")),
        
        tabPanel("Guesses", 
                 h3("All User Guesses"),
                 DT::dataTableOutput("guesses_table")),
        
        tabPanel("Analytics", 
                 h3("Learning Analytics"),
                 plotOutput("error_by_phase"),
                 plotOutput("learning_progression"),
                 plotOutput("accuracy_distribution")),
        
        tabPanel("Summary", 
                 h3("Summary Statistics"),
                 verbatimTextOutput("detailed_stats"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Database connection
  db_path <- "correlation_app_data.db"
  
  # Reactive data
  data <- reactive({
    input$refresh_data
    tryCatch({
      con <- dbConnect(SQLite(), db_path)
      
      sessions <- dbGetQuery(con, "SELECT * FROM user_sessions ORDER BY start_time DESC")
      guesses <- dbGetQuery(con, "SELECT * FROM user_guesses ORDER BY timestamp DESC")
      
      dbDisconnect(con)
      
      list(sessions = sessions, guesses = guesses)
    }, error = function(e) {
      list(sessions = data.frame(), guesses = data.frame())
    })
  })
  
  # Summary statistics
  output$summary_stats <- renderText({
    d <- data()
    if (nrow(d$sessions) == 0) {
      return("No data available yet.")
    }
    
    paste0(
      "Total Sessions: ", nrow(d$sessions), "\n",
      "Total Guesses: ", nrow(d$guesses), "\n",
      "Consent Rate: ", round(mean(d$sessions$consent_given) * 100, 1), "%\n",
      "Avg Questions/Session: ", round(mean(d$sessions$total_questions, na.rm = TRUE), 1), "\n",
      "Avg Accuracy: ", round(mean(d$sessions$accuracy_percentage, na.rm = TRUE), 1), "%"
    )
  })
  
  # Sessions table
  output$sessions_table <- DT::renderDataTable({
    d <- data()
    if (nrow(d$sessions) == 0) return(data.frame())
    
    d$sessions %>%
      mutate(
        start_time = as.POSIXct(start_time),
        end_time = as.POSIXct(end_time),
        consent_given = ifelse(consent_given, "Yes", "No")
      ) %>%
      select(Session_ID = session_id, 
             Start_Time = start_time, 
             Consent = consent_given,
             Questions = total_questions,
             Accuracy = accuracy_percentage,
             Avg_Error = avg_error)
  }, options = list(pageLength = 10))
  
  # Guesses table
  output$guesses_table <- DT::renderDataTable({
    d <- data()
    if (nrow(d$guesses) == 0) return(data.frame())
    
    d$guesses %>%
      mutate(timestamp = as.POSIXct(timestamp)) %>%
      select(Session = session_id,
             Question = question_number,
             Phase = phase,
             Variable1 = variable1,
             Variable2 = variable2,
             Guess = user_guess,
             Correct = correct_answer,
             Error = error,
             Time = timestamp)
  }, options = list(pageLength = 15))
  
  # Analytics plots
  output$error_by_phase <- renderPlot({
    d <- data()
    if (nrow(d$guesses) == 0) return(ggplot() + annotate("text", x = 0.5, y = 0.5, label = "No data available"))
    
    ggplot(d$guesses, aes(x = phase, y = error)) +
      geom_boxplot(fill = "lightblue") +
      labs(title = "Error Distribution by Learning Phase",
           x = "Phase", y = "Absolute Error") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$learning_progression <- renderPlot({
    d <- data()
    if (nrow(d$guesses) == 0) return(ggplot() + annotate("text", x = 0.5, y = 0.5, label = "No data available"))
    
    ggplot(d$guesses, aes(x = question_number, y = error)) +
      geom_point(alpha = 0.5) +
      geom_smooth(method = "loess", color = "red") +
      labs(title = "Learning Progression: Error Over Questions",
           x = "Question Number", y = "Absolute Error") +
      theme_minimal()
  })
  
  output$accuracy_distribution <- renderPlot({
    d <- data()
    if (nrow(d$sessions) == 0) return(ggplot() + annotate("text", x = 0.5, y = 0.5, label = "No data available"))
    
    ggplot(d$sessions, aes(x = accuracy_percentage)) +
      geom_histogram(bins = 20, fill = "lightgreen") +
      labs(title = "Distribution of Session Accuracy",
           x = "Accuracy (%)", y = "Count") +
      theme_minimal()
  })
  
  # Detailed statistics
  output$detailed_stats <- renderText({
    d <- data()
    if (nrow(d$sessions) == 0) return("No data available yet.")
    
    # Phase statistics
    phase_stats <- d$guesses %>%
      group_by(phase) %>%
      summarise(
        count = n(),
        avg_error = mean(error, na.rm = TRUE),
        avg_guess = mean(user_guess, na.rm = TRUE)
      )
    
    paste0(
      "=== DETAILED STATISTICS ===\n\n",
      "SESSIONS:\n",
      "Total: ", nrow(d$sessions), "\n",
      "With consent: ", sum(d$sessions$consent_given), "\n",
      "Average questions: ", round(mean(d$sessions$total_questions, na.rm = TRUE), 1), "\n",
      "Average accuracy: ", round(mean(d$sessions$accuracy_percentage, na.rm = TRUE), 1), "%\n\n",
      "GUESSES BY PHASE:\n",
      paste(capture.output(print(phase_stats)), collapse = "\n"), "\n\n",
      "TIME PERIOD:\n",
      "First guess: ", min(d$guesses$timestamp), "\n",
      "Last guess: ", max(d$guesses$timestamp), "\n"
    )
  })
  
  # Download handlers
  output$download_sessions <- downloadHandler(
    filename = function() paste0("sessions_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content = function(file) write.csv(data()$sessions, file, row.names = FALSE)
  )
  
  output$download_guesses <- downloadHandler(
    filename = function() paste0("guesses_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content = function(file) write.csv(data()$guesses, file, row.names = FALSE)
  )
  
  output$download_summary <- downloadHandler(
    filename = function() paste0("summary_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content = function(file) {
      d <- data()
      summary_data <- d$guesses %>%
        group_by(phase) %>%
        summarise(
          count = n(),
          avg_error = mean(error, na.rm = TRUE),
          avg_guess = mean(user_guess, na.rm = TRUE)
        )
      write.csv(summary_data, file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server) 