# Analysis for Adaptive Employee Preferences Survey
# - Reads SQLite responses
# - Estimates MNL on pooled choices (baseline; can be extended to HB)
# - Computes attribute importance and WTP
# - Builds efficient frontier and Slade-style A–D portfolios

required_packages <- c("DBI", "RSQLite", "tidyverse", "mlogit", "scales")
installed <- required_packages %in% rownames(installed.packages())
if (any(!installed)) install.packages(required_packages[!installed], repos = "https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(tidyverse)
  library(mlogit)
  library(scales)
})

ROOT <- getwd()
APP_DIR <- file.path(ROOT, "employee_preferences_app")
DB_PATH <- file.path(APP_DIR, "db", "app.sqlite")
OUTPUT_DIR <- file.path(APP_DIR, "outputs")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# Mirror attribute setup used in app
attributes_df <- tribble(
  ~attribute,                ~level,               ~label,                                        ~order, ~is_better_higher, ~cost_k,
  "Base pay",               "0%",                "Base unchanged",                             1L,     TRUE,              0.0,
  "Base pay",               "10%",               "Base +10%",                                  2L,     TRUE,              10.0,
  "Base pay",               "20%",               "Base +20%",                                  3L,     TRUE,              20.0,
  "Learning",               "0",                 "No mandatory training",                      1L,     TRUE,              0.0,
  "Learning",               "40",                "40 hours/yr mandatory training",             2L,     TRUE,              1.5,
  "Learning",               "60+Mentor",         "60 hours + mentoring program",               3L,     TRUE,              2.5,
  "Manager effectiveness",  "Average",           "Average manager capability",                  1L,     TRUE,              0.0,
  "Manager effectiveness",  "Enhanced",          "Invest to strengthen managers",               2L,     TRUE,              1.5,
  "Internal job market",    "StatusQuo",         "No change",                                   1L,     TRUE,              0.0,
  "Internal job market",    "ApplyNoPermission", "Apply without manager permission",            2L,     TRUE,              0.5,
  "Internal job market",    "ActiveRecruit",     "Managers actively recruit across departments", 3L,     TRUE,              1.0,
  "Health care",            "Premium25to50",     "Pay $25–$50 premium for dependents",          1L,     TRUE,              0.0,
  "Health care",            "NoChange",          "No change to current plan",                   2L,     TRUE,              2.0,
  "Health care",            "CashWaiver",        "Cash for waiving portions of coverage",       3L,     TRUE,              1.0
) %>% arrange(attribute, order)

attr_levels <- attributes_df %>% group_by(attribute) %>% summarise(levels = list(level), .groups = "drop")

profiles_df <- attr_levels %>%
  pull(levels) %>%
  do.call(expand.grid, .) %>%
  as_tibble() %>%
  setNames(attr_levels$attribute) %>%
  mutate(profile_id = row_number(), .before = 1)

# Design matrix (same as in app)
build_design_matrix <- function(profiles_tbl) {
  mats <- lapply(unique(attributes_df$attribute), function(att){
    levs <- attributes_df %>% filter(attribute == att) %>% arrange(order) %>% pull(level)
    levs_no_base <- levs[-1]
    mm <- sapply(levs_no_base, function(lv){ as.integer(profiles_tbl[[att]] == lv) })
    if (is.null(dim(mm))) mm <- matrix(mm, ncol = 1)
    colnames(mm) <- paste(att, levs_no_base, sep = "|")
    mm
  })
  X <- do.call(cbind, mats)
  attr(X, "col_labels") <- colnames(X)
  X
}

profiles_X <- build_design_matrix(profiles_df)

# Load data
con <- dbConnect(RSQLite::SQLite(), DB_PATH)
if (!dbExistsTable(con, "tasks")) {
  stop("No tasks table found. Run the app to collect data first.")
}

raw_tasks <- dbReadTable(con, "tasks") %>% as_tibble()
raw_final <- if (dbExistsTable(con, "final_intentions")) dbReadTable(con, "final_intentions") %>% as_tibble() else tibble()

if (nrow(raw_tasks) == 0) {
  stop("No responses found in tasks table. Run the app to collect data, or simulate data.")
}

# Build long-format choice data for mlogit: for each task, two alts with chosen flag
choices_long <- raw_tasks %>%
  mutate(chid = paste(respondent_id, task_num, sep = "_")) %>%
  select(respondent_id, chid, task_num, altA_id, altB_id, choice) %>%
  pivot_longer(cols = c(altA_id, altB_id), names_to = "which", values_to = "profile_id") %>%
  mutate(alt = if_else(which == "altA_id", "A", "B"), chosen = as.integer((choice == "Choose A" & alt == "A") | (choice == "Choose B" & alt == "B"))) %>%
  arrange(respondent_id, chid, alt)

