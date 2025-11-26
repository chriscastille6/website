# Assessment Data Export and Analysis Integration
# Location: /scripts/export_assessment_data.R
# Purpose: R scripts for exporting Supabase assessment data and connecting to existing analysis pipelines
# Why: Enables seamless integration between React assessments and R analysis workflows
# RELEVANT FILES: supabase-schema.sql, employee_preferences_app/analysis/*.R, cnjoint analysis/analysis.R

# Required packages
required_packages <- c(
  "DBI", "RPostgres", "tidyverse", "jsonlite", "lubridate", 
  "httr", "config", "here"
)

# Install missing packages
missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]
if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

# Load packages
suppressPackageStartupMessages({
  library(DBI)
  library(RPostgres)
  library(tidyverse)
  library(jsonlite)
  library(lubridate)
  library(httr)
})

# Supabase connection configuration
# Note: Replace with your actual Supabase credentials
SUPABASE_CONFIG <- list(
  url = Sys.getenv("SUPABASE_URL", "YOUR_SUPABASE_URL"),
  service_key = Sys.getenv("SUPABASE_SERVICE_KEY", "YOUR_SUPABASE_SERVICE_KEY"),
  db_host = Sys.getenv("SUPABASE_DB_HOST", "db.your-project.supabase.co"),
  db_port = as.integer(Sys.getenv("SUPABASE_DB_PORT", "5432")),
  db_name = Sys.getenv("SUPABASE_DB_NAME", "postgres"),
  db_user = Sys.getenv("SUPABASE_DB_USER", "postgres"),
  db_password = Sys.getenv("SUPABASE_DB_PASSWORD", "YOUR_DB_PASSWORD")
)

#' Connect to Supabase PostgreSQL database
#' @return DBI connection object
connect_supabase <- function() {
  tryCatch({
    con <- dbConnect(
      RPostgres::Postgres(),
      host = SUPABASE_CONFIG$db_host,
      port = SUPABASE_CONFIG$db_port,
      dbname = SUPABASE_CONFIG$db_name,
      user = SUPABASE_CONFIG$db_user,
      password = SUPABASE_CONFIG$db_password,
      sslmode = "require"
    )
    
    message("✓ Connected to Supabase database")
    return(con)
  }, error = function(e) {
    stop("Failed to connect to Supabase: ", e$message)
  })
}

#' Get assessment metadata
#' @param con Database connection
#' @param assessment_name Optional filter by assessment name
#' @return Tibble of assessment metadata
get_assessments <- function(con, assessment_name = NULL) {
  query <- "SELECT * FROM assessments WHERE is_active = TRUE"
  
  if (!is.null(assessment_name)) {
    query <- paste0(query, " AND name = '", assessment_name, "'")
  }
  
  query <- paste0(query, " ORDER BY created_at")
  
  result <- dbGetQuery(con, query) %>%
    as_tibble() %>%
    mutate(
      config = map(config, ~ fromJSON(.x, simplifyVector = FALSE)),
      created_at = as_datetime(created_at),
      updated_at = as_datetime(updated_at)
    )
  
  message("✓ Retrieved ", nrow(result), " assessment(s)")
  return(result)
}

#' Get participant data
#' @param con Database connection
#' @param assessment_id Optional filter by assessment ID
#' @param include_demographics Include demographic data
#' @return Tibble of participant data
get_participants <- function(con, assessment_id = NULL, include_demographics = TRUE) {
  query <- "
    SELECT p.*, 
           COUNT(r.id) as response_count,
           MAX(r.created_at) as last_response
    FROM participants p
    LEFT JOIN responses r ON p.id = r.participant_id"
  
  if (!is.null(assessment_id)) {
    query <- paste0(query, " AND r.assessment_id = '", assessment_id, "'")
  }
  
  query <- paste0(query, " GROUP BY p.id ORDER BY p.created_at")
  
  result <- dbGetQuery(con, query) %>%
    as_tibble() %>%
    mutate(
      created_at = as_datetime(created_at),
      last_active = as_datetime(last_active),
      last_response = as_datetime(last_response)
    )
  
  if (include_demographics) {
    result <- result %>%
      mutate(demographics = map(demographics, ~ fromJSON(.x, simplifyVector = FALSE)))
  } else {
    result <- result %>%
      select(-demographics)
  }
  
  message("✓ Retrieved ", nrow(result), " participant(s)")
  return(result)
}

