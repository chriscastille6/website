library(shiny)
library(ggplot2)
library(plotly)

# Structured learning progression correlations
learning_correlations <- data.frame(
  phase = c(
    # Phase 1: Intuitive examples (build confidence)
    rep("Intuitive", 5),
    # Phase 2: Effect sizes from real life (challenging but real)
    rep("Medical", 7),
    # Phase 3: Business-relevant correlations from Meyer et al. Table 2
    rep("Business & Organizational Psychology", 6),
    # Phase 4: Mixed challenges (from either table)
    rep("Mixed", 6)
  ),
  order = 1:24,
  variable1 = c(
    # Intuitive examples
    "Height", "Weight", "Nearness to the equator", 
    "Gender (female vs male)", "Gender (female vs male)",
    # Medical interventions
    "Baseball batting average", "Ibuprofen use", "Sugar consumption", "Sleeping pill use",
    "Aspirin consumption", "Antihypertensive medication", "Chemotherapy treatment",
    # Business-relevant correlations from Meyer et al. Table 2
    "Extroversion test scores", "Conscientiousness test scores", "Integrity test scores",
    "Graduate Record Exam scores", "General intelligence test scores", "Motivation to manage",
    # Mixed challenges
    "MMPI depression scores", "Beck Hopelessness Scale", "Conscientiousness test scores",
    "Graduate Record Exam scores", "Integrity test scores", "Neuropsychological test scores"
  ),
  variable2 = c(
    # Intuitive examples
    "Weight", "Height", "Daily temperature",
    "Height", "Self-reported empathy and nurturance",
    # Medical interventions
    "Hit success in a particular at-bat", "Pain reduction", "Children's behavior and cognitive processes",
    "Insomnia improvement", "Reduced risk of death by heart attack",
    "Reduced risk of stroke", "Surviving breast cancer",
    # Business-relevant correlations from Meyer et al. Table 2
    "Success in sales", "Job proficiency", "Subsequent supervisory ratings",
    "Subsequent graduate GPA", "Functional effectiveness across jobs", "Managerial effectiveness",
    # Mixed challenges
    "Subsequent cancer within 20 years", "Subsequent suicide", "Job proficiency",
    "Subsequent graduate GPA", "Subsequent supervisory ratings", "Differentiation of dementia from controls"
  ),
  variable1_desc = c(
    # Intuitive examples
    "Height in inches",
    "Body weight in pounds",
    "Distance from equator in degrees latitude",
    "Biological sex (male/female, self-reported)",
    "Biological sex (male/female, self-reported)",
    # Medical interventions
    "Season batting average as a professional baseball player",
    "Taking ibuprofen medication (yes/no, clinical trial)",
    "Daily sugar intake in grams (measured through food diaries)",
    "Taking prescription sleeping medication (yes/no)",
    "Regular aspirin use (yes/no, measured through medication logs)",
    "Antihypertensive medication treatment (yes/no, medical records)",
    "Receiving chemotherapy treatment (yes/no, medical records)",
    # Business-relevant correlations from Meyer et al. Table 2
    "Extroversion personality trait (standardized personality test)",
    "Conscientiousness personality trait (standardized personality test)",
    "Integrity test scores (personnel selection test)",
    "Graduate Record Exam scores (standardized test)",
    "General intelligence test scores (standardized cognitive test)",
    "Motivation to manage (Miner Sentence Completion Test)",
    # Mixed challenges
    "MMPI depression scale scores (standardized psychological test)",
    "Beck Hopelessness Scale scores (clinical assessment)",
    "Conscientiousness personality trait (standardized personality test)",
    "Graduate Record Exam scores (standardized test)",
    "Integrity test scores (personnel selection test)",
    "Neuropsychological test battery scores (clinical assessment)"
  ),
  variable2_desc = c(
    # Intuitive examples
    "Body weight in pounds",
    "Height in inches",
    "Average daily temperature in degrees Fahrenheit",
    "Height in inches",
    "Self-reported empathy and nurturance (standardized personality scales)",
    # Medical interventions
    "Success in getting a hit in a specific at-bat",
    "Pain reduction (self-reported improvement)",
    "Children's behavior and cognitive processes (measured through standardized assessments)",
    "Improvement in sleep quality (self-reported)",
    "Reduced risk of death by heart attack (medical diagnosis)",
    "Reduced risk of stroke (medical diagnosis)",
    "5-year survival rate after breast cancer diagnosis",
    # Business-relevant correlations from Meyer et al. Table 2
    "Success in sales (concurrent and predictive)",
    "Job proficiency (concurrent and predictive)",
    "Subsequent supervisory ratings of job performance",
    "Subsequent graduate GPA",
    "Functional effectiveness across jobs",
    "Managerial effectiveness (performance criterion measures)",
    # Mixed challenges
    "Cancer diagnosis within 20 years (medical records)",
    "Suicide attempts or completion (medical/psychological records)",
    "Job performance ratings by supervisors",
    "Graduate school grade point average",
    "Supervisory performance ratings",
    "Clinical diagnosis accuracy (dementia vs. normal aging)"
  ),
  correlation = c(
    # Intuitive examples (strong, obvious relationships)
    0.67, 0.67, 0.60, 0.60, 0.32,
    # Medical interventions (surprisingly small effects)
    0.06, 0.14, 0.00, 0.27, 0.02, 0.03, 0.03,
    # Business-relevant correlations from Meyer et al. Table 2
    0.11, 0.23, 0.27, 0.24, 0.25, 0.11,
    # Mixed challenges (from both tables)
    0.05, 0.08, 0.12, 0.24, 0.27, 0.68
  ),
  sample_size = c(
    # Intuitive examples
    19724, 19724, 16948, 16962, 19546,
    # Medical interventions
    0, 8488, 560, 205, 22071, 59086, 9069,
    # Business-relevant correlations from Meyer et al. Table 2
    194326, 21650, 5788, 5186, 40000, 626,
    # Mixed challenges
    2018, 2123, 21650, 5186, 5788, 94
  ),
  description = c(
    # Intuitive examples
    "Height and weight for U.S. adults",
    "Weight and height for U.S. adults",
    "Nearness to the equator and daily temperature in the U.S.A.",
    "Gender and height for U.S. adults (men are taller)",
    "Gender and self-reported empathy and nurturance (females are higher)",
    # Medical interventions
    "General batting skill as a Major League baseball player and hit success on a given instance at bat",
    "Effect of nonsteroidal anti-inflammatory drugs (e.g., ibuprofen) on pain reduction",
    "Effect of sugar consumption on children's behavior and cognitive processes",
    "Sleeping pills (benzodiazepines or zolpidem) and short-term improvement in chronic insomnia",
    "Aspirin and reduced risk of death by heart attack",
    "Antihypertensive medication and reduced risk of stroke",
    "Chemotherapy and surviving breast cancer",
    # Business-relevant correlations from Meyer et al. Table 2
    "Extroversion and success in sales (concurrent and predictive)",
    "Conscientiousness and job proficiency (concurrent and predictive)",
    "Integrity test scores and subsequent supervisory ratings",
    "Graduate Record Exam scores and subsequent graduate GPA",
    "General intelligence and functional effectiveness across jobs",
    "Motivation to manage and managerial effectiveness",
    # Mixed challenges
    "MMPI depression scores and subsequent cancer within 20 years",
    "Beck Hopelessness Scale scores and subsequent suicide",
    "Conscientiousness test scores and job proficiency",
    "Graduate Record Exam scores and subsequent graduate GPA",
    "Integrity test scores and subsequent supervisory ratings",
    "Neuropsychological test scores and differentiation of dementia from controls"
  ),
  context = c(
    # Intuitive examples
    rep("This is an intuitive relationship that most people would expect to be strong. These correlations help you get comfortable with the concept of correlation coefficients.", 5),
    # Medical interventions
    rep("This represents a medical intervention effect. Notice how much smaller these correlations are than you might expect - medical treatments often have more modest effects than people assume.", 7),
    # Business-relevant correlations from Meyer et al. Table 2
    rep("This represents business and organizational psychology research from Meyer et al. (2001) Table 2. These correlations show how personality traits, cognitive abilities, and motivation predict important workplace outcomes.", 6),
    # Mixed challenges
    rep("This represents a mixed challenge from either Table 1 or Table 2 of Meyer et al. (2001). These correlations span different domains and effect sizes.", 6)
  ),
  learning_message = c(
    # Intuitive examples
    rep("Great! You're learning to recognize strong, intuitive relationships.", 5),
    # Medical interventions
    rep("Surprising, right? Medical interventions often have smaller effects than we expect.", 7),
    # Business-relevant correlations from Meyer et al. Table 2
    rep("Business psychology research shows how individual differences predict workplace success.", 6),
    # Mixed challenges
    rep("Mixed challenges help you apply your learning across different domains.", 6)
  )
)

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .btn-primary { background-color: #007bff; border-color: #007bff; }
      .btn-success { background-color: #28a745; border-color: #28a745; }
      .btn-info { background-color: #17a2b8; border-color: #17a2b8; }
      .btn-secondary { background-color: #6c757d; border-color: #6c757d; }
      .btn { width: 150px; }
      .phase-indicator { 
        background-color: #e9ecef; 
        padding: 10px; 
        border-radius: 5px; 
        margin-bottom: 15px;
        text-align: center;
        font-weight: bold;
      }
      .phase-intuitive { background-color: #d4edda; border-left: 4px solid #28a745; }
      .phase-medical { background-color: #fff3cd; border-left: 4px solid #ffc107; }
      .phase-psychological { background-color: #f8d7da; border-left: 4px solid #dc3545; }
      .phase-mixed { background-color: #e2e3e5; border-left: 4px solid #6c757d; }
    ")),
    tags$script(HTML("
      Shiny.addCustomMessageHandler('showConsentModal', function(message) {
        document.getElementById('consent_modal').style.display = 'block';
      });
      
      Shiny.addCustomMessageHandler('hideConsentModal', function(message) {
        document.getElementById('consent_modal').style.display = 'none';
      });
    "))
  ),
  
  titlePanel("Guess the Correlation"),
  subtitle = "Structured Learning: Intuitive → Medical → Business & Organizational Psychology",
  
  # GDPR Consent Modal
  tags$div(
    id = "consent_modal",
    style = "display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.5);",
    tags$div(
      style = "background-color: white; margin: 15% auto; padding: 20px; border-radius: 10px; width: 80%; max-width: 600px;",
      h3("Data Collection Consent"),
      p("This app may collect anonymous data about correlation guessing performance for educational research purposes."),
      p("Data collected includes:"),
      tags$ul(
        tags$li("Your correlation guesses"),
        tags$li("Correct correlation values"),
        tags$li("Error rates and accuracy"),
        tags$li("Session duration"),
        tags$li("No personal information (name, email, IP address)")
      ),
      p("All data is anonymous and will only be used for educational research to understand how people estimate correlations."),
      p("You can play the game without consenting to data collection."),
      tags$div(
        style = "text-align: center; margin-top: 20px;",
        actionButton("consent_yes", "I consent to data collection", class = "btn-primary", style = "width: 200px; margin-right: 10px;"),
        actionButton("consent_no", "Play without data collection", class = "btn-secondary", style = "width: 200px; color: white;")
      )
    )
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 4,
      
      # Phase indicator
      uiOutput("phase_indicator"),
      
      h3("What do you think is the correlation between:"),
      uiOutput("variable_question"),
      br(),
      
      sliderInput("user_correlation", "Your correlation guess (r):", value = 0, min = -1, max = 1, step = 0.01),
      
      actionButton("generate_plot", "Generate Plot", class = "btn-info", style = "width: 200px;"),
      br(),
      checkboxInput("show_trendline", "Show Trendline", value = FALSE),
      br(),
      
      conditionalPanel(
        condition = "input.generate_plot > 0",
        actionButton("submit_guess", "Submit for Feedback", class = "btn-primary", style = "width: 200px;"),
        br(), br()
      ),
      
      conditionalPanel(
        condition = "input.submit_guess > 0",
        h4("Feedback"),
        textOutput("feedback_text"),
        br(),
        actionButton("next_question", "Next Question", class = "btn-success", style = "width: 200px;")
      ),
      
      br()
    ),
    
    mainPanel(
      width = 8,
      
      tabsetPanel(
        tabPanel(
          "How to Play",
          h3("Structured Learning Approach"),
          p("This game is designed to help you learn about correlations through a progressive approach:"),
          p("1. Read the variable names and think about what relationship you expect"),
          p("2. Enter your correlation coefficient (r) in the sidebar"),
          p("3. Click 'Generate Plot' to see your prediction visualized (the number of dots corresponds to the sample size reported in the literature, e.g., Meyer et al., 2001. Sometimes K (# of studies) is given when N is not available)"),
          p("4. Adjust your guess if needed, then submit for feedback"),
          p("5. See how close you were to the real correlation from research!"),
          br(),
          h4("Learning Progression:"),
          tags$ol(
            tags$li("Phase 1 (Green): Intuitive examples to build confidence"),
            tags$li("Phase 2 (Yellow): Effect sizes from real life"),
            tags$li("Phase 3 (Red): Applied Psychological Research"),
            tags$li("Phase 4 (Mixed): More examples from our database")
          ),
          br(),
          plotlyOutput("scatter_plot", height = "500px"),
          br(),
          conditionalPanel(
            condition = "input.submit_guess > 0",
            h3("Binomial Effect Size Display"),
            p("The Binomial Effect Size Display (BESD) helps translate correlation coefficients into more intuitive language."),
            p("For any correlation r, we can calculate:"),
            p("Success rate with intervention = 0.35 + (r/2)"),
            p("Success rate without intervention = 0.35"),
            br(),
            h4("Current Example:"),
            plotOutput("besd_plot", height = "400px"),
            br(),
            uiOutput("besd_explanation")
          )
        ),
        tabPanel(
          "Understanding Correlation Coefficients",
          h3("Understanding Correlation Coefficients"),
          p("Correlation coefficients (r) range from -1 to +1:"),
          tags$ul(
            tags$li("r = 0: No linear relationship"),
            tags$li("r = ±0.1: Weak relationship"),
            tags$li("r = ±0.3: Moderate relationship"), 
            tags$li("r = ±0.5: Strong relationship"),
            tags$li("r = ±0.7: Very strong relationship"),
            tags$li("r = ±1.0: Perfect linear relationship")
          ),
          p("Note: The scatter plots show standardized variables (z-scores), so the scale is in standard deviation units. Even small correlations can be meaningful in large samples."),
          br(),
          h4("Formula:"),
          p("r = Σ[(x - x̄)(y - ȳ)] / √[Σ(x - x̄)² × Σ(y - ȳ)²]"),
          h4("Example Calculation:"),
          p("Let's calculate the correlation for a simple example with 5 data points:"),
          tags$table(
            class = "table table-bordered",
            tags$thead(
              tags$tr(
                tags$th("Point"), tags$th("X"), tags$th("Y"), tags$th("X - X̄"), tags$th("Y - Ȳ"), tags$th("(X - X̄)(Y - Ȳ)")
              )
            ),
            tags$tbody(
              tags$tr(tags$td("1"), tags$td("1"), tags$td("2"), tags$td("-1"), tags$td("-1"), tags$td("1")),
              tags$tr(tags$td("2"), tags$td("2"), tags$td("4"), tags$td("0"), tags$td("1"), tags$td("0")),
              tags$tr(tags$td("3"), tags$td("3"), tags$td("3"), tags$td("1"), tags$td("0"), tags$td("0")),
              tags$tr(tags$td("4"), tags$td("4"), tags$td("5"), tags$td("2"), tags$td("2"), tags$td("4")),
              tags$tr(tags$td("5"), tags$td("5"), tags$td("6"), tags$td("3"), tags$td("3"), tags$td("9"))
            )
          ),
          p("X̄ = 3, Ȳ = 4"),
          p("Numerator: Σ[(x - x̄)(y - ȳ)] = 1 + 0 + 0 + 4 + 9 = 14"),
          p("Denominator: √[Σ(x - x̄)² × Σ(y - ȳ)²] = √[15 × 15] = 15"),
          p("r = 14/15 = 0.933")
        ),
        tabPanel(
          "Your Data",
          conditionalPanel(
            condition = "input.submit_guess > 0",
            wellPanel(
              h4("Your Statistics"),
              textOutput("game_stats"),
              br(),
              downloadButton("download_data", "Download Session Data (CSV)", class = "btn-info", style = "width: 250px;")
            ),
            br(),
            h4("Your Progress"),
            plotlyOutput("progress_plot", height = "300px")
          ),
          conditionalPanel(
            condition = "input.submit_guess == 0",
            h4("Your Data"),
            p("Complete at least one question to see your statistics and progress here.")
          )
        )
      ),
      
      # Footer with attributions
      tags$div(
        style = "margin-top: 30px; padding: 20px; background-color: #f8f9fa; border-radius: 5px; text-align: center;",
        p("This app is inspired by Daniel Läkens' 'Guess the Correlation' game", style = "font-style: italic;"),
        p("Built with R Shiny for educational purposes", style = "font-size: 12px; color: #666;")
      )
    )
  )
)

server <- function(input, output, session) {
  
  game_state <- reactiveValues(
    current_question = 1,
    correct_guesses = 0,
    total_error = 0,
    questions_answered = 0,
    current_correlation = 0,
    current_sample_size = 100,
    current_description = "",
    current_variable1 = "",
    current_variable2 = "",
    current_variable1_desc = "",
    current_variable2_desc = "",
    current_context = "",
    current_phase = "",
    current_learning_message = "",
    guess_history = data.frame(question = integer(), guess = numeric(), correct = numeric(), error = numeric()),
    guess_submitted = FALSE,
    user_correlation_guess = 0,
    plot_generated = FALSE,
    session_id = paste0("session_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sample(1000:9999, 1)),
    consent_given = FALSE
  )
  
  # Show consent modal on app start
  observe({
    if (!game_state$consent_given) {
      session$sendCustomMessage("showConsentModal", list())
    }
  })
  
  # Handle consent responses
  observeEvent(input$consent_yes, {
    game_state$consent_given <- TRUE
    session$sendCustomMessage("hideConsentModal", list())
    start_new_game()
  })
  
  observeEvent(input$consent_no, {
    game_state$consent_given <- FALSE
    session$sendCustomMessage("hideConsentModal", list())
    start_new_game()
  })
  
  start_new_game <- function() {
    setup_question(1)
  }
  
  setup_question <- function(question_number) {
    current_row <- learning_correlations[question_number, ]
    game_state$current_question <- question_number
    game_state$current_correlation <- current_row$correlation
    game_state$current_sample_size <- current_row$sample_size
    game_state$current_description <- current_row$description
    game_state$current_variable1 <- current_row$variable1
    game_state$current_variable2 <- current_row$variable2
    game_state$current_variable1_desc <- current_row$variable1_desc
    game_state$current_variable2_desc <- current_row$variable2_desc
    game_state$current_context <- current_row$context
    game_state$current_phase <- current_row$phase
    game_state$current_learning_message <- current_row$learning_message
    game_state$guess_submitted <- FALSE
    game_state$plot_generated <- FALSE
    
    updateSliderInput(session, "user_correlation", value = 0)
  }
  
  # Phase indicator
  output$phase_indicator <- renderUI({
    phase_class <- paste0("phase-", tolower(game_state$current_phase))
    phase_text <- switch(game_state$current_phase,
      "Intuitive" = "Phase 1: Intuitive Examples",
      "Medical" = "Phase 2: Effect Sizes from Real Life", 
              "Applied Psychological Research" = "Phase 3: Applied Psychological Research",
      "Mixed" = "Phase 4: Mixed Challenges"
    )
    
    tags$div(
      class = paste("phase-indicator", phase_class),
      phase_text
    )
  })
  
  plot_data <- reactive({
    req(input$user_correlation)
    
    set.seed(42 + game_state$current_question)
    n <- game_state$current_sample_size
    
    if (is.na(n) || n <= 0) {
      n <- 100
    }
    
    z1 <- rnorm(n, 0, 1)
    z2 <- rnorm(n, 0, 1)
    
    rho <- input$user_correlation
    
    x <- z1
    y <- rho * z1 + sqrt(1 - rho^2) * z2
    
    data.frame(x = x, y = y, id = 1:n)
  })
  
  output$variable_question <- renderUI({
    question_text <- paste0(
      "<strong>Question ", game_state$current_question, " of ", nrow(learning_correlations), "</strong><br><br>",
      "X: ", game_state$current_variable1, "<br>",
      "<small><em>", game_state$current_variable1_desc, "</em></small><br><br>",
      "Y: ", game_state$current_variable2, "<br>",
      "<small><em>", game_state$current_variable2_desc, "</em></small>"
    )
    
    HTML(question_text)
  })
  
  # BESD plot
  output$besd_plot <- renderPlot({
    # Use the current correlation from the game state
    r <- game_state$current_correlation
    
    # Convert r to BESD success rate
    success_rate_with_intervention <- 0.35 + (r / 2)
    success_rate_without_intervention <- 0.35  # Baseline from actual data
    
    # Create a data frame for the BESD, ordering by success rate (smaller first)
    besd_data_r <- data.frame(
      Group = c("No", "Yes"),  # Reorder to put the smaller column (No) first
      SuccessRate = c(success_rate_without_intervention, success_rate_with_intervention)
    )
    
    # Create dynamic title based on current variables
    current_title <- paste0("How ", game_state$current_variable1, " Correlates to ", game_state$current_variable2, " (r = ", round(r, 3), ")")
    
    # Plot the BESD
    bp <- barplot(besd_data_r$SuccessRate * 100, 
                  names.arg = besd_data_r$Group, 
                  ylab = paste0("Probability of having above average ", tolower(game_state$current_variable2), " (%)"), 
                  xlab = paste0("Is the person above median ", tolower(game_state$current_variable1), "?"),
                  col = c("grey", "lightgreen"),  # Colors corresponding to the groups
                  main = current_title,
                  ylim = c(0, 100),
                  cex.axis = 1.2,  # Match app font size
                  cex.lab = 1.2,   # Match app font size
                  cex.main = 1.4)  # Match app font size
    
    # Add the rates inside the bars
    text(bp, besd_data_r$SuccessRate * 100 / 2, 
         labels = paste(round(besd_data_r$SuccessRate * 100, 1), "%"), 
         cex = 1.2, col = "black")  # Black text, match app font size
  })
  
  # BESD explanation
  output$besd_explanation <- renderUI({
    r <- game_state$current_correlation
    success_rate_with_intervention <- 0.35 + (r / 2)
    success_rate_without_intervention <- 0.35
    difference <- success_rate_with_intervention - success_rate_without_intervention
    
    HTML(paste0(
      "<p>This means that ", round(success_rate_with_intervention * 100, 1), 
      "% of people with high ", tolower(game_state$current_variable1), 
      " also have high ", tolower(game_state$current_variable2), 
      ", compared to ", round(success_rate_without_intervention * 100, 1), 
      "% of people with low ", tolower(game_state$current_variable1), ".</p>",
      "<p>The difference of ", round(difference * 100, 1), 
      " percentage points makes the effect size more intuitive than just saying 'r = ", round(r, 3), "'.</p>"
    ))
  })
  
  # Create initial plot
  output$scatter_plot <- renderPlotly({
    suppressWarnings({
      if (!game_state$plot_generated) {
        plot_ly() %>%
          add_annotations(
            text = "Enter your correlation guess and click 'Generate Plot' to see your prediction",
            xref = "paper", yref = "paper",
            x = 0.5, y = 0.5,
            showarrow = FALSE,
            font = list(size = 16)
          ) %>%
          layout(
            title = "Your Correlation Prediction",
            xaxis = list(title = "X (Standardized)", range = c(-3, 3)),
            yaxis = list(title = "Y (Standardized)", range = c(-3, 3)),
            margin = list(t = 80, b = 80, l = 80, r = 80),
            showlegend = FALSE
          ) %>%
          config(displayModeBar = FALSE)
      } else {
        req(input$user_correlation)
        
        tryCatch({
          data <- plot_data()
          
          p <- plot_ly(
            data = data,
            x = ~x, 
            y = ~y,
            type = 'scatter',
            mode = 'markers',
            marker = list(size = 8, color = 'steelblue', opacity = 0.7),
            name = "Data Points",
            hovertemplate = paste(
              paste0(game_state$current_variable1, ": %{x:.2f}<br>"),
              paste0(game_state$current_variable2, ": %{y:.2f}<br>"),
              "Sample size: ", game_state$current_sample_size, "<br>",
              "<extra></extra>"
            ),
            key = ~id  # Essential for smooth transitions
          ) %>%
            layout(
              title = paste0("Your Prediction: r = ", input$user_correlation, " (n = ", game_state$current_sample_size, ")"),
              xaxis = list(title = paste0(game_state$current_variable1, " (Standardized)"), range = c(-3, 3)),
              yaxis = list(title = paste0(game_state$current_variable2, " (Standardized)"), range = c(-3, 3)),
              showlegend = TRUE,
              margin = list(t = 80, b = 80, l = 80, r = 80),
              transition = list(
                duration = 1500,
                easing = 'elastic-out',
                ordering = 'trace'
              )
            ) %>%
            config(displayModeBar = FALSE)
          
          if (input$show_trendline) {
            x_full_range <- seq(-3, 3, length.out = 100)
            y_guess <- input$user_correlation * x_full_range
            
            p <- p %>% add_trace(
              x = x_full_range,
              y = y_guess,
              type = 'scatter',
              mode = 'lines',
              line = list(color = 'black', width = 3, dash = 'solid'),
              name = paste0('Your prediction (r = ', input$user_correlation, ')'),
              showlegend = TRUE,
              hoverinfo = 'skip',
              key = paste0("trendline_", input$user_correlation)  # Unique key for trendline
            )
          }
          
          if (game_state$guess_submitted) {
            x_full_range <- seq(-3, 3, length.out = 100)
            y_true <- game_state$current_correlation * x_full_range
            
            p <- p %>% add_trace(
              x = x_full_range,
              y = y_true,
              type = 'scatter',
              mode = 'lines',
              line = list(color = 'limegreen', width = 3, dash = 'solid'),
              name = paste0('True correlation (r = ', round(game_state$current_correlation, 3), ')'),
              showlegend = TRUE,
              hoverinfo = 'skip',
              key = paste0("true_line_", game_state$current_correlation)  # Unique key for true line
            )
          }
          
          return(p)
        }, error = function(e) {
          cat("Error generating plot:", e$message, "\n")
          plot_ly() %>%
            add_annotations(
              text = paste("Error generating plot:", e$message),
              xref = "paper", yref = "paper",
              x = 0.5, y = 0.5,
              showarrow = FALSE,
              font = list(size = 16, color = "red")
            ) %>%
            layout(
              title = "Error",
              xaxis = list(title = "X (Standardized)", range = c(-3, 3)),
              yaxis = list(title = "Y (Standardized)", range = c(-3, 3)),
              margin = list(t = 80, b = 80, l = 80, r = 80),
              showlegend = FALSE
            ) %>%
            config(displayModeBar = FALSE)
        })
      }
    })
  })
  
  # Remove plotlyProxy approach - let the plot re-render with transitions
  
  observeEvent(input$generate_plot, {
    game_state$plot_generated <- TRUE
  })
  
  # The plot will automatically re-render with transitions when input$user_correlation changes
  

  
  observeEvent(input$submit_guess, {
    if (!is.null(input$user_correlation)) {
      user_correlation_guess <- as.numeric(input$user_correlation)
      correct_correlation <- game_state$current_correlation
      
      game_state$user_correlation_guess <- user_correlation_guess
      game_state$guess_submitted <- TRUE
      
      correlation_close <- abs(user_correlation_guess - correct_correlation) < 0.05
      is_correct <- correlation_close
      
      if (is_correct) {
        game_state$correct_guesses <- game_state$correct_guesses + 1
      }
      
      error <- abs(user_correlation_guess - correct_correlation)
      game_state$total_error <- game_state$total_error + error
      game_state$questions_answered <- game_state$questions_answered + 1
      
      new_row <- data.frame(
        question = game_state$current_question,
        guess = user_correlation_guess,
        correct = correct_correlation,
        error = error
      )
      game_state$guess_history <- rbind(game_state$guess_history, new_row)
      
      feedback <- paste0(
        "Your guess: r = ", user_correlation_guess, "\n",
        "Correct answer: r = ", correct_correlation, "\n",
        "Error: ", round(error, 3), "\n\n",
        game_state$current_learning_message
      )
      
      output$feedback_text <- renderText(feedback)
    }
  })
  
  observeEvent(input$next_question, {
    next_question <- game_state$current_question + 1
    
    if (next_question <= nrow(learning_correlations)) {
      setup_question(next_question)
      output$feedback_text <- renderText("")
      game_state$plot_generated <- FALSE
      game_state$guess_submitted <- FALSE
    } else {
      # Game completed
      output$feedback_text <- renderText("Congratulations! You've completed all phases of the learning progression!")
    }
  })
  
  output$game_stats <- renderText({
    if (game_state$questions_answered > 0) {
      accuracy <- round(game_state$correct_guesses / game_state$questions_answered * 100, 1)
      avg_error <- round(game_state$total_error / game_state$questions_answered, 3)
      
      paste0(
        "Questions answered: ", game_state$questions_answered, "\n",
        "Accuracy: ", accuracy, "%\n",
        "Average Error: ", avg_error
      )
    }
  })
  
  output$progress_plot <- renderPlotly({
    suppressWarnings({
      if (nrow(game_state$guess_history) > 0) {
        p <- plot_ly(
          data = game_state$guess_history,
          x = ~question,
          y = ~guess,
          type = 'scatter',
          mode = 'lines+markers',
          name = 'Your Guesses',
          line = list(color = 'blue'),
          marker = list(size = 8)
        ) %>%
          add_trace(
            y = ~correct,
            name = 'Correct Values',
            line = list(color = 'red', dash = 'dash'),
            mode = 'lines+markers',
            marker = list(size = 8)
          ) %>%
          layout(
            title = "Your Correlation Guesses vs. Correct Values",
            xaxis = list(title = "Question Number", tickmode = 'linear', tick0 = 1, dtick = 1, showticklabels = TRUE),
            yaxis = list(title = "Correlation Coefficient (r)", range = c(-1, 1), tickmode = 'linear', tick0 = -1, dtick = 0.2),
            showlegend = TRUE,
            margin = list(t = 100, b = 80, l = 80, r = 80),
            transition = list(duration = 300, easing = 'quad-in-out')
          ) %>%
          config(displayModeBar = FALSE)
        
        return(p)
      }
    })
  })
  
  # Download handler for session data
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("correlation_game_session_", game_state$session_id, ".csv")
    },
    content = function(file) {
      if (nrow(game_state$guess_history) > 0) {
        session_data <- game_state$guess_history
        session_data$session_id <- game_state$session_id
        session_data$timestamp <- Sys.time()
        write.csv(session_data, file, row.names = FALSE)
      } else {
        empty_data <- data.frame(
          question = integer(),
          guess = numeric(),
          correct = numeric(),
          error = numeric(),
          session_id = character(),
          timestamp = as.POSIXct(character())
        )
        write.csv(empty_data, file, row.names = FALSE)
      }
    }
  )
}

shinyApp(ui = ui, server = server) 