# Attach design variables
Xcols <- colnames(profiles_X)
with_design <- choices_long %>%
  mutate(row = match(profile_id, profiles_df$profile_id))
for (j in seq_along(Xcols)) {
  with_design[[Xcols[j]]] <- profiles_X[with_design$row, j]
}
with_design <- with_design %>% select(-row)

# mlogit data
df_mlogit <- mlogit.data(with_design, choice = "chosen", shape = "long", chid.var = "chid", alt.var = "alt", id.var = "respondent_id")

# Estimate pooled MNL
formula_term <- paste(sprintf("`%s`", Xcols), collapse = " + ")
fm <- as.formula(paste("chosen ~", formula_term, "| 0"))
fit <- mlogit(fm, data = df_mlogit)
print(summary(fit))

coef_est <- coef(fit)

# Importance: range over levels per attribute
imp_tbl <- {
  ranges <- list()
  for (att in unique(attributes_df$attribute)) {
    levs <- attributes_df %>% filter(attribute == att) %>% arrange(order) %>% pull(level)
    base <- levs[1]
    alts <- levs[-1]
    betas <- c(0, as.numeric(coef_est[paste(att, alts, sep = "|")]))
    rng <- max(betas) - min(betas)
    ranges[[att]] <- rng
  }
  tibble(attribute = names(ranges), range = unlist(ranges)) %>% mutate(importance = 100 * range / sum(range)) %>% arrange(desc(importance))
}

# WTP: translate non-monetary betas into % base pay equivalents using slope from Base pay 10% vs 0%
# Approximate salary slope: beta for Base pay|10% represents +10%; use per-1% slope
bp10 <- unname(coef_est["Base pay|10%"])
bp20 <- unname(coef_est["Base pay|20%"])
# Use first segment slope for local WTP
salary_per_pct <- bp10 / 10
wtp_tbl <- tibble(
  attribute_level = names(coef_est),
  coef = as.numeric(coef_est)
) %>%
  filter(!str_starts(attribute_level, "Base pay|")) %>%
  mutate(wtp_pct_base = coef / salary_per_pct)

# Save outputs
readr::write_csv(imp_tbl, file.path(OUTPUT_DIR, "attribute_importance.csv"))
readr::write_csv(wtp_tbl, file.path(OUTPUT_DIR, "wtp_pct.csv"))

# Efficient frontier on discrete options (mirror app attributes)
frontier_grid <- expand_grid(
  `Learning` = c("0", "40", "60+Mentor"),
  `Manager effectiveness` = c("Average", "Enhanced"),
  `Internal job market` = c("StatusQuo", "ApplyNoPermission", "ActiveRecruit"),
  `Health care` = c("Premium25to50", "NoChange", "CashWaiver"),
  `Base pay` = c("0%", "10%", "20%")
) %>%
  mutate(profile_id = pmap_int(across(all_of(colnames(profiles_df)[-1])), function(...){
    row <- profiles_df %>% filter(
      `Learning` == ..1, `Manager effectiveness` == ..2, `Internal job market` == ..3, `Health care` == ..4, `Base pay` == ..5
    ) %>% pull(profile_id)
    row[1]
  }))

Xcols <- colnames(profiles_X)
for (j in seq_along(Xcols)) {
  frontier_grid[[Xcols[j]]] <- profiles_X[frontier_grid$profile_id, j]
}

# Utility under pooled MNL
frontier_grid <- frontier_grid %>%
  mutate(util = as.numeric(as.matrix(select(., all_of(Xcols))) %*% coef_est))

# Cost per employee using attributes_df
level_cost <- attributes_df %>% select(attribute, level, cost_k)
frontier_grid <- frontier_grid %>%
  rowwise() %>%
  mutate(cost_k = {
    keys <- c(
      paste("Base pay", `Base pay`),
      paste("Learning", Learning),
      paste("Manager effectiveness", `Manager effectiveness`),
      paste("Internal job market", `Internal job market`),
      paste("Health care", `Health care`)
    )
    lc_keys <- paste(level_cost$attribute, level_cost$level)
    sum(level_cost$cost_k[match(keys, lc_keys)])
  }) %>%
  ungroup()

# Pareto frontier (best utility for each cost)
frontier_set <- frontier_grid %>%
  arrange(cost_k, desc(util)) %>%
  group_by(cost_k) %>% slice_max(order_by = util, n = 1, with_ties = FALSE) %>% ungroup() %>%
  arrange(cost_k) %>% mutate(is_efficient = util >= cummax(util)) %>% filter(is_efficient)

