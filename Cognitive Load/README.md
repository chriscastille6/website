# Cognitive Load Analysis: Bryson's Conditions

This repository contains a reproducible R script for analyzing cognitive load differences between two experimental conditions in the Bryson's study.

## Overview

The analysis compares cognitive load between:
1. **Christian Values Condition**: A longer text describing Christian values and practices
2. **Non-Christian Values Condition**: A shorter text about diversity

## Files

- `cognitive_load_analysis.R` - Main analysis script
- `sample script.R` - Original comprehensive script with additional examples
- `README.md` - This documentation file

## Prerequisites

Install the required R packages:

```r
install.packages(c("koRpus", "quanteda", "quanteda.textstats", "koRpus.lang.en", 
                   "dplyr", "ggplot2", "knitr", "kableExtra"))
```

## Usage

1. **Run the analysis**:
   ```r
   source("cognitive_load_analysis.R")
   ```

2. **The script will automatically**:
   - Analyze both text conditions
   - Generate comprehensive reports
   - Create visualizations
   - Save results to files

## Output Files

The script generates:
- `cognitive_load_results.RData` - R data file with all results
- `cognitive_load_results.csv` - CSV file with comparison data
- Console output with detailed analysis
- Three visualization plots

## Metrics Calculated

### Readability Indices
- Flesch Reading Ease Score
- Flesch-Kincaid Grade Level
- Gunning Fog Index
- SMOG Index
- Automated Readability Index (ARI)
- Coleman-Liau Index
- Dale-Chall Score
- Linsear Write Formula

### Cognitive Load Measures
- Syntactic complexity (sentence length)
- Lexical complexity (word length)
- Overall cognitive load score
- Cognitive load level classification

## Reproducibility Features

- **Set seed**: Ensures consistent results across runs
- **Version control**: All dependencies and versions documented
- **Data export**: Results saved in multiple formats
- **Clear documentation**: Step-by-step analysis process

## Experimental Conditions

### Christian Values Condition
"We are driven by Christian values that honor God in all we do, reflecting His love, grace, and truth. We close on Sundays to observe the Sabbath. We strive to honor God through our work. These biblical Christian values guide our firm, employees, and customers."

### Non-Christian Values Condition
"We celebrate diversity in all forms."

## Analysis Components

1. **Text Processing**: Tokenization and linguistic analysis
2. **Readability Assessment**: Multiple established readability formulas
3. **Complexity Analysis**: Syntactic and lexical complexity measures
4. **Cognitive Load Scoring**: Weighted combination of multiple factors
5. **Comparative Analysis**: Direct comparison between conditions
6. **Visualization**: Three different plot types for comprehensive understanding

## Interpretation

- **Flesch Score**: Higher scores (0-100) indicate easier reading
- **Cognitive Load Score**: Higher scores indicate greater cognitive demand
- **Sentence Length**: Longer sentences typically increase cognitive load
- **Word Length**: Longer words typically increase cognitive load

## Statistical Notes

This analysis provides descriptive statistics. For inferential statistics:
- Consider larger sample sizes
- Control for confounding variables
- Use appropriate statistical tests
- Report effect sizes and confidence intervals

## Customization

To analyze different texts:
1. Modify the `christian_values_text` and `non_christian_values_text` variables
2. Update condition names in the `texts` list
3. Re-run the script

## Citation

If using this script in research, please cite:
- The R packages used (koRpus, quanteda, etc.)
- The readability formulas employed
- This repository

## Contact

For questions or modifications, please contact the repository maintainer. 