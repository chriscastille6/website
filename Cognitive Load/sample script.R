# Text Cognitive Load Analysis
# Comprehensive assessment of text complexity and readability

# Load required libraries
library(koRpus)
library(quanteda)
library(quanteda.textstats)
library(koRpus.lang.en)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)

# Function to calculate comprehensive readability metrics
calculate_readability_metrics <- function(text) {
  
  # Tokenize and analyze text using koRpus
  tokenized <- tokenize(text, lang = "en")
  
  # Calculate various readability indices
  readability_scores <- readability(tokenized, 
                                    index = c("Flesch", "Flesch.Kincaid", 
                                              "Gunning.Fog", "SMOG", 
                                              "ARI", "Coleman.Liau", 
                                              "Dale.Chall", "Linsear.Write"))
  
  # Extract basic text statistics
  basic_stats <- basic.tagged(tokenized)
  
  # Calculate additional complexity measures
  word_length <- mean(nchar(tokenized$token[tokenized$token != ""]))
  sentence_length <- mean(basic_stats$sentences$words)
  
  # Syllable count (approximate)
  syllables <- sum(sapply(tokenized$token, function(x) {
    if(x == "") return(0)
    x <- tolower(x)
    x <- gsub("[^a-z]", "", x)
    if(nchar(x) <= 3) return(1)
    x <- gsub("(?:[^laeiouy]es|ed|[^laeiouy]e)$", "", x)
    x <- gsub("^y", "", x)
    length(gregexpr("[aeiouy]", x)[[1]])
  }))
  
  # Return comprehensive results
  return(list(
    readability = readability_scores,
    basic_stats = basic_stats,
    word_length = word_length,
    sentence_length = sentence_length,
    syllables = syllables,
    total_words = length(tokenized$token[tokenized$token != ""])
  ))
}