#' Get response data
#' @param con Database connection
#' @param assessment_id Assessment ID to filter by
#' @param participant_id Optional participant ID filter
#' @return Tibble of response data
get_responses <- function(con, assessment_id, participant_id = NULL) {
  query <- "
    SELECT r.*, p.session_id
    FROM responses r
    JOIN participants p ON r.participant_id = p.id
    WHERE r.assessment_id = $1"
  
  params <- list(assessment_id)
  
  if (!is.null(participant_id)) {
    query <- paste0(query, " AND r.participant_id = $2")
    params <- append(params, participant_id)
  }
  
  query <- paste0(query, " ORDER BY r.participant_id, r.created_at")
  
  result <- dbGetQuery(con, query, params = params) %>%
    as_tibble() %>%
    mutate(
      response_data = map(response_data, ~ fromJSON(.x, simplifyVector = FALSE)),
      created_at = as_datetime(created_at)
    )
  
  message("✓ Retrieved ", nrow(result), " response(s)")
  return(result)
}

#' Get results data
#' @param con Database connection
#' @param assessment_id Assessment ID to filter by
#' @param participant_id Optional participant ID filter
#' @return Tibble of results data
get_results <- function(con, assessment_id, participant_id = NULL) {
  query <- "
    SELECT r.*, p.session_id
    FROM results r
    JOIN participants p ON r.participant_id = p.id
    WHERE r.assessment_id = $1"
  
  params <- list(assessment_id)
  
  if (!is.null(participant_id)) {
    query <- paste0(query, " AND r.participant_id = $2")
    params <- append(params, participant_id)
  }
  
  query <- paste0(query, " ORDER BY r.completed_at DESC")
  
  result <- dbGetQuery(con, query, params = params) %>%
    as_tibble() %>%
    mutate(
      scores = map(scores, ~ fromJSON(.x, simplifyVector = FALSE)),
      completed_at = as_datetime(completed_at)
    )
  
  message("✓ Retrieved ", nrow(result), " result(s)")
  return(result)
}

#' Export occupational fit (conjoint) data for existing analysis pipeline
#' @param con Database connection
#' @param assessment_name Name of the conjoint assessment (default: "occupational-fit")
#' @return List with choice_data and assessment_data for analysis.R compatibility
export_conjoint_data <- function(con, assessment_name = "occupational-fit") {
  message("Exporting conjoint analysis data...")
  
  # Get assessment metadata
  assessment <- get_assessments(con, assessment_name)
  if (nrow(assessment) == 0) {
    stop("Assessment '", assessment_name, "' not found")
  }
  
  assessment_id <- assessment$id[1]
  
  # Get responses
  responses <- get_responses(con, assessment_id)
  
  # Transform to format expected by existing conjoint analysis pipeline
  choice_data <- responses %>%
    filter(question_type == "conjoint_choice") %>%
    mutate(
      task_id = str_extract(question_id, "\\d+$") %>% as.integer(),
      chosen_alt = map_int(response_data, ~ .x$chosen_alternative + 1), # Convert 0-based to 1-based
      resp_id = session_id
    ) %>%
    select(resp_id, task_id, chosen_alt, response_data) %>%
    # Expand task data from response_data
    mutate(
      task_data = map(response_data, ~ .x$task_data)
    ) %>%
    unnest_wider(task_data) %>%
    select(-response_data)
  
  # Get assessment responses (post-task questions)
  assessment_data <- responses %>%
    filter(question_type %in% c("likert", "mcq")) %>%
    mutate(
      question_type_clean = case_when(
        str_detect(question_id, "interesting") ~ "interesting",
        str_detect(question_id, "useful") ~ "useful",
        str_detect(question_id, "share_employer") ~ "share_employer",
        TRUE ~ question_id
      ),
      response_value = case_when(
        question_type == "likert" ~ map_dbl(response_data, ~ .x$value),
        question_type == "mcq" ~ map_dbl(response_data, ~ .x$selected),
        TRUE ~ NA_real_
      )
    ) %>%
    select(session_id, question_type_clean, response_value) %>%
    pivot_wider(
      names_from = question_type_clean,
      values_from = response_value,
      id_cols = session_id
    ) %>%
    rename(resp_id = session_id)
  
  message("✓ Transformed ", nrow(choice_data), " choice observations")
  message("✓ Transformed ", nrow(assessment_data), " assessment responses")
  
  return(list(
    choice_data = choice_data,
    assessment_data = assessment_data,
    assessment_metadata = assessment
  ))
}

#' Export personality test data
#' @param con Database connection
#' @param assessment_name Name of the personality assessment (default: "personality-test")
#' @return List with item responses and scale scores
export_personality_data <- function(con, assessment_name = "personality-test") {
  message("Exporting personality test data...")
  
  # Get assessment metadata
  assessment <- get_assessments(con, assessment_name)
  if (nrow(assessment) == 0) {
    stop("Assessment '", assessment_name, "' not found")
  }
  
  assessment_id <- assessment$id[1]
  
  # Get item responses
  responses <- get_responses(con, assessment_id) %>%
    filter(question_type == "likert") %>%
    mutate(
      item_id = question_id,
      response_value = map_dbl(response_data, ~ .x$value),
      response_time = map_dbl(response_data, ~ .x$response_time %||% NA_real_)
    ) %>%
    select(session_id, item_id, response_value, response_time, created_at)
  
  # Get scale scores from results
  results <- get_results(con, assessment_id) %>%
    mutate(
      scale_scores = map(scores, ~ .x)
    ) %>%
    select(session_id, scale_scores, completed_at)
  
  message("✓ Retrieved ", nrow(responses), " item responses")
  message("✓ Retrieved ", nrow(results), " personality profiles")
  
  return(list(
    item_responses = responses,
    scale_scores = results,
    assessment_metadata = assessment
  ))
}

