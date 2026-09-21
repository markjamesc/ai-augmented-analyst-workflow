#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(jsonlite))
if (!requireNamespace("digest", quietly = TRUE)) stop("Install digest before running tests")

args <- commandArgs(trailingOnly = TRUE)
repo_root <- if (length(args) >= 1L) normalizePath(args[[1]], mustWork = TRUE) else normalizePath(getwd(), mustWork = TRUE)
gate_script <- file.path(repo_root, "procedure-gate", "procedure_gate.R")
if (!file.exists(gate_script)) stop("Procedure Gate not found: ", gate_script)

# Test the small checking functions separately from the command-line runner.
gate <- new.env()
sys.source(gate_script, envir = gate)
gate$procedure_script_path <- function() gate_script

stopifnot(!gate$checks_pass(list()))
stopifnot(!gate$checks_pass(list(list(result = NULL))))
stopifnot(!gate$checks_pass(list(list(result = NA_character_))))
stopifnot(!gate$checks_pass(list(list(result = c("PASS", "FAIL")))))
stopifnot(!gate$checks_pass(list(list(result = "PASS"), list(result = "FAIL"))))
stopifnot(gate$checks_pass(list(list(result = "PASS"))))
stopifnot(identical(gate$`%not_in%`(c("start", "finish"), "start"), c(FALSE, TRUE)))

`%||%` <- function(x, y) if (is.null(x)) y else x

run_gate <- function(...) {
  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(shQuote(gate_script), vapply(list(...), shQuote, character(1))),
    stdout = TRUE,
    stderr = TRUE
  )
  list(output = output, status = as.integer(attr(output, "status") %||% 0L))
}

write_receipt <- function(root, name, value) {
  dir.create(file.path(root, "artifacts"), recursive = TRUE, showWarnings = FALSE)
  write_json(value, file.path(root, "artifacts", name), pretty = TRUE, auto_unbox = TRUE)
}

write_stage1 <- function(root) {
  write_receipt(root, "stage1_decision.json", list(
    stage = 1, status = "LOCKED", decision_statement = "Choose one action", decision_owner = "Test owner",
    ai2_independent_reconstruction = "PASS", ai3_independent_red_team = "PASS",
    start_gate = "PASS", stakeholder_confirmation = "CONFIRMED",
    human_analyst_approval = "APPROVED", unresolved_issues = 0
  ))
}

write_stage2 <- function(root) {
  write_receipt(root, "stage2_framing.json", list(
    stage = 2, status = "LOCKED", analytical_question = "Which action is supported?", capacity_stance = "unordered_ok",
    ai1_builder = "PASS", ai2_decision_fit_review = "PASS", ai3_framing_red_team = "PASS",
    cross_review = "PASS", framing_gate = "PASS", stakeholder_approval = "APPROVED",
    human_analyst_approval = "APPROVED", unresolved_issues = 0
  ))
}

write_stage3 <- function(root) {
  write_receipt(root, "stage3_locked_design.json", list(
    stage = 3,
    status = "LOCKED",
    design_version = "test-v1",
    population = "test population",
    grain = "test unit",
    window_start = "2026-01-01",
    window_end = "2026-02-01",
    decision_rules = list(rule = "test rule"),
    required_outputs = c("id", "action"),
    ml_mode = "None",
    ai1_independent_design = "PASS",
    ai2_independent_design = "PASS",
    ai3_independent_risk_dossier = "PASS",
    information_barrier = "PASS",
    cross_review = "PASS",
    design_gates = "PASS",
    human_analyst_approval = "APPROVED",
    unresolved_issues = 0,
    fixture_version = "fixtures-v1",
    fixture_ids = c("F01", "F02"),
    reconciliation_critical_fields = c("id", "action")
  ))
}

write_stage4 <- function(root) {
  evidence_dir <- file.path(root, "evidence-v2")
  dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
  roles <- c("source", "fixtures", "reconciliation", "structural", "validation", "lineage")
  evidence_receipts <- list()
  for (role in roles) {
    receipt <- list(
      status = "PASS",
      design_version = "test-v1",
      fixture_version = "fixtures-v1",
      checked_at_utc = "2026-09-21T00:00:00Z"
    )
    if (identical(role, "fixtures")) {
      receipt$cases <- data.frame(
        id = c("F01", "F02"),
        expected = c("A", "B"),
        observed_a = c("A", "B"),
        observed_b = c("A", "B")
      )
    }
    if (identical(role, "reconciliation")) {
      receipt$fields <- c("id", "action")
      receipt$mismatch_count <- 0
      receipt$row_count <- 2
    }
    if (identical(role, "lineage")) {
      receipt$source_snapshot <- "synthetic-source-v1"
      receipt$extract_identity <- "synthetic-extract-v1"
      receipt$script_versions <- c("r-a:test", "r-b:test")
    }
    relative_path <- paste0("evidence-v2/", role, ".json")
    full_path <- file.path(root, relative_path)
    write_json(receipt, full_path, pretty = TRUE, auto_unbox = TRUE)
    evidence_receipts[[role]] <- list(
      path = relative_path,
      sha256 = digest::digest(file = full_path, algo = "sha256")
    )
  }
  write_receipt(root, "stage4_validation_status.json", list(
    stage = 4,
    status = "PASS",
    design_version_used = "test-v1",
    sql_source_gate = "PASS",
    fixtures = "PASS",
    r_a_status = "PASS",
    r_b_status = "PASS",
    reconciliation = "PASS",
    structural_cross_review = "PASS",
    validation_gate = "PASS",
    unresolved_issues = 0,
    fixture_version_used = "fixtures-v1",
    decision_critical_model_required = FALSE,
    decision_critical_model_validation = "NOT_REQUIRED",
    evidence_receipts = evidence_receipts
  ))
}

