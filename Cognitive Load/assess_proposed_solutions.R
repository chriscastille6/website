# Assess Proposed Equalized Solutions
# Accurate metrics for the revised experimental conditions

library(quanteda)
library(quanteda.textstats)
library(dplyr)

# Proposed equalized solutions
christian_revised <- "We are guided by Christian values. We close on Sundays to rest. We honor God in our work. These values guide our company and employees."

non_christian_revised <- "We celebrate diversity in all forms. We welcome different perspectives. We value inclusion and respect. These principles guide our company and employees."

# Function to calculate comprehensive metrics
calculate_metrics <- function(text, condition_name) {
  
  # Create corpus
  corp <- corpus(text)
  
  # Calculate readability
  readability <- textstat_readability(corp, measure = "Flesch")
  
  # Calculate word and sentence statistics
  words <- tokens(corp, what = "word")
  sentences <- tokens(corp, what = "sentence")
  
  total_words <- length(unlist(words))
  total_sentences <- length(unlist(sentences))
  avg_sentence_length <- mean(lengths(sentences))
  avg_word_length <- mean(nchar(unlist(words)))
  
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
  
  # Return results
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

# Analyze both proposed solutions
christian_metrics <- calculate_metrics(christian_revised, "Revised Christian Values")
non_christian_metrics <- calculate_metrics(non_christian_revised, "Revised Non-Christian Values")

# Print detailed results
cat("=== PROPOSED EQUALIZED SOLUTIONS ASSESSMENT ===\n\n")

cat("REVISED CHRISTIAN VALUES:\n")
cat("Text:", christian_metrics$text, "\n")
cat("Total Words:", christian_metrics$total_words, "\n")
cat("Total Sentences:", christian_metrics$total_sentences, "\n")
cat("Average Sentence Length:", round(christian_metrics$avg_sentence_length, 1), "words\n")
cat("Average Word Length:", round(christian_metrics$avg_word_length, 1), "characters\n")
cat("Flesch Score:", round(christian_metrics$flesch_score, 1), "\n")
cat("Readability Category:", christian_metrics$readability_category, "\n")
cat("Cognitive Load Score:", round(christian_metrics$cognitive_load_score, 1), "\n\n")

cat("REVISED NON-CHRISTIAN VALUES:\n")
cat("Text:", non_christian_metrics$text, "\n")
cat("Total Words:", non_christian_metrics$total_words, "\n")
cat("Total Sentences:", non_christian_metrics$total_sentences, "\n")
cat("Average Sentence Length:", round(non_christian_metrics$avg_sentence_length, 1), "words\n")
cat("Average Word Length:", round(non_christian_metrics$avg_word_length, 1), "characters\n")
cat("Flesch Score:", round(non_christian_metrics$flesch_score, 1), "\n")
cat("Readability Category:", non_christian_metrics$readability_category, "\n")
cat("Cognitive Load Score:", round(non_christian_metrics$cognitive_load_score, 1), "\n\n")

# Comparison table
cat("COMPARISON TABLE:\n")
cat("================\n")
cat(sprintf("%-25s %-15s %-15s\n", "Metric", "Christian", "Non-Christian"))
cat(paste(rep("-", 55), collapse = ""), "\n")
cat(sprintf("%-25s %-15s %-15s\n", "Total Words", christian_metrics$total_words, non_christian_metrics$total_words))
cat(sprintf("%-25s %-15s %-15s\n", "Total Sentences", christian_metrics$total_sentences, non_christian_metrics$total_sentences))
cat(sprintf("%-25s %-15s %-15s\n", "Avg Sentence Length", round(christian_metrics$avg_sentence_length, 1), round(non_christian_metrics$avg_sentence_length, 1)))
cat(sprintf("%-25s %-15s %-15s\n", "Avg Word Length", round(christian_metrics$avg_word_length, 1), round(non_christian_metrics$avg_word_length, 1)))
cat(sprintf("%-25s %-15s %-15s\n", "Flesch Score", round(christian_metrics$flesch_score, 1), round(non_christian_metrics$flesch_score, 1)))
cat(sprintf("%-25s %-15s %-15s\n", "Readability Category", christian_metrics$readability_category, non_christian_metrics$readability_category))
cat(sprintf("%-25s %-15s %-15s\n", "Cognitive Load Score", round(christian_metrics$cognitive_load_score, 1), round(non_christian_metrics$cognitive_load_score, 1)))
cat("\n")

# Calculate differences
flesch_difference <- abs(christian_metrics$flesch_score - non_christian_metrics$flesch_score)
word_difference <- abs(christian_metrics$total_words - non_christian_metrics$total_words)
cognitive_load_difference <- abs(christian_metrics$cognitive_load_score - non_christian_metrics$cognitive_load_score)

cat("IMPROVEMENT ASSESSMENT:\n")
cat("=====================\n")
cat("Flesch Score Difference:", round(flesch_difference, 1), "points (vs 35.3 in original)\n")
cat("Word Count Difference:", word_difference, "words (vs 1 in original)\n")
cat("Cognitive Load Difference:", round(cognitive_load_difference, 1), "points (vs 10.9 in original)\n")
cat("Percentage Improvement in Flesch Gap:", round((35.3 - flesch_difference) / 35.3 * 100, 1), "%\n")
cat("Percentage Improvement in Cognitive Load Gap:", round((10.9 - cognitive_load_difference) / 10.9 * 100, 1), "%\n")

# Assessment
cat("\nASSESSMENT:\n")
cat("==========\n")
if(flesch_difference < 10) {
  cat("✅ EXCELLENT: Flesch scores are well-balanced (difference < 10 points)\n")
} else if(flesch_difference < 20) {
  cat("✅ GOOD: Flesch scores are reasonably balanced (difference < 20 points)\n")
} else {
  cat("⚠️ NEEDS IMPROVEMENT: Flesch scores still show significant imbalance\n")
}

if(cognitive_load_difference < 3) {
  cat("✅ EXCELLENT: Cognitive load scores are well-balanced (difference < 3 points)\n")
} else if(cognitive_load_difference < 5) {
  cat("✅ GOOD: Cognitive load scores are reasonably balanced (difference < 5 points)\n")
} else {
  cat("⚠️ NEEDS IMPROVEMENT: Cognitive load scores still show significant imbalance\n")
}

if(word_difference <= 2) {
  cat("✅ EXCELLENT: Word counts are well-balanced (difference ≤ 2 words)\n")
} else {
  cat("⚠️ NEEDS IMPROVEMENT: Word counts show imbalance\n")
} 