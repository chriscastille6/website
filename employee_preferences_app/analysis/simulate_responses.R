# Simulate respondents for the adaptive survey and write to SQLite
# - Uses the same attribute space as the app
# - Simulates adaptive pairs using the same MAP + D-optimal logic
# - Records tasks and final intention into the DB

required_packages <- c("DBI", "RSQLite", "tidyverse", "MASS")
installed <- required_packages %in% rownames(installed.packages())
if (any(!installed)) install.packages(required_packages[!installed], repos = "https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(tidyverse)
  library(MASS)
})

ROOT <- getwd()
APP_DIR <- file.path(ROOT, "employee_preferences_app")
DB_PATH <- file.path(APP_DIR, "db", "app.sqlite")
if (!dir.exists(dirname(DB_PATH))) dir.create(dirname(DB_PATH), recursive = TRUE)

# Attributes mirrored from app
attributes_df <- tribble(
  ~attribute,                ~level,          ~label,                                        ~order, ~is_better_higher, ~cost_k,
  "Base pay",               "0%",           "Base unchanged",                             1L,     TRUE,              0.0,
  "Base pay",               "10%",          "Base +10%",                                  2L,     TRUE,              10.0,
  "Base pay",               "20%",          "Base +20%",                                  3L,     TRUE,              20.0,
  "Learning",               "0",            "No mandatory training",                      1L,     TRUE,              0.0,
  "Learning",               "40",           "40 hours/yr mandatory training",             2L,     TRUE,              1.5,
  "Learning",               "60+Mentor",    "60 hours + mentoring program",               3L,     TRUE,              2.5,
  "Manager effectiveness",  "Average",      "Average manager capability",                  1L,     TRUE,              0.0,
  "Manager effectiveness",  "Enhanced",     "Invest to strengthen managers",               2L,     TRUE,              1.5,
  "Internal job market",    "Current",      "Current mobility support",                   1L,     TRUE,              0.0,
  "Internal job market",    "Enhanced",     "Remove barriers; active brokering",          2L,     TRUE,              1.0,
  "Health care",            "Current",      "Current plan",                                1L,     TRUE,              0.0,
  "Health care",            "Enhanced",     "Enhanced plan",                               2L,     TRUE,              2.0
) %>% arrange(attribute, order)

attr_levels <- attributes_df %>% group_by(attribute) %>% summarise(levels = list(level), .groups = "drop")

profiles_df <- attr_levels %>%
  pull(levels) %>%
  do.call(expand.grid, .) %>%
  as_tibble() %>%
  setNames(attr_levels$attribute) %>%
  mutate(profile_id = row_number(), .before = 1)

# Design matrix (dummy coding with first level as baseline)
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

# Adaptive functions (copy of app logic)
update_map <- function(X_diff, y, mu, Sigma) {
  neg_logpost <- function(b){
    eta <- as.numeric(X_diff %*% b)
    p <- 1/(1 + exp(-eta))
    -sum(y*log(p + 1e-12) + (1 - y)*log(1 - p + 1e-12)) + 0.5 * t(b - mu) %*% solve(Sigma) %*% (b - mu)
  }
  b0 <- mu
  opt <- optim(b0, neg_logpost, method = "BFGS", control = list(maxit = 200))
  b_hat <- opt$par
  eta <- as.numeric(X_diff %*% b_hat)
  p <- 1/(1 + exp(-eta))
  W <- diag(p * (1 - p) + 1e-9, nrow = length(p))
  H <- t(X_diff) %*% W %*% X_diff + solve(Sigma)
  V <- tryCatch(solve(H), error = function(e) MASS::ginv(H))
  list(mu = b_hat, Sigma = V)
}

pick_next_pair <- function(candidate_ids, mu, Sigma, profiles_X, n_pairs = 400L) {
  if (length(candidate_ids) < 2L) return(integer(0))
  draws <- replicate(n_pairs, sample(candidate_ids, 2L), simplify = FALSE)
  best <- NULL; best_score <- -Inf
  for (idx in draws) {
    Xa <- profiles_X[idx[1], , drop = FALSE]
    Xb <- profiles_X[idx[2], , drop = FALSE]
    Xdiff <- rbind(Xa - Xb)
    p <- 1/(1 + exp(-(Xdiff %*% mu)))
    W <- matrix(as.numeric(p * (1 - as.numeric(p)) + 1e-6), nrow = 1)
    info <- t(Xdiff) %*% W %*% Xdiff + solve(Sigma)
    d <- tryCatch(determinant(info, logarithm = TRUE)$modulus, error = function(e) -Inf)
    if (is.finite(d) && d > best_score) { best_score <- d; best <- idx }
  }
  unlist(best)
}