write_stage5 <- function(root) {
  workflow_path <- file.path(root, "artifacts", "workflow_gate_status.json")
  if (!file.exists(workflow_path)) stop("Workflow Gate report missing before Stage 5 fixture")
  write_receipt(root, "stage5_interpretation_status.json", list(
    stage = 5,
    status = "PASS",
    workflow_gate_report_sha256 = digest::digest(file = workflow_path, algo = "sha256"),
    ai1_first_pass = "PASS",
    ai2_first_pass = "PASS",
    ai3_first_pass = "PASS",
    information_barrier = "PASS",
    cross_review = "PASS",
    finish_gates = "PASS",
    human_analyst_approval = "APPROVED",
    unresolved_issues = 0,
    deliverables = c("stage5-evidence.md", "stage5-decision.md", "monitoring-plan.md")
  ))
}

project_root <- tempfile("procedure-gate-")
dir.create(project_root)

result <- run_gate("start", project_root, "TEST-001")
stopifnot(identical(result$status, 0L))

# Existing evidence cannot substitute for authorization.
write_stage1(project_root)
result <- run_gate("complete", project_root, "start")
stopifnot(!identical(result$status, 0L))
unlink(file.path(project_root, "artifacts", "stage1_decision.json"))

result <- run_gate("finalize", project_root)
stopifnot(!identical(result$status, 0L))

# A future stage cannot begin before its prerequisites.
result <- run_gate("begin", project_root, "design")
stopifnot(!identical(result$status, 0L))

# A missing receipt prevents completion but leaves the authorized step open for repair.
result <- run_gate("begin", project_root, "start")
stopifnot(identical(result$status, 0L))
result <- run_gate("complete", project_root, "start")
stopifnot(!identical(result$status, 0L))
# A receipt cannot pass on LOCKED alone; the existing role and approval procedure must be recorded.
write_receipt(project_root, "stage1_decision.json", list(
  stage = 1, status = "LOCKED", decision_statement = "Choose one action", decision_owner = "Test owner"
))
result <- run_gate("complete", project_root, "start")
stopifnot(!identical(result$status, 0L))
write_stage1(project_root)
result <- run_gate("complete", project_root, "start")
stopifnot(identical(result$status, 0L))

# Completed steps cannot be reopened.
result <- run_gate("begin", project_root, "start")
stopifnot(!identical(result$status, 0L))

result <- run_gate("begin", project_root, "framing")
stopifnot(identical(result$status, 0L))
write_stage2(project_root)
result <- run_gate("complete", project_root, "framing")
stopifnot(identical(result$status, 0L))

result <- run_gate("begin", project_root, "design")
stopifnot(identical(result$status, 0L))
write_stage3(project_root)
result <- run_gate("complete", project_root, "design")
stopifnot(identical(result$status, 0L))

result <- run_gate("begin", project_root, "execution")
stopifnot(identical(result$status, 0L))
result <- run_gate("complete", project_root, "execution")
stopifnot(!identical(result$status, 0L))
write_stage4(project_root)

# A superficially PASS Stage 4 receipt still fails if lower-tier evidence fails.
source_receipt <- file.path(project_root, "evidence-v2", "source.json")
write_json(list(status = "FAIL"), source_receipt)
result <- run_gate("complete", project_root, "execution")
stopifnot(!identical(result$status, 0L))
result <- run_gate("begin", project_root, "finish")
stopifnot(!identical(result$status, 0L))
write_stage4(project_root)
result <- run_gate("complete", project_root, "execution")
stopifnot(identical(result$status, 0L))
stopifnot(file.exists(file.path(project_root, "artifacts", "workflow_gate_status.json")))

result <- run_gate("begin", project_root, "finish")
stopifnot(identical(result$status, 0L))
write_stage5(project_root)

# Every required role/review/approval field must fail when individually absent.
for (step in c("start", "framing", "design", "finish")) {
  definition <- gate$step_by_id(gate$read_procedure(), step)
  receipt <- fromJSON(file.path(project_root, definition$artifact), simplifyVector = FALSE)
  stopifnot(gate$checks_pass(gate$validate_stage_receipt(step, receipt, project_root)))
  required_fields <- names(receipt)[vapply(receipt, function(value) {
    is.character(value) && length(value) == 1L && value %in% c("PASS", "APPROVED", "CONFIRMED")
  }, logical(1))]
  for (field in required_fields) {
    missing_field <- receipt
    missing_field[[field]] <- NULL
    stopifnot(!gate$checks_pass(gate$validate_stage_receipt(step, missing_field, project_root)))
  }
}

result <- run_gate("complete", project_root, "finish")
stopifnot(identical(result$status, 0L))

# A completed receipt cannot be changed silently before certification.
write_receipt(project_root, "stage1_decision.json", list(stage = 1, status = "LOCKED"))
result <- run_gate("finalize", project_root)
stopifnot(!identical(result$status, 0L))
write_stage1(project_root)
result <- run_gate("finalize", project_root)
stopifnot(identical(result$status, 0L))

certificate_path <- file.path(project_root, "artifacts", "final_certificate.json")
stopifnot(file.exists(certificate_path))
certificate <- fromJSON(certificate_path, simplifyVector = TRUE)
stopifnot(identical(certificate$result, "PASS"), isTRUE(certificate$certified))

state <- fromJSON(file.path(project_root, "artifacts", "procedure", "run_state.json"), simplifyVector = TRUE)
stopifnot(identical(state$status, "CERTIFIED"))

unlink(project_root, recursive = TRUE)
cat("Procedure Gate tests passed: illegal transitions blocked; five-stage run certified.\n")
