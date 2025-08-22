# Cognitive Load Analysis: Bryson's Conditions (Simplified Version)
# Reproducible analysis of cognitive load between Christian Values and Non-Christian Values conditions
# Author: [Your Name]
# Date: [Current Date]

# Load required libraries
library(quanteda)
library(quanteda.textstats)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)

# Set seed for reproducibility
set.seed(123)

# Define the two experimental conditions - isolating unique content only
christian_values_text <- "We are driven by Christian values that honor God in all we do, reflecting His love, grace, and truth. We close on Sundays to observe the Sabbath. We strive to honor God through our work."

non_christian_values_text <- "We are driven by inclusive values that foster open-mindedness in all we do, reflecting love, fairness, and understanding. We celebrate diversity in all forms. We strive to respect all backgrounds, identities and cultures."

# Store texts in a list for analysis
texts <- list(
  christian_values = christian_values_text,
  non_christian_values = non_christian_values_text
)

# Function to calculate readability metrics using quanteda
calculate_readability_metrics <- function(text) {
  
  # Create corpus
  corp <- corpus(text)
  
  # Tokenize
  toks <- tokens(corp)
  
  # Calculate basic statistics
  basic_stats <- textstat_summary(corp)
  
  # Calculate readability scores
  readability_scores <- textstat_readability(corp, 
                                            measure = c("Flesch", "Flesch.Kincaid", 
                                                       "SMOG", "ARI", "Coleman.Liau"))
  
  # Calculate word and sentence statistics
  sentences <- tokens(corp, what = "sentence")
  words <- tokens(corp, what = "word")
  
  avg_sentence_length <- mean(lengths(sentences))
  avg_word_length <- mean(nchar(unlist(words)))
  total_words <- length(unlist(words))
  
  # Calculate syllables (approximate)
  word_chars <- unlist(words)
  syllables <- sum(sapply(word_chars, function(x) {
    x <- tolower(x)
    x <- gsub("[^a-z]", "", x)
    if(nchar(x) <= 3) return(1)
    x <- gsub("(?:[^laeiouy]es|ed|[^laeiouy]e)$", "", x)
    x <- gsub("^y", "", x)
    length(gregexpr("[aeiouy]", x)[[1]])
  }))
  
  return(list(
    readability = readability_scores,
    basic_stats = basic_stats,
    avg_sentence_length = avg_sentence_length,
    avg_word_length = avg_word_length,
    total_words = total_words,
    syllables = syllables
  ))
}

# Function to assess cognitive load
assess_cognitive_load <- function(text) {
  
  # Calculate readability metrics
  metrics <- calculate_readability_metrics(text)
  
  # Create cognitive load assessment
  cognitive_load <- list()
  
  # 1. Syntactic Complexity
  cognitive_load$syntactic_complexity <- list(
    avg_sentence_length = metrics$avg_sentence_length,
    sentence_complexity = case_when(
      metrics$avg_sentence_length < 10 ~ "Low",
      metrics$avg_sentence_length < 20 ~ "Medium", 
      TRUE ~ "High"
    )
  )
  
  # 2. Lexical Complexity
  cognitive_load$lexical_complexity <- list(
    avg_word_length = metrics$avg_word_length,
    word_complexity = case_when(
      metrics$avg_word_length < 4.5 ~ "Low",
      metrics$avg_word_length < 5.5 ~ "Medium",
      TRUE ~ "High"
    )
  )
  
  # 3. Readability Level
  flesch_score <- metrics$readability$Flesch
  cognitive_load$readability_level <- list(
    flesch_score = flesch_score,
    readability_category = case_when(
      flesch_score >= 90 ~ "Very Easy",
      flesch_score >= 80 ~ "Easy", 
      flesch_score >= 70 ~ "Fairly Easy",
      flesch_score >= 60 ~ "Standard",
      flesch_score >= 50 ~ "Fairly Difficult",
      flesch_score >= 30 ~ "Difficult",
      TRUE ~ "Very Difficult"
    )
  )
  
  # 4. Overall Cognitive Load Assessment
  cognitive_load$overall_assessment <- list(
    total_score = (metrics$avg_sentence_length * 0.4) + (metrics$avg_word_length * 0.3) + ((100 - flesch_score) * 0.3),
    cognitive_load_level = case_when(
      (metrics$avg_sentence_length * 0.4) + (metrics$avg_word_length * 0.3) + ((100 - flesch_score) * 0.3) < 30 ~ "Low",
      (metrics$avg_sentence_length * 0.4) + (metrics$avg_word_length * 0.3) + ((100 - flesch_score) * 0.3) < 50 ~ "Medium",
      TRUE ~ "High"
    )
  )
  
  return(list(metrics = metrics, cognitive_load = cognitive_load))
}

