# Cognitive Load Analysis: Dan Heath's Pizza Parlor Examples
# Analysis of mission statement cognitive load differences
# Author: Christopher M. Castille
# Date: December 2024

# Load required libraries
library(quanteda)
library(quanteda.textstats)
library(dplyr)
library(ggplot2)

# Set seed for reproducibility
set.seed(123)

# Define Heath's pizza parlor mission statement examples
committee_mission <- "Our mission is to present with integrity the highest-quality entertainment solutions to families."
original_mission <- "Our mission is to serve the tastiest damn pizza in Wake County."

# Store texts in a list for analysis
texts <- list(
  "Committee Mission" = committee_mission,
  "Original Mission" = original_mission
)

# Function to calculate comprehensive metrics
calculate_comprehensive_metrics <- function(text, condition_name) {
  
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
  
  # Determine cognitive load level
  cognitive_load_level <- case_when(
    cognitive_load_score < 30 ~ "Low",
    cognitive_load_score < 50 ~ "Medium",
    TRUE ~ "High"
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
    cognitive_load_score = cognitive_load_score,
    cognitive_load_level = cognitive_load_level
  ))
}

# Calculate metrics for both conditions
committee_metrics <- calculate_comprehensive_metrics(committee_mission, "Committee Mission")
original_metrics <- calculate_comprehensive_metrics(original_mission, "Original Mission")

# Create comparison dataframe
comparison_data <- data.frame(
  Condition = c(committee_metrics$condition, original_metrics$condition),
  Text = c(committee_metrics$text, original_metrics$text),
  Total_Words = c(committee_metrics$total_words, original_metrics$total_words),
  Total_Sentences = c(committee_metrics$total_sentences, original_metrics$total_sentences),
  Avg_Sentence_Length = round(c(committee_metrics$avg_sentence_length, original_metrics$avg_sentence_length), 1),
  Avg_Word_Length = round(c(committee_metrics$avg_word_length, original_metrics$avg_word_length), 1),
  Flesch_Score = round(c(committee_metrics$flesch_score, original_metrics$flesch_score), 1),
  Readability_Category = c(committee_metrics$readability_category, original_metrics$readability_category),
  Cognitive_Load_Score = round(c(committee_metrics$cognitive_load_score, original_metrics$cognitive_load_score), 1),
  Cognitive_Load_Level = c(committee_metrics$cognitive_load_level, original_metrics$cognitive_load_level)
)

# Print analysis results
cat("HEATH'S PIZZA PARLOR MISSION STATEMENT ANALYSIS:\n")
cat("================================================\n\n")

cat("COMMITTEE-REVISED MISSION:\n")
cat("Text:", committee_metrics$text, "\n")
cat("Total Words:", committee_metrics$total_words, "\n")
cat("Total Sentences:", committee_metrics$total_sentences, "\n")
cat("Average Sentence Length:", round(committee_metrics$avg_sentence_length, 1), "words\n")
cat("Average Word Length:", round(committee_metrics$avg_word_length, 1), "characters\n")
cat("Flesch Score:", round(committee_metrics$flesch_score, 1), "\n")
cat("Readability Category:", committee_metrics$readability_category, "\n")
cat("Cognitive Load Score:", round(committee_metrics$cognitive_load_score, 1), "\n")
cat("Cognitive Load Level:", committee_metrics$cognitive_load_level, "\n\n")

cat("ORIGINAL MISSION:\n")
cat("Text:", original_metrics$text, "\n")
cat("Total Words:", original_metrics$total_words, "\n")
cat("Total Sentences:", original_metrics$total_sentences, "\n")
cat("Average Sentence Length:", round(original_metrics$avg_sentence_length, 1), "words\n")
cat("Average Word Length:", round(original_metrics$avg_word_length, 1), "characters\n")
cat("Flesch Score:", round(original_metrics$flesch_score, 1), "\n")
cat("Readability Category:", original_metrics$readability_category, "\n")
cat("Cognitive Load Score:", round(original_metrics$cognitive_load_score, 1), "\n")
cat("Cognitive Load Level:", original_metrics$cognitive_load_level, "\n\n")

# Calculate differences
flesch_difference <- abs(committee_metrics$flesch_score - original_metrics$flesch_score)
word_difference <- abs(committee_metrics$total_words - original_metrics$total_words)
cognitive_load_difference <- abs(committee_metrics$cognitive_load_score - original_metrics$cognitive_load_score)

cat("KEY DIFFERENCES:\n")
cat("Flesch Score Difference:", round(flesch_difference, 1), "points\n")
cat("Word Count Difference:", word_difference, "words\n")
cat("Cognitive Load Difference:", round(cognitive_load_difference, 1), "points\n\n")

# Create visualizations
# Readability comparison plot
readability_plot <- ggplot(comparison_data, aes(x = Condition, y = Flesch_Score, fill = Condition)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  geom_text(aes(label = Flesch_Score), vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("Committee Mission" = "#e74c3c", "Original Mission" = "#3498db")) +
  labs(title = "Heath's Pizza Parlor: Flesch Reading Ease Scores",
       y = "Flesch Score",
       x = "Mission Statement Version") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

ggsave("heath_readability_comparison.png", readability_plot, width = 8, height = 6, dpi = 300)

# Cognitive load comparison plot
cognitive_load_plot <- ggplot(comparison_data, aes(x = Condition, y = Cognitive_Load_Score, fill = Condition)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  geom_text(aes(label = Cognitive_Load_Score), vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("Committee Mission" = "#e74c3c", "Original Mission" = "#3498db")) +
  labs(title = "Heath's Pizza Parlor: Cognitive Load Scores",
       y = "Cognitive Load Score",
       x = "Mission Statement Version") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

ggsave("heath_cognitive_load_comparison.png", cognitive_load_plot, width = 8, height = 6, dpi = 300)

# Print results
print(comparison_data)

cat("Analysis complete! Charts saved as:\n")
cat("- heath_readability_comparison.png\n")
cat("- heath_cognitive_load_comparison.png\n")

