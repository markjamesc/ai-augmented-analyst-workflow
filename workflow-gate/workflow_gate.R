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
if (!requireNamespace("digest", quietly = TRUE)) stop("Install digest to verify SHA-256 receipts")

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


# Prospective contract v2: explicit modes and content-addressed evidence.
# These checks supplement (never bypass) the original project checks.
text_scalar <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
enum <- function(x, values) text_scalar(x) && x %in% values
nonempty_strings <- function(x) {
  is.character(x) && length(x) > 0L && !anyNA(x) && all(nzchar(trimws(x)))
}
add_check("Capacity stance explicit", enum(stage2$capacity_stance, c("unordered_ok", "hard_attention_budget")), "Explicit Stage 2 enum required")
add_check("ML mode explicit", enum(stage3$ml_mode, c("None", "A", "B")), "Explicit Stage 3 enum required")
if (identical(stage2$capacity_stance, "hard_attention_budget")) {
  ranking <- stage3$ranking_contract
  add_check("Ranking contract locked",
    is.list(ranking) && text_scalar(ranking$key) && text_scalar(ranking$tie_break) &&
    text_scalar(ranking$capacity_unit) && isTRUE(ranking$membership_first) &&
    identical(ranking$padding_allowed, FALSE) &&
    (isTRUE(ranking$owner_n_deferred) ||
      (is.numeric(ranking$n) && length(ranking$n) == 1L && !is.na(ranking$n) &&
       is.finite(ranking$n) && ranking$n >= 1 && ranking$n == floor(ranking$n))),
    "Budget requires key, tie-break, unit, membership-first, no padding and N or explicit owner deferral")
}
add_check("Structural cross-review PASS", is_value(stage4, "structural_cross_review", "PASS"), "Required lower-tier receipt")
add_check("Fixture identity", text_scalar(stage3$fixture_version) &&
  identical(stage3$fixture_version, stage4$fixture_version_used), "Frozen fixture version must match")
model_required <- identical(stage3$ml_mode, "A")
add_check("Model requirement matches ML mode",
  identical(stage4$decision_critical_model_required, model_required), "Mode A requires a decision-critical model; None/B do not")
add_check("Model validation matches ML mode",
  if (model_required) identical(stage4$decision_critical_model_validation, "PASS")
  else identical(stage4$decision_critical_model_validation, "NOT_REQUIRED"),
  "Mode A requires PASS; None/B require NOT_REQUIRED for the judged path")

receipt_roles <- c("source", "fixtures", "reconciliation", "structural", "validation", "lineage")
if (model_required) receipt_roles <- c(receipt_roles, "model")
manifest <- stage4$evidence_receipts
verified_receipts <- list()
add_check("Evidence receipt roles", is.list(manifest) && all(receipt_roles %in% names(manifest)), "All required receipt roles must be declared")
root_normal <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
for (role in receipt_roles) {
  entry <- if (is.list(manifest)) manifest[[role]] else NULL
  safe <- is.list(entry) && text_scalar(entry$path) && text_scalar(entry$sha256) &&
    grepl("^[a-fA-F0-9]{64}$", entry$sha256) &&
    !grepl("^(/|[A-Za-z]:|\\\\)", entry$path) &&
    !(".." %in% strsplit(gsub("\\\\", "/", entry$path), "/", fixed = TRUE)[[1]])
  file <- if (safe) file.path(project_root, entry$path) else ""
  if (safe) safe <- file.exists(file) && !dir.exists(file) &&
    startsWith(normalizePath(file, winslash = "/", mustWork = TRUE), paste0(root_normal, "/")) &&
    isTRUE(file.info(file)$size > 0)
  hash_ok <- safe && identical(tolower(entry$sha256), digest::digest(file = file, algo = "sha256"))
  add_check(paste("Receipt hash", role), hash_ok, "Nonempty local receipt and exact SHA-256 required")
  if (!hash_ok) next
  receipt <- tryCatch(fromJSON(file, simplifyVector = TRUE), error = function(e) NULL)
  metadata_ok <- is.list(receipt) && identical(receipt$status, "PASS") &&
    identical(receipt$design_version, stage3$design_version) &&
    identical(receipt$fixture_version, stage3$fixture_version) && text_scalar(receipt$checked_at_utc)
  add_check(paste("Receipt metadata", role), metadata_ok, "PASS, design/fixture identities and timestamp required")
  if (identical(role, "reconciliation")) {
    critical <- stage3$reconciliation_critical_fields
    add_check("Reconciliation scorecard", is.list(receipt) &&
      nonempty_strings(critical) && nonempty_strings(receipt$fields) &&
      setequal(critical, receipt$fields) &&
      is.numeric(receipt$mismatch_count) && identical(as.numeric(receipt$mismatch_count), 0) &&
      is.numeric(receipt$row_count) && length(receipt$row_count) == 1L &&
      !is.na(receipt$row_count) && is.finite(receipt$row_count) && receipt$row_count >= 0 &&
      receipt$row_count == floor(receipt$row_count), "All locked fields and zero mismatches required")
  }
  if (identical(role, "fixtures")) {
    cases <- receipt$cases
    add_check("Fixture scorecard", is.data.frame(cases) && nrow(cases) > 0 &&
      all(c("id", "expected", "observed_a", "observed_b") %in% names(cases)) &&
      nonempty_strings(cases$id) && !anyDuplicated(cases$id) &&
      nonempty_strings(stage3$fixture_ids) && setequal(cases$id, stage3$fixture_ids) &&
      !anyNA(cases) && all(cases$expected == cases$observed_a) &&
      all(cases$expected == cases$observed_b), "Every frozen fixture must match expected in both paths")
  }
  if (identical(role, "lineage")) {
    add_check("Lineage contents", is.list(receipt) && text_scalar(receipt$source_snapshot) &&
      text_scalar(receipt$extract_identity) && nonempty_strings(receipt$script_versions),
      "Source snapshot, extract identity and script versions required")
  }
  verified_receipts[[role]] <- entry
}

all_pass <- length(checks) > 0 && all(vapply(checks, function(x) identical(x$result, "PASS"), logical(1)))

dir.create(artifacts_dir, recursive = TRUE, showWarnings = FALSE)

gate_output <- list(
  contract_version = "prospective-v2",
  design_version = stage3$design_version,
  fixture_version = stage3$fixture_version,
  evidence_receipts = verified_receipts,
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
