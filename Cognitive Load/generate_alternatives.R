# Generate and Assess 30 Alternative Non-Christian Values Conditions
# Find the best empirical option for cognitive load equalization

library(quanteda)
library(quanteda.textstats)
library(dplyr)

# Original Christian Values condition (target to match)
christian_original <- "We are driven by Christian values that honor God in all we do, reflecting His love, grace, and truth. We close on Sundays to observe the Sabbath. We strive to honor God through our work."

# Generate 30 alternative Non-Christian Values conditions
alternatives <- c(
  # Simple vocabulary versions
  "We are driven by inclusive values that welcome all people in all we do, reflecting care, fairness, and kindness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by open values that welcome all people in all we do, reflecting care, fairness, and kindness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by fair values that welcome all people in all we do, reflecting care, fairness, and kindness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  
  # Different structures
  "We celebrate diversity in all forms. We welcome all people with care and fairness. We respect all cultures and backgrounds. We value kindness in all we do.",
  "We value diversity in all forms. We welcome all people with care and fairness. We respect all cultures and backgrounds. We show kindness in all we do.",
  "We support diversity in all forms. We welcome all people with care and fairness. We respect all cultures and backgrounds. We show kindness in all we do.",
  
  # Simplified versions
  "We are driven by fair values that welcome all people, reflecting care and kindness. We celebrate diversity. We respect all people and cultures.",
  "We are driven by open values that welcome all people, reflecting care and kindness. We celebrate diversity. We respect all people and cultures.",
  "We are driven by kind values that welcome all people, reflecting care and fairness. We celebrate diversity. We respect all people and cultures.",
  
  # Different word choices
  "We are driven by caring values that welcome all people in all we do, reflecting fairness and kindness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by kind values that welcome all people in all we do, reflecting fairness and care. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by fair values that welcome all people in all we do, reflecting kindness and care. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  
  # Alternative structures
  "We welcome all people with care and fairness. We celebrate diversity in all forms. We respect all cultures and backgrounds. We show kindness in all we do.",
  "We welcome all people with kindness and fairness. We celebrate diversity in all forms. We respect all cultures and backgrounds. We show care in all we do.",
  "We welcome all people with fairness and care. We celebrate diversity in all forms. We respect all cultures and backgrounds. We show kindness in all we do.",
  
  # Very simple versions
  "We welcome all people. We celebrate diversity. We respect all cultures. We show kindness in all we do.",
  "We welcome all people. We celebrate diversity. We respect all cultures. We show care in all we do.",
  "We welcome all people. We celebrate diversity. We respect all cultures. We show fairness in all we do.",
  
  # Different emphasis
  "We are driven by caring values that welcome all people in all we do, reflecting fairness and kindness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by kind values that welcome all people in all we do, reflecting fairness and care. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by fair values that welcome all people in all we do, reflecting kindness and care. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  
  # Alternative wordings
  "We are driven by open values that welcome all people in all we do, reflecting care and fairness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by caring values that welcome all people in all we do, reflecting kindness and fairness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  "We are driven by kind values that welcome all people in all we do, reflecting care and fairness. We celebrate diversity in all forms. We strive to respect all people and cultures.",
  
  # Different sentence structures
  "We welcome all people with care and fairness. We celebrate diversity in all forms. We respect all cultures and backgrounds. We show kindness in all we do.",
  "We welcome all people with kindness and fairness. We celebrate diversity in all forms. We respect all cultures and backgrounds. We show care in all we do.",
  "We welcome all people with fairness and care. We celebrate diversity in all forms. We respect all cultures and backgrounds. We show kindness in all we do.",
  
  # Minimal versions
  "We welcome all people. We celebrate diversity. We respect all cultures. We show kindness in all we do.",
  "We welcome all people. We celebrate diversity. We respect all cultures. We show care in all we do.",
  "We welcome all people. We celebrate diversity. We respect all cultures. We show fairness in all we do."
)

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

# Calculate metrics for original Christian Values condition
christian_metrics <- calculate_metrics(christian_original, "Original Christian Values")

# Calculate metrics for all alternatives
results <- data.frame()

for(i in 1:length(alternatives)) {
  alt_metrics <- calculate_metrics(alternatives[i], paste0("Alternative ", i))
  
  # Calculate differences from Christian condition
  flesch_diff <- abs(alt_metrics$flesch_score - christian_metrics$flesch_score)
  word_diff <- abs(alt_metrics$total_words - christian_metrics$total_words)
  cognitive_load_diff <- abs(alt_metrics$cognitive_load_score - christian_metrics$cognitive_load_score)
  
  # Calculate overall balance score (lower is better)
  balance_score <- flesch_diff + (word_diff * 2) + (cognitive_load_diff * 3)
  
  results <- rbind(results, data.frame(
    Alternative = i,
    Text = alt_metrics$text,
    Words = alt_metrics$total_words,
    Sentences = alt_metrics$total_sentences,
    Avg_Sentence_Length = round(alt_metrics$avg_sentence_length, 1),
    Avg_Word_Length = round(alt_metrics$avg_word_length, 1),
    Flesch_Score = round(alt_metrics$flesch_score, 1),
    Readability_Category = alt_metrics$readability_category,
    Cognitive_Load_Score = round(alt_metrics$cognitive_load_score, 1),
    Flesch_Difference = round(flesch_diff, 1),
    Word_Difference = word_diff,
    Cognitive_Load_Difference = round(cognitive_load_diff, 1),
    Balance_Score = round(balance_score, 1)
  ))
}

# Sort by balance score (best first)
results <- results %>% arrange(Balance_Score)

# Print results
cat("=== 30 ALTERNATIVE NON-CHRISTIAN VALUES CONDITIONS ===\n\n")

cat("ORIGINAL CHRISTIAN VALUES (TARGET):\n")
cat("Text:", christian_metrics$text, "\n")
cat("Words:", christian_metrics$total_words, "\n")
cat("Flesch Score:", round(christian_metrics$flesch_score, 1), "\n")
cat("Cognitive Load Score:", round(christian_metrics$cognitive_load_score, 1), "\n\n")

cat("TOP 10 BEST ALTERNATIVES (Ranked by Balance Score):\n")
cat("==================================================\n\n")

for(i in 1:10) {
  cat("RANK", i, "- Alternative", results$Alternative[i], "\n")
  cat("Text:", results$Text[i], "\n")
  cat("Words:", results$Words[i], "| Flesch:", results$Flesch_Score[i], "| Cognitive Load:", results$Cognitive_Load_Score[i], "\n")
  cat("Differences - Flesch:", results$Flesch_Difference[i], "| Words:", results$Word_Difference[i], "| Cognitive Load:", results$Cognitive_Load_Difference[i], "\n")
  cat("Balance Score:", results$Balance_Score[i], "\n")
  cat("---\n\n")
}

# Save complete results to CSV
write.csv(results, "alternative_conditions_analysis.csv", row.names = FALSE)

cat("Complete analysis saved to 'alternative_conditions_analysis.csv'\n")
cat("Total alternatives analyzed:", nrow(results), "\n") 