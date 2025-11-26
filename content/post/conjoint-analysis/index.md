---
title: "Using Conjoint Analysis to Optimize People Investments"
description: "Revisiting insights inspired by Slade (2002) for HR and executive decision-making."
date: 2025-07-06T00:00:00Z
lastmod: 2025-07-06T00:00:00Z
authors: ["admin"]
categories: ["analytics", "people-analytics", "experiments"]
tags: ["conjoint-analysis", "discrete-choice", "HR", "ROI"]
draft: true
featured: false
image:
  caption: ""
  focal_point: ""
  preview_only: true
---

Executive summary goes here.

### At a glance
- Key trade-offs quantified (salary vs. flexibility vs. manager quality vs. training)
- Relative importance and WTP charts below

![Relative Importance](/img/conjoint/attribute_importance.png)

![WTP](/img/conjoint/wtp.png)

## Why conjoint analysis for HR and CEOs

- What decisions it informs (e.g., compensation design, benefits, hybrid policies)
- How it quantifies trade-offs and ROI

## Study setup (reproduction overview)

This post accompanies an R script that simulates a discrete choice experiment (DCE), estimates a multinomial logit (MNL) model, and quantifies attribute importance and willingness-to-pay (WTP). The approach is inspired by Slade (2002) and demonstrates how to prioritize people investments.

- Data and code: See `cnjoint analysis/analysis.R`
- Figures and tables: see `static/img/conjoint/` (importance, WTP, power curve, efficient frontier, CSV tables)

## Key results

- Attribute importance chart
- WTP estimates
- Efficient frontier: best WTP per budget tier

![Efficient Frontier](/img/conjoint/efficient_frontier.png)

Power planning (simulation-based):

![Power Curve](/img/conjoint/power_curve.png)

### Budget tiers (Slade-style table excerpt)

For a given per-employee budget, the frontier suggests the following package with maximum WTP gain (salary-equivalent):

- $0K: training 0K, manager program 0, onsite; cost $0K; WTP +$0K
- $0.5K: training 0K, manager program 0, hybrid; cost $0.3K; WTP +$7.11K
- $2K: training 0K, manager program 1, hybrid; cost $1.8K; WTP +$21.81K
- $4K: training 2K, manager program 1, hybrid; cost $3.8K; WTP +$27.04K
- $8K: training 5K, manager program 1, hybrid; cost $6.8K; WTP +$34.88K

Full table: see `static/img/conjoint/frontier_by_budget.csv` and `frontier_pareto.csv`.

## Managerial implications

Actionable takeaways for compensation, benefits, and workplace policy.

## Appendix: Methods

Short methodological notes and references. 

## Total Rewards Optimization (TRO): 5-step workflow

- **1) Frame and map rewards**: Align business goals, define segments, and build a total rewards matrix (pay, benefits, learning, career, manager effectiveness, work design). Establish governance and success metrics.
- **2) Listen and measure preferences**: Use conjoint analysis to give employees a voice and quantify the relative value/willingness-to-pay for each reward element and level.
- **3) Quantify economics**: Model per-employee program costs and the financial value of outcomes (e.g., turnover costs, attraction/engagement implications) under alternative packages.
- **4) Optimize and scenario**: Compute the efficient frontier and evaluate budget-tier portfolios (e.g., B/C/D scenarios). Select the package that maximizes impact at the chosen investment.
- **5) Implement and monitor**: Tailor by segment, communicate the EVP, pilot/iterate, and track retention/engagement vs. plan.

Key reference: WTW Total Rewards Optimization (TRO) — data-driven employee listening, cost/impact modeling, and portfolio optimization [link](`https://www.wtwco.com/en-us/solutions/services/total-rewards-optimization`). This post applies the same principles with open R code, simulated data, and Slade-style frontier analysis. 

## Broadening the economics and bundle design

- **Additional cost components**: absenteeism, accidents/safety incidents, health claims, disability, overtime/coverage, and productivity losses. Convert each to $/employee/year to integrate with turnover economics.
- **Additional offerings to test**: workplace health promotion, employee assistance programs (EAP), financial wellness, caregiving supports (child/elder care), safety programs, PTO/policies, and flexible scheduling. Add as attributes/levels in the rewards matrix.
- **How to model**: estimate utilities via conjoint; map each offering to expected changes in outcomes (e.g., absenteeism days, incident rates, claims) using internal data or literature priors; monetize the outcome deltas; sum net benefits across outcomes; re-compute the efficient frontier and portfolio B/C/D at target budgets.
- **Result**: leaders can assemble a bundle of interventions that optimizes the human capital budget across retention, attendance, safety, and wellbeing, not just turnover. 