library(ggplot2)

# Example correlation (using a moderate correlation for demonstration)
r <- 0.30

# Convert r to BESD success rate
success_rate_with_intervention <- 0.35 + (r / 2)  # 0.35 + 0.15 = 0.50
success_rate_without_intervention <- 0.35

# Create data frame
besd_data <- data.frame(
  Group = c("Low", "High"),
  SuccessRate = c(success_rate_without_intervention, success_rate_with_intervention)
)

# Set y-axis limits to always show 30% to 55%
y_min <- 0.30
 y_max <- 0.55

# Create the plot with cropped y-axis
p <- ggplot(besd_data, aes(x = Group, y = SuccessRate, fill = Group)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = paste0(round(SuccessRate * 100, 1), "%")), 
            vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("Low" = "#E8E8E8", "High" = "#90EE90")) +
  scale_y_continuous(
    limits = c(y_min, y_max),
    labels = function(x) paste0(round(x * 100, 1), "%"),
    expand = c(0, 0)
  ) +
  labs(
    title = "BESD Visualization: Height vs Weight (r = 0.30)",
    x = "Is the person above median height?",
    y = "Probability of having above average weight",
    fill = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    axis.text.x = element_text(size = 14, face = "bold"),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.margin = margin(20, 20, 20, 20)
  )

# Save the plot
ggsave("besd_visualization_cropped.png", p, width = 8, height = 6, dpi = 300)

print("BESD visualization saved as besd_visualization_cropped.png")
print(paste("Y-axis range:", round(y_min * 100, 1), "% to", round(y_max * 100, 1), "%")) 