# Location: /Users/ccastille/Documents/GitHub/Website/content/post/what-is-pal-of-the-bayou/generate_turnover_contagion_figure.R
# Purpose: Reproduce the compounding turnover probabilities bar chart
# Why: Create reproducible code for the turnover contagion visualization with exact replica
# RELEVANT FILES: index.md, turnover-contagion-bars-figure1.png

# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------

library(ggplot2)
library(dplyr)

# -----------------------------------------------------------------------------
# DATA
# -----------------------------------------------------------------------------

# Data from the blog post caption:
# "employees with no departing connections have a baseline risk (1x), 
# while those with 1, 2, 3, 4, or 5 connections who have left face 
# 1.7x, 3.3x, 5.0x, 6.6x, and 8.3x increases in turnover probability, respectively."

turnover_data <- data.frame(
  connections = 0:5,
  multiplier = c(1.0, 1.7, 3.3, 5.0, 6.6, 8.3),
  label = c("1x", "1.7x", "3.3x", "5.0x", "6.6x", "8.3x")
)

# Define colors: smooth gradient from grey (0) to red (5), each getting closer to red
# Using a smooth transition from grey (#808080) to red (#DC143C)
color_map <- c(
  "0" = "#808080",  # 0 connections: grey (baseline)
  "1" = "#9A6B6B",  # 1 connection: grey with red tint
  "2" = "#B45656",  # 2 connections: more red
  "3" = "#CE4141",  # 3 connections: red-grey mix
  "4" = "#E82C2C",  # 4 connections: bright red
  "5" = "#DC143C"   # 5 connections: crimson red (highest risk)
)

# -----------------------------------------------------------------------------
# CREATE PLOT
# -----------------------------------------------------------------------------

# Create the bar chart with custom colors
p <- ggplot(turnover_data, aes(x = factor(connections), y = multiplier, fill = factor(connections))) +
  geom_bar(stat = "identity", width = 0.7) +
  scale_fill_manual(values = color_map, guide = "none") +
  geom_text(aes(x = factor(connections), y = multiplier, label = label), 
            vjust = -0.5, 
            size = 4, 
            fontface = "bold",
            inherit.aes = FALSE) +
  labs(
    x = "Number of Connections Who Have Left",
    y = "Turnover Probability Multiplier",
    title = "Compounding Turnover Probabilities",
    subtitle = "The odds of an employee turning over increase by approximately 2.1x\nfor every connection that has left Allstate"
  ) +
  scale_y_continuous(limits = c(0, 9), breaks = seq(0, 9, by = 1)) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 15)),
    axis.title.x = element_text(size = 12, margin = margin(t = 10)),
    axis.title.y = element_text(size = 12, margin = margin(r = 10)),
    axis.text = element_text(size = 10),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.margin = margin(20, 20, 20, 20)
  )

# -----------------------------------------------------------------------------
# SAVE PLOT
# -----------------------------------------------------------------------------

ggsave("turnover-contagion-bars-figure1.png",
       plot = p,
       width = 10,
       height = 6,
       dpi = 300)

cat("\n[✓] Figure saved as 'turnover-contagion-bars-figure1.png'\n")
cat("    Location: ", getwd(), "/turnover-contagion-bars-figure1.png\n", sep = "")

# Display the plot
print(p)

