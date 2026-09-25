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
  for (path in c("stage5-evidence.md", "stage5-decision.md", "monitoring-plan.md")) {
    writeLines(paste("Synthetic deliverable:", path), file.path(root, path))
  }
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

# Finalization must inspect the actual released evidence, not just its report.
original_source <- readBin(source_receipt, "raw", n = file.info(source_receipt)$size)
write_json(list(status = "FAIL"), source_receipt)
stopifnot(run_gate("finalize", project_root)$status != 0L)
failed_certificate <- fromJSON(certificate_path)
stopifnot(identical(failed_certificate$result, "FAIL"), identical(failed_certificate$certified, FALSE))
state <- fromJSON(file.path(project_root, "artifacts", "procedure", "run_state.json"))
stopifnot(!identical(state$status, "CERTIFIED"))
stopifnot(length(list.files(file.path(project_root, "artifacts", "procedure", "certificates"))) > 0L)
writeBin(original_source, source_receipt)
stopifnot(run_gate("finalize", project_root)$status == 0L)
unlink(source_receipt)
stopifnot(run_gate("finalize", project_root)$status != 0L)
writeBin(original_source, source_receipt)
stopifnot(run_gate("finalize", project_root)$status == 0L)

# Stage 5 names must resolve to real, nonempty project files.
finish_receipt <- fromJSON(file.path(project_root, "artifacts", "stage5_interpretation_status.json"), simplifyVector = FALSE)
for (bad_path in c("missing.md", "../outside.md", project_root, "empty.md")) {
  file.create(file.path(project_root, "empty.md"))
  invalid <- finish_receipt
  invalid$deliverables <- list(bad_path)
  stopifnot(!gate$checks_pass(gate$validate_stage_receipt("finish", invalid, project_root)))
}
deliverable <- file.path(project_root, "stage5-evidence.md")
original_deliverable <- readBin(deliverable, "raw", n = file.info(deliverable)$size)
writeLines("Changed after completion", deliverable)
stopifnot(run_gate("finalize", project_root)$status != 0L)
unlink(deliverable)
stopifnot(run_gate("finalize", project_root)$status != 0L)
writeBin(original_deliverable, deliverable)
stopifnot(run_gate("finalize", project_root)$status == 0L)
cat("Regression checks passed: changed evidence, missing/changed deliverables, stale PASS invalidation.\n")

# Owner-approved receipt amendment: a completed receipt is superseded only through a
# matching change record; the old bytes are archived and the step is never reopened.
amend_root <- tempfile("procedure-gate-amend-")
dir.create(amend_root)
stopifnot(run_gate("start", amend_root, "TEST-AMEND")$status == 0L)
stopifnot(run_gate("begin", amend_root, "start")$status == 0L)
write_stage1(amend_root)
stopifnot(run_gate("complete", amend_root, "start")$status == 0L)
stopifnot(run_gate("begin", amend_root, "framing")$status == 0L)
write_stage2(amend_root)
stopifnot(run_gate("complete", amend_root, "framing")$status == 0L)
stopifnot(run_gate("begin", amend_root, "design")$status == 0L)
write_stage3(amend_root)
stopifnot(run_gate("complete", amend_root, "design")$status == 0L)
stopifnot(run_gate("begin", amend_root, "execution")$status == 0L)

sha <- function(path) digest::digest(file = path, algo = "sha256")
read_bytes <- function(path) readBin(path, "raw", n = file.info(path)$size)
state_path <- file.path(amend_root, "artifacts", "procedure", "run_state.json")
read_run_state <- function() fromJSON(state_path, simplifyVector = FALSE)
design_path <- file.path(amend_root, "artifacts", "stage3_locked_design.json")
old_sha <- sha(design_path)
old_bytes <- read_bytes(design_path)
v1 <- fromJSON(design_path, simplifyVector = FALSE)
dir.create(file.path(amend_root, "change-control"))
v2_rel <- "change-control/stage3_v2.json"
record_rel <- "change-control/CC-TEST-01.json"
archive_rel <- "artifacts/archive/stage3_locked_design.v1.json"
v2_path <- file.path(amend_root, v2_rel)
record_path <- file.path(amend_root, record_rel)
archive_path <- file.path(amend_root, archive_rel)

write_v2 <- function(path = v2_path, base = v1, supersedes = old_sha, drop = character()) {
  receipt <- base
  receipt$decision_horizon <- "28 days after the decision origin"
  receipt$supersedes_sha256 <- supersedes
  receipt$change_control_id <- "CC-TEST-01"
  receipt[drop] <- NULL
  write_json(receipt, path, pretty = TRUE, auto_unbox = TRUE)
}
write_record <- function(path = record_path, ..., drop = character()) {
  record <- list(
    change_id = "CC-TEST-01", step = "design", reason = "Locked receipt omitted required fields",
    approval_text = "I approve change control CC-TEST-01.", approval_timestamp = "2026-09-25T11:47:00-05:00",
    superseded_sha256 = old_sha, new_sha256 = sha(v2_path), archive_path = archive_rel
  )
  overrides <- list(...)
  for (field in names(overrides)) record[[field]] <- overrides[[field]]
  record[drop] <- NULL
  write_json(record, path, pretty = TRUE, auto_unbox = TRUE)
}
amend <- function(step = "design", receipt = v2_rel, record = record_rel) {
  run_gate("amend", amend_root, step, receipt, record)$status
}
unchanged <- function() {
  state <- read_run_state()
  identical(sha(design_path), old_sha) && identical(state$completed_steps$design$artifact$sha256, old_sha) &&
    is.null(state$amendment_history) && !file.exists(archive_path)
}
amend_cases <- 0L
refused <- function(status) {
  amend_cases <<- amend_cases + 1L
  stopifnot(status != 0L, unchanged())
}

