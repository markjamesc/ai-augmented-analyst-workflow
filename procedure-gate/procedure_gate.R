#!/usr/bin/env Rscript

# R Procedure Gate
# ----------------
# Deterministic referee for the existing five-stage method. It does not perform
# analysis or change the workflow. It records which step is active, verifies
# the machine-readable receipt for that step, delegates the Stage 4 -> Stage 5
# release decision to workflow-gate/workflow_gate.R, and certifies the run only
# after all five existing stages pass.

suppressPackageStartupMessages(library(jsonlite))
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Install digest to verify procedure and artifact hashes")
}

`%||%` <- function(x, y) if (is.null(x)) y else x
`%not_in%` <- function(x, y) !(x %in% y)

procedure_script_path <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) == 0L) return(normalizePath("procedure-gate/procedure_gate.R", mustWork = TRUE))
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
}

procedure_repo_root <- function() {
  normalizePath(file.path(dirname(procedure_script_path()), ".."), mustWork = TRUE)
}

procedure_paths <- function(project_root) {
  project_root <- normalizePath(project_root, mustWork = TRUE)
  list(
    project_root = project_root,
    procedure_file = file.path(procedure_repo_root(), "procedure-gate", "procedure.json"),
    procedure_dir = file.path(project_root, "artifacts", "procedure"),
    checks_dir = file.path(project_root, "artifacts", "procedure", "checks"),
    state = file.path(project_root, "artifacts", "procedure", "run_state.json"),
    certificate = file.path(project_root, "artifacts", "final_certificate.json"),
    workflow_report = file.path(project_root, "artifacts", "workflow_gate_status.json"),
    workflow_console = file.path(project_root, "artifacts", "procedure", "checks", "execution-workflow-gate-console.txt")
  )
}

read_procedure <- function() {
  fromJSON(
    file.path(procedure_repo_root(), "procedure-gate", "procedure.json"),
    simplifyVector = FALSE
  )
}

read_state <- function(project_root) {
  paths <- procedure_paths(project_root)
  if (!file.exists(paths$state)) stop("Procedure run has not been started: ", paths$state)
  fromJSON(paths$state, simplifyVector = FALSE)
}

write_json_atomic <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- paste0(path, ".tmp")
  write_json(value, temporary, pretty = TRUE, auto_unbox = TRUE, null = "null")
  if (.Platform$OS.type == "windows" && file.exists(path)) unlink(path)
  if (!file.rename(temporary, path)) stop("Could not atomically write: ", path)
  invisible(value)
}

save_state <- function(state, project_root) {
  write_json_atomic(state, procedure_paths(project_root)$state)
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

timestamp_utc <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

text_scalar <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
}

is_value <- function(x, field, expected) {
  is.list(x) && field %in% names(x) && identical(as.character(x[[field]]), as.character(expected))
}

has_fields <- function(x, fields) {
  is.list(x) && all(fields %in% names(x))
}

step_by_id <- function(procedure, step_id) {
  matches <- Filter(function(step) identical(step$id, step_id), procedure$steps)
  if (length(matches) == 0L) stop("Unknown procedure step: ", step_id)
  if (length(matches) > 1L) stop("Duplicate procedure step: ", step_id)
  matches[[1]]
}

completed_ids <- function(state) {
  names(state$completed_steps %||% list()) %||% character()
}

verify_completed_artifacts <- function(state, project_root) {
  completed <- state$completed_steps %||% list()
  if (length(completed) == 0L) return(TRUE)
  all(vapply(completed, function(value) {
    relative_path <- value$artifact$path %||% ""
    expected_hash <- value$artifact$sha256 %||% ""
    path <- file.path(normalizePath(project_root, mustWork = TRUE), relative_path)
    text_scalar(relative_path) && text_scalar(expected_hash) && file.exists(path) &&
      !dir.exists(path) && identical(tolower(expected_hash), sha256_file(path))
  }, logical(1)))
}

