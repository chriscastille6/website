# Conjoint analysis (Slade 2002 inspired)

This folder contains a self-contained simulation and estimation in R that demonstrates how conjoint (discrete choice) analysis quantifies trade-offs among people investments.

## Files
- `analysis.R`: Simulates a discrete choice experiment, estimates a multinomial logit (MNL), computes attribute importance and willingness-to-pay (WTP), efficient frontier, and simulation-based power; saves outputs.
- `Slade et al. - 2002 - How Microsoft optimized its investment in people a.pdf`: Background article that inspired this demonstration.

## Setup
Ensure you have R installed. The script will auto-install required packages if missing: `tidyverse`, `mlogit`, and `scales`.

## Run
From the repository root:

```sh
Rscript "cnjoint analysis/analysis.R"
```

Outputs will be written to:
- `PAL-of-the-Bayou/static/img/conjoint/attribute_importance.png`
- `PAL-of-the-Bayou/static/img/conjoint/wtp.png`
- `PAL-of-the-Bayou/static/img/conjoint/efficient_frontier.png`
- `PAL-of-the-Bayou/static/img/conjoint/power_curve.png`
- CSVs: `importance.csv`, `wtp.csv`, `frontier_all_options.csv`, `frontier_pareto.csv`, `frontier_by_budget.csv`, `power_results.csv`

## Resource requirements and audience
- Who is this for: HR leadership (Total Rewards, CHRO), People Analytics, CFO/COO; consultants designing Total Rewards or flexible work policies.
- Org size guidance: works for SMBs (n≈100–500) and enterprises (n≥1,000). If segment reporting is required, plan for roughly ≥200 per key subgroup (Sawtooth guidance) or ≥300 overall for aggregate credibility.
- Budget/time: survey programming and panel recruitment typically 2–6 weeks; analysis and reporting 1–3 weeks. Costs depend on sampling and incentive strategy.
- Sample size heuristics: start with 300 overall; ≥200 per critical subgroup; ensure ~500–1000 exposures per level across the sample. Validate with simulation-based power (see `power_curve.png`).

## Citations and further reading
- Halversen, C. (2020). Sample Size Rule of Thumb for CBC. Sawtooth Software Blog. `https://sawtoothsoftware.com/resources/blog/posts/sample-size-rules-of-thumb`
- Sambandam, R. (2017). How to Determine Sample Size in Conjoint Studies. Quirk’s/TRC. `https://trcmarketresearch.com/whitepaper/how-to-determine-sample-size-in-conjoint-studies/`
- Mas, A., & Pallais, A. (2017). Valuing Alternative Work Arrangements. NBER Working Paper 22708; AEA Research Highlights; NBER Digest. `https://www.nber.org/digest/dec16/putting-price-tags-alternative-work-arrangements`
- Mas, A., & Pallais, A. (2019). Labor Supply and the Value of Non-Work Time. AER: Insights. `https://www.aeaweb.org/articles?id=10.1257/aeri.20180070`
- Maestas, N., Mullen, K., Powell, D., von Wachter, T., & Wenger, J. (2018). The Value of Working Conditions… (RAND). `http://www.econ.ucla.edu/tvwachter/papers/working_conditions_mmpwvw_Oct2018_webpage.pdf`
- WorldatWork (Total Rewards guidance). `https://thehrc.com/elevating-the-impact-of-your-organizations-total-rewards/`

Notes: This demo uses simulated data to illustrate workflow and ROI framing; replace attributes/levels/costs with your organization’s specifics. 