# Reproducing the Google Trends Figure

This directory contains the code and data needed to reproduce the Google Trends figure featured in the "What is PAL of the Bayou?" blog post.

## Files

- `generate_google_trends_figure.R` - R script to generate the figure
- `data/google_trends_data.csv` - Google Trends data (2004-2025) for five HR-related terms
- `featured.png` - The generated figure (output)

## Usage

To regenerate the figure:

```r
# From R or RStudio, set working directory to this folder:
setwd("content/post/what-is-pal-of-the-bayou/")

# Run the script
source("generate_google_trends_figure.R")
```

The script will:
1. Load data from `data/google_trends_data.csv`
2. Create the visualization showing search interest trends
3. Save the figure as `featured.png`

## Data Source

The Google Trends data compares five terms:
- People analytics
- HR analytics
- Workforce analytics
- Talent analytics
- Human capital analytics

Data covers 2004-2025 for the United States.

## Alternative: Fetch Fresh Data

If you want to fetch fresh data from Google Trends API instead of using the CSV:

1. Install the `gtrendsR` package: `install.packages("gtrendsR")`
2. Uncomment the gtrendsR code section in `generate_google_trends_figure.R`
3. Note: Google Trends API has rate limits, so fetching may take several minutes

## Reference

Adapted from: van der Laken, P. (2021, February 3). *People analytics vs HR analytics – Google Trends*. https://paulvanderlaken.com/2021/02/03/people-analytics-hr-analytics-google-trends/