#' Export all assessment data to CSV files
#' @param output_dir Directory to save CSV files (default: "assessment_exports")
#' @param assessment_names Vector of assessment names to export (default: all active)
export_to_csv <- function(output_dir = "assessment_exports", assessment_names = NULL) {
  message("Exporting assessment data to CSV files...")
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Connect to database
  con <- connect_supabase()
  on.exit(dbDisconnect(con))
  
  # Get assessments to export
  assessments <- get_assessments(con, assessment_names)
  
  if (nrow(assessments) == 0) {
    stop("No assessments found to export")
  }
  
  for (i in seq_len(nrow(assessments))) {
    assessment <- assessments[i, ]
    assessment_name <- assessment$name
    assessment_id <- assessment$id
    
    message("Exporting ", assessment_name, "...")
    
    # Create assessment-specific directory
    assessment_dir <- file.path(output_dir, assessment_name)
    if (!dir.exists(assessment_dir)) {
      dir.create(assessment_dir)
    }
    
    # Export participants
    participants <- get_participants(con, assessment_id, include_demographics = FALSE)
    write_csv(participants, file.path(assessment_dir, "participants.csv"))
    
    # Export responses
    responses <- get_responses(con, assessment_id)
    
    # Flatten response_data for CSV export
    responses_flat <- responses %>%
      mutate(
        response_json = map_chr(response_data, ~ toJSON(.x, auto_unbox = TRUE))
      ) %>%
      select(-response_data)
    
    write_csv(responses_flat, file.path(assessment_dir, "responses.csv"))
    
    # Export results
    results <- get_results(con, assessment_id)
    
    # Flatten scores for CSV export
    results_flat <- results %>%
      mutate(
        scores_json = map_chr(scores, ~ toJSON(.x, auto_unbox = TRUE))
      ) %>%
      select(-scores)
    
    write_csv(results_flat, file.path(assessment_dir, "results.csv"))
    
    # Export assessment metadata
    assessment_meta <- assessment %>%
      mutate(
        config_json = toJSON(config, auto_unbox = TRUE)
      ) %>%
      select(-config)
    
    write_csv(assessment_meta, file.path(assessment_dir, "assessment_metadata.csv"))
    
    message("✓ Exported ", assessment_name, " to ", assessment_dir)
  }
  
  message("✓ Export complete. Files saved to: ", normalizePath(output_dir))
}

#' Generate assessment summary report
#' @param con Database connection
#' @param assessment_name Optional filter by assessment name
#' @return Tibble with summary statistics
generate_summary_report <- function(con, assessment_name = NULL) {
  message("Generating assessment summary report...")
  
  assessments <- get_assessments(con, assessment_name)
  
  summary_data <- map_dfr(assessments$id, function(assessment_id) {
    assessment_info <- assessments %>% filter(id == assessment_id)
    
    participants <- get_participants(con, assessment_id, include_demographics = FALSE)
    responses <- get_responses(con, assessment_id)
    results <- get_results(con, assessment_id)
    
    tibble(
      assessment_name = assessment_info$name,
      assessment_title = assessment_info$title,
      assessment_type = assessment_info$type,
      total_participants = nrow(participants),
      total_responses = nrow(responses),
      completed_assessments = nrow(results),
      completion_rate = round((nrow(results) / nrow(participants)) * 100, 1),
      avg_response_time_ms = mean(responses$response_time_ms, na.rm = TRUE),
      first_response = min(responses$created_at, na.rm = TRUE),
      last_response = max(responses$created_at, na.rm = TRUE),
      data_sharing_consent = sum(participants$consent_data_sharing, na.rm = TRUE),
      ai_coaching_consent = sum(participants$consent_ai_coaching, na.rm = TRUE)
    )
  })
  
  message("✓ Generated summary for ", nrow(summary_data), " assessment(s)")
  return(summary_data)
}

# Example usage functions
if (FALSE) {
  # Connect to database
  con <- connect_supabase()
  
  # Export conjoint data for existing analysis pipeline
  conjoint_data <- export_conjoint_data(con)
  
  # Save for use with existing analysis.R
  saveRDS(conjoint_data, "conjoint_data_export.rds")
  
  # Export personality data
  personality_data <- export_personality_data(con)
  
  # Generate summary report
  summary <- generate_summary_report(con)
  print(summary)
  
  # Export all data to CSV
  export_to_csv("assessment_exports")
  
  # Close connection
  dbDisconnect(con)
}