# Function to assess cognitive load using multiple dimensions
assess_cognitive_load <- function(text) {
  
  # Calculate readability metrics
  metrics <- calculate_readability_metrics(text)
  
  # Create cognitive load assessment
  cognitive_load <- list()
  
  # 1. Syntactic Complexity
  cognitive_load$syntactic_complexity <- list(
    avg_sentence_length = metrics$sentence_length,
    sentence_complexity = case_when(
      metrics$sentence_length < 10 ~ "Low",
      metrics$sentence_length < 20 ~ "Medium", 
      TRUE ~ "High"
    )
  )
  
  # 2. Lexical Complexity
  cognitive_load$lexical_complexity <- list(
    avg_word_length = metrics$word_length,
    word_complexity = case_when(
      metrics$word_length < 4.5 ~ "Low",
      metrics$word_length < 5.5 ~ "Medium",
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
    total_score = (metrics$sentence_length * 0.4) + (metrics$word_length * 0.3) + ((100 - flesch_score) * 0.3),
    cognitive_load_level = case_when(
      (metrics$sentence_length * 0.4) + (metrics$word_length * 0.3) + ((100 - flesch_score) * 0.3) < 30 ~ "Low",
      (metrics$sentence_length * 0.4) + (metrics$word_length * 0.3) + ((100 - flesch_score) * 0.3) < 50 ~ "Medium",
      TRUE ~ "High"
    )
  )
  
  return(list(metrics = metrics, cognitive_load = cognitive_load))
}

# Function to analyze multiple texts and compare
compare_texts_cognitive_load <- function(text_list, text_names = NULL) {
  
  if(is.null(text_names)) {
    text_names <- paste0("Text_", 1:length(text_list))
  }
  
  results <- list()
  
  for(i in 1:length(text_list)) {
    results[[text_names[i]]] <- assess_cognitive_load(text_list[[i]])
  }
  
  # Create comparison dataframe
  comparison_df <- data.frame(
    Text_Name = text_names,
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
create_cognitive_load_visualizations <- function(comparison_results) {
  
  # 1. Readability comparison
  p1 <- ggplot(comparison_results$comparison, aes(x = Text_Name, y = Flesch_Score, fill = Readability_Category)) +
    geom_bar(stat = "identity") +
    geom_hline(yintercept = 60, linetype = "dashed", color = "red") +
    labs(title = "Readability Scores by Text",
         subtitle = "Dashed line indicates 'Standard' readability threshold",
         x = "Text", y = "Flesch Reading Ease Score",
         fill = "Readability Category") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # 2. Cognitive load comparison
  p2 <- ggplot(comparison_results$comparison, aes(x = Text_Name, y = Cognitive_Load_Score, fill = Cognitive_Load_Level)) +
    geom_bar(stat = "identity") +
    labs(title = "Cognitive Load Assessment by Text",
         x = "Text", y = "Cognitive Load Score",
         fill = "Cognitive Load Level") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # 3. Scatter plot of sentence vs word complexity
  p3 <- ggplot(comparison_results$comparison, aes(x = Avg_Sentence_Length, y = Avg_Word_Length, 
                                                  color = Cognitive_Load_Level, size = Total_Words)) +
    geom_point() +
    geom_text(aes(label = Text_Name), vjust = -1, size = 3) +
    labs(title = "Text Complexity: Sentence Length vs Word Length",
         x = "Average Sentence Length (words)", 
         y = "Average Word Length (characters)",
         color = "Cognitive Load Level",
         size = "Total Words") +
    theme_minimal()
  
  return(list(readability_plot = p1, cognitive_load_plot = p2, complexity_scatter = p3))
}

# Example usage function
analyze_text_cognitive_load <- function(text, text_name = "Sample Text") {
  
  cat("=== COGNITIVE LOAD ANALYSIS ===\n\n")
  cat("Text:", text_name, "\n")
  cat("Length:", nchar(text), "characters\n\n")
  
  # Perform analysis
  analysis <- assess_cognitive_load(text)
  
  # Print results
  cat("READABILITY METRICS:\n")
  cat("--------------------\n")
  cat("Flesch Reading Ease Score:", round(analysis$cognitive_load$readability_level$flesch_score, 1), "\n")
  cat("Readability Category:", analysis$cognitive_load$readability_level$readability_category, "\n")
  cat("Average Sentence Length:", round(analysis$cognitive_load$syntactic_complexity$avg_sentence_length, 1), "words\n")
  cat("Average Word Length:", round(analysis$cognitive_load$lexical_complexity$avg_word_length, 1), "characters\n")
  cat("Total Words:", analysis$metrics$total_words, "\n\n")
  
  cat("COGNITIVE LOAD ASSESSMENT:\n")
  cat("-------------------------\n")
  cat("Syntactic Complexity:", analysis$cognitive_load$syntactic_complexity$sentence_complexity, "\n")
  cat("Lexical Complexity:", analysis$cognitive_load$lexical_complexity$word_complexity, "\n")
  cat("Overall Cognitive Load Score:", round(analysis$cognitive_load$overall_assessment$total_score, 1), "\n")
  cat("Cognitive Load Level:", analysis$cognitive_load$overall_assessment$cognitive_load_level, "\n\n")
  
  # Print detailed readability scores
  cat("DETAILED READABILITY SCORES:\n")
  cat("----------------------------\n")
  print(analysis$metrics$readability)
  
  return(analysis)
}

# Function to create a summary report
create_cognitive_load_report <- function(texts, text_names = NULL) {
  
  if(is.null(text_names)) {
    text_names <- paste0("Text_", 1:length(texts))
  }
  
  # Compare all texts
  comparison <- compare_texts_cognitive_load(texts, text_names)
  
  # Create visualizations
  plots <- create_cognitive_load_visualizations(comparison)
  
  # Create summary table
  summary_table <- comparison$comparison %>%
    arrange(Cognitive_Load_Score) %>%
    select(Text_Name, Flesch_Score, Readability_Category, 
           Avg_Sentence_Length, Avg_Word_Length, Cognitive_Load_Level)
  
  # Print report
  cat("=== COGNITIVE LOAD ANALYSIS REPORT ===\n\n")
  
  cat("SUMMARY TABLE:\n")
  cat("--------------\n")
  print(kable(summary_table, format = "html", digits = 2) %>%
          kable_styling(bootstrap_options = c("striped", "hover")))
  
  cat("\nRECOMMENDATIONS:\n")
  cat("----------------\n")
  
  # Find the most complex text
  most_complex <- comparison$comparison[which.max(comparison$comparison$Cognitive_Load_Score), ]
  least_complex <- comparison$comparison[which.min(comparison$comparison$Cognitive_Load_Score), ]
  
  cat("Most cognitively demanding text:", most_complex$Text_Name, "\n")
  cat("Least cognitively demanding text:", least_complex$Text_Name, "\n\n")
  
  # Provide recommendations
  cat("GENERAL RECOMMENDATIONS:\n")
  cat("- Texts with Flesch scores below 60 may be difficult for general audiences\n")
  cat("- Average sentence length above 20 words increases cognitive load\n")
  cat("- Average word length above 5.5 characters indicates complex vocabulary\n")
  cat("- Consider simplifying texts with 'High' cognitive load levels\n")
  
  return(list(comparison = comparison, plots = plots, summary_table = summary_table))
}

# Example usage
if(FALSE) {
  # Sample texts for demonstration
  sample_texts <- list(
    simple = "The cat sat on the mat. It was a sunny day. The cat enjoyed the warmth.",
    moderate = "The feline creature positioned itself upon the woven floor covering. Meteorological conditions were characterized by abundant solar radiation. The domesticated animal derived pleasure from the thermal energy.",
    complex = "The domesticated feline specimen strategically positioned its anatomical structure upon the intricately woven textile floor covering. The prevailing meteorological conditions were characterized by an abundance of solar radiation permeating the atmospheric conditions. The mammalian companion derived considerable pleasure from the thermal energy emanating from the celestial body."
  )
  
  # Analyze individual text
  analyze_text_cognitive_load(sample_texts$simple, "Simple Text")
  
  # Create comprehensive report
  report <- create_cognitive_load_report(sample_texts, c("Simple", "Moderate", "Complex"))
  
  # Display plots
  print(report$plots$readability_plot)
  print(report$plots$cognitive_load_plot)
  print(report$plots$complexity_scatter)
} 

# Example Cognitive Load Analysis
# Demonstrates how to use the text cognitive load assessment functions

# Source the cognitive load analysis functions
source("scripts/simple_text_cognitive_load.R")

# Example 1: Analyze a single text
cat("EXAMPLE 1: SINGLE TEXT ANALYSIS\n")
cat("================================\n\n")

sample_text <- "The implementation of cognitive load theory in educational contexts necessitates careful consideration of both intrinsic and extraneous cognitive load factors. Intrinsic cognitive load refers to the inherent complexity of the learning material, while extraneous cognitive load encompasses the manner in which information is presented to learners. Effective instructional design should minimize extraneous cognitive load while optimizing germane cognitive load to facilitate meaningful learning experiences."

# Analyze the text
analysis_result <- analyze_text_cognitive_load(sample_text, "Academic Text Sample")

# Example 2: Compare multiple texts
cat("\n\nEXAMPLE 2: MULTIPLE TEXT COMPARISON\n")
cat("====================================\n\n")

# Define different types of texts
texts <- list(
  simple = "The cat sat on the mat. It was a sunny day. The cat enjoyed the warmth.",
  
  moderate = "The feline creature positioned itself upon the woven floor covering. Meteorological conditions were characterized by abundant solar radiation. The domesticated animal derived pleasure from the thermal energy.",
  
  academic = "The implementation of cognitive load theory in educational contexts necessitates careful consideration of both intrinsic and extraneous cognitive load factors. Intrinsic cognitive load refers to the inherent complexity of the learning material, while extraneous cognitive load encompasses the manner in which information is presented to learners.",
  
  technical = "The algorithm implements a recursive descent parser with backtracking capabilities, utilizing a context-free grammar specification to generate parse trees. The computational complexity is O(n³) in the worst-case scenario, with space complexity of O(n²) for storing intermediate parse states.",
  
  conversational = "Hey there! I was thinking we should probably grab some coffee later. You know, just to catch up and maybe discuss that project we've been working on. What do you think? We could meet at that new place downtown."
)

# Create comprehensive report
report <- create_cognitive_load_report(texts, c("Simple", "Moderate", "Academic", "Technical", "Conversational"))

# Display the plots
cat("\n\nPLOTTING RESULTS...\n")
cat("==================\n\n")

# Readability comparison plot
print(report$plots$readability_plot)

# Cognitive load comparison plot  
print(report$plots$cognitive_load_plot)

# Complexity scatter plot
print(report$plots$complexity_scatter)

# Example 3: Analyze text from a file
cat("\n\nEXAMPLE 3: ANALYZING TEXT FROM FILE\n")
cat("====================================\n\n")

# Function to read and analyze text from a file
analyze_text_file <- function(file_path, text_name = NULL) {
  if(is.null(text_name)) {
    text_name <- basename(file_path)
  }
  
  # Read the file
  text_content <- readLines(file_path, warn = FALSE)
  text_content <- paste(text_content, collapse = " ")
  
  # Analyze the text
  result <- analyze_text_cognitive_load(text_content, text_name)
  
  return(result)
}

# Example usage (uncomment if you have a text file to analyze)
# file_analysis <- analyze_text_file("path/to/your/text/file.txt", "My Document")

# Example 4: Batch analysis of multiple files
cat("\n\nEXAMPLE 4: BATCH ANALYSIS FUNCTION\n")
cat("===================================\n\n")

# Function to analyze multiple text files
batch_analyze_files <- function(file_paths, file_names = NULL) {
  if(is.null(file_names)) {
    file_names <- basename(file_paths)
  }
  
  texts <- list()
  for(i in 1:length(file_paths)) {
    text_content <- readLines(file_paths[i], warn = FALSE)
    texts[[i]] <- paste(text_content, collapse = " ")
  }
  
  # Create comparison report
  report <- create_cognitive_load_report(texts, file_names)
  
  return(report)
}

# Example usage (uncomment if you have multiple files to analyze)
# file_paths <- c("file1.txt", "file2.txt", "file3.txt")
# batch_report <- batch_analyze_files(file_paths, c("Document 1", "Document 2", "Document 3"))

# Example 5: Custom analysis for specific use cases
cat("\n\nEXAMPLE 5: CUSTOM ANALYSIS\n")
cat("==========================\n\n")

# Function to assess if text is appropriate for a specific audience
assess_audience_appropriateness <- function(text, target_grade_level = 8) {
  
  analysis <- assess_cognitive_load(text)
  
  cat("AUDIENCE APPROPRIATENESS ASSESSMENT\n")
  cat("==================================\n")
  cat("Target Grade Level:", target_grade_level, "\n")
  cat("Text Flesch-Kincaid Grade Level:", round(analysis$readability_scores$flesch_kincaid_grade, 1), "\n\n")
  
  # Determine appropriateness
  grade_diff <- analysis$readability_scores$flesch_kincaid_grade - target_grade_level
  
  if(abs(grade_diff) <= 1) {
    cat("✅ APPROPRIATE: Text complexity matches target audience\n")
  } else if(grade_diff > 1) {
    cat("⚠️  TOO DIFFICULT: Text is", round(grade_diff, 1), "grade levels above target\n")
    cat("   Recommendations:\n")
    cat("   - Simplify vocabulary\n")
    cat("   - Break up long sentences\n")
    cat("   - Add more context and examples\n")
  } else {
    cat("ℹ️  TOO SIMPLE: Text is", round(abs(grade_diff), 1), "grade levels below target\n")
    cat("   Consider using more complex language for this audience\n")
  }
  
  return(analysis)
}

# Test audience appropriateness
audience_analysis <- assess_audience_appropriateness(sample_text, target_grade_level = 8)

cat("\n\nSUMMARY\n")
cat("=======\n")
cat("This script demonstrates several ways to assess cognitive load in text:\n")
cat("1. Single text analysis with detailed metrics\n")
cat("2. Comparison of multiple texts\n")
cat("3. File-based analysis\n")
cat("4. Batch processing of multiple files\n")
cat("5. Audience appropriateness assessment\n\n")
cat("The analysis provides:\n")
cat("- Readability scores (Flesch, Flesch-Kincaid, Gunning Fog)\n")
cat("- Text complexity metrics (sentence length, word length)\n")
cat("- Cognitive load assessment\n")
cat("- Visual comparisons and recommendations\n") 