verify_workflow_report <- function(state, project_root) {
  if (is.null(state$workflow_gate)) return(TRUE)
  path <- procedure_paths(project_root)$workflow_report
  expected_hash <- state$workflow_gate$report_sha256 %||% ""
  text_scalar(expected_hash) && file.exists(path) &&
    identical(tolower(expected_hash), sha256_file(path))
}

framework_hashes <- function(procedure) {
  files <- unique(c(
    "docs/MASTER_PROMPT.md",
    vapply(procedure$steps, function(step) step$framework, character(1)),
    "docs/r-workflow-gate-enforcement.md",
    "workflow-gate/workflow_gate.R"
  ))
  values <- lapply(files, function(relative_path) {
    path <- file.path(procedure_repo_root(), relative_path)
    if (!file.exists(path)) stop("Controlling file is missing: ", relative_path)
    list(path = relative_path, sha256 = sha256_file(path))
  })
  names(values) <- files
  values
}

verify_framework_hashes <- function(state) {
  procedure_path <- file.path(procedure_repo_root(), "procedure-gate", "procedure.json")
  procedure_ok <- file.exists(procedure_path) &&
    identical(tolower(state$procedure_sha256 %||% ""), sha256_file(procedure_path))
  locked <- state$framework_hashes %||% list()
  if (length(locked) == 0L) return(FALSE)
  procedure_ok && all(vapply(locked, function(entry) {
    path <- file.path(procedure_repo_root(), entry$path)
    file.exists(path) && identical(tolower(entry$sha256), sha256_file(path))
  }, logical(1)))
}

check_result <- function(name, pass, detail) {
  list(
    check = name,
    result = if (isTRUE(pass)) "PASS" else "FAIL",
    detail = detail
  )
}

checks_pass <- function(checks) {
  length(checks) > 0L && all(vapply(checks, function(x) identical(x$result, "PASS"), logical(1)))
}

save_checks <- function(project_root, step_id, phase, checks) {
  paths <- procedure_paths(project_root)
  dir.create(paths$checks_dir, recursive = TRUE, showWarnings = FALSE)
  record <- list(
    step = step_id,
    phase = phase,
    result = if (checks_pass(checks)) "PASS" else "FAIL",
    checked_at_utc = timestamp_utc(),
    checks = checks
  )
  path <- file.path(paths$checks_dir, paste0(step_id, "-", phase, ".json"))
  write_json_atomic(record, path)
  list(path = path, sha256 = sha256_file(path), result = record$result)
}

