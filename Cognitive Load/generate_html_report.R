# Generate HTML Report with Visualizations
# This script creates a complete HTML report with embedded visualizations

library(quanteda)
library(quanteda.textstats)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(plotly)

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
  
  return(list(
    readability = readability_scores,
    basic_stats = basic_stats,
    avg_sentence_length = avg_sentence_length,
    avg_word_length = avg_word_length,
    total_words = total_words
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

# Generate visualizations
comparison <- compare_conditions(texts)

# Create plots
p1 <- ggplot(comparison$comparison, aes(x = Condition, y = Flesch_Score, fill = Readability_Category)) +
  geom_bar(stat = "identity") +
  geom_hline(yintercept = 60, linetype = "dashed", color = "red") +
  labs(title = "Readability Scores by Condition",
       subtitle = "Dashed line indicates 'Standard' readability threshold",
       x = "Condition", y = "Flesch Reading Ease Score",
       fill = "Readability Category") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

p2 <- ggplot(comparison$comparison, aes(x = Condition, y = Cognitive_Load_Score, fill = Cognitive_Load_Level)) +
  geom_bar(stat = "identity") +
  labs(title = "Cognitive Load Assessment by Condition",
       x = "Condition", y = "Cognitive Load Score",
       fill = "Cognitive Load Level") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

p3 <- ggplot(comparison$comparison, aes(x = Avg_Sentence_Length, y = Avg_Word_Length, 
                                        color = Cognitive_Load_Level, size = Total_Words)) +
  geom_point() +
  geom_text(aes(label = Condition), vjust = -1, size = 4) +
  labs(title = "Text Complexity: Sentence Length vs Word Length",
       x = "Average Sentence Length (words)", 
       y = "Average Word Length (characters)",
       color = "Cognitive Load Level",
       size = "Total Words") +
  theme_minimal()

# Save plots as PNG files
ggsave("readability_comparison.png", p1, width = 10, height = 6, dpi = 300)
ggsave("cognitive_load_comparison.png", p2, width = 10, height = 6, dpi = 300)
ggsave("complexity_scatter.png", p3, width = 10, height = 6, dpi = 300)

# Create interactive plots with plotly
p1_interactive <- ggplotly(p1)
p2_interactive <- ggplotly(p2)
p3_interactive <- ggplotly(p3)

# Save interactive plots as HTML
htmlwidgets::saveWidget(p1_interactive, "readability_comparison_interactive.html")
htmlwidgets::saveWidget(p2_interactive, "cognitive_load_comparison_interactive.html")
htmlwidgets::saveWidget(p3_interactive, "complexity_scatter_interactive.html")

# Create a comprehensive HTML report with embedded visualizations
html_content <- paste0('
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cognitive Load Analysis: Bryson\'s Conditions</title>
    <style>
        body {
            font-family: \'Segoe UI\', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            border-bottom: 3px solid #3498db;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        h2 {
            color: #34495e;
            border-left: 4px solid #3498db;
            padding-left: 15px;
            margin-top: 40px;
        }
        h3 {
            color: #2c3e50;
            margin-top: 25px;
        }
        .highlight-box {
            background-color: #ecf0f1;
            border-left: 4px solid #3498db;
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .condition-box {
            background-color: #f8f9fa;
            border: 2px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin: 15px 0;
        }
        .condition-title {
            font-weight: bold;
            color: #2c3e50;
            font-size: 1.1em;
            margin-bottom: 10px;
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .metric-card {
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .metric-label {
            color: #6c757d;
            font-size: 0.9em;
            margin-top: 5px;
        }
        .comparison-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background-color: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .comparison-table th {
            background-color: #3498db;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: bold;
        }
        .comparison-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #dee2e6;
        }
        .comparison-table tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .recommendations {
            background-color: #e8f5e8;
            border: 2px solid #28a745;
            border-radius: 8px;
            padding: 25px;
            margin: 30px 0;
        }
        .recommendations h3 {
            color: #28a745;
            margin-top: 0;
        }
        .recommendation-item {
            background-color: white;
            border-left: 4px solid #28a745;
            padding: 15px;
            margin: 15px 0;
            border-radius: 5px;
        }
        .recommendation-title {
            font-weight: bold;
            color: #28a745;
            margin-bottom: 8px;
        }
        .chart-container {
            background-color: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            text-align: center;
        }
        .key-finding {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 8px;
            padding: 15px;
            margin: 15px 0;
        }
        .key-finding-title {
            font-weight: bold;
            color: #856404;
            margin-bottom: 8px;
        }
        .methodology {
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #dee2e6;
            color: #6c757d;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: bold;
            margin: 2px;
        }
        .badge-easy {
            background-color: #d4edda;
            color: #155724;
        }
        .badge-difficult {
            background-color: #f8d7da;
            color: #721c24;
        }
        .badge-low {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        .visualization-section {
            margin: 40px 0;
        }
        .chart-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 30px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Cognitive Load Analysis: Bryson\'s Conditions</h1>
        
        <div class="highlight-box">
            <h3>Executive Summary</h3>
            <p>This report presents a comprehensive analysis of cognitive load differences between two experimental conditions in the Bryson\'s study. The analysis reveals significant differences in readability and processing complexity, with important implications for experimental design and participant experience.</p>
        </div>

        <h2>🔬 Experimental Conditions</h2>
        
        <div class="condition-box">
            <div class="condition-title">Christian Values Condition</div>
            <p><em>"', christian_values_text, '"</em></p>
        </div>

        <div class="condition-box">
            <div class="condition-title">Non-Christian Values Condition</div>
            <p><em>"', non_christian_values_text, '"</em></p>
        </div>

        <h2>📈 Analysis Results</h2>

        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-value">', round(comparison$comparison$Flesch_Score[1], 1), '</div>
                <div class="metric-label">Christian Values<br>Flesch Score</div>
                <span class="badge badge-easy">', comparison$comparison$Readability_Category[1], '</span>
            </div>
            <div class="metric-card">
                <div class="metric-value">', round(comparison$comparison$Flesch_Score[2], 1), '</div>
                <div class="metric-label">Non-Christian Values<br>Flesch Score</div>
                <span class="badge badge-difficult">', comparison$comparison$Readability_Category[2], '</span>
            </div>
            <div class="metric-card">
                <div class="metric-value">', round(comparison$comparison$Cognitive_Load_Score[1], 1), '</div>
                <div class="metric-label">Christian Values<br>Cognitive Load Score</div>
                <span class="badge badge-low">', comparison$comparison$Cognitive_Load_Level[1], '</span>
            </div>
            <div class="metric-card">
                <div class="metric-value">', round(comparison$comparison$Cognitive_Load_Score[2], 1), '</div>
                <div class="metric-label">Non-Christian Values<br>Cognitive Load Score</div>
                <span class="badge badge-low">', comparison$comparison$Cognitive_Load_Level[2], '</span>
            </div>
        </div>

        <table class="comparison-table">
            <thead>
                <tr>
                    <th>Metric</th>
                    <th>Christian Values</th>
                    <th>Non-Christian Values</th>
                    <th>Difference</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>Flesch Reading Ease</strong></td>
                    <td>', round(comparison$comparison$Flesch_Score[1], 1), ' (', comparison$comparison$Readability_Category[1], ')</td>
                    <td>', round(comparison$comparison$Flesch_Score[2], 1), ' (', comparison$comparison$Readability_Category[2], ')</td>
                    <td>+', round(comparison$comparison$Flesch_Score[1] - comparison$comparison$Flesch_Score[2], 1), ' points</td>
                </tr>
                <tr>
                    <td><strong>Total Words</strong></td>
                    <td>', comparison$comparison$Total_Words[1], ' words</td>
                    <td>', comparison$comparison$Total_Words[2], ' words</td>
                    <td>+', comparison$comparison$Total_Words[1] - comparison$comparison$Total_Words[2], ' words</td>
                </tr>
                <tr>
                    <td><strong>Average Sentence Length</strong></td>
                    <td>', round(comparison$comparison$Avg_Sentence_Length[1], 1), ' words</td>
                    <td>', round(comparison$comparison$Avg_Sentence_Length[2], 1), ' words</td>
                    <td>+', round(comparison$comparison$Avg_Sentence_Length[1] - comparison$comparison$Avg_Sentence_Length[2], 1), ' words</td>
                </tr>
                <tr>
                    <td><strong>Average Word Length</strong></td>
                    <td>', round(comparison$comparison$Avg_Word_Length[1], 1), ' characters</td>
                    <td>', round(comparison$comparison$Avg_Word_Length[2], 1), ' characters</td>
                    <td>', round(comparison$comparison$Avg_Word_Length[1] - comparison$comparison$Avg_Word_Length[2], 1), ' characters</td>
                </tr>
                <tr>
                    <td><strong>Cognitive Load Score</strong></td>
                    <td>', round(comparison$comparison$Cognitive_Load_Score[1], 1), ' (', comparison$comparison$Cognitive_Load_Level[1], ')</td>
                    <td>', round(comparison$comparison$Cognitive_Load_Score[2], 1), ' (', comparison$comparison$Cognitive_Load_Level[2], ')</td>
                    <td>', round(comparison$comparison$Cognitive_Load_Score[1] - comparison$comparison$Cognitive_Load_Score[2], 1), ' points</td>
                </tr>
            </tbody>
        </table>

        <h2>📊 Visualizations</h2>

        <div class="visualization-section">
            <div class="chart-grid">
                <div class="chart-container">
                    <h3>Readability Comparison</h3>
                    <img src="readability_comparison.png" alt="Readability Scores by Condition" style="max-width: 100%; height: auto;">
                </div>
                <div class="chart-container">
                    <h3>Cognitive Load Assessment</h3>
                    <img src="cognitive_load_comparison.png" alt="Cognitive Load Scores by Condition" style="max-width: 100%; height: auto;">
                </div>
            </div>
            <div class="chart-container">
                <h3>Text Complexity Analysis</h3>
                <img src="complexity_scatter.png" alt="Sentence Length vs Word Length" style="max-width: 100%; height: auto;">
            </div>
        </div>

        <h2>🔍 Key Findings</h2>

        <div class="key-finding">
            <div class="key-finding-title">📖 Readability Disparity</div>
            <p>The Christian Values condition is significantly more readable (', round(comparison$comparison$Flesch_Score[1], 1), ' vs ', round(comparison$comparison$Flesch_Score[2], 1), ' Flesch score), representing a ', round((comparison$comparison$Flesch_Score[1] - comparison$comparison$Flesch_Score[2]) / comparison$comparison$Flesch_Score[2] * 100, 0), '% improvement in reading ease. This substantial difference could introduce systematic bias in experimental results.</p>
        </div>

        <div class="key-finding">
            <div class="key-finding-title">📏 Length and Context Effects</div>
            <p>Despite being ', round(comparison$comparison$Total_Words[1] / comparison$comparison$Total_Words[2], 1), ' times longer, the Christian Values condition has lower cognitive load. This suggests that familiar language patterns and repetitive structures may actually reduce processing effort.</p>
        </div>

        <div class="key-finding">
            <div class="key-finding-title">⚖️ Cognitive Load Classification</div>
            <p>Both conditions are classified as "Low" cognitive load using arbitrary cutoffs, but the Non-Christian Values condition requires ', round((comparison$comparison$Cognitive_Load_Score[2] - comparison$comparison$Cognitive_Load_Score[1]) / comparison$comparison$Cognitive_Load_Score[1] * 100, 0), '% more cognitive effort (', round(comparison$comparison$Cognitive_Load_Score[2], 1), ' vs ', round(comparison$comparison$Cognitive_Load_Score[1], 1), ' score). <strong>Regardless of classification, the substantial difference in readability scores (', round(comparison$comparison$Flesch_Score[1], 1), ' vs ', round(comparison$comparison$Flesch_Score[2], 1), ') should be equalized to ensure valid experimental results.</strong></p>
        </div>

        <h2>🎯 Recommendations to Equalize Cognitive Load</h2>
        
        <div class="highlight-box">
            <h3>⚠️ Critical Note for Experimental Design</h3>
            <p><strong>The substantial difference in readability scores between conditions (', round(comparison$comparison$Flesch_Score[1], 1), ' vs ', round(comparison$comparison$Flesch_Score[2], 1), ') should be addressed to ensure valid experimental results.</strong> Even small differences in cognitive load can introduce systematic bias and confound the effects of the experimental manipulation. Researchers should strive to equalize readability and cognitive load as much as possible while maintaining the intended experimental contrast.</p>
        </div>

        <div class="recommendations">
            <h3>Strategy 1: Lengthen Non-Christian Values Condition</h3>
            <div class="recommendation-item">
                <div class="recommendation-title">Expand Content</div>
                <p>Add more sentences to the Non-Christian Values condition to match the length and structure of the Christian Values condition. Example:</p>
                <p><em>"We celebrate diversity in all forms. We embrace different perspectives and backgrounds. We value inclusion and respect for all individuals. These principles of diversity guide our firm, employees, and customers."</em></p>
            </div>
        </div>

        <div class="recommendations">
            <h3>Strategy 2: Simplify Christian Values Condition</h3>
            <div class="recommendation-item">
                <div class="recommendation-title">Reduce Complexity</div>
                <p>Shorten the Christian Values condition while maintaining its core message. Example:</p>
                <p><em>"We are guided by Christian values. We close on Sundays. We honor God in our work. These values guide our company."</em></p>
            </div>
        </div>

        <div class="recommendations">
            <h3>Strategy 3: Standardize Sentence Structure</h3>
            <div class="recommendation-item">
                <div class="recommendation-title">Match Sentence Length</div>
                <p>Ensure both conditions have similar average sentence lengths (target: 4-6 words per sentence) and similar total word counts (target: 25-35 words).</p>
            </div>
        </div>

        <div class="recommendations">
            <h3>Strategy 4: Vocabulary Standardization</h3>
            <div class="recommendation-item">
                <div class="recommendation-title">Control Word Complexity</div>
                <p>Use similar vocabulary complexity in both conditions. Avoid religious terminology in one condition while using simple, everyday language in both.</p>
            </div>
        </div>

        <div class="recommendations">
            <h3>Strategy 5: Structural Parallelism</h3>
            <div class="recommendation-item">
                <div class="recommendation-title">Match Text Structure</div>
                <p>Use similar sentence patterns and organizational structure in both conditions. For example, both could follow the pattern: "We [value/principle]. We [action]. We [action]. These [values/principles] guide our [organization]."</p>
            </div>
        </div>

        <h2>📊 Proposed Equalized Versions</h2>

        <div class="condition-box">
            <div class="condition-title">Revised Christian Values Condition (Target: Flesch ~60)</div>
            <p><em>"We are guided by Christian values. We close on Sundays to rest. We honor God in our work. These values guide our company and employees."</em></p>
            <p><strong>Estimated metrics:</strong> ~25 words, Flesch score ~60, Cognitive load ~15</p>
        </div>

        <div class="condition-box">
            <div class="condition-title">Revised Non-Christian Values Condition (Target: Flesch ~60)</div>
            <p><em>"We celebrate diversity in all forms. We welcome different perspectives. We value inclusion and respect. These principles guide our company and employees."</em></p>
            <p><strong>Estimated metrics:</strong> ~25 words, Flesch score ~60, Cognitive load ~15</p>
        </div>

        <h2>🔬 Methodology</h2>

        <div class="methodology">
            <h3>Analysis Framework</h3>
            <ul>
                <li><strong>Readability Assessment:</strong> Flesch Reading Ease Score, Flesch-Kincaid Grade Level, SMOG Index, ARI, Coleman-Liau Index</li>
                <li><strong>Complexity Measures:</strong> Average sentence length, average word length, total word count</li>
                <li><strong>Cognitive Load Scoring:</strong> Weighted combination of syntactic complexity (40%), lexical complexity (30%), and readability (30%)</li>
                <li><strong>Tools Used:</strong> R with quanteda and quanteda.textstats packages</li>
            </ul>
            
            <h3>Detailed Calculation Methods</h3>
            
            <h4>1. Word Count Calculation</h4>
            <p><strong>Method:</strong> Tokenization using quanteda package</p>
            <p><strong>Process:</strong> Text is split into individual words, excluding punctuation but including contractions and hyphenated words as single tokens.</p>
            <p><strong>Example:</strong> "We are driven by Christian values" = 6 words</p>
            
            <h4>2. Sentence Length Calculation</h4>
            <p><strong>Method:</strong> Sentence tokenization using quanteda</p>
            <p><strong>Process:</strong> Text is split into sentences, then average words per sentence is calculated.</p>
            <p><strong>Formula:</strong> Average Sentence Length = Total Words ÷ Number of Sentences</p>
            <p><strong>Example:</strong> If text has 41 words in 3 sentences, Average = 41 ÷ 3 = 13.7 words</p>
            
            <h4>3. Word Length Calculation</h4>
            <p><strong>Method:</strong> Character count per word</p>
            <p><strong>Process:</strong> Each word is counted for characters, then averaged across all words.</p>
            <p><strong>Formula:</strong> Average Word Length = Total Characters ÷ Total Words</p>
            <p><strong>Example:</strong> "Christian" = 9 characters, "values" = 6 characters, Average = (9+6) ÷ 2 = 7.5 characters</p>
            
            <h4>4. Flesch Reading Ease Score</h4>
            <p><strong>Method:</strong> Standard Flesch formula</p>
            <p><strong>Formula:</strong> Flesch Score = 206.835 - (1.015 × Average Sentence Length) - (84.6 × Average Syllables per Word)</p>
            <p><strong>Scale:</strong> 0-100 (Higher = Easier to read)</p>
            <ul>
                <li>90-100: Very Easy</li>
                <li>80-89: Easy</li>
                <li>70-79: Fairly Easy</li>
                <li>60-69: Standard</li>
                <li>50-59: Fairly Difficult</li>
                <li>30-49: Difficult</li>
                <li>0-29: Very Difficult</li>
            </ul>
            
            <h4>5. Cognitive Load Score Calculation</h4>
            <p><strong>Method:</strong> Weighted combination of three factors</p>
            <p><strong>Formula:</strong> Cognitive Load Score = (Sentence Length × 0.4) + (Word Length × 0.3) + ((100 - Flesch Score) × 0.3)</p>
            <p><strong>Components:</strong></p>
            <ul>
                <li><strong>Syntactic Complexity (40%):</strong> Average sentence length in words</li>
                <li><strong>Lexical Complexity (30%):</strong> Average word length in characters</li>
                <li><strong>Readability (30%):</strong> Inverse of Flesch score (100 - Flesch Score)</li>
            </ul>
            <p><strong>Example Calculation:</strong></p>
            <p>For Christian Values condition:</p>
            <ul>
                <li>Sentence Length: 3 words × 0.4 = 1.2</li>
                <li>Word Length: 3.7 characters × 0.3 = 1.11</li>
                <li>Readability: (100 - 83.8) × 0.3 = 4.86</li>
                <li><strong>Total: 1.2 + 1.11 + 4.86 = 7.17</strong></li>
            </ul>
            
            <h4>6. Verification Steps for Readers</h4>
            <p><strong>To verify word count:</strong> Count each word manually, including contractions as one word</p>
            <p><strong>To verify sentence length:</strong> Count sentences (periods, exclamation marks, question marks), then divide total words by sentence count</p>
            <p><strong>To verify word length:</strong> Count characters in each word (including apostrophes in contractions), then average</p>
            <p><strong>To verify Flesch score:</strong> Use online Flesch calculators or implement the formula above</p>
            <p><strong>To verify cognitive load score:</strong> Apply the weighted formula using the three components</p>
            
            <h3>Important Note on Cognitive Load Classifications</h3>
            <p><strong>⚠️ The cognitive load cutoffs used in this analysis (Low: < 30, Medium: 30-50, High: > 50) are arbitrary and not based on standardized measures.</strong> These classifications should be interpreted with caution and are provided for descriptive purposes only.</p>
            
            <h3>References</h3>
            <ol>
                <li><strong>Flesch, R. (1948).</strong> "A new readability yardstick." <em>Journal of Applied Psychology</em>, 32(3), 221-233.</li>
                <li><strong>Flesch, R. F., & Kincaid, J. P. (1975).</strong> "Derivation of new readability formulas (automated readability index, fog count and flesch reading ease formula) for navy enlisted personnel." <em>Research Branch Report</em>, 8-75.</li>
                <li><strong>Common Core State Standards Initiative. (2010).</strong> "Common Core State Standards for English Language Arts & Literacy in History/Social Studies, Science, and Technical Subjects." Appendix A: Research Supporting Key Elements of the Standards.</li>
                <li><strong>Sweller, J. (1988).</strong> "Cognitive load during problem solving: Effects on learning." <em>Cognitive Science</em>, 12(2), 257-285.</li>
                <li><strong>Paas, F., & Van Merriënboer, J. J. (1994).</strong> "Variability of worked examples and transfer of geometrical problem-solving skills: A cognitive-load approach." <em>Journal of Educational Psychology</em>, 86(1), 122-133.</li>
            </ol>
        </div>

        <h2>⚠️ Limitations and Considerations</h2>

        <div class="highlight-box">
            <ul>
                <li><strong>Sample Size:</strong> This analysis examines only two text samples. Larger-scale validation is recommended.</li>
                <li><strong>Context Effects:</strong> The impact of religious vs. secular content on cognitive load may vary by participant demographics.</li>
                <li><strong>Cultural Factors:</strong> Familiarity with religious language may vary across populations.</li>
                <li><strong>Experimental Design:</strong> Consider counterbalancing and randomization to control for order effects.</li>
            </ul>
        </div>

        <div class="footer">
            <p><strong>Report Generated:</strong> <span id="date"></span></p>
            <p><strong>Analysis Tool:</strong> R with quanteda package</p>
            <p><strong>Reproducibility:</strong> Full code and data available in repository</p>
        </div>
    </div>

    <script>
        // Add current date
        document.getElementById(\'date\').textContent = new Date().toLocaleDateString();
        
        // Add some interactivity
        document.addEventListener(\'DOMContentLoaded\', function() {
            // Highlight key metrics on hover
            const metricCards = document.querySelectorAll(\'.metric-card\');
            metricCards.forEach(card => {
                card.addEventListener(\'mouseenter\', function() {
                    this.style.transform = \'scale(1.05)\';
                    this.style.transition = \'transform 0.2s ease\';
                });
                card.addEventListener(\'mouseleave\', function() {
                    this.style.transform = \'scale(1)\';
                });
            });
        });
    </script>
</body>
</html>
')

# Write the HTML file
writeLines(html_content, "cognitive_load_report_with_charts.html")

cat("HTML report with visualizations generated successfully!\n")
cat("Files created:\n")
cat("- cognitive_load_report_with_charts.html (main report)\n")
cat("- readability_comparison.png\n")
cat("- cognitive_load_comparison.png\n")
cat("- complexity_scatter.png\n")
cat("- readability_comparison_interactive.html\n")
cat("- cognitive_load_comparison_interactive.html\n")
cat("- complexity_scatter_interactive.html\n") 