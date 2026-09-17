#!/usr/bin/env Rscript

# Five-Stage Workflow Gate
# ------------------------
# Purpose: verify that the required procedural controls were actually completed
# before Stage 5 is allowed to begin.
#
# This script does NOT redo Stage 4 analytical reconciliation. R-A / R-B and
# their reconciliation remain inside Stage 4. This gate verifies that the
# required Stage 1-4 artifacts exist, are locked/passed, use the same Stage 3
# design version, and contain no unresolved validation failures.
#
# Usage:
#   Rscript workflow-gate/workflow_gate.R
#   Rscript workflow-gate/workflow_gate.R /path/to/project
#
# Dependency:
#   install.packages("jsonlite")

suppressPackageStartupMessages(library(jsonlite))

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1) normalizePath(args[[1]], mustWork = FALSE) else getwd()
artifacts_dir <- file.path(project_root, "artifacts")

paths <- list(
  stage1 = file.path(artifacts_dir, "stage1_decision.json"),
  stage2 = file.path(artifacts_dir, "stage2_framing.json"),
  stage3 = file.path(artifacts_dir, "stage3_locked_design.json"),
  stage4 = file.path(artifacts_dir, "stage4_validation_status.json"),
  gate   = file.path(artifacts_dir, "workflow_gate_status.json")
)

checks <- list()
add_check <- function(name, pass, detail) {
  checks[[length(checks) + 1]] <<- list(
    check = name,
    result = if (isTRUE(pass)) "PASS" else "FAIL",
    detail = detail
  )
}

read_json_safe <- function(path, label) {
  if (!file.exists(path)) {
    add_check(paste(label, "artifact exists"), FALSE, paste("Missing:", path))
    return(NULL)
  }

  out <- tryCatch(
    fromJSON(path, simplifyVector = TRUE),
    error = function(e) e
  )

  if (inherits(out, "error")) {
    add_check(paste(label, "artifact parses"), FALSE, conditionMessage(out))
    return(NULL)
  }

  add_check(paste(label, "artifact exists"), TRUE, path)
  add_check(paste(label, "artifact parses"), TRUE, "Valid JSON")
  out
}

has_fields <- function(x, fields) {
  if (is.null(x)) return(FALSE)
  all(fields %in% names(x))
}

is_value <- function(x, field, expected) {
  !is.null(x) && field %in% names(x) && identical(as.character(x[[field]]), as.character(expected))
}

stage1 <- read_json_safe(paths$stage1, "Stage 1")
stage2 <- read_json_safe(paths$stage2, "Stage 2")
stage3 <- read_json_safe(paths$stage3, "Stage 3")
stage4 <- read_json_safe(paths$stage4, "Stage 4")

# Stage 1: decision must be explicitly locked.
required_stage1 <- c("stage", "status", "decision_statement", "decision_owner")
add_check(
  "Stage 1 required fields",
  has_fields(stage1, required_stage1),
  paste("Required:", paste(required_stage1, collapse = ", "))
)
add_check(
  "Stage 1 locked",
  is_value(stage1, "status", "LOCKED"),
  "status must equal LOCKED"
)

# Stage 2: framing question must be explicitly locked.
required_stage2 <- c("stage", "status", "analytical_question")
add_check(
  "Stage 2 required fields",
  has_fields(stage2, required_stage2),
  paste("Required:", paste(required_stage2, collapse = ", "))
)
add_check(
  "Stage 2 locked",
  is_value(stage2, "status", "LOCKED"),
  "status must equal LOCKED"
)

# Stage 3: machine-readable measurement contract.
required_stage3 <- c(
  "stage", "status", "design_version", "population", "grain",
  "window_start", "window_end", "decision_rules", "required_outputs"
)
add_check(
  "Stage 3 required fields",
  has_fields(stage3, required_stage3),
  paste("Required:", paste(required_stage3, collapse = ", "))
)
add_check(
  "Stage 3 locked",
  is_value(stage3, "status", "LOCKED"),
  "status must equal LOCKED"
)

# Stage 4: report the results of the existing analytical validation process.
required_stage4 <- c(
  "stage", "status", "design_version_used", "sql_source_gate",
  "fixtures", "r_a_status", "r_b_status", "reconciliation",
  "validation_gate", "unresolved_issues"
)
add_check(
  "Stage 4 required fields",
  has_fields(stage4, required_stage4),
  paste("Required:", paste(required_stage4, collapse = ", "))
)

if (!is.null(stage3) && !is.null(stage4) &&
    "design_version" %in% names(stage3) && "design_version_used" %in% names(stage4)) {
  same_version <- identical(
    as.character(stage3$design_version),
    as.character(stage4$design_version_used)
  )
  add_check(
    "Stage 4 used locked Stage 3 version",
    same_version,
    paste0("Stage 3=", stage3$design_version, "; Stage 4=", stage4$design_version_used)
  )
} else {
  add_check(
    "Stage 4 used locked Stage 3 version",
    FALSE,
    "Version fields unavailable"
  )
}

for (field in c("sql_source_gate", "fixtures", "r_a_status", "r_b_status", "reconciliation", "validation_gate")) {
  add_check(
    paste("Stage 4", field),
    is_value(stage4, field, "PASS"),
    paste(field, "must equal PASS")
  )
}

issues_ok <- !is.null(stage4) &&
  "unresolved_issues" %in% names(stage4) &&
  !is.na(suppressWarnings(as.numeric(stage4$unresolved_issues))) &&
  as.numeric(stage4$unresolved_issues) == 0
add_check(
  "Stage 4 unresolved issues",
  issues_ok,
  "unresolved_issues must equal 0"
)

add_check(
  "Stage 4 overall status",
  is_value(stage4, "status", "PASS"),
  "status must equal PASS"
)

all_pass <- length(checks) > 0 && all(vapply(checks, function(x) identical(x$result, "PASS"), logical(1)))

dir.create(artifacts_dir, recursive = TRUE, showWarnings = FALSE)

gate_output <- list(
  gate = "five_stage_workflow_gate",
  result = if (all_pass) "PASS" else "FAIL",
  stage5_allowed = all_pass,
  checked_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  project_root = project_root,
  checks = checks
)

write_json(gate_output, paths$gate, pretty = TRUE, auto_unbox = TRUE, null = "null")

cat("\nFive-Stage Workflow Gate\n")
cat("========================\n")
for (x in checks) {
  cat(sprintf("%-46s %s\n", x$check, x$result))
}
cat("------------------------\n")
cat("OVERALL:", gate_output$result, "\n")
cat("STAGE 5 ALLOWED:", if (gate_output$stage5_allowed) "YES" else "NO", "\n")
cat("REPORT:", paths$gate, "\n\n")

if (!all_pass) {
  quit(status = 1, save = "no")
}

quit(status = 0, save = "no")
