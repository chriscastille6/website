# Session Information for Reproducibility
# Run this script to capture the exact R environment used for the analysis

# Capture session information
session_info <- sessionInfo()

# Print session information
cat("=== R SESSION INFORMATION ===\n\n")
print(session_info)

# Save session information to file
sink("session_info.txt")
print(session_info)
sink()

cat("\nSession information saved to 'session_info.txt'\n")

# Check if required packages are installed
required_packages <- c("koRpus", "quanteda", "quanteda.textstats", "koRpus.lang.en", 
                       "dplyr", "ggplot2", "knitr", "kableExtra")

cat("\n=== PACKAGE VERSION CHECK ===\n\n")

for(pkg in required_packages) {
  if(pkg %in% installed.packages()[,"Package"]) {
    version <- packageVersion(pkg)
    cat(sprintf("%-20s: %s\n", pkg, version))
  } else {
    cat(sprintf("%-20s: NOT INSTALLED\n", pkg))
  }
}

# Save package versions to file
package_versions <- sapply(required_packages, function(pkg) {
  if(pkg %in% installed.packages()[,"Package"]) {
    as.character(packageVersion(pkg))
  } else {
    "NOT INSTALLED"
  }
})

package_info <- data.frame(
  Package = names(package_versions),
  Version = unname(package_versions)
)

write.csv(package_info, "package_versions.csv", row.names = FALSE)
cat("\nPackage versions saved to 'package_versions.csv'\n")

cat("\n=== REPRODUCIBILITY CHECKLIST ===\n")
cat("✓ R version captured\n")
cat("✓ Package versions captured\n")
cat("✓ Session info saved to file\n")
cat("✓ Package versions saved to CSV\n")
cat("\nTo reproduce this analysis:\n")
cat("1. Install R version:", R.version.string, "\n")
cat("2. Install packages with versions listed above\n")
cat("3. Run the cognitive_load_analysis.R script\n") 