# A missing change record is refused and changes nothing.
write_v2()
refused(amend())
# The new receipt must name the receipt it supersedes.
write_v2(drop = "supersedes_sha256")
write_record()
refused(amend())
write_v2(supersedes = strrep("0", 64))
write_record()
refused(amend())
# Mismatched hashes are refused: the new receipt hash and the superseded hash must both match the files.
write_v2()
write_record(new_sha256 = strrep("0", 64))
refused(amend())
write_record(superseded_sha256 = strrep("0", 64))
refused(amend())
# Every change-record field is required, approval must be explicit, and the new receipt must pass complete's checks.
for (field in c("change_id", "step", "reason", "approval_text", "approval_timestamp", "superseded_sha256", "new_sha256", "archive_path")) {
  write_record(drop = field)
  refused(amend())
}
write_record(approval_text = "PENDING owner approval")
refused(amend())
write_record(approval_timestamp = "PENDING")
refused(amend())
write_record(step = "framing")
refused(amend())
write_v2(drop = "human_analyst_approval")
write_record()
refused(amend())
# The archive must be a new, safe path, never a live receipt.
write_v2()
for (bad_archive in c("artifacts/stage3_locked_design.json", "../outside.json", "artifacts/./x.json", record_rel)) {
  write_record(archive_path = bad_archive)
  refused(amend())
}
# A step with a later completed step cannot be amended; nor can an incomplete step.
stage1_path <- file.path(amend_root, "artifacts", "stage1_decision.json")
stage1_v2 <- fromJSON(stage1_path, simplifyVector = FALSE)
stage1_v2$supersedes_sha256 <- sha(stage1_path)
write_json(stage1_v2, file.path(amend_root, "change-control", "stage1_v2.json"), pretty = TRUE, auto_unbox = TRUE)
write_record(file.path(amend_root, "change-control", "CC-TEST-S1.json"), change_id = "CC-TEST-S1", step = "start",
  superseded_sha256 = sha(stage1_path), new_sha256 = sha(file.path(amend_root, "change-control", "stage1_v2.json")),
  archive_path = "artifacts/archive/stage1_decision.v1.json")
refused(amend("start", "change-control/stage1_v2.json", "change-control/CC-TEST-S1.json"))
write_record()
refused(amend("execution"))

# Pass path: old bytes archived verbatim, new receipt installed, history appended, step not reopened.
write_v2()
write_record()
stopifnot(amend() == 0L)
stopifnot(identical(read_bytes(archive_path), old_bytes))
stopifnot(identical(sha(design_path), sha(v2_path)))
state <- read_run_state()
stopifnot(identical(state$completed_steps$design$artifact$sha256, sha(v2_path)))
stopifnot(length(state$amendment_history) == 1L, identical(state$amendment_history[[1]]$change_id, "CC-TEST-01"))
stopifnot(identical(state$amendment_history[[1]]$superseded$sha256, old_sha))
stopifnot(identical(state$current_step, "execution"))
stopifnot(run_gate("begin", amend_root, "design")$status != 0L)
stopifnot(amend() != 0L)  # the same change record cannot be applied twice
status <- fromJSON(paste(run_gate("status", amend_root)$output, collapse = "\n"), simplifyVector = FALSE)
stopifnot(length(status$amendment_history) == 1L)

# The begun later step is re-verified on completion against the amended receipt.
write_stage4(amend_root)
stopifnot(run_gate("complete", amend_root, "execution")$status == 0L)
# Once a later step is complete, the earlier receipt cannot be amended again.
v3_path <- file.path(amend_root, "change-control", "stage3_v3.json")
write_v2(v3_path, base = fromJSON(design_path, simplifyVector = FALSE), supersedes = sha(design_path))
write_record(file.path(amend_root, "change-control", "CC-TEST-02.json"), change_id = "CC-TEST-02",
  superseded_sha256 = sha(design_path), new_sha256 = sha(v3_path), archive_path = "artifacts/archive/stage3_locked_design.v2.json")
stopifnot(amend("design", "change-control/stage3_v3.json", "change-control/CC-TEST-02.json") != 0L)
stopifnot(identical(read_run_state()$completed_steps$design$artifact$sha256, sha(v2_path)))

# Tampering after amendment is detected: archived receipt, change record, amended receipt.
for (path in c(archive_path, record_path, design_path)) {
  original <- read_bytes(path)
  writeLines("{\"tampered\": true}", path)
  stopifnot(run_gate("begin", amend_root, "finish")$status != 0L)
  unlink(path)
  stopifnot(run_gate("begin", amend_root, "finish")$status != 0L)
  writeBin(original, path)
}
stopifnot(run_gate("begin", amend_root, "finish")$status == 0L)
write_stage5(amend_root)
stopifnot(run_gate("complete", amend_root, "finish")$status == 0L)
stopifnot(run_gate("finalize", amend_root)$status == 0L)
certificate <- fromJSON(file.path(amend_root, "artifacts", "final_certificate.json"), simplifyVector = FALSE)
stopifnot(isTRUE(certificate$certified), length(certificate$amendment_history) == 1L)
stopifnot(identical(certificate$amendment_history[[1]]$new$sha256, sha(v2_path)))
original <- read_bytes(archive_path)
writeLines("changed", archive_path)
stopifnot(run_gate("finalize", amend_root)$status != 0L)
writeBin(original, archive_path)
stopifnot(run_gate("finalize", amend_root)$status == 0L)
unlink(amend_root, recursive = TRUE)
cat("Amendment checks passed:", amend_cases, "refused amendments left state unchanged; archived, re-verified and certified.\n")

unlink(project_root, recursive = TRUE)
cat("Procedure Gate tests passed: illegal transitions blocked; five-stage run certified.\n")
