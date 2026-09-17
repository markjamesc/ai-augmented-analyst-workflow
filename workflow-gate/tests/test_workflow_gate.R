#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(jsonlite))

args <- commandArgs(trailingOnly = TRUE)
repo_root <- if (length(args) >= 1) normalizePath(args[[1]], mustWork = TRUE) else normalizePath(getwd(), mustWork = TRUE)
gate_script <- file.path(repo_root, "workflow-gate", "workflow_gate.R")

if (!file.exists(gate_script)) stop("Gate script not found: ", gate_script)

write_project <- function(root, reconciliation = "PASS") {
  artifacts <- file.path(root, "artifacts")
  dir.create(artifacts, recursive = TRUE, showWarnings = FALSE)

  write_json(
    list(
      stage = 1,
      status = "LOCKED",
      decision_statement = "Choose an action",
      decision_owner = "Test owner"
    ),
    file.path(artifacts, "stage1_decision.json"),
    pretty = TRUE,
    auto_unbox = TRUE
  )

  write_json(
    list(
      stage = 2,
      status = "LOCKED",
      analytical_question = "Which action is supported by the evidence?"
    ),
    file.path(artifacts, "stage2_framing.json"),
    pretty = TRUE,
    auto_unbox = TRUE
  )

  write_json(
    list(
      stage = 3,
      status = "LOCKED",
      design_version = "test-v1",
      population = "test population",
      grain = "test unit",
      window_start = "2026-01-01",
      window_end = "2026-02-01",
      decision_rules = list(rule = "test rule"),
      required_outputs = c("unit_id", "action")
    ),
    file.path(artifacts, "stage3_locked_design.json"),
    pretty = TRUE,
    auto_unbox = TRUE
  )

  write_json(
    list(
      stage = 4,
      status = if (identical(reconciliation, "PASS")) "PASS" else "FAIL",
      design_version_used = "test-v1",
      sql_source_gate = "PASS",
      fixtures = "PASS",
      r_a_status = "PASS",
      r_b_status = "PASS",
      reconciliation = reconciliation,
      validation_gate = if (identical(reconciliation, "PASS")) "PASS" else "FAIL",
      unresolved_issues = if (identical(reconciliation, "PASS")) 0 else 1
    ),
    file.path(artifacts, "stage4_validation_status.json"),
    pretty = TRUE,
    auto_unbox = TRUE
  )
}

run_gate <- function(project_root) {
  out <- system2(
    command = file.path(R.home("bin"), "Rscript"),
    args = c(shQuote(gate_script), shQuote(project_root)),
    stdout = TRUE,
    stderr = TRUE
  )
  attr(out, "status") %||% 0L
}

`%||%` <- function(x, y) if (is.null(x)) y else x

pass_root <- tempfile("workflow-gate-pass-")
dir.create(pass_root)
write_project(pass_root, reconciliation = "PASS")
pass_status <- run_gate(pass_root)
if (!identical(as.integer(pass_status), 0L)) {
  stop("Expected PASS fixture to return exit code 0; got ", pass_status)
}
pass_report <- fromJSON(file.path(pass_root, "artifacts", "workflow_gate_status.json"))
if (!identical(pass_report$result, "PASS") || !isTRUE(pass_report$stage5_allowed)) {
  stop("PASS fixture did not produce PASS / stage5_allowed=true")
}

fail_root <- tempfile("workflow-gate-fail-")
dir.create(fail_root)
write_project(fail_root, reconciliation = "FAIL")
fail_status <- run_gate(fail_root)
if (identical(as.integer(fail_status), 0L)) {
  stop("Expected FAIL fixture to return non-zero exit code")
}
fail_report <- fromJSON(file.path(fail_root, "artifacts", "workflow_gate_status.json"))
if (!identical(fail_report$result, "FAIL") || isTRUE(fail_report$stage5_allowed)) {
  stop("FAIL fixture did not produce FAIL / stage5_allowed=false")
}

cat("Workflow gate tests passed: known PASS accepted; deliberate reconciliation failure blocked.\n")
