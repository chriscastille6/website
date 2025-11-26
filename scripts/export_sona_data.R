# Export SONA Data for IRB
# Location: /scripts/export_sona_data.R
# Purpose: Export study data and assessment results for IRB review
# Why: Provides anonymized data exports for IRB access to approved studies
# RELEVANT FILES: supabase-schema.sql, static/assessments/admin/irb-dashboard.html

library(DBI)
library(RPostgres)

# Supabase connection configuration
SUPABASE_CONFIG <- list(
  url = Sys.getenv("SUPABASE_URL"),
  service_key = Sys.getenv("SUPABASE_SERVICE_KEY"),
  db_host = Sys.getenv("SUPABASE_DB_HOST"),
  db_port = 5432,
  db_name = "postgres",
  db_user = "postgres",
  db_password = Sys.getenv("SUPABASE_DB_PASSWORD")
)

#' Connect to Supabase database
connect_supabase <- function() {
  con <- dbConnect(
    Postgres(),
    host = SUPABASE_CONFIG$db_host,
    port = SUPABASE_CONFIG$db_port,
    dbname = SUPABASE_CONFIG$db_name,
    user = SUPABASE_CONFIG$db_user,
    password = SUPABASE_CONFIG$db_password
  )
  return(con)
}

#' Export study data for IRB
#' @param study_id UUID of the study
#' @param output_dir Directory to save exports
export_study_data <- function(study_id, output_dir = "sona_exports") {
  con <- connect_supabase()
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Get study information
  study <- dbGetQuery(con, paste0(
    "SELECT * FROM sona_studies WHERE id = '", study_id, "'"
  ))
  
  if (nrow(study) == 0) {
    stop("Study not found")
  }
  
  # Get participants (anonymized - participant IDs only)
  participants <- dbGetQuery(con, paste0(
    "SELECT sp.*, p.participant_id, p.created_at as participant_created_at
     FROM study_participants sp
     JOIN participants p ON sp.participant_id = p.id
     WHERE sp.study_id = '", study_id, "'"
  ))
  
  # Get assessment results
  results <- dbGetQuery(con, paste0(
    "SELECT r.*, a.name as assessment_name, a.title as assessment_title,
            p.participant_id
     FROM results r
     JOIN assessments a ON r.assessment_id = a.id
     JOIN participants p ON r.participant_id = p.id
     JOIN study_participants sp ON sp.participant_id = p.id
     WHERE sp.study_id = '", study_id, "'"
  ))
  
  # Get assessments used in study
  assessments <- dbGetQuery(con, paste0(
    "SELECT a.* FROM assessments a
     JOIN study_assessments sa ON a.id = sa.assessment_id
     WHERE sa.study_id = '", study_id, "'"
  ))
  
  # Save exports
  study_file <- file.path(output_dir, paste0("study_", study$sona_study_id, ".csv"))
  write.csv(study, study_file, row.names = FALSE)
  
  participants_file <- file.path(output_dir, paste0("participants_", study$sona_study_id, ".csv"))
  write.csv(participants, participants_file, row.names = FALSE)
  
  results_file <- file.path(output_dir, paste0("results_", study$sona_study_id, ".csv"))
  write.csv(results, results_file, row.names = FALSE)
  
  assessments_file <- file.path(output_dir, paste0("assessments_", study$sona_study_id, ".csv"))
  write.csv(assessments, assessments_file, row.names = FALSE)
  
  cat("Exported study data to:", output_dir, "\n")
  cat("- Study info:", study_file, "\n")
  cat("- Participants:", participants_file, "\n")
  cat("- Results:", results_file, "\n")
  cat("- Assessments:", assessments_file, "\n")
  
  dbDisconnect(con)
  
  return(list(
    study = study,
    participants = participants,
    results = results,
    assessments = assessments
  ))
}

#' Export all studies for IRB review
#' @param output_dir Directory to save exports
export_all_studies <- function(output_dir = "sona_exports") {
  con <- connect_supabase()
  
  # Get all studies
  studies <- dbGetQuery(con, "SELECT * FROM sona_studies ORDER BY created_at DESC")
  
  if (nrow(studies) == 0) {
    cat("No studies found\n")
    dbDisconnect(con)
    return(NULL)
  }
  
  # Export each study
  for (i in 1:nrow(studies)) {
    cat("Exporting study:", studies$sona_study_id[i], "\n")
    tryCatch({
      export_study_data(studies$id[i], output_dir)
    }, error = function(e) {
      cat("Error exporting study", studies$sona_study_id[i], ":", e$message, "\n")
    })
  }
  
  dbDisconnect(con)
}

# Example usage:
# export_study_data("study-uuid-here")
# export_all_studies()




