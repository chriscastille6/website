# =============================================================================
# COGNITIVE LOAD ANALYSIS SHINY APP
# =============================================================================
# Web application for comparing cognitive load between text conditions
# 
# To run: shiny::runApp()
# To deploy: rsconnect::deployApp()
# =============================================================================

library(shiny)
library(quanteda)
library(quanteda.textstats)
library(dplyr)
library(DT)
library(ggplot2)

# Set seed for reproducibility
set.seed(123)

# =============================================================================
# GLOBAL FUNCTIONS AND DATA
# =============================================================================

# Baseline texts (Heath's pizza parlor examples)
baseline_committee <- "Our mission is to present with integrity the highest-quality entertainment solutions to families."

baseline_original <- "Our mission is to serve the tastiest damn pizza in Wake County."

# Function to calculate comprehensive metrics
calculate_comprehensive_metrics <- function(text, condition_name) {
  
  if (text == "" || is.null(text)) {
    return(NULL)
  }
  
  # Create corpus for this text
  corp_single <- corpus(text)
  
  # Calculate readability
  readability <- textstat_readability(corp_single, measure = "Flesch")
  
  # Calculate word and sentence statistics
  words_single <- tokens(corp_single, what = "word")
  sentences_single <- tokens(corp_single, what = "sentence")
  
  total_words <- length(unlist(words_single))
  total_sentences <- length(unlist(sentences_single))
  avg_sentence_length <- mean(lengths(sentences_single))
  avg_word_length <- mean(nchar(unlist(words_single)))
  
  # Calculate cognitive load score
  flesch_score <- readability$Flesch
  cognitive_load_score <- (avg_sentence_length * 0.4) + (avg_word_length * 0.3) + ((100 - flesch_score) * 0.3)
  
  # Determine readability category
  readability_category <- case_when(
    flesch_score >= 90 ~ "Very Easy",
    flesch_score >= 80 ~ "Easy",
    flesch_score >= 70 ~ "Fairly Easy",
    flesch_score >= 60 ~ "Standard",
    flesch_score >= 50 ~ "Fairly Difficult",
    flesch_score >= 30 ~ "Difficult",
    TRUE ~ "Very Difficult"
  )
  
  return(list(
    condition = condition_name,
    text = text,
    total_words = total_words,
    total_sentences = total_sentences,
    avg_sentence_length = avg_sentence_length,
    avg_word_length = avg_word_length,
    flesch_score = flesch_score,
    readability_category = readability_category,
    cognitive_load_score = cognitive_load_score
  ))
}



# =============================================================================
# UI DEFINITION
# =============================================================================

ui <- fluidPage(
  
  # Title and header
  titlePanel("Cognitive Load Analysis Tool"),
  
  # Main navigation
  tabsetPanel(
    
    # =============================================================================
    # TAB 1: MAIN ANALYSIS
    # =============================================================================
    tabPanel("Main Analysis", 
             
             fluidRow(
               column(12,
                      h3("Baseline Conditions"),
                      p("These are Dan Heath's pizza parlor mission statement examples demonstrating cognitive load differences.")
               )
             ),
             
             fluidRow(
               column(6,
                      h4("Committee-Revised Mission"),
                      textAreaInput("baseline_committee_input", 
                                  label = NULL,
                                  value = baseline_committee,
                                  rows = 3,
                                  resize = "vertical")
               ),
               column(6,
                      h4("Original Mission"),
                      textAreaInput("baseline_original_input", 
                                  label = NULL,
                                  value = baseline_original,
                                  rows = 3,
                                  resize = "vertical")
               )
             ),
             
             hr(),
             
             fluidRow(
               column(12,
                      h3("New Text Input"),
                      p("Enter new text below to compare against the baseline conditions.")
               )
             ),
             
             fluidRow(
               column(6,
                      h4("New Text A"),
                      textAreaInput("new_text_a", 
                                  label = NULL,
                                  placeholder = "Enter your new text here...",
                                  rows = 4,
                                  resize = "vertical")
               ),
               column(6,
                      h4("New Text B"),
                      textAreaInput("new_text_b", 
                                  label = NULL,
                                  placeholder = "Enter your new text here...",
                                  rows = 4,
                                  resize = "vertical")
               )
             ),
             
             fluidRow(
               column(12,
                      actionButton("analyze_btn", "Analyze Cognitive Load", 
                                 class = "btn-primary btn-lg")
               )
             ),
             
             hr(),
             
             fluidRow(
               column(12,
                      h3("Analysis Results"),
                      p("Comprehensive cognitive load metrics for all conditions:"),
                      DTOutput("results_table")
               )
             ),
             
             fluidRow(
               column(12,
                      h3("Key Differences"),
                      p("Comparison of differences between conditions:"),
                      DTOutput("differences_table")
               )
             )
    ),
    

    
    # =============================================================================
    # TAB 3: ABOUT
    # =============================================================================
    tabPanel("About",
             
             fluidRow(
               column(12,
                      h3("About This Tool"),
                      p("This cognitive load analysis tool helps researchers and content creators assess the readability and cognitive complexity of text conditions."),
                      
                      h4("Metrics Calculated:"),
                      tags$ul(
                        tags$li("Word count and sentence count"),
                        tags$li("Average sentence length"),
                        tags$li("Average word length"),
                        tags$li("Flesch Reading Ease score"),
                        tags$li("Custom cognitive load score"),
                        tags$li("Readability categories")
                      ),
                      
                      h4("Cognitive Load Score Formula:"),
                      p("(Average Sentence Length × 0.4) + (Average Word Length × 0.3) + ((100 - Flesch Score) × 0.3)"),
                      
                      h4("Important Notes:"),
                      tags$ul(
                        tags$li("Focus on relative differences rather than absolute scores"),
                        tags$li("Equalize readability and cognitive load to avoid systematic bias"),
                        tags$li("This tool uses the quanteda and quanteda.textstats R packages for text analysis and readability calculations"),
                        tags$li("This app was created with the help of ", tags$a(href="https://cursor.com/agents", target="_blank", "Cursor"), " AI coding assistant")
                      ),
                      
                      h4("References:"),
                      tags$div(
                        style = "margin-left: 20px; text-indent: -20px; padding-left: 20px;",
                        tags$p("Benoit, K., Watanabe, K., Wang, H., Nulty, P., Obeng, A., Müller, S., & Matsuo, A. (2018). quanteda: An R package for the quantitative analysis of textual data. ", tags$em("Journal of Open Source Software"), ",", tags$em("3"), "(30), 774."),
                        tags$p("Flesch, R. (1948). A new readability yardstick. ", tags$em("Journal of Applied Psychology"), ",", tags$em("32"), "(3), 221-233."),
                        tags$p("Graesser, A. C., McNamara, D. S., & Kulikowich, J. M. (2011). Coh-Metrix: Providing multilevel analyses of text characteristics. ", tags$em("Educational Researcher"), ",", tags$em("40"), "(5), 223-234."),
                        tags$p("Kintsch, W., & van Dijk, T. A. (1978). Toward a model of text comprehension and production. ", tags$em("Psychological Review"), ",", tags$em("85"), "(5), 363-394."),
                        tags$p("Mayer, R. E. (2005). Cognitive theory of multimedia learning. ", tags$em("The Cambridge Handbook of Multimedia Learning"), ", 31-48."),
                        tags$p("Sweller, J. (1988). Cognitive load during problem solving: Effects on learning. ", tags$em("Cognitive Science"), ", ", tags$em("12"), "(2), 257-285.")
                      )
               )
             )
    )
  )
)