# Plot
p_frontier <- ggplot(frontier_grid, aes(x = cost_k, y = util)) +
  geom_point(alpha = 0.3, color = "#94A3B8") +
  geom_step(data = frontier_set, aes(x = cost_k, y = util), color = "#EF4444", linewidth = 1) +
  geom_point(data = frontier_set, aes(x = cost_k, y = util), color = "#EF4444", size = 2) +
  labs(x = "Annual cost per employee ($K)", y = "Utility (pooled MNL units)",
       title = "Efficient Frontier of Reward Packages (Pooled MNL)") +
  theme_minimal(base_size = 12)

ggsave(file.path(OUTPUT_DIR, "efficient_frontier.png"), p_frontier, width = 7.5, height = 4.5, dpi = 150)

# Slade-style A–D portfolios
N_employees <- 1000
turnover_cost_per_sep <- 200000
baseline_turnover_rate <- 0.15

# Choose A: a plausible current package (higher health spend, lower manager/internal)
portfolio_A <- frontier_grid %>% filter(`Base pay` == "0%", Learning == "0", `Manager effectiveness` == "Average", `Internal job market` == "StatusQuo", `Health care` == "CashWaiver") %>% slice(1)
A_cost <- portfolio_A$cost_k
A_util <- portfolio_A$util

# C: maximize util with cost <= A_cost
portfolio_C <- frontier_grid %>% filter(cost_k <= A_cost + 1e-9) %>% arrange(desc(util), cost_k) %>% slice(1)

# Map util delta -> turnover drop to target -4pp at C
beta <- (0.04) / (portfolio_C$util - A_util)

calc_metrics <- function(df){
  df %>% mutate(
    invest_delta_k = cost_k - A_cost,
    turnover_rate = pmax(0.0, pmin(1.0, baseline_turnover_rate - beta * (util - A_util))),
    turnover_drop_pp = (baseline_turnover_rate - turnover_rate),
    savings_musd = (turnover_drop_pp * N_employees * turnover_cost_per_sep) / 1e6,
    invest_delta_musd = invest_delta_k * N_employees / 1e3,
    net_benefit_musd = savings_musd - invest_delta_musd
  )
}

slade_all <- calc_metrics(frontier_grid)

# B: keep turnover ~same, reduce investment
portfolio_B <- slade_all %>% filter(abs(turnover_drop_pp) < 0.001, invest_delta_musd < 0) %>% arrange(desc(net_benefit_musd)) %>% slice(1)
# D: invest about +$7.5M
portfolio_D <- slade_all %>% filter(invest_delta_musd >= 7.0, invest_delta_musd <= 8.0) %>% arrange(desc(net_benefit_musd)) %>% slice(1)

abcd <- bind_rows(
  portfolio_A %>% mutate(label = "A"),
  portfolio_B %>% mutate(label = "B"),
  portfolio_C %>% mutate(label = "C"),
  portfolio_D %>% mutate(label = "D")
) %>% select(label, `Base pay`, Learning, `Manager effectiveness`, `Internal job market`, `Health care`, cost_k, invest_delta_musd, turnover_rate, turnover_drop_pp, savings_musd, net_benefit_musd)

readr::write_csv(abcd, file.path(OUTPUT_DIR, "slade_portfolios.csv"))

p_slade <- ggplot(slade_all, aes(x = invest_delta_musd, y = turnover_drop_pp)) +
  geom_point(alpha = 0.15, color = "#94A3B8") +
  geom_step(data = slade_all %>% arrange(invest_delta_musd, desc(turnover_drop_pp)) %>% group_by(invest_delta_musd) %>% slice_max(order_by = turnover_drop_pp, n = 1, with_ties = FALSE) %>% ungroup() %>% arrange(invest_delta_musd) %>% mutate(is_eff = turnover_drop_pp >= cummax(turnover_drop_pp)) %>% filter(is_eff),
            aes(x = invest_delta_musd, y = turnover_drop_pp), color = "#111827", linewidth = 1) +
  geom_point(data = abcd %>% mutate(retention_pp = turnover_drop_pp, invest_m = invest_delta_musd), aes(x = invest_m, y = retention_pp), color = "#EF4444", size = 2) +
  geom_text(data = abcd %>% mutate(retention_pp = turnover_drop_pp, invest_m = invest_delta_musd), aes(x = invest_m, y = retention_pp, label = label), vjust = -1, size = 3) +
  scale_x_continuous(name = "Decrease / Increase in investment from current ($M)") +
  scale_y_continuous(name = "Increase in indicated retention (percentage points)") +
  labs(title = "Total Rewards Efficient Frontier (Slade-style)") +
  theme_minimal(base_size = 12)

ggsave(file.path(OUTPUT_DIR, "slade_frontier.png"), p_slade, width = 7.5, height = 4.5, dpi = 150)

message("Analysis complete. Outputs saved to ", OUTPUT_DIR) 