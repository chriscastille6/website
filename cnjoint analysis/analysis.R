# Package setup
required_packages <- c("tidyverse", "mlogit", "scales")
installed <- required_packages %in% rownames(installed.packages())
if (any(!installed)) install.packages(required_packages[!installed], repos = "https://cloud.r-project.org")
suppressPackageStartupMessages({
  library(tidyverse)
  library(mlogit)
  library(scales)
})

set.seed(123)

# Simulate a simple HR-focused DCE inspired by Slade (2002)
# Attributes: salary, training budget, manager quality, flexibility
salary_levels <- c(80, 100, 120) # in $K
training_levels <- c(0, 2, 5)    # in $K per employee
manager_levels <- c("average", "good")
flex_levels <- c("onsite", "hybrid", "remote")

attrs <- expand_grid(
  salary = salary_levels,
  training = training_levels,
  manager = manager_levels,
  flexibility = flex_levels
)

# Generate choice sets (2 alternatives per task)
num_tasks <- 12
num_resp <- 200
alts_per_task <- 2

choice_sets <- tibble(resp_id = rep(1:num_resp, each = num_tasks)) %>%
  group_by(resp_id) %>%
  group_modify(~{
    map_dfr(1:num_tasks, function(task_id){
      sample_rows <- sample(nrow(attrs), alts_per_task)
      tibble(task_id = task_id, alt_id = 1:alts_per_task) %>%
        bind_cols(attrs[sample_rows, ])
    })
  }) %>%
  ungroup()

# True utilities to simulate choices
# Utilities are linear-in-parameters with effects-coded categoricals
salary_beta <- 0.04      # per $1K
training_beta <- 0.10    # per $1K
manager_good_beta <- 0.6
flex_hybrid_beta <- 0.3
flex_remote_beta <- 0.25

sim_data <- choice_sets %>%
  mutate(
    manager_good = if_else(manager == "good", 1, 0),
    flex_hybrid = if_else(flexibility == "hybrid", 1, 0),
    flex_remote = if_else(flexibility == "remote", 1, 0),
    util = salary_beta * salary +
           training_beta * training +
           manager_good_beta * manager_good +
           flex_hybrid_beta * flex_hybrid +
           flex_remote_beta * flex_remote +
           rnorm(n(), sd = 0.25)
  ) %>%
  group_by(resp_id, task_id) %>%
  mutate(choice_prob = exp(util) / sum(exp(util))) %>%
  ungroup() %>%
  group_by(resp_id, task_id) %>%
  mutate(chosen = as.integer(rank(-choice_prob, ties.method = "random") == 1L)) %>%
  ungroup()

# Prepare for mlogit
mlogit_df <- sim_data %>%
  mutate(
    alt = paste0("alt", alt_id),
    chid = paste(resp_id, task_id, sep = "_")
  ) %>%
  arrange(resp_id, task_id, alt_id) %>%
  mlogit.data(
    choice = "chosen",
    shape = "long",
    chid.var = "chid",
    alt.var = "alt",
    id.var = "resp_id"
  )

# Estimate MNL
mnl_fit <- mlogit(
  chosen ~ salary + training + manager_good + flex_hybrid + flex_remote | 0,
  data = mlogit_df
)

print(summary(mnl_fit))

# Attribute importance (range of part-worths)
# For continuous variables (salary, training): use range over levels observed
coef_est <- coef(mnl_fit)

range_salary <- (max(salary_levels) - min(salary_levels)) * coef_est["salary"]
range_training <- (max(training_levels) - min(training_levels)) * coef_est["training"]
range_manager <- abs(coef_est["manager_good"]) # vs average baseline
range_flex <- max(0, coef_est["flex_hybrid"], coef_est["flex_remote"]) - min(0, coef_est["flex_hybrid"], coef_est["flex_remote"]) 

imp_tbl <- tibble(
  attribute = c("Salary", "Training", "Manager quality", "Flexibility"),
  range = c(range_salary, range_training, range_manager, range_flex)
) %>%
  mutate(importance = 100 * range / sum(range)) %>%
  arrange(desc(importance))

print(imp_tbl)

# WTP: translate non-monetary betas into salary $K equivalents
wtp_tbl <- tibble(
  attribute_level = c("Manager: good vs average", "Flex: hybrid vs onsite", "Flex: remote vs onsite", "Training: +$1K"),
  wtp_k = c(
    coef_est["manager_good"]/coef_est["salary"],
    coef_est["flex_hybrid"]/coef_est["salary"],
    coef_est["flex_remote"]/coef_est["salary"],
    coef_est["training"]/coef_est["salary"]
  )
)