# =============================================================================
# SERVER LOGIC
# =============================================================================

server <- function(input, output, session) {
  
  # No longer needed since we're using textAreaInput
  # The baseline texts are now directly editable in the UI
  
  # Main analysis reactive
  analysis_results <- reactiveVal(NULL)
  differences_results <- reactiveVal(NULL)
  
  # Analyze button handler
  observeEvent(input$analyze_btn, {
    
    # Calculate metrics for all conditions
    baseline_committee_metrics <- calculate_comprehensive_metrics(input$baseline_committee_input, "Committee Mission")
    baseline_original_metrics <- calculate_comprehensive_metrics(input$baseline_original_input, "Original Mission")
    
    new_text_a_metrics <- NULL
    new_text_b_metrics <- NULL
    
    if (input$new_text_a != "") {
      new_text_a_metrics <- calculate_comprehensive_metrics(input$new_text_a, "New Text A")
    }
    
    if (input$new_text_b != "") {
      new_text_b_metrics <- calculate_comprehensive_metrics(input$new_text_b, "New Text B")
    }
    
    # Combine all metrics
    all_metrics <- list(baseline_committee_metrics, baseline_original_metrics)
    if (!is.null(new_text_a_metrics)) all_metrics <- c(all_metrics, list(new_text_a_metrics))
    if (!is.null(new_text_b_metrics)) all_metrics <- c(all_metrics, list(new_text_b_metrics))
    
    # Remove NULL entries
    all_metrics <- all_metrics[!sapply(all_metrics, is.null)]
    
    # Create results dataframe
    results_df <- do.call(rbind, lapply(all_metrics, function(m) {
      data.frame(
        Condition = m$condition,
        Total_Words = m$total_words,
        Total_Sentences = m$total_sentences,
        Avg_Sentence_Length = round(m$avg_sentence_length, 1),
        Avg_Word_Length = round(m$avg_word_length, 1),
        Flesch_Score = round(m$flesch_score, 1),
        Readability_Category = m$readability_category,
        Cognitive_Load_Score = round(m$cognitive_load_score, 1),
        stringsAsFactors = FALSE
      )
    }))
    
    analysis_results(results_df)
    
    # Calculate differences if we have multiple conditions
    if (nrow(results_df) >= 2) {
      differences_list <- list()
      
      for (i in 2:nrow(results_df)) {
        baseline <- results_df[1, ]
        current <- results_df[i, ]
        
        diff_df <- data.frame(
          Comparison = paste(baseline$Condition, "vs", current$Condition),
          Flesch_Difference = round(abs(baseline$Flesch_Score - current$Flesch_Score), 1),
          Word_Difference = abs(baseline$Total_Words - current$Total_Words),
          Cognitive_Load_Difference = round(abs(baseline$Cognitive_Load_Score - current$Cognitive_Load_Score), 1),
          stringsAsFactors = FALSE
        )
        
        differences_list[[i-1]] <- diff_df
      }
      
      differences_df <- do.call(rbind, differences_list)
      differences_results(differences_df)
    }
  })
  
  # Display results table
  output$results_table <- renderDT({
    req(analysis_results())
    
    datatable(analysis_results(),
              options = list(
                pageLength = 10,
                scrollX = TRUE,
                dom = 't'
              ),
              rownames = FALSE)
  })
  
  # Display differences table
  output$differences_table <- renderDT({
    req(differences_results())
    
    datatable(differences_results(),
              options = list(
                pageLength = 10,
                scrollX = TRUE,
                dom = 't'
              ),
              rownames = FALSE)
  })
  

}

# =============================================================================
# RUN THE APP
# =============================================================================

shinyApp(ui = ui, server = server) 