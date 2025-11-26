# Adaptive Employee Preferences Survey (Slade-style)
# Shiny app implementing: BYO -> Adaptive CBC -> Constructed package -> Likelihood-to-stay
# Storage: SQLite. Analysis is in analysis/estimate_and_optimize.R

# ---- Package setup ----
required_packages <- c(
  "shiny", "bslib", "dplyr", "tidyr", "purrr", "stringr", "tibble",
  "DBI", "RSQLite", "ggplot2", "digest", "MASS"
)
installed <- required_packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(required_packages[!installed], repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
  library(tibble)
  library(DBI)
  library(RSQLite)
  library(ggplot2)
})

# ---- Config ----
APP_TITLE <- "Employee Preferences Survey"
MAX_TASKS <- 10L
DB_PATH <- file.path(getwd(), "employee_preferences_app", "db", "app.sqlite")
if (!dir.exists(dirname(DB_PATH))) dir.create(dirname(DB_PATH), recursive = TRUE)

# Output directory for optional figures (not used in app runtime)
OUTPUT_DIR <- file.path(getwd(), "employee_preferences_app", "outputs")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# ---- Attribute and level definitions (Slade-style) ----
# Costs are per employee per year in $K (illustrative, aligned with analysis workflow)
attributes_df <- tribble(
  ~attribute,                ~level,               ~label,                                                                                 ~order, ~is_better_higher, ~cost_k,
  "Base pay",               "0%",                "No change in current annual base pay (with ongoing merit opportunity)",               1L,     TRUE,              0.0,
  "Base pay",               "10%",               "10% more than the current annual base pay (with ongoing merit opportunity)",         2L,     TRUE,              10.0,
  "Base pay",               "20%",               "20% more than current annual base pay (with ongoing merit opportunity)",            3L,     TRUE,              20.0,
  "Learning",               "0",                 "You negotiate training opportunities with your manager",                             1L,     TRUE,              0.0,
  "Learning",               "40",                "Managers are held accountable for ensuring at least 40 hours of formal training/yr", 2L,     TRUE,              1.5,
  "Learning",               "60+Mentor",         "Assurance of at least 60 hours of formal training per year, plus mentoring program", 3L,     TRUE,              2.5,
  "Manager effectiveness",  "Average",           "No change in your manager's effectiveness",                                         1L,     TRUE,              0.0,
  "Manager effectiveness",  "Enhanced",          "Organization invests to ensure your manager excels at delegating, motivating, being fair, and empowering", 2L, TRUE, 1.5,
  "Internal job market",    "StatusQuo",         "No change in current internal job market practices (i.e., online career center, current transfer policy)", 1L, TRUE, 0.0,
  "Internal job market",    "ApplyNoPermission", "You may apply for other internal positions without manager's permission",            2L,     TRUE,              0.5,
  "Internal job market",    "ActiveRecruit",     "Managers are allowed to actively recruit employees from other departments",          3L,     TRUE,              1.0,
  "Health care",            "Premium25to50",     "You pay a total monthly health care premium between $25–$50 for all dependent coverage", 1L, TRUE,         0.0,
  "Health care",            "NoChange",          "No change to current health care program",                                          2L,     TRUE,              2.0,
  "Health care",            "CashWaiver",        "You receive cash for waiving portions of health care coverage",                      3L,     TRUE,              1.0
) %>% arrange(attribute, order)

# Helper: list of attributes with their ordered levels
attr_levels <- attributes_df %>% group_by(attribute) %>% summarise(levels = list(level), .groups = "drop")

# Build the full profile grid
profiles_df <- attr_levels %>%
  pull(levels) %>%
  do.call(expand.grid, .) %>%
  as_tibble() %>%
  setNames(attr_levels$attribute) %>%
  mutate(profile_id = row_number(), .before = 1)

# Map each attribute-level to a cost_k and human-friendly label
level_meta <- attributes_df %>% select(attribute, level, label, cost_k)