# Function to compare the two conditions
compare_conditions <- function(texts) {
  
  results <- list()
  
  for(i in 1:length(texts)) {
    results[[names(texts)[i]]] <- assess_cognitive_load(texts[[i]])
  }
  
  # Create comparison dataframe
  comparison_df <- data.frame(
    Condition = names(texts),
    Flesch_Score = sapply(results, function(x) x$cognitive_load$readability_level$flesch_score),
    Readability_Category = sapply(results, function(x) x$cognitive_load$readability_level$readability_category),
    Avg_Sentence_Length = sapply(results, function(x) x$cognitive_load$syntactic_complexity$avg_sentence_length),
    Avg_Word_Length = sapply(results, function(x) x$cognitive_load$lexical_complexity$avg_word_length),
    Total_Words = sapply(results, function(x) x$metrics$total_words),
    Cognitive_Load_Score = sapply(results, function(x) x$cognitive_load$overall_assessment$total_score),
    Cognitive_Load_Level = sapply(results, function(x) x$cognitive_load$overall_assessment$cognitive_load_level)
  )
  
  return(list(detailed_results = results, comparison = comparison_df))
}

# Function to create visualizations
create_visualizations <- function(comparison_results) {
  
  # 1. Readability comparison
  p1 <- ggplot(comparison_results$comparison, aes(x = Condition, y = Flesch_Score, fill = Readability_Category)) +
    geom_bar(stat = "identity") +
    geom_hline(yintercept = 60, linetype = "dashed", color = "red") +
    labs(title = "Readability Scores by Condition",
         subtitle = "Dashed line indicates 'Standard' readability threshold",
         x = "Condition", y = "Flesch Reading Ease Score",
         fill = "Readability Category") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # 2. Cognitive load comparison
  p2 <- ggplot(comparison_results$comparison, aes(x = Condition, y = Cognitive_Load_Score, fill = Cognitive_Load_Level)) +
    geom_bar(stat = "identity") +
    labs(title = "Cognitive Load Assessment by Condition",
         x = "Condition", y = "Cognitive Load Score",
         fill = "Cognitive Load Level") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # 3. Scatter plot of sentence vs word complexity
  p3 <- ggplot(comparison_results$comparison, aes(x = Avg_Sentence_Length, y = Avg_Word_Length, 
                                                  color = Cognitive_Load_Level, size = Total_Words)) +
    geom_point() +
    geom_text(aes(label = Condition), vjust = -1, size = 4) +
    labs(title = "Text Complexity: Sentence Length vs Word Length",
         x = "Average Sentence Length (words)", 
         y = "Average Word Length (characters)",
         color = "Cognitive Load Level",
         size = "Total Words") +
    theme_minimal()
  
  return(list(readability_plot = p1, cognitive_load_plot = p2, complexity_scatter = p3))
}

