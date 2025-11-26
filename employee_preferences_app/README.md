# Employee Preferences Survey (Adaptive Conjoint, Slade-style)

This app reproduces the approach described by Slade et al. (2002):
- Build-Your-Own screener (BYO)
- Adaptive choice-based conjoint (CBC) choice tasks
- Constructed best package
- Likelihood-to-stay measurement
- Estimation and efficient frontier / A–D portfolio analysis

## Run the survey app

In R:

```r
setwd("/Users/ccastille/Documents/GitHub/Website")
source("employee_preferences_app/app.R")
# In interactive sessions, it launches automatically; otherwise run:
# shiny::runApp(app)
```

Data are stored in `employee_preferences_app/db/app.sqlite`.

## Run analysis

After collecting responses, run:

```r
setwd("/Users/ccastille/Documents/GitHub/Website")
source("employee_preferences_app/analysis/estimate_and_optimize.R")
```

Outputs go to `employee_preferences_app/outputs/`, including:
- `attribute_importance.csv`
- `wtp_pct.csv`
- `efficient_frontier.png`
- `slade_portfolios.csv`
- `slade_frontier.png`

## Notes
- Attribute definitions and costs mirror the article’s examples. Adjust `attributes_df` in `app.R` and the analysis script to fit your organization.
- The adaptive engine uses a MAP logistic update and a simple D-optimal pair picker. You can swap in a more advanced design method (`idefix`) or a hierarchical Bayes estimator for finer-grained utilities. 