# ---- Design coding (dummy coding with first level as baseline per attribute) ----
# Create a design matrix for profiles (no intercept). Returns matrix with column names like attr|level
build_design_matrix <- function(profiles_tbl) {
  mats <- lapply(unique(attributes_df$attribute), function(att){
    levs <- attributes_df %>% filter(attribute == att) %>% arrange(order) %>% pull(level)
    # baseline is first level -> create dummies for remaining levels
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

# Utility for a full profile: u = X %*% beta
# For pairwise 2-alternative tasks, we use difference coding: x = X_A - X_B and y = 1 if A chosen, else 0

# ---- Adaptive engine ----
# MAP update for binary logit on pairwise differences with Gaussian prior N(mu, Sigma)
update_map <- function(X_diff, y, mu, Sigma) {
  # X_diff: n x p, y in {0,1}
  neg_logpost <- function(b){
    eta <- as.numeric(X_diff %*% b)
    p <- 1/(1 + exp(-eta))
    # add small eps for numerical stability
    -sum(y*log(p + 1e-12) + (1 - y)*log(1 - p + 1e-12)) + 0.5 * t(b - mu) %*% solve(Sigma) %*% (b - mu)
  }
  b0 <- mu
  opt <- optim(b0, neg_logpost, method = "BFGS", control = list(maxit = 200))
  b_hat <- opt$par
  # Observed information at MAP
  eta <- as.numeric(X_diff %*% b_hat)
  p <- 1/(1 + exp(-eta))
  W <- diag(p * (1 - p) + 1e-9, nrow = length(p))
  H <- t(X_diff) %*% W %*% X_diff + solve(Sigma)
  V <- tryCatch(solve(H), error = function(e) MASS::ginv(H))
  list(mu = b_hat, Sigma = V)
}

# Simple D-optimal pair picker: sample candidate pairs and choose the one maximizing det(info)
pick_next_pair <- function(candidate_ids, mu, Sigma, profiles_X, n_pairs = 400L) {
  if (length(candidate_ids) < 2L) return(integer(0))
  draws <- replicate(n_pairs, sample(candidate_ids, 2L), simplify = FALSE)
  best <- NULL; best_score <- -Inf
  for (idx in draws) {
    Xa <- profiles_X[idx[1], , drop = FALSE]
    Xb <- profiles_X[idx[2], , drop = FALSE]
    Xdiff <- rbind(Xa - Xb)  # one-row matrix
    p <- 1/(1 + exp(-(Xdiff %*% mu)))
    W <- matrix(as.numeric(p * (1 - as.numeric(p)) + 1e-6), nrow = 1)
    info <- t(Xdiff) %*% W %*% Xdiff + solve(Sigma)
    d <- tryCatch(determinant(info, logarithm = TRUE)$modulus, error = function(e) -Inf)
    if (is.finite(d) && d > best_score) { best_score <- d; best <- idx }
  }
  unlist(best)
}

# Construct best package given current mu by scanning candidates and picking max utility
pick_best_profile <- function(candidate_ids, mu, profiles_X) {
  if (length(candidate_ids) == 0L) return(NA_integer_)
  utils <- as.numeric(profiles_X[candidate_ids, , drop = FALSE] %*% mu)
  candidate_ids[which.max(utils)]
}

# Generate a random hex respondent id
gen_id <- function() paste(sample(c(0:9, letters[1:6]), 32, replace = TRUE), collapse = "")

# ---- Storage (SQLite) ----
con <- dbConnect(RSQLite::SQLite(), DB_PATH)

ensure_schema <- function(con){
  dbExecute(con, "CREATE TABLE IF NOT EXISTS respondents (respondent_id TEXT PRIMARY KEY, started_at TEXT, finished_at TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS byo_answers (respondent_id TEXT, attribute TEXT, level TEXT, is_must INTEGER, unacceptable_levels TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS tasks (respondent_id TEXT, task_num INTEGER, altA_id INTEGER, altB_id INTEGER, choice TEXT, recorded_at TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS final_intentions (respondent_id TEXT, best_profile_id INTEGER, likelihood_stay INTEGER, recorded_at TEXT)")
}

ensure_schema(con)

record_start <- function(con, rid){
  dbExecute(con, "INSERT OR IGNORE INTO respondents(respondent_id, started_at) VALUES(?, datetime('now'))", params = list(rid))
}

record_byo <- function(con, rid, byo_tbl){
  # byo_tbl: attribute, selected_level, is_must, unacceptable_levels (character vector per row)
  if (nrow(byo_tbl) == 0) return(invisible(TRUE))
  df <- byo_tbl %>% mutate(unacceptable_levels = vapply(unacceptable_levels, function(x) paste(x, collapse = ","), character(1)))
  dbExecute(con, "DELETE FROM byo_answers WHERE respondent_id = ?", params = list(rid))
  dbWriteTable(con, "byo_answers", df %>% transmute(respondent_id = rid, attribute, level = selected_level, is_must = as.integer(is_must), unacceptable_levels), append = TRUE)
}

record_task <- function(con, rid, task_num, altA_id, altB_id, choice){
  dbExecute(con, "INSERT INTO tasks(respondent_id, task_num, altA_id, altB_id, choice, recorded_at) VALUES(?, ?, ?, ?, ?, datetime('now'))",
           params = list(rid, task_num, altA_id, altB_id, choice))
}

record_final <- function(con, rid, best_profile_id, likelihood){
  dbExecute(con, "INSERT OR REPLACE INTO final_intentions(respondent_id, best_profile_id, likelihood_stay, recorded_at) VALUES(?, ?, ?, datetime('now'))",
           params = list(rid, best_profile_id, as.integer(likelihood)))
  dbExecute(con, "UPDATE respondents SET finished_at = datetime('now') WHERE respondent_id = ?", params = list(rid))
}

# ---- Theme & Styles ----
THEME <- bs_theme(
  version = 5,
  bootswatch = "minty",
  primary = "#4F46E5",
  secondary = "#0EA5E9",
  success = "#10B981",
  warning = "#F59E0B",
  danger  = "#EF4444",
  base_font = bslib::font_google("Inter"),
  code_font = bslib::font_google("JetBrains Mono")
)

custom_css <- "
.hero-card { padding: 1rem 1.25rem; }
.app-card { transition: box-shadow .2s ease, transform .2s ease; }
.app-card:hover { box-shadow: 0 12px 30px rgba(2,6,23,.12), 0 6px 12px rgba(2,6,23,.06); transform: translateY(-2px); }
.option-card { transition: box-shadow .2s ease, transform .2s ease; }
.option-card:hover { box-shadow: 0 12px 30px rgba(2,6,23,.12), 0 6px 12px rgba(2,6,23,.06); transform: translateY(-2px); }
.progress { height: .5rem; background-color: var(--bs-gray-200); }
.progress-bar { background-color: var(--bs-primary); }
.btn { letter-spacing: .2px; }
.card-header { font-weight: 600; }
.table-sm th { width: 45%; }
"

# ---- UI ----
ui <- page_navbar(
  id = "main_nav",
  title = APP_TITLE,
  theme = THEME,
  
  nav_panel("Consent", 
    card(class = "hero-card app-card",
      card_header("Welcome"),
      card_body(
        tags$style(HTML(custom_css)),
        h3("Employee Preferences Survey", class = "mb-3"),
        # Explanatory section about Total Rewards Optimization (with APA citation) moved above intro paragraph
        div(class = "mb-3",
          card(class = "app-card",
            card_header("What is Total Rewards Optimization?"),
            card_body(
              p("Towers Perrin’s Total Rewards Optimization (TRO) uses conjoint analysis to quantify which rewards employees value most, and combines those preferences with program costs and expected impact on outcomes like attraction, retention, and engagement. This helps leaders allocate limited budgets to the mix of rewards employees value most while maximizing ROI."),
              tags$ul(class = "mb-2",
                tags$li("Give employees a voice via conjoint analysis to reveal preference trade-offs."),
                tags$li("Model the cost and impact of changes on attraction, retention, and engagement."),
                tags$li("Eliminate guesswork in plan design and tailor strategies to workforce segments.")
              ),
              p(class = "mb-0",
                em("APA: WTW. (2025). Total rewards optimization (TRO). "),
                a(href = "https://www.wtwco.com/en-us/solutions/services/total-rewards-optimization", target = "_blank",
                  "https://www.wtwco.com/en-us/solutions/services/total-rewards-optimization")
              )
            )
          )
        ),
        p(class = "text-muted", "Make a few quick choices to help us understand which rewards matter most."),
        tags$ul(class = "mb-3",
          tags$li("Choose preferred levels for each reward (Build-Your-Own)."),
          tags$li("Complete ", strong(MAX_TASKS), " short choice tasks (2 options each)."),
          tags$li("Review your constructed best package and rate your likelihood of staying.")
        ),
        div(class = "d-flex align-items-center gap-3 mt-3",
          checkboxInput("consent", "I consent to participate.", value = FALSE),
          actionButton("start_btn", "Start", class = "btn btn-primary", disabled = TRUE)
        )
      )
    )
  ),
  
  
  nav_panel("Choices", 
    card(class = "app-card",
      card_header("Please choose the option you prefer"),
      card_body(
        uiOutput("choice_ui"),
        div(class = "mt-3",
          textOutput("progress_text")
        )
      )
    )
  ),
  
  nav_panel("Your Package", 
    card(class = "app-card",
      card_header("Based on your choices, here is your best package"),
      card_body(
        uiOutput("best_pkg_ui"),
        uiOutput("likelihood_ui"),
        actionButton("submit_final", "Submit and finish", class = "btn btn-success")
      )
    )
  ),
  
  nav_panel("Thanks", 
    card(class = "app-card",
      card_body(
        h4("Thank you for participating."),
        p("You may now close this window.")
      )
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  # Enable Start when consent checked
  observe({
    shinyjs_enable <- function(id, enable = TRUE){ session$sendInputMessage(id, list(disabled = !enable)) }
    # fallback if shinyjs not used: toggle attribute directly via JS
    session$sendCustomMessage("toggleBtn", list(id = "start_btn", disabled = !isTRUE(input$consent)))
  })
  
  # Add a small JS helper to disable/enable buttons without shinyjs
  session$onFlushed(function(){
    session$sendCustomMessage("initJS", TRUE)
  })
  
  observeEvent(input$start_btn, {
    # Initialize first adaptive pair without BYO (to mirror Slade et al.)
    npair <- pick_next_pair(state$candidate_ids, state$mu, state$Sigma, profiles_X)
    if (length(npair) == 0L) npair <- sample(state$candidate_ids, 2)
    state$current_pair <- npair
    updateNavbarPage(session, inputId = "main_nav", selected = "Choices")
  })
  
  # Respondent state
  p <- ncol(profiles_X)
  state <- reactiveValues(
    rid = gen_id(),
    mu = rep(0, p),
    Sigma = diag(p) * 1000,
    candidate_ids = profiles_df$profile_id,
    tasks_done = 0L,
    Xdiff = NULL,
    y = NULL,
    current_pair = NULL,
    byo = NULL,
    likelihood_set = FALSE,
    likelihood_visible = FALSE
  )
  
  # Record start
  observeEvent(TRUE, {
    record_start(con, state$rid)
  }, once = TRUE)
  
  # (BYO removed to mirror Slade et al.; adaptive flow starts immediately after consent)
  
  # Render choice UI
  output$choice_ui <- renderUI({
    req(state$current_pair)
    ids <- state$current_pair
    a <- profiles_df %>% filter(profile_id == ids[1])
    b <- profiles_df %>% filter(profile_id == ids[2])
    
    panel_alt <- function(df, alt_label){
      rows <- lapply(names(df)[-1], function(att){
        lv <- as.character(df[[att]][1])
        label <- level_meta %>% filter(attribute == att, level == lv) %>% pull(label)
        tags$tr(
          tags$th(att),
          tags$td(if (length(label) == 0) lv else label)
        )
      })
      card(class = "option-card",
        card_header(alt_label),
        card_body(
          tags$table(class = "table table-sm",
            do.call(tags$tbody, rows)
          )
        )
      )
    }
    
    fluidRow(
      column(6, panel_alt(a, "Option A")),
      column(6, panel_alt(b, "Option B"))
    ) %>% tagList(
      div(class = "mt-3",
        actionButton("choose_A", "Choose A", class = "btn btn-primary me-2"),
        actionButton("choose_B", "Choose B", class = "btn btn-secondary")
      )
    )
  })
  
  output$progress_text <- renderUI({
    pct <- round(100 * (state$tasks_done)/MAX_TASKS)
    div(
      div(class = "progress",
        div(class = "progress-bar", role = "progressbar", style = paste0("width: ", pct, "%"), `aria-valuenow` = pct, `aria-valuemin` = 0, `aria-valuemax` = 100)
      ),
      div(class = "mt-1 text-muted small", paste0("Task ", state$tasks_done + 1L, " of ", MAX_TASKS))
    )
  })
  
  # Handle choice
  handle_choice <- function(choice_label){
    ids <- state$current_pair
    altA <- ids[1]; altB <- ids[2]
    xdiff <- profiles_X[altA, , drop = FALSE] - profiles_X[altB, , drop = FALSE]
    y <- if (choice_label == "A") 1 else 0
    # Append
    state$Xdiff <- if (is.null(state$Xdiff)) xdiff else rbind(state$Xdiff, xdiff)
    state$y <- c(state$y, y)
    # Update posterior
    u <- update_map(state$Xdiff, state$y, state$mu, state$Sigma)
    state$mu <- u$mu; state$Sigma <- u$Sigma
    # Record task
    record_task(con, state$rid, state$tasks_done + 1L, altA, altB, paste0("Choose ", choice_label))
    # Increment
    state$tasks_done <- state$tasks_done + 1L
    # Next step
    if (state$tasks_done >= MAX_TASKS) {
      updateNavbarPage(session, inputId = "main_nav", selected = "Your Package")
      return()
    }
    # Next pair
    npair <- pick_next_pair(state$candidate_ids, state$mu, state$Sigma, profiles_X)
    if (length(npair) == 0L) {
      # Fallback: random pair from candidates
      cand <- sample(state$candidate_ids, 2)
      state$current_pair <- cand
    } else {
      state$current_pair <- npair
    }
  }
  
  observeEvent(input$choose_A, handle_choice("A"))
  observeEvent(input$choose_B, handle_choice("B"))
  
  # Best package UI
  output$best_pkg_ui <- renderUI({
    # Determine best profile
    best_id <- pick_best_profile(state$candidate_ids, state$mu, profiles_X)
    req(!is.na(best_id))
    best <- profiles_df %>% filter(profile_id == best_id)
    cost <- 0
    rows <- lapply(names(best)[-1], function(att){
      lv <- as.character(best[[att]][1])
      meta <- level_meta %>% filter(attribute == att, level == lv)
      cost <<- cost + ifelse(nrow(meta) == 0, 0, meta$cost_k[1])
      label <- ifelse(nrow(meta) == 0, lv, meta$label[1])
      tags$tr(tags$th(att), tags$td(label))
    })
    tagList(
      tags$table(class = "table table-sm",
        tags$tbody(rows)
      ),
      div(class = "mt-2 text-muted", paste0("Approx. annual cost per employee: $", format(round(cost * 1000), big.mark = ",")))
    )
  })
  
  # Likelihood UI: start as not set; reveal slider only after user clicks
  output$likelihood_ui <- renderUI({
    if (!isTRUE(state$likelihood_visible)) {
      div(class = "mt-3",
        div(class = "text-muted small mb-2", "Likelihood to stay (not set)"),
        actionButton("init_likelihood", "Set likelihood", class = "btn btn-outline-primary btn-sm")
      )
    } else {
      tagList(
        sliderInput("likelihood", "How likely are you to stay with the company for the next 12 months, if you received this package?", min = 0, max = 100, value = 50, post = "%"),
        div(class = "text-muted small mb-2", "Please adjust the slider to record your answer (no default is recorded until you move it).")
      )
    }
  })

  observeEvent(input$init_likelihood, {
    state$likelihood_visible <- TRUE
  }, ignoreInit = TRUE)

  # Track likelihood slider interaction
  observeEvent(input$likelihood, ignoreInit = TRUE, {
    state$likelihood_set <- TRUE
  })
  
  # Final submission
  observeEvent(input$submit_final, {
    if (!isTRUE(state$likelihood_visible) || !isTRUE(state$likelihood_set)) {
      showNotification("Please set and adjust the likelihood before submitting.", type = "warning")
      return()
    }
    best_id <- pick_best_profile(state$candidate_ids, state$mu, profiles_X)
    record_final(con, state$rid, best_id, input$likelihood)
    updateNavbarPage(session, inputId = "main_nav", selected = "Thanks")
  })
}

# Small JS to toggle button disabled state without extra deps
js <- "
Shiny.addCustomMessageHandler('initJS', function(x){
  // no-op
});
Shiny.addCustomMessageHandler('toggleBtn', function(x){
  var el = document.getElementById(x.id);
  if(!el) return;
  if(x.disabled){ el.setAttribute('disabled','disabled'); } else { el.removeAttribute('disabled'); }
});
"

# Wrap UI with JS
ui <- tagList(
  tags$head(tags$script(HTML(js))),
  ui
)

# Create shiny app (do not auto-run here to allow parsing in non-interactive contexts)
app <- shinyApp(ui, server)

# If run directly (interactive), start the app
if (interactive()) {
  runApp(app, launch.browser = TRUE)
}

# Return the app object when sourced
app 