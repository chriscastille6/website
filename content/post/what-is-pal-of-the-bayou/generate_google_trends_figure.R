# Location: /Users/ccastille/Documents/GitHub/Website/content/post/what-is-pal-of-the-bayou/generate_google_trends_figure.R
# Purpose: Generate the Google Trends figure showing People Analytics vs HR Analytics search interest over time
# Why: Reproducible code for the featured image in the "What is PAL of the Bayou?" blog post
# RELEVANT FILES: index.md, featured.png, data/google_trends_data.csv

# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(lubridate)

# Optional: uncomment to fetch fresh data from Google Trends API
# library(gtrendsR)

# -----------------------------------------------------------------------------
# LOAD DATA
# -----------------------------------------------------------------------------

# Option 1: Load from CSV file (if available)
# The CSV should have format: Month,people analytics: (United States),hr analytics: (United States),...
if (file.exists("data/google_trends_data.csv")) {
  cat("Loading Google Trends data from CSV...\n")
  trend_data <- read_csv("data/google_trends_data.csv", skip = 2, show_col_types = FALSE) %>%
    rename(date = Month) %>%
    mutate(date = as.Date(paste0(date, "-01"))) %>%
    pivot_longer(-date, names_to = "keyword", values_to = "hits") %>%
    mutate(
      keyword = str_remove(keyword, ":.*$"),
      keyword = str_remove(keyword, " \\(United States\\)"),
      # Capitalize first letter of each word to match color_map
      keyword = str_to_title(keyword),
      hits = as.numeric(hits)
    ) %>%
    filter(!is.na(hits))
} else {
  # Option 2: Fetch from Google Trends API (requires gtrendsR package)
  # Uncomment the following lines to fetch fresh data:
  # cat("Fetching Google Trends data from API...\n")
  # terms <- c("People analytics", "HR analytics", "Workforce analytics",
  #            "Talent analytics", "Human capital analytics")
  # 
  # results <- list()
  # for (term in terms) {
  #   try({
  #     Sys.sleep(5)  # Rate limiting
  #     trends <- gtrends(term, geo = "US", time = "2004-01-01 2025-01-01")$interest_over_time
  #     results[[term]] <- trends
  #   }, silent = TRUE)
  # }
  # 
  # trend_data <- bind_rows(results)
  
  # If neither option works, stop with error
  stop("No data file found. Please either:\n",
       "  1. Place 'data/google_trends_data.csv' in this directory, or\n",
       "  2. Uncomment the gtrendsR code above to fetch from API")
}

# -----------------------------------------------------------------------------
# PREPARE DATA FOR PLOTTING
# -----------------------------------------------------------------------------

# Clean and prepare the data
trend_data_clean <- trend_data %>%
  filter(!is.na(hits)) %>%
  mutate(
    hits = as.numeric(hits),
    keyword = factor(keyword, levels = unique(keyword))
  )

# Manually define label positions for the plot
manual_labels <- data.frame(
  keyword = c("People analytics", "HR analytics", "Workforce analytics",
              "Talent analytics", "Human capital analytics"),
  x = as.POSIXct(c("2017-01-01", "2016-01-01", "2016-01-01", "2015-01-01", "2015-01-01")),
  y = c(75, 40, 25, 15, 8)
)

# Define color palette for each term
color_map <- c(
  "People analytics"       = "#9ecae1",  # soft blue
  "HR analytics"           = "#fcae91",  # soft red
  "Workforce analytics"    = "#a1d99b",  # soft green
  "Talent analytics"       = "#d4b9da",  # soft purple
  "Human capital analytics" = "#fdd0a2"   # soft orange
)

# -----------------------------------------------------------------------------
# CREATE PLOT
# -----------------------------------------------------------------------------

p <- ggplot(trend_data_clean, aes(x = date, y = hits, group = keyword)) +
  geom_point(aes(color = keyword), alpha = 0.3, size = 1) +
  geom_smooth(aes(color = keyword), method = "loess", se = FALSE, linewidth = 1.2) +
  geom_label(data = manual_labels,
             aes(x = x, y = y, label = keyword, fill = keyword),
             color = "black", fontface = "bold", size = 3,
             label.size = 0.3, label.r = unit(0.15, "lines")) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  geom_vline(xintercept = min(trend_data_clean$date), color = "black", linewidth = 0.5) +
  scale_color_manual(values = color_map) +
  scale_fill_manual(values = color_map) +
  scale_y_continuous(limits = c(0, 100)) +
  scale_x_date(
    date_breaks = "2 years",
    date_labels = "%Y",
    expand = c(0.02, 0)
  ) +
  labs(
    title = "The rise of people analytics",
    subtitle = "Search interest in 'People Analytics' has dramatically outpaced 'HR Analytics' since 2015",
    x = "Year",
    y = "Search Interest",
    caption = "Adapted from van der Laken, P. (2021, February 3). *People analytics vs HR analytics – Google Trends*.\nhttps://paulvanderlaken.com/2021/02/03/people-analytics-hr-analytics-google-trends/"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 16, hjust = 0),
    plot.subtitle = element_text(size = 12, hjust = 0, margin = margin(b = 10)),
    plot.caption = element_text(size = 8, hjust = 0, margin = margin(t = 10)),
    axis.text.x = element_text(size = 11, angle = 0, hjust = 0.5),
    axis.title.x = element_text(size = 12, margin = margin(t = 10))
  )

# -----------------------------------------------------------------------------
# SAVE PLOT
# -----------------------------------------------------------------------------

ggsave("featured.png",
       plot = p,
       width = 14,  # inches (increased for better visibility)
       height = 8,  # inches (increased for better visibility)
       dpi = 600,   # high resolution
       bg = "white")  # ensure white background

cat("\n[✓] Figure saved as 'featured.png'\n")
cat("    Location: ", getwd(), "/featured.png\n", sep = "")