# Function to create a comprehensive report
create_report <- function(texts) {
  
  # Compare conditions
  comparison <- compare_conditions(texts)
  
  # Create visualizations
  plots <- create_visualizations(comparison)
  
  # Create summary table
  summary_table <- comparison$comparison %>%
    arrange(Cognitive_Load_Score) %>%
    select(Condition, Flesch_Score, Readability_Category, 
           Avg_Sentence_Length, Avg_Word_Length, Cognitive_Load_Level)
  
  # Print report
  cat("=== COGNITIVE LOAD ANALYSIS: BRYSON'S CONDITIONS ===\n\n")
  
  cat("EXPERIMENTAL CONDITIONS:\n")
  cat("------------------------\n")
  cat("1. Christian Values Condition:\n")
  cat("   ", texts$christian_values, "\n\n")
  cat("2. Non-Christian Values Condition:\n")
  cat("   ", texts$non_christian_values, "\n\n")
  
  cat("SUMMARY TABLE:\n")
  cat("--------------\n")
  print(kable(summary_table, format = "html", digits = 2) %>%
          kable_styling(bootstrap_options = c("striped", "hover")))
  
  cat("\nDETAILED ANALYSIS:\n")
  cat("-----------------\n")
  
  # Detailed analysis for each condition
  for(i in 1:length(texts)) {
    condition_name <- names(texts)[i]
    cat("\n", toupper(condition_name), "CONDITION:\n")
    cat("Text:", texts[[i]], "\n")
    cat("Length:", nchar(texts[[i]]), "characters\n")
    cat("Words:", comparison$comparison$Total_Words[i], "\n")
    cat("Flesch Score:", round(comparison$comparison$Flesch_Score[i], 1), "\n")
    cat("Readability:", comparison$comparison$Readability_Category[i], "\n")
    cat("Avg Sentence Length:", round(comparison$comparison$Avg_Sentence_Length[i], 1), "words\n")
    cat("Avg Word Length:", round(comparison$comparison$Avg_Word_Length[i], 1), "characters\n")
    cat("Cognitive Load Level:", comparison$comparison$Cognitive_Load_Level[i], "\n")
  }
  
  cat("\nCOMPARATIVE FINDINGS:\n")
  cat("--------------------\n")
  
  # Find which condition has higher cognitive load
  higher_load <- comparison$comparison[which.max(comparison$comparison$Cognitive_Load_Score), ]
  lower_load <- comparison$comparison[which.min(comparison$comparison$Cognitive_Load_Score), ]
  
  cat("Higher cognitive load condition:", higher_load$Condition, "\n")
  cat("Lower cognitive load condition:", lower_load$Condition, "\n")
  cat("Difference in cognitive load score:", round(higher_load$Cognitive_Load_Score - lower_load$Cognitive_Load_Score, 1), "\n")
  
  # Statistical significance note
  cat("\nNOTE: This analysis provides descriptive statistics only.\n")
  cat("For inferential statistics, consider running appropriate statistical tests\n")
  cat("with a larger sample size and control for confounding variables.\n")
  
  return(list(comparison = comparison, plots = plots, summary_table = summary_table))
}

# Function to save results for reproducibility
save_results <- function(results, filename = "cognitive_load_results.RData") {
  save(results, file = filename)
  cat("Results saved to:", filename, "\n")
}

# Function to export results to CSV
export_to_csv <- function(results, filename = "cognitive_load_results.csv") {
  write.csv(results$comparison$comparison, file = filename, row.names = FALSE)
  cat("Results exported to:", filename, "\n")
}

# Main analysis execution
cat("Starting Cognitive Load Analysis...\n")
cat("===================================\n\n")

# Run the analysis
results <- create_report(texts)

# Save results for reproducibility
save_results(results)

# Export to CSV
export_to_csv(results)

# Display plots
cat("\nGenerating visualizations...\n")
cat("============================\n\n")

# Display the plots
print(results$plots$readability_plot)
print(results$plots$cognitive_load_plot)
print(results$plots$complexity_scatter)

cat("\nAnalysis complete! Results have been saved and exported.\n")
cat("=======================================================\n") 