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


# Synthetic receipts exercise the gate contract, not any real project outcome.
upgrade_fixture <- function(root, files) {
  values <- lapply(files, function(p) fromJSON(file.path(root, p), simplifyVector = TRUE))
  values[[2]]$capacity_stance <- "unordered_ok"
  values[[3]]$ml_mode <- if (isTRUE(values[[4]]$decision_critical_model_required)) "A" else "None"
  values[[3]]$fixture_version <- "fixtures-v1"
  values[[3]]$fixture_ids <- c("F01", "F02")
  values[[3]]$reconciliation_critical_fields <- c("id", "action")
  values[[4]]$fixture_version_used <- "fixtures-v1"
  values[[4]]$structural_cross_review <- "PASS"
  values[[4]]$decision_critical_model_required <- identical(values[[3]]$ml_mode, "A")
  values[[4]]$decision_critical_model_validation <- if (identical(values[[3]]$ml_mode, "A")) "PASS" else "NOT_REQUIRED"
  roles <- c("source", "fixtures", "reconciliation", "structural", "validation", "lineage")
  if (identical(values[[3]]$ml_mode, "A")) roles <- c(roles, "model")
  dir.create(file.path(root, "evidence-v2"), showWarnings = FALSE)
  receipts <- list()
  for (role in roles) {
    v <- list(status = "PASS", design_version = values[[3]]$design_version,
      fixture_version = "fixtures-v1", checked_at_utc = "2026-09-20T00:00:00Z")
    if (role == "fixtures") v$cases <- data.frame(id = c("F01", "F02"), expected = c("A", "B"), observed_a = c("A", "B"), observed_b = c("A", "B"))
    if (role == "reconciliation") {
      v$fields <- c("id", "action"); v$mismatch_count <- 0; v$row_count <- 2
    }
    if (role == "lineage") {
      v$source_snapshot <- "synthetic-source-v1"; v$extract_identity <- "synthetic-extract-v1"
      v$script_versions <- c("builder-a:test", "builder-b:test")
    }
    path <- paste0("evidence-v2/", role, ".json")
    write_json(v, file.path(root, path), auto_unbox = TRUE, pretty = TRUE)
    receipts[[role]] <- list(path = path, sha256 = digest::digest(file = file.path(root, path), algo = "sha256"))
  }
  values[[4]]$evidence_receipts <- receipts
  for (i in seq_along(files)) write_json(values[[i]], file.path(root, files[[i]]), auto_unbox = TRUE, pretty = TRUE)
}

fixture_files <- c("artifacts/stage1_decision.json", "artifacts/stage2_framing.json", "artifacts/stage3_locked_design.json", "artifacts/stage4_validation_status.json")
report_path <- "artifacts/workflow_gate_status.json"
original_fixture <- write_project
write_project <- function(root, ...) { original_fixture(root, ...); upgrade_fixture(root, fixture_files) }
make_fixture <- function(root) write_project(root)

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

# Forward-contract regressions: each defect must block Stage 5.
change_json <- function(root, index, fn) {
  path <- file.path(root, fixture_files[[index]])
  x <- fromJSON(path, simplifyVector = TRUE)
  write_json(fn(x), path, pretty = TRUE, auto_unbox = TRUE)
}
change_receipt <- function(root, role, fn) {
  path4 <- file.path(root, fixture_files[[4]])
  s4 <- fromJSON(path4, simplifyVector = TRUE)
  path <- file.path(root, s4$evidence_receipts[[role]]$path)
  x <- fromJSON(path, simplifyVector = TRUE)
  write_json(fn(x), path, pretty = TRUE, auto_unbox = TRUE)
  s4$evidence_receipts[[role]]$sha256 <- digest::digest(file = path, algo = "sha256")
  write_json(s4, path4, pretty = TRUE, auto_unbox = TRUE)
}
cases <- list(
  missing_capacity = function(r) change_json(r, 2, function(x) { x$capacity_stance <- NULL; x }),
  invalid_capacity = function(r) change_json(r, 2, function(x) { x$capacity_stance <- "TBD"; x }),
  missing_mode = function(r) change_json(r, 3, function(x) { x$ml_mode <- NULL; x }),
  invalid_mode = function(r) change_json(r, 3, function(x) { x$ml_mode <- ""; x }),
  missing_ranking = function(r) change_json(r, 2, function(x) { x$capacity_stance <- "hard_attention_budget"; x }),
  missing_receipt = function(r) unlink(file.path(r, "evidence-v2/source.json")),
  tampered_receipt = function(r) cat("tampered", file = file.path(r, "evidence-v2/source.json"), append = TRUE),
  empty_receipt = function(r) writeLines(character(), file.path(r, "evidence-v2/source.json")),
  wrong_version = function(r) change_receipt(r, "source", function(x) { x$design_version <- "wrong"; x }),
  failed_receipt = function(r) change_receipt(r, "validation", function(x) { x$status <- "FAIL"; x }),
  mismatch = function(r) change_receipt(r, "reconciliation", function(x) { x$mismatch_count <- 1; x }),
  missing_field = function(r) change_receipt(r, "reconciliation", function(x) { x$fields <- "id"; x }),
  wrong_fixture = function(r) change_receipt(r, "fixtures", function(x) { x$cases$observed_b[[1]] <- "WRONG"; x }),
  missing_fixture = function(r) change_receipt(r, "fixtures", function(x) { x$cases <- x$cases[1,,drop=FALSE]; x }),
  missing_lineage = function(r) change_receipt(r, "lineage", function(x) { x$script_versions <- NULL; x }),
  mode_a_without_validation = function(r) change_json(r, 3, function(x) { x$ml_mode <- "A"; x }),
  missing_structural = function(r) change_json(r, 4, function(x) { x$structural_cross_review <- NULL; x })
)
for (name in names(cases)) {
  root <- tempfile(paste0("gate-", name, "-")); dir.create(root); make_fixture(root)
  cases[[name]](root)
  status <- system2(file.path(R.home("bin"), "Rscript"), c(shQuote(gate_script), shQuote(root)), stdout = FALSE, stderr = FALSE)
  if (identical(status, 0L)) stop("Defect incorrectly accepted: ", name)
  report <- fromJSON(file.path(root, report_path))
  stopifnot(identical(report$result, "FAIL"), identical(report$stage5_allowed, FALSE))
  unlink(root, recursive = TRUE)
}
for (mode in c("None", "B")) {
  root <- tempfile("gate-valid-budget-"); dir.create(root); make_fixture(root)
  change_json(root, 2, function(x) { x$capacity_stance <- "hard_attention_budget"; x })
  change_json(root, 3, function(x) {
    x$ml_mode <- mode
    x$ranking_contract <- list(key = "locked-rule-score", tie_break = "id", capacity_unit = "cases",
      membership_first = TRUE, padding_allowed = FALSE, owner_n_deferred = TRUE)
    x
  })
  status <- system2(file.path(R.home("bin"), "Rscript"), c(shQuote(gate_script), shQuote(root)), stdout = FALSE, stderr = FALSE)
  stopifnot(identical(status, 0L))
  unlink(root, recursive = TRUE)
}
cat("Forward regression tests passed: 17 defects rejected; explicit modes and deferred budget accepted.\n")
