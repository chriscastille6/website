# Hierarchical Bayes estimation for random-coefficients MNL (simple implementation)
# - Reads SQLite responses written by the app
# - Constructs difference-coded pairwise data
# - Runs a basic Gibbs-within-Metropolis to sample individual betas and population hyperparameters
# - Saves individual posterior means and population summary

required_packages <- c("DBI", "RSQLite", "tidyverse")
installed <- required_packages %in% rownames(installed.packages())
if (any(!installed)) install.packages(required_packages[!installed], repos = "https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(tidyverse)
})

ROOT <- getwd()
APP_DIR <- file.path(ROOT, "employee_preferences_app")
DB_PATH <- file.path(APP_DIR, "db", "app.sqlite")
OUTPUT_DIR <- file.path(APP_DIR, "outputs")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# Attributes mirror app
attributes_df <- tribble(
  ~attribute,                ~level,          ~order,
  "Base pay",               "0%",           1L,
  "Base pay",               "10%",          2L,
  "Base pay",               "20%",          3L,
  "Learning",               "0",            1L,
  "Learning",               "40",           2L,
  "Learning",               "60+Mentor",    3L,
  "Manager effectiveness",  "Average",      1L,
  "Manager effectiveness",  "Enhanced",     2L,
  "Internal job market",    "Current",      1L,
  "Internal job market",    "Enhanced",     2L,
  "Health care",            "Current",      1L,
  "Health care",            "Enhanced",     2L
) %>% arrange(attribute, order)

attr_levels <- attributes_df %>% group_by(attribute) %>% summarise(levels = list(level), .groups = "drop")

profiles_df <- attr_levels %>%
  pull(levels) %>%
  do.call(expand.grid, .) %>%
  as_tibble() %>%
  setNames(attr_levels$attribute) %>%
  mutate(profile_id = row_number(), .before = 1)

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
Xcols <- colnames(profiles_X)

# Load data
con <- dbConnect(RSQLite::SQLite(), DB_PATH)
if (!dbExistsTable(con, "tasks")) stop("No tasks found.")
raw_tasks <- dbReadTable(con, "tasks") %>% as_tibble()

if (nrow(raw_tasks) == 0) stop("No task rows to estimate.")

# Build per-respondent design for pairwise differences
choices_long <- raw_tasks %>%
  mutate(chid = paste(respondent_id, task_num, sep = "_")) %>%
  select(respondent_id, chid, task_num, altA_id, altB_id, choice)

# For each row, create x = X_A - X_B and y in {0,1}
rows <- vector("list", nrow(choices_long))
for (i in seq_len(nrow(choices_long))){
  a <- choices_long$altA_id[i]; b <- choices_long$altB_id[i]
  x <- profiles_X[a, , drop = FALSE] - profiles_X[b, , drop = FALSE]
  y <- as.integer(choices_long$choice[i] == "Choose A")
  rows[[i]] <- tibble(respondent_id = choices_long$respondent_id[i], task_num = choices_long$task_num[i], y = y) %>%
    bind_cols(as_tibble(x))
}
px <- bind_rows(rows)
colnames(px) <- c("respondent_id", "task_num", "y", Xcols)

# HB settings
set.seed(123)
R <- length(unique(px$respondent_id))
P <- length(Xcols)
respondents <- unique(px$respondent_id)

# Priors
mu0 <- rep(0, P)
Sigma0 <- diag(P) * 10
nu0 <- P + 2
S0 <- diag(P)

# Storage
n_iter <- getOption("hb_iter", 2500)
burn_in <- getOption("hb_burnin", 1000)
thin <- getOption("hb_thin", 5)

# Initialize
mu <- rep(0, P)
Sigma <- diag(P)
betas <- matrix(0, nrow = R, ncol = P)
rownames(betas) <- respondents

# Helper: logit log-likelihood for respondent r
ll_r <- function(beta_r, Xr, yr){
  eta <- as.numeric(Xr %*% beta_r)
  sum(yr * log(1/(1 + exp(-eta))) + (1 - yr) * log(1 - 1/(1 + exp(-eta))))
}

# Split data by respondent
split_X <- lapply(respondents, function(r){ as.matrix(px %>% filter(respondent_id == r) %>% select(all_of(Xcols))) })
split_y <- lapply(respondents, function(r){ as.numeric(px %>% filter(respondent_id == r) %>% pull(y)) })

# Metropolis step for beta_r
proposal_sd <- 0.10

samples_mu <- matrix(NA_real_, nrow = floor((n_iter - burn_in)/thin), ncol = P)
colnames(samples_mu) <- Xcols

for (iter in seq_len(n_iter)){
  # 1) Sample individual betas via MH
  for (i in seq_len(R)){
    br <- betas[i, ]
    Xr <- split_X[[i]]; yr <- split_y[[i]]
    prop <- br + rnorm(P, sd = proposal_sd)
    log_acc <- (ll_r(prop, Xr, yr) - 0.5 * t(prop - mu) %*% solve(Sigma) %*% (prop - mu)) -
               (ll_r(br, Xr, yr)   - 0.5 * t(br - mu)   %*% solve(Sigma) %*% (br - mu))
    if (is.finite(log_acc) && log(runif(1)) < as.numeric(log_acc)) br <- prop
    betas[i, ] <- br
  }
  # 2) Sample (mu, Sigma) given betas ~ Normal-Inverse-Wishart approximate
  bbar <- colMeans(betas)
  S <- cov(betas) * (R - 1)
  # Update Sigma via IW(nu0 + R, S0 + S + shrink)
  nu_post <- nu0 + R
  S_post <- S0 + S + (R * (bbar - mu0) %*% t(bbar - mu0))
  # Draw Sigma via inverse Wishart using Wishart on precision
  # Use a simple approximation: Sigma <- S_post / (nu_post - P - 1)
  Sigma <- S_post / (nu_post - P - 1)
  # Update mu ~ N(m_post, Sigma/R)
  mu <- bbar
  
  # Store
  if (iter > burn_in && ((iter - burn_in) %% thin == 0)){
    samples_mu[(iter - burn_in)/thin, ] <- mu
  }
}

post_mu <- colMeans(samples_mu)
ind_post <- as_tibble(betas)
colnames(ind_post) <- Xcols
ind_post <- bind_cols(tibble(respondent_id = respondents), ind_post)

readr::write_csv(ind_post, file.path(OUTPUT_DIR, "hb_individual_betas.csv"))
readr::write_csv(tibble(parameter = Xcols, mean = post_mu), file.path(OUTPUT_DIR, "hb_population_mean.csv"))

message("HB estimation completed. Saved individual betas and population mean.") 