print(wtp_tbl)

# Save plots
out_dir <- "/Users/ccastille/Documents/GitHub/Website/PAL-of-the-Bayou/static/img/conjoint"
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Importance bar chart
p_imp <- imp_tbl %>%
  ggplot(aes(x = reorder(attribute, importance), y = importance)) +
  geom_col(fill = "#3B82F6") +
  coord_flip() +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  labs(x = NULL, y = "Attribute importance (%)",
       title = "Relative Importance of People Investment Attributes") +
  theme_minimal(base_size = 12)

ggsave(file.path(out_dir, "attribute_importance.png"), p_imp, width = 7, height = 4, dpi = 150)

# WTP chart
p_wtp <- wtp_tbl %>%
  ggplot(aes(x = reorder(attribute_level, wtp_k), y = wtp_k)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_col(fill = "#10B981") +
  coord_flip() +
  labs(x = NULL, y = "Willingness-to-pay (in $K salary equivalent)",
       title = "WTP for Non-Monetary Attributes") +
  theme_minimal(base_size = 12)

ggsave(file.path(out_dir, "wtp.png"), p_wtp, width = 7, height = 4, dpi = 150)

# Write CSV outputs for transparency
readr::write_csv(imp_tbl, file.path(out_dir, "importance.csv"))
readr::write_csv(wtp_tbl, file.path(out_dir, "wtp.csv"))

# Efficient frontier: maximize WTP (utility in $K) under per-employee budget
# Define discrete policy options and assumed per-employee annual costs (in $K)
frontier_grid <- expand_grid(
  training_k = c(0, 2, 5),
  manager_prog = c(0, 1),  # 1 = invest to move average->good
  flexibility = c("onsite", "hybrid", "remote")
) %>%
  mutate(
    cost_k = training_k +
      if_else(manager_prog == 1, 1.5, 0) +
      case_when(
        flexibility == "onsite" ~ 0,
        flexibility == "hybrid" ~ 0.3,
        flexibility == "remote" ~ 0.5,
        TRUE ~ 0
      ),
    manager_good = manager_prog,
    flex_hybrid = as.integer(flexibility == "hybrid"),
    flex_remote = as.integer(flexibility == "remote"),
    # WTP gain in $K salary equivalent vs baseline (0 training, average manager, onsite)
    wtp_gain_k = (coef_est["training"] * training_k +
                  coef_est["manager_good"] * manager_good +
                  coef_est["flex_hybrid"] * flex_hybrid +
                  coef_est["flex_remote"] * flex_remote) / coef_est["salary"],
    roi = if_else(cost_k > 0, wtp_gain_k / cost_k, NA_real_)
  )

# Pareto frontier (non-dominated by (cost_k, wtp_gain_k))
frontier_set <- frontier_grid %>%
  arrange(cost_k, desc(wtp_gain_k)) %>%
  group_by(cost_k) %>%
  slice_max(order_by = wtp_gain_k, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(cost_k) %>%
  mutate(is_efficient = wtp_gain_k >= cummax(wtp_gain_k)) %>%
  filter(is_efficient) %>%
  select(training_k, manager_prog, flexibility, cost_k, wtp_gain_k, roi)

# Also compute best plan at selected budget tiers
budget_tiers <- c(0, 0.5, 1, 2, 3, 4, 5, 6, 8)
frontier_by_budget <- map_dfr(budget_tiers, function(b){
  frontier_grid %>%
    filter(cost_k <= b) %>%
    arrange(desc(wtp_gain_k), cost_k) %>%
    slice_head(n = 1) %>%
    mutate(budget_k = b)
}) %>%
  select(budget_k, training_k, manager_prog, flexibility, cost_k, wtp_gain_k, roi)

readr::write_csv(frontier_grid, file.path(out_dir, "frontier_all_options.csv"))
readr::write_csv(frontier_set, file.path(out_dir, "frontier_pareto.csv"))
readr::write_csv(frontier_by_budget, file.path(out_dir, "frontier_by_budget.csv"))

p_frontier <- ggplot(frontier_grid, aes(x = cost_k, y = wtp_gain_k)) +
  geom_point(alpha = 0.3, color = "#94A3B8") +
  geom_step(data = frontier_set, aes(x = cost_k, y = wtp_gain_k), color = "#EF4444", linewidth = 1) +
  geom_point(data = frontier_set, aes(x = cost_k, y = wtp_gain_k), color = "#EF4444", size = 2) +
  labs(x = "Annual cost per employee ($K)", y = "WTP gain ($K, salary equivalent)",
       title = "Efficient Frontier of People Investment Options",
       subtitle = "Frontier shows best achievable WTP for a given per-employee budget") +
  theme_minimal(base_size = 12)

ggsave(file.path(out_dir, "efficient_frontier.png"), p_frontier, width = 7.5, height = 4.5, dpi = 150)

# --- Slade-style reproduction: portfolios A–D ---
# Assumptions calibrated to the article narrative
N_employees <- 1000
turnover_cost_per_sep <- 200000  # $200K per separation
baseline_turnover_rate <- 0.15   # 15%

# Reward elements and levels
slade_grid <- expand_grid(
  base_pay_inc = c(0, 10, 20),     # % increase
  learning_hrs = c(0, 40),         # 0 vs mandatory 40 hours
  manager_prog = c(0, 1),          # 0=no, 1=yes
  internal_market = c(0, 1),       # 0=weak, 1=strong
  health_enhanced = c(0, 1)        # 0=current, 1=enhanced
)

# Costs per employee ($K) for each element
avg_salary_k <- 100
slade_costs <- slade_grid %>%
  mutate(
    cost_k = (base_pay_inc/100) * avg_salary_k +
      if_else(learning_hrs == 40, 1.5, 0) +
      if_else(manager_prog == 1, 1.5, 0) +
      if_else(internal_market == 1, 1.0, 0) +
      if_else(health_enhanced == 1, 2.0, 0)
  )

# Preference weights (utility units), reflecting diminishing returns for pay
# and higher value on manager/learning/internal market vs. health
u_base_pay <- function(pct){ ifelse(pct == 0, 0, ifelse(pct == 10, 1.0, 1.4)) }
slade_utils <- slade_costs %>%
  mutate(
    util = u_base_pay(base_pay_inc) +
      if_else(learning_hrs == 40, 1.2, 0) +
      if_else(manager_prog == 1, 2.0, 0) +
      if_else(internal_market == 1, 1.5, 0) +
      if_else(health_enhanced == 1, 0.4, 0)
  )

# Baseline portfolio A reflecting higher health spend, less in manager/internal
portfolio_A <- slade_utils %>%
  filter(base_pay_inc == 0, learning_hrs == 0, manager_prog == 0, internal_market == 0, health_enhanced == 1) %>%
  slice(1)

# Calibrate utility->retention mapping so that best same-cost portfolio (C) yields -4pp turnover
A_cost <- portfolio_A$cost_k
A_util <- portfolio_A$util

# Candidate C: maximize util with cost <= A_cost
portfolio_C <- slade_utils %>%
  filter(cost_k <= A_cost + 1e-9) %>%
  arrange(desc(util), cost_k) %>% slice(1)

# Map utility delta to turnover change: turnover = baseline - beta*(util - A_util)
# Choose beta so that C gives -4pp
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

slade_all <- calc_metrics(slade_utils)

# --- Extend ROI: performance utility (productivity uplift) ---
revenue_per_employee_usd <- 300000   # average revenue per FTE
margin_pct <- 0.20                   # profit margin
# Calibrate so that portfolio C implies ~1% productivity uplift vs A
util_delta_C <- (portfolio_C$util - A_util)
prod_gamma <- ifelse(util_delta_C > 0, 0.01 / util_delta_C, 0.0)

slade_all <- slade_all %>% mutate(
  prod_uplift_pct = pmax(0, prod_gamma * (util - A_util)),
  prod_value_musd = (N_employees * revenue_per_employee_usd * margin_pct * prod_uplift_pct) / 1e6,
  net_benefit_total_musd = net_benefit_musd + prod_value_musd
)

readr::write_csv(slade_all %>% select(base_pay_inc, learning_hrs, manager_prog, internal_market,
                                      health_enhanced, cost_k, invest_delta_musd, turnover_rate,
                                      turnover_drop_pp, savings_musd, prod_uplift_pct, prod_value_musd,
                                      net_benefit_musd, net_benefit_total_musd),
                 file.path(out_dir, "roi_extended.csv"))
# --- end performance utility extension ---

# Portfolio B: keep turnover ~same (within 0.1pp) but reduce investment (invest_delta_musd < 0), maximize net benefit
portfolio_B <- slade_all %>%
  filter(abs(turnover_drop_pp) < 0.001, invest_delta_musd < 0) %>%
  arrange(desc(net_benefit_musd)) %>% slice_head(n = 1)

# Recompute C with metrics
portfolio_Cm <- slade_all %>% filter(base_pay_inc == portfolio_C$base_pay_inc,
                                     learning_hrs == portfolio_C$learning_hrs,
                                     manager_prog == portfolio_C$manager_prog,
                                     internal_market == portfolio_C$internal_market,
                                     health_enhanced == portfolio_C$health_enhanced)

# Portfolio D: invest about +$7.5M (±$0.5M), maximize net benefit
portfolio_D <- slade_all %>%
  filter(invest_delta_musd >= 7.0, invest_delta_musd <= 8.0) %>%
  arrange(desc(net_benefit_musd)) %>% slice_head(n = 1)

slade_out <- bind_rows(
  portfolio_A %>% mutate(label = "A"),
  portfolio_B %>% mutate(label = "B"),
  portfolio_Cm %>% mutate(label = "C"),
  portfolio_D %>% mutate(label = "D")
) %>%
  select(label, base_pay_inc, learning_hrs, manager_prog, internal_market, health_enhanced,
         cost_k, invest_delta_musd, turnover_rate, turnover_drop_pp, savings_musd, net_benefit_musd) %>%
  arrange(label)

readr::write_csv(slade_out, file.path(out_dir, "slade_portfolios.csv"))

# Calibrated (narrative-matched) Slade table
target_B_invest <- -1.5
target_B_drop <- 0.00

pick_closest <- function(df, invest_target, drop_target, tol_invest = 0.3, tol_drop = 0.003){
  cand <- df %>% mutate(
    invest_err = abs(invest_delta_musd - invest_target),
    drop_err = abs(turnover_drop_pp - drop_target),
    score = invest_err + 5*drop_err
  ) %>% arrange(score, desc(net_benefit_musd)) %>% slice(1)
  cand
}

cand_B <- pick_closest(slade_all, target_B_invest, target_B_drop)

# Targets for C and D
target_C_invest <- 0.0
target_C_drop <- 0.04
cand_C <- pick_closest(slade_all, target_C_invest, target_C_drop)

target_D_invest <- 7.5
target_D_drop <- 0.07
cand_D <- pick_closest(slade_all, target_D_invest, target_D_drop)

slade_out2 <- bind_rows(
  portfolio_A %>% mutate(label = "A"),
  cand_B %>% mutate(label = "B"),
  cand_C %>% mutate(label = "C"),
  cand_D %>% mutate(label = "D")
) %>%
  select(label, base_pay_inc, learning_hrs, manager_prog, internal_market, health_enhanced,
         cost_k, invest_delta_musd, turnover_rate, turnover_drop_pp, savings_musd, net_benefit_musd) %>%
  arrange(label)

readr::write_csv(slade_out2, file.path(out_dir, "slade_portfolios_calibrated.csv"))

# Plot Slade-style efficient frontier: retention increase (pp) vs investment delta ($M)
slade_frontier <- slade_all %>%
  arrange(invest_delta_musd, desc(turnover_drop_pp)) %>%
  group_by(invest_delta_musd) %>%
  slice_max(order_by = turnover_drop_pp, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(invest_delta_musd) %>%
  mutate(is_efficient = turnover_drop_pp >= cummax(turnover_drop_pp)) %>%
  filter(is_efficient)

# Points A, B, C, D from calibrated table
abcd <- slade_out2 %>% mutate(retention_pp = turnover_drop_pp,
                              invest_m = invest_delta_musd)

p_slade <- ggplot(slade_all, aes(x = invest_delta_musd, y = turnover_drop_pp)) +
  geom_point(alpha = 0.15, color = "#94A3B8") +
  geom_step(data = slade_frontier, aes(x = invest_delta_musd, y = turnover_drop_pp),
            color = "#111827", linewidth = 1) +
  geom_point(data = abcd, aes(x = invest_m, y = retention_pp), color = "#EF4444", size = 2) +
  geom_text(data = abcd, aes(x = invest_m, y = retention_pp, label = label), vjust = -1, size = 3) +
  scale_x_continuous(name = "Decrease / Increase in investment from current ($M)") +
  scale_y_continuous(name = "Increase in indicated retention (percentage points)") +
  labs(title = "Total Rewards Efficient Frontier (Slade-style)",
       subtitle = "A/B/C/D denote portfolios; curve shows optimal retention for each investment level") +
  theme_minimal(base_size = 12)

ggsave(file.path(out_dir, "slade_frontier.png"), p_slade, width = 7.5, height = 4.5, dpi = 150)
# --- end Slade-style reproduction ---

# --- Power analysis (simulation-based) ---
# Vary respondents and tasks; estimate power to detect selected effects at alpha=0.05

simulate_power <- function(num_resp, num_tasks, alts_per_task = 2, reps = 100, seed = 123){
  set.seed(seed)
  results <- vector("list", reps)
  for(r in seq_len(reps)){
    choice_sets_r <- tibble(resp_id = rep(1:num_resp, each = num_tasks)) %>%
      group_by(resp_id) %>%
      group_modify(~{
        map_dfr(1:num_tasks, function(task_id){
          sample_rows <- sample(nrow(attrs), alts_per_task)
          tibble(task_id = task_id, alt_id = 1:alts_per_task) %>%
            bind_cols(attrs[sample_rows, ])
        })
      }) %>%
      ungroup()

    sim_data_r <- choice_sets_r %>%
      mutate(
        manager_good = if_else(manager == "good", 1, 0),
        flex_hybrid = if_else(flexibility == "hybrid", 1, 0),
        flex_remote = if_else(flexibility == "remote", 1, 0),
        util = salary_beta * salary +
               training_beta * training +
               manager_good_beta * manager_good +
               flex_hybrid_beta * flex_hybrid +
               flex_remote_beta * flex_remote +
               rnorm(n(), sd = 0.25)
      ) %>%
      group_by(resp_id, task_id) %>%
      mutate(choice_prob = exp(util) / sum(exp(util))) %>%
      ungroup() %>%
      group_by(resp_id, task_id) %>%
      mutate(chosen = as.integer(rank(-choice_prob, ties.method = "random") == 1L)) %>%
      ungroup() %>%
      mutate(
        alt = paste0("alt", alt_id),
        chid = paste(resp_id, task_id, sep = "_")
      )

    mlogit_df_r <- mlogit.data(
      sim_data_r,
      choice = "chosen",
      shape = "long",
      chid.var = "chid",
      alt.var = "alt",
      id.var = "resp_id"
    )

    fit_r <- try(mlogit(chosen ~ salary + training + manager_good + flex_hybrid + flex_remote | 0, data = mlogit_df_r), silent = TRUE)
    if(inherits(fit_r, "try-error")){
      results[[r]] <- tibble(manager_good = NA, flex_hybrid = NA, flex_remote = NA, salary = NA, training = NA)
    } else {
      coefs <- coef(fit_r)
      ses <- sqrt(diag(vcov(fit_r)))
      z <- coefs / ses
      pvals <- 2*pnorm(-abs(z))
      results[[r]] <- tibble(
        manager_good = as.integer(pvals["manager_good"] < 0.05),
        flex_hybrid  = as.integer(pvals["flex_hybrid"]  < 0.05),
        flex_remote  = as.integer(pvals["flex_remote"]  < 0.05),
        salary       = as.integer(pvals["salary"]       < 0.05),
        training     = as.integer(pvals["training"]     < 0.05)
      )
    }
  }
  bind_rows(results) %>% summarise(across(everything(), ~mean(.x, na.rm = TRUE))) %>%
    mutate(n = num_resp, tasks = num_tasks)
}

n_grid <- c(50, 100, 150, 200, 300, 400, 600, 800)
task_grid <- c(8, 12)

power_results <- map_dfr(task_grid, function(tk){
  map_dfr(n_grid, function(nn){ simulate_power(nn, tk, alts_per_task = 2, reps = 30) })
})

readr::write_csv(power_results, file.path(out_dir, "power_results.csv"))

p_power <- power_results %>%
  select(n, tasks, manager_good, flex_hybrid, flex_remote) %>%
  pivot_longer(cols = c(manager_good, flex_hybrid, flex_remote), names_to = "parameter", values_to = "power") %>%
  mutate(parameter = recode(parameter,
                            manager_good = "Manager: good",
                            flex_hybrid = "Flex: hybrid",
                            flex_remote = "Flex: remote")) %>%
  ggplot(aes(x = n, y = power, color = parameter)) +
  geom_line(size = 1) +
  geom_point(size = 1.5) +
  facet_wrap(~ tasks, labeller = labeller(tasks = function(x) paste0(x, " tasks/resp"))) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_x_continuous(breaks = n_grid) +
  labs(x = "Respondents (n)", y = "Power (alpha = 0.05)",
       title = "Simulation-based Power for Key Attributes",
       subtitle = "Higher n and more tasks per respondent increase detection power") +
  theme_minimal(base_size = 12) +
  theme(legend.title = element_blank())

ggsave(file.path(out_dir, "power_curve.png"), p_power, width = 8, height = 4.5, dpi = 150)

message("Analysis complete. Figures saved to ", out_dir) 