read_artifact_safe <- function(path) {
  if (!file.exists(path) || dir.exists(path) || file.info(path)$size <= 0) return(NULL)
  tryCatch(fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
}

validate_stage_receipt <- function(step_id, receipt, project_root) {
  checks <- list()
  add <- function(name, pass, detail) {
    checks[[length(checks) + 1L]] <<- check_result(name, pass, detail)
  }

  if (identical(step_id, "start")) {
    required <- c(
      "stage", "status", "decision_statement", "decision_owner",
      "ai2_independent_reconstruction", "ai3_independent_red_team",
      "start_gate", "stakeholder_confirmation", "human_analyst_approval",
      "unresolved_issues"
    )
    add("Stage 1 required fields", has_fields(receipt, required), paste(required, collapse = ", "))
    add("Stage 1 number", is_value(receipt, "stage", 1), "stage must equal 1")
    add("Stage 1 locked", is_value(receipt, "status", "LOCKED"), "status must equal LOCKED")
    for (field in c("ai2_independent_reconstruction", "ai3_independent_red_team", "start_gate")) {
      add(paste("Stage 1", field), is_value(receipt, field, "PASS"), paste(field, "must equal PASS"))
    }
    add("Stakeholder confirmation", is_value(receipt, "stakeholder_confirmation", "CONFIRMED"), "stakeholder_confirmation must equal CONFIRMED")
    add("Stage 1 human approval", is_value(receipt, "human_analyst_approval", "APPROVED"), "human_analyst_approval must equal APPROVED")
    add("Stage 1 unresolved issues", is.list(receipt) && identical(as.numeric(receipt$unresolved_issues), 0), "unresolved_issues must equal 0")
  }

  if (identical(step_id, "framing")) {
    required <- c(
      "stage", "status", "analytical_question", "capacity_stance",
      "ai1_builder", "ai2_decision_fit_review", "ai3_framing_red_team",
      "cross_review", "framing_gate", "stakeholder_approval",
      "human_analyst_approval", "unresolved_issues"
    )
    add("Stage 2 required fields", has_fields(receipt, required), paste(required, collapse = ", "))
    add("Stage 2 number", is_value(receipt, "stage", 2), "stage must equal 2")
    add("Stage 2 locked", is_value(receipt, "status", "LOCKED"), "status must equal LOCKED")
    stance_ok <- is.list(receipt) && text_scalar(receipt$capacity_stance) &&
      receipt$capacity_stance %in% c("unordered_ok", "hard_attention_budget")
    add("Capacity stance explicit", stance_ok, "capacity_stance must be unordered_ok or hard_attention_budget")
    for (field in c("ai1_builder", "ai2_decision_fit_review", "ai3_framing_red_team", "cross_review", "framing_gate")) {
      add(paste("Stage 2", field), is_value(receipt, field, "PASS"), paste(field, "must equal PASS"))
    }
    add("Stage 2 stakeholder approval", is_value(receipt, "stakeholder_approval", "APPROVED"), "stakeholder_approval must equal APPROVED")
    add("Stage 2 human approval", is_value(receipt, "human_analyst_approval", "APPROVED"), "human_analyst_approval must equal APPROVED")
    add("Stage 2 unresolved issues", is.list(receipt) && identical(as.numeric(receipt$unresolved_issues), 0), "unresolved_issues must equal 0")
  }

  if (identical(step_id, "design")) {
    required <- c(
      "stage", "status", "design_version", "population", "grain",
      "window_start", "window_end", "decision_rules", "required_outputs",
      "ml_mode", "ai1_independent_design", "ai2_independent_design",
      "ai3_independent_risk_dossier", "information_barrier", "cross_review",
      "design_gates", "human_analyst_approval", "unresolved_issues"
    )
    add("Stage 3 required fields", has_fields(receipt, required), paste(required, collapse = ", "))
    add("Stage 3 number", is_value(receipt, "stage", 3), "stage must equal 3")
    add("Stage 3 locked", is_value(receipt, "status", "LOCKED"), "status must equal LOCKED")
    mode_ok <- is.list(receipt) && text_scalar(receipt$ml_mode) && receipt$ml_mode %in% c("None", "A", "B")
    add("ML mode explicit", mode_ok, "ml_mode must be None, A, or B")
    for (field in c("ai1_independent_design", "ai2_independent_design", "ai3_independent_risk_dossier", "information_barrier", "cross_review", "design_gates")) {
      add(paste("Stage 3", field), is_value(receipt, field, "PASS"), paste(field, "must equal PASS"))
    }
    add("Stage 3 human approval", is_value(receipt, "human_analyst_approval", "APPROVED"), "human_analyst_approval must equal APPROVED")
    add("Stage 3 unresolved issues", is.list(receipt) && identical(as.numeric(receipt$unresolved_issues), 0), "unresolved_issues must equal 0")
  }

  if (identical(step_id, "execution")) {
    add("Stage 4 receipt present", is.list(receipt), "stage4_validation_status.json must parse")
    add("Stage 4 number", is_value(receipt, "stage", 4), "stage must equal 4")
    add("Stage 4 status", is_value(receipt, "status", "PASS"), "status must equal PASS")
  }

  if (identical(step_id, "finish")) {
    required <- c(
      "stage", "status", "workflow_gate_report_sha256",
      "ai1_first_pass", "ai2_first_pass", "ai3_first_pass",
      "information_barrier", "cross_review", "finish_gates", "human_analyst_approval",
      "unresolved_issues", "deliverables"
    )
    add("Stage 5 required fields", has_fields(receipt, required), paste(required, collapse = ", "))
    add("Stage 5 number", is_value(receipt, "stage", 5), "stage must equal 5")
    add("Stage 5 status", is_value(receipt, "status", "PASS"), "status must equal PASS")
    for (field in c("ai1_first_pass", "ai2_first_pass", "ai3_first_pass", "information_barrier", "cross_review", "finish_gates")) {
      add(paste("Stage 5", field), is_value(receipt, field, "PASS"), paste(field, "must equal PASS"))
    }
    add(
      "Human analyst approval",
      is_value(receipt, "human_analyst_approval", "APPROVED"),
      "human_analyst_approval must equal APPROVED"
    )
    issues_ok <- is.list(receipt) && "unresolved_issues" %in% names(receipt) &&
      is.numeric(receipt$unresolved_issues) && length(receipt$unresolved_issues) == 1L &&
      !is.na(receipt$unresolved_issues) && receipt$unresolved_issues == 0
    add("Stage 5 unresolved issues", issues_ok, "unresolved_issues must equal 0")
    deliverables_ok <- is.list(receipt) && length(receipt$deliverables) > 0L &&
      all(vapply(receipt$deliverables, text_scalar, logical(1)))
    add("Stage 5 deliverables recorded", deliverables_ok, "deliverables must contain at least one recorded artifact")
    workflow_path <- procedure_paths(project_root)$workflow_report
    workflow_hash_ok <- file.exists(workflow_path) && is.list(receipt) &&
      text_scalar(receipt$workflow_gate_report_sha256) &&
      identical(tolower(receipt$workflow_gate_report_sha256), sha256_file(workflow_path))
    add("Stage 5 used certified Workflow Gate report", workflow_hash_ok, "workflow gate report hash must match")
  }

  checks
}

run_workflow_gate <- function(project_root) {
  paths <- procedure_paths(project_root)
  gate_script <- normalizePath(
    file.path(procedure_repo_root(), "workflow-gate", "workflow_gate.R"),
    mustWork = TRUE
  )
  output <- system2(
    command = file.path(R.home("bin"), "Rscript"),
    args = c(shQuote(gate_script), shQuote(paths$project_root)),
    stdout = TRUE,
    stderr = TRUE
  )
  exit_status <- attr(output, "status") %||% 0L
  dir.create(dirname(paths$workflow_console), recursive = TRUE, showWarnings = FALSE)
  writeLines(output, paths$workflow_console)
  report <- read_artifact_safe(paths$workflow_report)
  passed <- identical(as.integer(exit_status), 0L) && is.list(report) &&
    identical(report$result, "PASS") && isTRUE(report$stage5_allowed)
  list(
    passed = passed,
    exit_status = as.integer(exit_status),
    report = report,
    report_path = paths$workflow_report,
    report_sha256 = if (file.exists(paths$workflow_report)) sha256_file(paths$workflow_report) else NULL,
    console_path = paths$workflow_console
  )
}

procedure_start <- function(project_root, run_id) {
  if (!text_scalar(run_id)) stop("run_id must be one nonempty string")
  paths <- procedure_paths(project_root)
  if (file.exists(paths$state)) stop("Procedure run already exists: ", paths$state)
  procedure <- read_procedure()
  state <- list(
    run_id = run_id,
    procedure_id = procedure$procedure_id,
    procedure_version = procedure$procedure_version,
    procedure_sha256 = sha256_file(paths$procedure_file),
    status = "IN_PROGRESS",
    current_step = NULL,
    completed_steps = list(),
    framework_hashes = framework_hashes(procedure),
    workflow_gate = NULL,
    final_certificate = NULL,
    started_at_utc = timestamp_utc(),
    updated_at_utc = timestamp_utc()
  )
  save_state(state, project_root)
  list(status = "STARTED", run_id = run_id, next_step = procedure$steps[[1]]$id)
}

procedure_begin <- function(project_root, step_id) {
  state <- read_state(project_root)
  procedure <- read_procedure()
  step <- step_by_id(procedure, step_id)
  checks <- list(
    check_result("Run is active", identical(state$status, "IN_PROGRESS"), "status must equal IN_PROGRESS"),
    check_result("No other step is active", is.null(state$current_step), "current_step must be null"),
    check_result("Step is not already complete", step_id %not_in% completed_ids(state), "completed steps cannot be reopened"),
    check_result("Completed receipts unchanged", verify_completed_artifacts(state, project_root), "completed artifact hashes must still match"),
    check_result("Workflow Gate report unchanged", verify_workflow_report(state, project_root), "recorded workflow report hash must still match"),
    check_result(
      "Prerequisites complete",
      all(unlist(step$requires, use.names = FALSE) %in% completed_ids(state)),
      paste("Required:", paste(unlist(step$requires, use.names = FALSE), collapse = ", "))
    ),
    check_result("Controlling documents unchanged", verify_framework_hashes(state), "framework hashes must match run start")
  )
  record <- save_checks(project_root, step_id, "begin", checks)
  if (!checks_pass(checks)) return(list(status = "BLOCKED", step = step_id, checks = checks))
  state$current_step <- step_id
  state$updated_at_utc <- timestamp_utc()
  save_state(state, project_root)
  list(status = "AUTHORIZED", step = step_id, framework = step$framework, check_report = record)
}

procedure_complete <- function(project_root, step_id) {
  state <- read_state(project_root)
  procedure <- read_procedure()
  step <- step_by_id(procedure, step_id)
  artifact_path <- file.path(normalizePath(project_root, mustWork = TRUE), step$artifact)
  receipt <- read_artifact_safe(artifact_path)
  checks <- list(
    check_result("Step was authorized", identical(state$current_step, step_id), "current_step must match completion request"),
    check_result("Controlling documents unchanged", verify_framework_hashes(state), "framework hashes must match run start"),
    check_result("Previously completed receipts unchanged", verify_completed_artifacts(state, project_root), "completed artifact hashes must still match"),
    check_result("Workflow Gate report unchanged", verify_workflow_report(state, project_root), "recorded workflow report hash must still match"),
    check_result("Required receipt exists and parses", is.list(receipt), step$artifact)
  )
  checks <- c(checks, validate_stage_receipt(step_id, receipt, project_root))

  workflow <- NULL
  if (identical(step_id, "execution") && checks_pass(checks)) {
    workflow <- run_workflow_gate(project_root)
    checks[[length(checks) + 1L]] <- check_result(
      "Existing Workflow Gate PASS",
      workflow$passed,
      paste("exit_status=", workflow$exit_status, "; report=", workflow$report_path, sep = "")
    )
  }

  record <- save_checks(project_root, step_id, "complete", checks)
  if (!checks_pass(checks)) {
    return(list(status = "FAIL", step = step_id, checks = checks, workflow_gate = workflow))
  }

  artifact_record <- list(path = step$artifact, sha256 = sha256_file(artifact_path))
  state$completed_steps[[step_id]] <- list(
    completed_at_utc = timestamp_utc(),
    artifact = artifact_record,
    check_report = list(path = record$path, sha256 = record$sha256)
  )
  if (identical(step_id, "execution")) {
    state$workflow_gate <- list(
      status = "PASS",
      report_path = "artifacts/workflow_gate_status.json",
      report_sha256 = workflow$report_sha256,
      console_path = "artifacts/procedure/checks/execution-workflow-gate-console.txt",
      verified_at_utc = timestamp_utc()
    )
  }
  state$current_step <- NULL
  state$updated_at_utc <- timestamp_utc()
  save_state(state, project_root)

  step_ids <- vapply(procedure$steps, function(x) x$id, character(1))
  position <- match(step_id, step_ids)
  next_step <- if (position < length(step_ids)) step_ids[[position + 1L]] else "FINALIZE"
  list(status = "PASS", completed_step = step_id, next_step = next_step, check_report = record)
}

procedure_status <- function(project_root) {
  state <- read_state(project_root)
  procedure <- read_procedure()
  step_ids <- vapply(procedure$steps, function(x) x$id, character(1))
  done <- completed_ids(state)
  next_step <- if (!is.null(state$current_step)) state$current_step else {
    remaining <- step_ids[step_ids %not_in% done]
    if (length(remaining) > 0L) remaining[[1]] else "FINALIZE"
  }
  list(
    run_id = state$run_id,
    status = state$status,
    current_step = state$current_step,
    completed_steps = done,
    next_step = next_step,
    workflow_gate = state$workflow_gate,
    final_certificate = state$final_certificate
  )
}

procedure_finalize <- function(project_root) {
  state <- read_state(project_root)
  procedure <- read_procedure()
  paths <- procedure_paths(project_root)
  required <- vapply(procedure$steps, function(x) x$id, character(1))
  checks <- list(
    check_result("No step is active", is.null(state$current_step), "current_step must be null"),
    check_result("All five stages complete", all(required %in% completed_ids(state)), paste(required, collapse = ", ")),
    check_result("Workflow Gate certified Execution", is.list(state$workflow_gate) && identical(state$workflow_gate$status, "PASS"), "workflow_gate status must equal PASS"),
    check_result("Completed receipts unchanged", verify_completed_artifacts(state, project_root), "completed artifact hashes must still match"),
    check_result("Workflow Gate report unchanged", verify_workflow_report(state, project_root), "recorded workflow report hash must still match"),
    check_result("Controlling documents unchanged", verify_framework_hashes(state), "framework hashes must match run start")
  )
  record <- save_checks(project_root, "final", "certification", checks)
  if (!checks_pass(checks)) return(list(status = "FAIL", checks = checks))

  completed <- lapply(required, function(id) {
    value <- state$completed_steps[[id]]
    list(id = id, artifact_path = value$artifact$path, artifact_sha256 = value$artifact$sha256)
  })
  certificate <- list(
    certificate = "five_stage_procedure_certificate",
    result = "PASS",
    certified = TRUE,
    run_id = state$run_id,
    procedure_id = state$procedure_id,
    procedure_version = state$procedure_version,
    procedure_sha256 = state$procedure_sha256,
    completed_steps = completed,
    workflow_gate_report_sha256 = state$workflow_gate$report_sha256,
    certification_check_sha256 = record$sha256,
    certified_at_utc = timestamp_utc()
  )
  certificate$certificate_sha256 <- digest::digest(certificate, algo = "sha256")
  write_json_atomic(certificate, paths$certificate)

  state$status <- "CERTIFIED"
  state$final_certificate <- list(
    path = "artifacts/final_certificate.json",
    sha256 = sha256_file(paths$certificate)
  )
  state$updated_at_utc <- timestamp_utc()
  save_state(state, project_root)
  certificate
}

print_json <- function(value) {
  cat(toJSON(value, pretty = TRUE, auto_unbox = TRUE, null = "null"), "\n")
}

procedure_main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2L) {
    stop(
      paste(
        "Usage:",
        "Rscript procedure-gate/procedure_gate.R start <project-root> <run-id>",
        "Rscript procedure-gate/procedure_gate.R begin <project-root> <step>",
        "Rscript procedure-gate/procedure_gate.R complete <project-root> <step>",
        "Rscript procedure-gate/procedure_gate.R status <project-root>",
        "Rscript procedure-gate/procedure_gate.R finalize <project-root>",
        sep = "\n  "
      )
    )
  }
  action <- args[[1]]
  project_root <- args[[2]]
  result <- switch(
    action,
    start = {
      if (length(args) < 3L) stop("start requires <run-id>")
      procedure_start(project_root, args[[3]])
    },
    begin = {
      if (length(args) < 3L) stop("begin requires <step>")
      procedure_begin(project_root, args[[3]])
    },
    complete = {
      if (length(args) < 3L) stop("complete requires <step>")
      procedure_complete(project_root, args[[3]])
    },
    status = procedure_status(project_root),
    finalize = procedure_finalize(project_root),
    stop("Unknown action: ", action)
  )
  print_json(result)
  if (is.list(result) && identical(result$status, "FAIL")) quit(status = 1L, save = "no")
  if (is.list(result) && identical(result$status, "BLOCKED")) quit(status = 1L, save = "no")
}

if (sys.nframe() == 0L) procedure_main()
