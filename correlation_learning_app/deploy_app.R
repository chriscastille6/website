# Correlation Learning App Deployment Script
# Run this script in R or RStudio to deploy the app to Shinyapps.io

# Install required packages if not already installed
if (!require("shiny")) install.packages("shiny")
if (!require("plotly")) install.packages("plotly")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("rsconnect")) install.packages("rsconnect")

# Load required packages
library(shiny)
library(plotly)
library(ggplot2)
library(rsconnect)

# Configure Shinyapps.io account
rsconnect::setAccountInfo(name='christopher-m-castille', 
                          token='B16286A69BF7606C57880B95159F265E', 
                          secret='zB0EEo2ktIMMQuKpPXL5vgQKm+aC5PXDRo8lX6jc')

# Set working directory to the app folder
setwd("/Users/ccastille/Documents/GitHub/Website/PAL-of-the-Bayou/correlation_learning_app")

# Create a copy with standard naming
file.copy("corr_guessing_game_structured.R", "app.R", overwrite = TRUE)

# Deploy the app with force update
cat("Deploying updated Correlation Learning App to Shinyapps.io...\n")
cat("This version includes the updated intuitive questions (no duplicates).\n")
rsconnect::deployApp(forceUpdate = TRUE)

cat("Deployment complete! Your updated app should be available at:\n")
cat("https://christopher-m-castille.shinyapps.io/correlation-learning-app/\n")
cat("\nNew intuitive questions include:\n")
cat("1. Height → Weight (r = 0.67)\n")
cat("2. Age → Income (r = 0.45)\n")
cat("3. Latitude → Temperature (r = 0.60)\n")
cat("4. Gender → Height (r = 0.60)\n")
cat("5. Education → Income (r = 0.55)\n") 