# DB helpers
con <- dbConnect(RSQLite::SQLite(), DB_PATH)
dbExecute(con, "CREATE TABLE IF NOT EXISTS respondents (respondent_id TEXT PRIMARY KEY, started_at TEXT, finished_at TEXT)")
dbExecute(con, "CREATE TABLE IF NOT EXISTS byo_answers (respondent_id TEXT, attribute TEXT, level TEXT, is_must INTEGER, unacceptable_levels TEXT)")
dbExecute(con, "CREATE TABLE IF NOT EXISTS tasks (respondent_id TEXT, task_num INTEGER, altA_id INTEGER, altB_id INTEGER, choice TEXT, recorded_at TEXT)")
dbExecute(con, "CREATE TABLE IF NOT EXISTS final_intentions (respondent_id TEXT, best_profile_id INTEGER, likelihood_stay INTEGER, recorded_at TEXT)")

record_start <- function(con, rid){ dbExecute(con, "INSERT OR IGNORE INTO respondents(respondent_id, started_at) VALUES(?, datetime('now'))", params = list(rid)) }
record_task <- function(con, rid, task_num, a, b, choice){ dbExecute(con, "INSERT INTO tasks(respondent_id, task_num, altA_id, altB_id, choice, recorded_at) VALUES(?, ?, ?, ?, ?, datetime('now'))", params = list(rid, task_num, a, b, choice)) }
record_final <- function(con, rid, best_id, like){ dbExecute(con, "INSERT OR REPLACE INTO final_intentions(respondent_id, best_profile_id, likelihood_stay, recorded_at) VALUES(?, ?, ?, datetime('now'))", params = list(rid, best_id, as.integer(like))) ; dbExecute(con, "UPDATE respondents SET finished_at = datetime('now') WHERE respondent_id = ?", params = list(rid)) }

# Simulation controls
set.seed(42)
num_resp <- getOption("sim_num_resp", 150)
max_tasks <- getOption("sim_tasks", 10)

# Prior over true betas (reflect Slade-like preferences)
p <- ncol(profiles_X)
mu_true <- rep(0, p)
Sigma_true <- diag(p)
# Index helper for columns
gc <- function(name){ which(colnames(profiles_X) == name) }
# Set means: base pay increments, learning, manager enhanced, internal enhanced, small health
if ("Base pay|10%" %in% colnames(profiles_X)) mu_true[gc("Base pay|10%")] <- 0.10
if ("Base pay|20%" %in% colnames(profiles_X)) mu_true[gc("Base pay|20%")] <- 0.14
if ("Learning|40" %in% colnames(profiles_X)) mu_true[gc("Learning|40")] <- 0.20
if ("Learning|60+Mentor" %in% colnames(profiles_X)) mu_true[gc("Learning|60+Mentor")] <- 0.35
if ("Manager effectiveness|Enhanced" %in% colnames(profiles_X)) mu_true[gc("Manager effectiveness|Enhanced")] <- 0.60
if ("Internal job market|Enhanced" %in% colnames(profiles_X)) mu_true[gc("Internal job market|Enhanced")] <- 0.40
if ("Health care|Enhanced" %in% colnames(profiles_X)) mu_true[gc("Health care|Enhanced")] <- 0.10

# Simulate
for (r in seq_len(num_resp)){
  rid <- paste0("sim_", sprintf("%04d", r))
  record_start(con, rid)
  # Initialize belief
  mu <- rep(0, p); Sigma <- diag(p) * 1000
  candidate_ids <- profiles_df$profile_id
  Xdiff_hist <- NULL; y_hist <- c()
  for (t in seq_len(max_tasks)){
    pair <- pick_next_pair(candidate_ids, mu, Sigma, profiles_X)
    if (length(pair) == 0L) pair <- sample(candidate_ids, 2)
    a <- pair[1]; b <- pair[2]
    xdiff <- profiles_X[a, , drop = FALSE] - profiles_X[b, , drop = FALSE]
    pA <- 1/(1 + exp(-as.numeric(xdiff %*% mu_true)))
    choice <- if (runif(1) < pA) "A" else "B"
    y <- if (choice == "A") 1 else 0
    Xdiff_hist <- if (is.null(Xdiff_hist)) xdiff else rbind(Xdiff_hist, xdiff)
    y_hist <- c(y_hist, y)
    # Update MAP
    upd <- update_map(Xdiff_hist, y_hist, mu, Sigma)
    mu <- upd$mu; Sigma <- upd$Sigma
    record_task(con, rid, t, a, b, paste0("Choose ", choice))
  }
  # Final: best package under true beta
  utils <- as.numeric(profiles_X %*% mu_true)
  best_id <- profiles_df$profile_id[which.max(utils)]
  # Likelihood: scaled sigmoid of utility gap vs median
  u_best <- max(utils); u_med <- median(utils)
  like <- round(100 * (1/(1 + exp(-(u_best - u_med)))))
  record_final(con, rid, best_id, like)
}

message(sprintf("Simulated %d respondents with %d tasks each.", num_resp, max_tasks)) 