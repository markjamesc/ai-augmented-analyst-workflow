#!/usr/bin/env Rscript
# AI-authored: OpenAI ChatGPT GPT-6.
# S4-t1v2 under owner card t1609s6705; separately reviewed.
# Parse guard executes before package load, root lookup, or any write.
# Baseline builders are independently gated in fixtures/metamorphic/reconciliation.
# In --self-test mode, ordinary reports are PRE-INJECTION snapshots only.
# Self-test results independently re-evaluate affected test gates after corruption.
.argv <- commandArgs(trailingOnly = FALSE)
.file_argument <- grep("^--file=", .argv, value = TRUE)
.file <- if (length(.file_argument) == 1L) {
  sub("^--file=", "", .file_argument)
} else { NA_character_ }
.parse_ok <- tryCatch({
  if (is.na(.file) || !file.exists(.file)) stop("Cannot locate own source")
  parse(file = .file)
  TRUE
}, error = function(e) {
  cat("SETUP ERROR: source parse guard: ", conditionMessage(e), "\n",
      sep = "", file = stderr())
  FALSE
})
if (!.parse_ok) quit(save = "no", status = 2L)

.main <- function() {
suppressPackageStartupMessages({
  library(jsonlite)
  library(digest)
})

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1L || length(args) > 2L ||
    (length(args) == 2L && args[[2L]] != "--self-test")) {
  cat("Usage: versioned_reports.R <ROOT> [--self-test]\n",
      file = stderr())
  quit(save = "no", status = 2L)
}

root <- tryCatch(
  normalizePath(args[[1L]], winslash = "/", mustWork = TRUE),
  error = function(e) NA_character_
)

if (is.na(root) || !dir.exists(root)) {
  cat("SETUP ERROR: ROOT is not a directory\n", file = stderr())
  quit(save = "no", status = 2L)
}

self_test <- length(args) == 2L

P <- function(...) file.path(root, ...)
S <- function(...) file.path(sandbox, ...)

utc <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

stamp_now <- function() {
  format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
}

sha <- function(path) {
  if (!file.exists(path) || dir.exists(path)) return(NA_character_)
  digest::digest(file = path, algo = "sha256")
}

same_sha <- function(a, b) {
  is.character(a) && length(a) == 1L &&
    is.character(b) && length(b) == 1L &&
    !is.na(a) && !is.na(b) &&
    identical(tolower(a), tolower(b))
}

readj <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(
    jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) NULL
  )
}

readc <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(
    read.csv(
      path, colClasses = "character",
      check.names = FALSE,
      na.strings = character(),
      stringsAsFactors = FALSE
    ),
    error = function(e) NULL
  )
}

scalar <- function(x, default = NA_character_) {
  if (is.null(x) || length(x) != 1L || is.na(x))
    return(default)
  as.character(x)
}

integer_scalar <- function(x, default = NA_integer_) {
  z <- suppressWarnings(as.integer(unlist(x, use.names = FALSE)))
  if (length(z) != 1L || is.na(z)) default else z
}

as_flag <- function(x) {
  identical(toupper(scalar(x)), "TRUE")
}

json_write <- function(object, path) {
  if (file.exists(path) || dir.exists(path))
    stop(paste("Refusing overwrite:", path))
  if (!dir.exists(dirname(path)))
    stop(paste("Missing destination directory:", dirname(path)))

  jsonlite::write_json(
    object, path,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
}

slash <- function(path) {
  gsub("\\", "/", path, fixed = TRUE)
}

valid_rel <- function(path) {
  is.character(path) &&
    length(path) == 1L &&
    !is.na(path) &&
    nzchar(path) &&
    !grepl("^(/|[A-Za-z]:|\\\\)", path) &&
    !any(strsplit(slash(path), "/", fixed = TRUE)[[1L]] %in%
           c("", ".", ".."))
}

relative_to <- function(path, base) {
  full <- normalizePath(path, winslash = "/", mustWork = TRUE)
  parent <- normalizePath(base, winslash = "/", mustWork = TRUE)
  prefix <- paste0(parent, "/")
  if (!startsWith(full, prefix))
    stop(paste("Path escapes root:", full))
  substring(full, nchar(prefix) + 1L)
}

ref <- function(rel) {
  if (!valid_rel(rel))
    stop(paste("Invalid reference:", rel))
  list(path = slash(rel), sha256 = sha(P(rel)))
}

ref_sandbox <- function(rel) {
  if (!valid_rel(rel))
    stop(paste("Invalid sandbox reference:", rel))
  ref(file.path(stamp_rel, "sandbox", rel))
}

ref_stamp <- function(rel) {
  if (!valid_rel(rel))
    stop(paste("Invalid stamp reference:", rel))
  ref(file.path(stamp_rel, rel))
}

setup_error <- function(message) {
  stop(
    structure(
      list(message = message, call = NULL),
      class = c("setup_error", "error", "condition")
    )
  )
}

ensure_new_dir <- function(path) {
  if (file.exists(path) || dir.exists(path))
    setup_error(paste("Destination exists:", path))
  if (!dir.create(path, recursive = TRUE, showWarnings = FALSE))
    setup_error(paste("Cannot create:", path))
}

copy_one <- function(rel) {
  if (!valid_rel(rel))
    setup_error(paste("Unsafe component path:", rel))

  source <- P(rel)
  target <- S(rel)

  if (!file.exists(source) || dir.exists(source))
    setup_error(paste("Missing required source:", rel))

  if (file.exists(target))
    setup_error(paste("Sandbox collision:", rel))

  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)

  if (!file.copy(source, target, overwrite = FALSE,
                 copy.mode = FALSE, copy.date = FALSE))
    setup_error(paste("Copy failed:", rel))

  if (!same_sha(sha(source), sha(target)))
    setup_error(paste("Copied bytes differ:", rel))

  invisible(TRUE)
}

# Exact supplied contracts.R helpers, required by m_compare.

m_text <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x)) &&
  !grepl("^(TODO|TBD|REPLACE|PENDING|NOT_SET__|\\{\\{)", trimws(x), ignore.case = TRUE)

m_missing_values <- function(rule) unlist(if (!is.null(rule[["missing_values"]])) rule[["missing_values"]] else rule[["missing_value"]], use.names=FALSE)
m_missing_rule <- function(rule, plan) {
  is.list(rule) && m_text(rule$flag_field) && rule$flag_field %in% unlist(plan$exact_fields) &&
    xor(is.null(rule[["missing_value"]]), is.null(rule[["missing_values"]])) &&
    length(m_missing_values(rule)) > 0L && is.character(m_missing_values(rule)) &&
    !anyNA(m_missing_values(rule)) && all(nzchar(m_missing_values(rule))) &&
    !anyDuplicated(m_missing_values(rule)) && m_text(rule$present_value) &&
    !rule$present_value %in% m_missing_values(rule) &&
    is.character(rule$missing_token) && length(rule$missing_token)==1L && !is.na(rule$missing_token) &&
    rule$missing_token %in% c("", "null", "NA")
}

# Verbatim m_compare from the attached contracts_R_excerpt.txt.

m_compare <- function(a, b, plan) {
  fields <- unique(c(unlist(plan$keys), unlist(plan$exact_fields), unlist(plan$numeric_fields)))
  if (!is.data.frame(a) || !is.data.frame(b) || anyDuplicated(names(a)) || anyDuplicated(names(b)) || !all(fields %in% names(a)) || !all(fields %in% names(b))) return(FALSE)
  keys <- unlist(plan$keys)
  canonical <- function(d) {
    k <- d[, keys, drop = FALSE]
    if (anyNA(k) || anyDuplicated(k) || any(vapply(k, function(x) any(!nzchar(trimws(as.character(x)))), logical(1)))) return(NULL)
    d[do.call(order, c(unname(k), list(na.last = TRUE, method = "radix"))), fields, drop = FALSE]
  }
  a <- canonical(a); b <- canonical(b)
  if (is.null(a) || is.null(b) || nrow(a) != nrow(b)) return(FALSE)
  exact <- unique(c(keys, unlist(plan$exact_fields)))
  if (!all(vapply(exact, function(f) identical(as.character(a[[f]]), as.character(b[[f]])), logical(1)))) return(FALSE)
  all(vapply(unlist(plan$numeric_fields), function(f) {
    x <- suppressWarnings(as.numeric(a[[f]])); y <- suppressWarnings(as.numeric(b[[f]]))
    # Missingness is permitted ONLY under an explicit locked flag/token contract.
    rule <- plan$numeric_missingness[[f]]
    keep <- rep(TRUE, nrow(a))
    if (!is.null(rule)) {
      if (!m_missing_rule(rule, plan) || !rule$flag_field %in% names(a)) return(FALSE)
      fa <- as.character(a[[rule$flag_field]]); fb <- as.character(b[[rule$flag_field]])
      if (anyNA(fa) || !identical(fa, fb) || !all(fa %in% c(m_missing_values(rule), rule$present_value))) return(FALSE)
      missing <- fa %in% m_missing_values(rule)
      if (anyNA(a[[f]][missing]) || anyNA(b[[f]][missing]) ||
          !all(as.character(a[[f]][missing]) == rule$missing_token) ||
          !all(as.character(b[[f]][missing]) == rule$missing_token)) return(FALSE)
      keep <- !missing
    }
    all(is.finite(x[keep])) && all(is.finite(y[keep])) && all(abs(x[keep]-y[keep]) <= plan$absolute_tolerance + plan$relative_tolerance * pmax(abs(x[keep]), abs(y[keep])))
  }, logical(1)))
}

# Lock is authoritative. No fixture expected values are read here.

lock_rel <- "artifacts/stage3_locked_design.json"
lock <- readj(P(lock_rel))

if (is.null(lock) ||
    is.null(lock$methodology$operational$validation_components) ||
    is.null(lock$methodology$checkpoints) ||
    is.null(lock$methodology$replay_outputs) ||
    is.null(lock$fixture_ids)) {
  cat("SETUP ERROR: missing or malformed lock\n", file = stderr())
  quit(save = "no", status = 2L)
}

locked <- lock$methodology$operational$validation_components
groups <- c("R-A", "R-B", "harness", "configuration", "input")

if (!identical(names(locked), groups)) {
  cat("SETUP ERROR: component groups do not match lock contract\n",
      file = stderr())
  quit(save = "no", status = 2L)
}

component_paths <- unlist(locked, use.names = FALSE)

if (!length(component_paths) ||
    anyDuplicated(component_paths) ||
    !all(vapply(component_paths, valid_rel, logical(1)))) {
  cat("SETUP ERROR: invalid component list\n", file = stderr())
  quit(save = "no", status = 2L)
}

components <- lapply(groups, function(group) {
  lapply(unlist(locked[[group]], use.names = FALSE), function(path) {
    value <- sha(P(path))
    if (is.na(value))
      setup_error(paste("Missing locked component:", path))
    list(path = path, sha256 = value)
  })
})
names(components) <- groups

fixture_ids <- unlist(lock$fixture_ids, use.names = FALSE)
checkpoint_plans <- lock$methodology$checkpoints
checkpoint_ids <- vapply(checkpoint_plans, `[[`, character(1), "id")
mr_ids <- vapply(
  Filter(function(x) isTRUE(x$applicable),
         lock$methodology$metamorphic),
  `[[`, character(1), "id"
)

test_ids <- c(
  "fixtures:R-A",
  "fixtures:R-B",
  "replay",
  "reconciliation",
  unlist(lapply(mr_ids, function(id) {
    paste("metamorphic", id, c("R-A", "R-B"), sep = ":")
  }), use.names = FALSE)
)

if (length(test_ids) != 20L ||
    anyDuplicated(test_ids) ||
    anyDuplicated(fixture_ids) ||
    anyDuplicated(checkpoint_ids)) {
  cat("SETUP ERROR: locked test coverage malformed\n", file = stderr())
  quit(save = "no", status = 2L)
}

checkpoint_files <- c(
  K0 = "audit_rows.csv",
  K1 = "reason_totals.csv",
  K2 = "rank_rows.csv",
  K3 = "totals.csv",
  K4 = "build_report.csv"
)

if (!identical(checkpoint_ids, names(checkpoint_files))) {
  cat("SETUP ERROR: checkpoint map disagrees with lock\n",
      file = stderr())
  quit(save = "no", status = 2L)
}

# Allocate exactly one new UTC directory.
# A collision is an error; the timestamp is never silently changed.

stamp <- stamp_now()
stamp_rel <- file.path("outputs", "verification", "versioned", stamp)
stamp_dir <- P(stamp_rel)
sandbox <- file.path(stamp_dir, "sandbox")

# The versioned parent is the only permitted ancestor creation.
versioned_parent <- dirname(stamp_dir)
if (!dir.exists(versioned_parent)) {
  if (!dir.create(versioned_parent, recursive = TRUE,
                  showWarnings = FALSE)) {
    cat("SETUP ERROR: cannot create versioned parent\n",
        file = stderr())
    quit(save = "no", status = 2L)
  }
}

if (file.exists(stamp_dir) || dir.exists(stamp_dir)) {
  cat("SETUP ERROR: UTC stamp already exists\n", file = stderr())
  quit(save = "no", status = 2L)
}

ensure_new_dir(stamp_dir)
ensure_new_dir(sandbox)
ensure_new_dir(file.path(stamp_dir, "tests"))
ensure_new_dir(file.path(stamp_dir, "console"))

# Copy all locked components and all environment/fixture files.
# Additional files are allowed only from the specified subtrees.

all_files <- component_paths

for (directory in c("environment", "validation/fixtures")) {
  source_directory <- P(directory)
  if (!dir.exists(source_directory))
    setup_error(paste("Missing required directory:", directory))

  extra <- list.files(
    source_directory,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  extra <- extra[!dir.exists(extra)]
  extra <- vapply(extra, relative_to, character(1), base = root)
  all_files <- c(all_files, extra)
}

all_files <- unique(all_files)

if (!all(vapply(all_files, valid_rel, logical(1))))
  setup_error("Unsafe sandbox input path")

for (path in all_files) copy_one(path)

verify_components <- function() {
  details <- lapply(groups, function(group) {
    lapply(components[[group]], function(item) {
      observed <- sha(S(item$path))
      list(
        path = item$path,
        expected = item$sha256,
        observed = observed,
        result = if (same_sha(observed, item$sha256))
          "PASS" else "FAIL"
      )
    })
  })
  names(details) <- groups

  checks <- unlist(details, recursive = FALSE)
  list(
    result = if (length(checks) &&
                 all(vapply(checks, function(x)
                   identical(x$result, "PASS"), logical(1))))
      "PASS" else "FAIL",
    details = details
  )
}

initial_integrity <- verify_components()

if (!identical(initial_integrity$result, "PASS"))
  setup_error("Sandbox component rehash failed")

# All child invocations use sandbox paths exclusively.

rscript <- file.path(
  R.home("bin"),
  if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
)

if (!file.exists(rscript))
  setup_error("Rscript executable not found")

commands <- list()

run_child <- function(id, script, arguments) {
  if (!file.exists(S(script)))
    setup_error(paste("Missing executable script:", script))

  console_rel <- file.path("console", paste0(id, ".txt"))
  console_path <- file.path(stamp_dir, console_rel)

  if (file.exists(console_path))
    setup_error(paste("Console capture exists:", console_rel))

  argv <- c("--vanilla", S(script), arguments)

  # A file destination avoids relying on system2's in-memory capture.
  status <- tryCatch(
    suppressWarnings(system2(
      rscript,
      args = shQuote(argv),
      stdout = console_path,
      stderr = console_path,
      wait = TRUE
    )),
    error = function(e) {
      if (!file.exists(console_path))
        writeLines(conditionMessage(e), console_path)
      127L
    }
  )

  if (is.null(status) || length(status) != 1L || is.na(status))
    status <- 127L

  # Owner card t1638s6865: every console capture starts with a one-line header, so a quiet child never leaves an empty
  # (gate-invalid, zero-byte) evidence file. The child's own output follows unchanged.
  body <- if (file.exists(console_path)) readBin(console_path, "raw", file.info(console_path)$size) else raw(0)
  header <- sprintf("# exit status %d; %s\n", as.integer(status), if (length(body)) paste(length(body), "bytes of output follow") else "no output")
  con <- file(console_path, "wb"); writeBin(c(charToRaw(header), body), con); close(con)

  entry <- list(
    id = id,
    executable = rscript,
    arguments = as.list(argv),
    command = paste(shQuote(c(rscript, argv)), collapse = " "),
    exit_code = as.integer(status),
    console = ref_stamp(console_rel)
  )

  commands[[length(commands) + 1L]] <<- entry
  entry
}

# The baseline input is supplied, not an expected answer.
# Builder execution precedes every comparison/harness execution.

builder_commands <- list()

for (id in c("r_a", "r_b")) {
  out_rel <- file.path("outputs", id)
  out_abs <- S(out_rel)

  ensure_new_dir(out_abs)

  builder_commands[[id]] <- run_child(
    paste0("builder_", id),
    file.path("analysis", id, "main.R"),
    c(S("data/fixture_8row.csv"), out_abs)
  )
}

compare_command <- run_child(
  "compare_keyed",
  "validation/compare_keyed.R",
  sandbox
)

fixtures_command <- run_child(
  "run_fixtures",
  "validation/run_fixtures.R",
  sandbox
)

methodology_command <- run_child(
  "check_methodology",
  "validation/check_methodology.R",
  sandbox
)

# Other locked scripts, including structural_review.R,
# check_lineage.R, source_verify.R and verify_run.R, are hashed but
# are not executed by this versioned test-report writer.

vd <- "outputs/verification"

fixture_rel <- file.path(vd, "fixture_results.csv")
metamorphic_rel <- file.path(vd, "metamorphic_results.csv")
reconciliation_rel <- file.path(vd, "reconciliation_detail.json")
replay_rel <- file.path(vd, "replay.json")

fixture_data <- readc(S(fixture_rel))
mr_data <- readc(S(metamorphic_rel))
reconciliation_data <- readj(S(reconciliation_rel))
replay_data <- readj(S(replay_rel))

# Checks deliberately never default to PASS.

check <- function(name, condition, observed, evidence) {
  if (is.null(evidence) ||
      !is.list(evidence) ||
      is.null(evidence$path) ||
      is.null(evidence$sha256))
    stop("Check requires an evidence reference")

  list(
    name = name,
    result = if (isTRUE(condition)) "PASS" else "FAIL",
    observed = observed,
    evidence = evidence
  )
}

result_of <- function(checks) {
  if (!length(checks)) return("FAIL")
  if (all(vapply(
    checks,
    function(x) identical(x$result, "PASS"),
    logical(1)
  ))) "PASS" else "FAIL"
}

safe_ref_sandbox <- function(path) {
  if (!valid_rel(path))
    return(list(path = file.path(stamp_rel, "sandbox", "MISSING"),
                sha256 = NA_character_))
  ref_sandbox(path)
}

file_evidence <- function(path, expected = NULL) {
  if (!valid_rel(path))
    return(list(ok = FALSE, reference = safe_ref_sandbox("MISSING")))

  actual <- sha(S(path))
  ok <- !is.na(actual)

  if (!is.null(expected))
    ok <- ok && same_sha(actual, expected)

  list(
    ok = ok,
    reference = ref_sandbox(path)
  )
}

# Fixture family: exact locked coverage, success flags and exit codes.

fixture_checks <- function(path_id) {
  match_col <- if (path_id == "R-A") "match_a" else "match_b"
  exit_col <- if (path_id == "R-A") "exit_a" else "exit_b"

  evidence <- safe_ref_sandbox(fixture_rel)

  shape_ok <- !is.null(fixture_data) &&
    all(c("id", match_col, exit_col) %in% names(fixture_data))

  coverage_ok <- shape_ok &&
    nrow(fixture_data) == length(fixture_ids) &&
    !anyDuplicated(fixture_data$id) &&
    setequal(fixture_data$id, fixture_ids)

  out <- list(check(
    "locked fixture coverage",
    coverage_ok,
    list(
      expected = as.list(fixture_ids),
      observed = if (shape_ok) as.list(fixture_data$id)
        else list()
    ),
    evidence
  ))

  for (fid in fixture_ids) {
    rows <- if (shape_ok)
      fixture_data[fixture_data$id == fid, , drop = FALSE]
    else NULL

    ok <- !is.null(rows) &&
      nrow(rows) == 1L &&
      as_flag(rows[[match_col]][[1L]]) &&
      identical(integer_scalar(rows[[exit_col]][[1L]]), 0L)

    out[[length(out) + 1L]] <- check(
      paste("fixture", fid, path_id),
      ok,
      if (!is.null(rows) && nrow(rows) == 1L)
        list(
          match = rows[[match_col]][[1L]],
          exit = rows[[exit_col]][[1L]]
        )
      else list(rows = if (is.null(rows)) 0L else nrow(rows)),
      evidence
    )
  }

  for (builder_id in c("r_a", "r_b")) {
    out[[length(out) + 1L]] <- check(
      paste("baseline builder exit", builder_id),
      identical(builder_commands[[builder_id]]$exit_code, 0L),
      builder_commands[[builder_id]]$exit_code,
      builder_commands[[builder_id]]$console
    )
  }

  out[[length(out) + 1L]] <- check(
    "run_fixtures command exit",
    identical(fixtures_command$exit_code, 0L),
    fixtures_command$exit_code,
    fixtures_command$console
  )

  out
}

# Checkpoint family: independent m_compare recomputation and
# sandbox-to-live byte identity. Checkpoint fragments reference LIVE files.

checkpoint_rows <- list()
checkpoint_checks <- list()

for (plan in checkpoint_plans) {
  id <- plan$id
  filename <- checkpoint_files[[id]]

  a_rel <- file.path("outputs", "r_a", filename)
  b_rel <- file.path("outputs", "r_b", filename)

  a <- readc(S(a_rel))
  b <- readc(S(b_rel))

  semantic_match <- tryCatch(
    isTRUE(m_compare(a, b, plan)),
    error = function(e) FALSE
  )

  live_a <- ref(a_rel)
  live_b <- ref(b_rel)

  sandbox_a <- ref_sandbox(a_rel)
  sandbox_b <- ref_sandbox(b_rel)

  byte_match <- same_sha(live_a$sha256, sandbox_a$sha256) &&
    same_sha(live_b$sha256, sandbox_b$sha256)

  checkpoint_pass <- semantic_match && byte_match &&
    identical(builder_commands$r_a$exit_code, 0L) &&
    identical(builder_commands$r_b$exit_code, 0L)

  checkpoint_rows[[length(checkpoint_rows) + 1L]] <- list(
    id = id,
    a = live_a,
    b = live_b,
    result = if (checkpoint_pass) "PASS" else "FAIL"
  )

  checkpoint_checks[[length(checkpoint_checks) + 1L]] <- check(
    paste(id, "m_compare"),
    semantic_match,
    list(
      checkpoint = id,
      semantic_match = semantic_match,
      sandbox_a = sandbox_a,
      sandbox_b = sandbox_b
    ),
    sandbox_a
  )

  checkpoint_checks[[length(checkpoint_checks) + 1L]] <- check(
    paste(id, "sandbox-live byte identity"),
    byte_match,
    list(
      live_a = live_a,
      live_b = live_b,
      sandbox_a = sandbox_a,
      sandbox_b = sandbox_b
    ),
    sandbox_b
  )
}

reconciliation_checks <- c(
  list(check(
    "reconciliation harness exit",
    identical(compare_command$exit_code, 0L),
    compare_command$exit_code,
    compare_command$console
  )),
  list(check(
    "reconciliation detail status and mismatch count",
    !is.null(reconciliation_data) &&
      identical(reconciliation_data$status, "PASS") &&
      identical(integer_scalar(reconciliation_data$mismatch_count),
                0L),
    list(
      status = reconciliation_data$status,
      mismatch_count = reconciliation_data$mismatch_count
    ),
    safe_ref_sandbox(reconciliation_rel)
  )),
  checkpoint_checks
)

# Metamorphic family: exact row and the actual per-row harness report.
# A report SHA supplied by the harness must equal independently hashed bytes.

metamorphic_rows <- list()
metamorphic_checks <- list()

mr_shape_ok <- !is.null(mr_data) &&
  all(c("id", "path_id", "result",
        "report_path", "report_sha256") %in% names(mr_data))

expected_mr_keys <- unlist(lapply(mr_ids, function(id) {
  paste(id, c("R-A", "R-B"), sep = ":")
}), use.names = FALSE)

actual_mr_keys <- if (mr_shape_ok) {
  paste(mr_data$id, mr_data$path_id, sep = ":")
} else { character() }

mr_coverage_ok <- mr_shape_ok &&
  length(actual_mr_keys) == length(expected_mr_keys) &&
  !anyDuplicated(actual_mr_keys) &&
  setequal(actual_mr_keys, expected_mr_keys)

for (mid in mr_ids) {
  for (path_id in c("R-A", "R-B")) {
    test_id <- paste("metamorphic", mid, path_id, sep = ":")

    rows <- if (mr_shape_ok)
      mr_data[
        mr_data$id == mid & mr_data$path_id == path_id,
        , drop = FALSE
      ]
    else NULL

    row_ok <- !is.null(rows) && nrow(rows) == 1L

    report_path <- if (row_ok) rows$report_path[[1L]] else "MISSING"
    expected_hash <- if (row_ok) rows$report_sha256[[1L]]
      else NA_character_

    report_file <- file_evidence(report_path, expected_hash)
    report_object <- if (row_ok && valid_rel(report_path))
      readj(S(report_path))
    else NULL

    report_matches <- row_ok &&
      report_file$ok &&
      !is.null(report_object) &&
      identical(report_object$id, mid) &&
      identical(report_object$path_id, path_id) &&
      identical(report_object$result, "PASS")

    passed <- row_ok &&
      identical(rows$result[[1L]], "PASS") &&
      report_matches &&
      mr_coverage_ok &&
      identical(fixtures_command$exit_code, 0L)

    metamorphic_checks[[test_id]] <- list(
      check(
        "locked metamorphic coverage",
        mr_coverage_ok,
        list(
          expected = as.list(expected_mr_keys),
          observed = as.list(actual_mr_keys)
        ),
        safe_ref_sandbox(metamorphic_rel)
      ),
      check(
        "metamorphic row result",
        row_ok && identical(rows$result[[1L]], "PASS"),
        if (row_ok) rows$result[[1L]] else "MISSING",
        safe_ref_sandbox(metamorphic_rel)
      ),
      check(
        "harness report exists, hashes, and reports PASS",
        report_matches,
        list(
          expected_sha256 = expected_hash,
          actual_sha256 = report_file$reference$sha256,
          report_status = report_object$result
        ),
        report_file$reference
      ),
      check(
        "baseline R-A builder exit",
        identical(builder_commands$r_a$exit_code, 0L),
        builder_commands$r_a$exit_code,
        builder_commands$r_a$console
      ),
      check(
        "baseline R-B builder exit",
        identical(builder_commands$r_b$exit_code, 0L),
        builder_commands$r_b$exit_code,
        builder_commands$r_b$console
      ),
      check(
        "run_fixtures child exit",
        identical(fixtures_command$exit_code, 0L),
        fixtures_command$exit_code,
        fixtures_command$console
      )
    )

    metamorphic_rows[[length(metamorphic_rows) + 1L]] <- list(
      id = mid,
      path_id = path_id,
      result = if (passed) "PASS" else "FAIL",
      report = report_file$reference
    )
  }
}

# Replay family: verify both the harness's claims and the actual bytes.
# Original refs in the fragment point to LIVE outputs.
# Replayed refs point into the versioned sandbox.

replay_checks <- list()

replay_status_ok <- !is.null(replay_data) &&
  identical(replay_data$status, "PASS") &&
  isTRUE(replay_data$clean_session) &&
  identical(integer_scalar(replay_data$exit_status), 0L)

replay_checks[[1L]] <- check(
  "replay status, clean session, integer exit",
  replay_status_ok,
  list(
    status = replay_data$status,
    clean_session = replay_data$clean_session,
    exit_status = replay_data$exit_status
  ),
  safe_ref_sandbox(replay_rel)
)

replay_checks[[2L]] <- check(
  "check_methodology child exit",
  identical(methodology_command$exit_code, 0L),
  methodology_command$exit_code,
  methodology_command$console
)

replay_pairs <- list()
replay_outputs <- unlist(
  lock$methodology$replay_outputs, use.names = FALSE
)

harness_pairs <- replay_data$outputs

replay_coverage_ok <- is.list(harness_pairs) &&
  length(harness_pairs) == length(replay_outputs) &&
  !anyDuplicated(vapply(
    harness_pairs,
    function(x) scalar(x$original$path),
    character(1)
  )) &&
  setequal(
    vapply(harness_pairs, function(x)
      scalar(x$original$path), character(1)),
    replay_outputs
  )

replay_checks[[length(replay_checks) + 1L]] <- check(
  "locked replay output coverage",
  replay_coverage_ok,
  list(
    expected = as.list(replay_outputs),
    observed = if (is.list(harness_pairs))
      lapply(harness_pairs, function(x) x$original$path)
    else list()
  ),
  safe_ref_sandbox(replay_rel)
)

for (original in replay_outputs) {
  matching <- if (is.list(harness_pairs))
    Filter(function(x) identical(x$original$path, original),
           harness_pairs)
  else list()

  pair_ok <- length(matching) == 1L
  pair <- if (pair_ok) matching[[1L]] else NULL

  replayed_path <- if (pair_ok)
    scalar(pair$replayed$path)
  else NA_character_

  safe_replayed <- pair_ok &&
    valid_rel(replayed_path) &&
    startsWith(slash(replayed_path), "outputs/replay/")

  replayed_ref <- if (safe_replayed)
    ref_sandbox(replayed_path)
  else safe_ref_sandbox("MISSING")

  sandbox_original <- ref_sandbox(original)
  live_original <- ref(original)

  original_matches <- same_sha(
    sandbox_original$sha256,
    live_original$sha256
  )

  replay_matches <- safe_replayed &&
    same_sha(sandbox_original$sha256, replayed_ref$sha256)

  claimed_matches <- pair_ok &&
    same_sha(pair$original$sha256, sandbox_original$sha256) &&
    same_sha(pair$replayed$sha256, replayed_ref$sha256) &&
    isTRUE(pair$identical)

  replay_checks[[length(replay_checks) + 1L]] <- check(
    paste("replay byte identity", original),
    original_matches && replay_matches && claimed_matches,
    list(
      sandbox_original = sandbox_original,
      live_original = live_original,
      replayed = replayed_ref,
      harness_agrees = claimed_matches
    ),
    replayed_ref
  )

  replay_pairs[[length(replay_pairs) + 1L]] <- list(
    original = live_original,
    replayed = replayed_ref
  )
}

replay_report_path <- if (!is.null(replay_data)) {
  scalar(replay_data$report$path)
} else { NA_character_ }

replay_report <- if (valid_rel(replay_report_path)) {
  ref_sandbox(replay_report_path)
} else { safe_ref_sandbox("MISSING") }

replay_report_ok <- !is.na(replay_report$sha256) &&
  same_sha(replay_report$sha256, replay_data$report$sha256)

replay_checks[[length(replay_checks) + 1L]] <- check(
  "replay textual report hash",
  replay_report_ok,
  list(
    actual = replay_report$sha256,
    claimed = replay_data$report$sha256
  ),
  replay_report
)

# Every test also binds component integrity immediately before reporting.
# This prevents post-copy input changes from remaining undetected.

integrity_final <- verify_components()
integrity_ref_rel <- "component_integrity.json"

json_write(
  list(
    initial = initial_integrity,
    final = integrity_final,
    checked_at_utc = utc()
  ),
  file.path(stamp_dir, integrity_ref_rel)
)

integrity_ref <- ref_stamp(integrity_ref_rel)

integrity_check <- check(
  "locked component identity at report creation",
  identical(integrity_final$result, "PASS"),
  integrity_final$result,
  integrity_ref
)

# Build the complete family check map.

checks_by_id <- list(
  "fixtures:R-A" = fixture_checks("R-A"),
  "fixtures:R-B" = fixture_checks("R-B"),
  "replay" = replay_checks,
  "reconciliation" = reconciliation_checks
)

for (id in names(metamorphic_checks))
  checks_by_id[[id]] <- metamorphic_checks[[id]]

if (!setequal(names(checks_by_id), test_ids))
  setup_error("Internal test ID coverage mismatch")

# Self-test probes act on the actual sandbox, never on live ROOT.
#
# Clean case: use the results just computed.
# Component case: append a byte to a copied component, then rehash.
# Failure case: corrupt a replayed CSV, then independently check bytes.
# Both injected changes are in the new sandbox directory.
#
# These probes cannot certify the ordinary run as clean after mutation.

self_test_cases <- list()
report_phase <- if (self_test) "pre-injection; NOT final-sandbox certification" else "final"

if (self_test) {
  clean_results <- vapply(test_ids, function(id) {
    result_of(c(checks_by_id[[id]], list(integrity_check)))
  }, character(1))
  clean_ok <- length(clean_results) == 20L && all(clean_results == "PASS")
  self_test_cases[[1L]] <- list(
    case = "clean", expected = "PASS",
    observed = if (clean_ok) "PASS" else "FAIL",
    result = if (clean_ok) "PASS" else "FAIL"
  )

  # Case B re-derives the fixture:R-B report's PASS/FAIL gate
  # from the mutated component, rather than merely observing a changed hash.
  component_target <- S("analysis/r_b/main.R")
  con <- file(component_target, open = "ab")
  writeBin(as.raw(0x58), con)
  close(con)
  compromised_integrity <- verify_components()
  compromised_gate <- check(
    "locked component identity after injection",
    identical(compromised_integrity$result, "PASS"),
    compromised_integrity$result,
    ref_sandbox("analysis/r_b/main.R")
  )
  component_test_status <- result_of(c(
    checks_by_id[["fixtures:R-B"]], list(compromised_gate)
  ))
  self_test_cases[[2L]] <- list(
    case = "tampered_component", affected_test = "fixtures:R-B",
    expected = "FAIL", observed = component_test_status,
    detected = identical(component_test_status, "FAIL"),
    result = if (identical(component_test_status, "FAIL")) "PASS" else "FAIL",
    evidence = ref_sandbox("analysis/r_b/main.R")
  )

  # Case C independently re-derives the replay equality check after
  # tampering; capture pristine expected SHA before touching the file.
  first_pair <- if (is.list(harness_pairs) && length(harness_pairs)) {
    harness_pairs[[1L]]
  } else { NULL }
  target_rel <- if (!is.null(first_pair)) {
    scalar(first_pair$replayed$path)
  } else { NA_character_ }
  target_original <- if (!is.null(first_pair)) {
    scalar(first_pair$original$path)
  } else { NA_character_ }
  pristine_sha <- if (valid_rel(target_rel)) sha(S(target_rel)) else NA_character_
  original_sha <- if (valid_rel(target_original)) sha(S(target_original)) else NA_character_
  mutation_performed <- valid_rel(target_rel) &&
    startsWith(slash(target_rel), "outputs/replay/") &&
    !is.na(pristine_sha) && !is.na(original_sha) &&
    !identical(target_rel, target_original)
  if (mutation_performed) {
    con <- file(S(target_rel), open = "ab")
    writeBin(as.raw(0x59), con)
    close(con)
  }
  modified_sha <- if (mutation_performed) sha(S(target_rel)) else NA_character_
  replay_equality <- mutation_performed &&
    same_sha(pristine_sha, original_sha) &&
    same_sha(modified_sha, original_sha) &&
    same_sha(modified_sha, pristine_sha)
  # Derive a new replay test status using the same result_of gate used
  # by production reports, replacing the affected byte-identity check.
  replay_rechecks <- replay_checks
  if (mutation_performed) {
    affected_name <- paste("replay byte identity", target_original)
    ix <- which(vapply(replay_rechecks, function(x)
      identical(x$name, affected_name), logical(1)))
    if (length(ix) == 1L) {
      replay_rechecks[[ix]] <- check(
        affected_name, replay_equality,
        list(pristine_sha256 = pristine_sha,
             original_sha256 = original_sha,
             tampered_sha256 = modified_sha),
        ref_sandbox(target_rel)
      )
    } else { mutation_performed <- FALSE }
  }
  replay_test_status <- if (mutation_performed) {
    result_of(replay_rechecks)
  } else { "NOT_EXECUTED" }
  detected_replay <- mutation_performed &&
    !same_sha(modified_sha, pristine_sha) &&
    identical(replay_test_status, "FAIL")
  self_test_cases[[3L]] <- list(
    case = "corrupted_replay_output", affected_test = "replay",
    expected = "FAIL", observed = replay_test_status,
    detected = detected_replay,
    pristine_sha256 = pristine_sha,
    tampered_sha256 = modified_sha,
    result = if (detected_replay) "PASS" else "FAIL",
    evidence = if (valid_rel(target_rel)) ref_sandbox(target_rel)
      else safe_ref_sandbox("MISSING")
  )
  json_write(list(
    status = if (all(vapply(self_test_cases, function(x)
      identical(x$result, "PASS"), logical(1)))) "PASS" else "FAIL",
    cases = self_test_cases,
    reports_phase = report_phase,
    certification = FALSE,
    recorded_at_utc = utc()
  ), file.path(stamp_dir, "self_test.json"))
}

# Ordinary reports are snapshots of the unmodified execution.
# Self-test mutation is disclosed in self_test.json and summary.json.

test_entries <- list()
test_results <- character()

for (id in test_ids) {
  checks <- c(checks_by_id[[id]], list(integrity_check))
  status <- result_of(checks)
  recorded <- utc()

  report <- list(
    id = id,
    result = status,
    components = components,
    recorded_at_utc = recorded,
    evidence_phase = report_phase,
    checks = checks
  )

  filename <- paste0(gsub(":", "__", id, fixed = TRUE), ".json")
  report_rel <- file.path("tests", filename)

  json_write(report, file.path(stamp_dir, report_rel))

  test_entries[[length(test_entries) + 1L]] <- list(
    id = id,
    result = status,
    components = components,
    recorded_at_utc = recorded,
    report = ref_stamp(report_rel)
  )

  test_results <- c(test_results, status)
}

# Coordinator fragments: never infer PASS from the existence of a report.

json_write(
  list(components = components, tests = test_entries),
  file.path(stamp_dir, "test_versions.json")
)

json_write(
  unname(checkpoint_rows),
  file.path(stamp_dir, "checkpoints.json")
)

json_write(
  unname(metamorphic_rows),
  file.path(stamp_dir, "metamorphic.json")
)

replay_fragment_status <- result_of(replay_checks)

json_write(
  list(
    status = replay_fragment_status,
    clean_session = isTRUE(replay_data$clean_session),
    exit_status = integer_scalar(replay_data$exit_status, 127L),
    report = replay_report,
    outputs = replay_pairs
  ),
  file.path(stamp_dir, "replay.json")
)

# Machine-observable environment only.

session_rel <- "session_info.txt"
capture.output(
  sessionInfo(),
  file = file.path(stamp_dir, session_rel)
)

json_write(
  list(
    r_version = R.version.string,
    os = Sys.info()[["sysname"]],
    locale = Sys.getlocale(),
    timezone = Sys.timezone(),
    encoding = l10n_info(),
    rng_kind = as.list(RNGkind()),
    threads = list(
      OMP_NUM_THREADS = Sys.getenv("OMP_NUM_THREADS", unset = ""),
      OPENBLAS_NUM_THREADS =
        Sys.getenv("OPENBLAS_NUM_THREADS", unset = ""),
      MKL_NUM_THREADS = Sys.getenv("MKL_NUM_THREADS", unset = "")
    ),
    session_info = ref_stamp(session_rel)
  ),
  file.path(stamp_dir, "environment.json")
)

# Resolve the tool's actual source file from --file, rather than
# assuming its location relative to the working directory.

full_args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", full_args, value = TRUE)

tool_path <- if (length(script_arg) == 1L) {
  sub("^--file=", "", script_arg)
} else { NA_character_ }

tool_sha <- if (!is.na(tool_path)) sha(tool_path) else NA_character_

all_pass <- length(test_results) == 20L &&
  all(test_results == "PASS")

self_test_pass <- !self_test ||
  all(vapply(self_test_cases, function(x)
    identical(x$result, "PASS"), logical(1)))

final_status <- if (all_pass && self_test_pass) "PASS" else "FAIL"

json_write(
  list(
    status = final_status,
    mode = if (self_test) "self-test" else "normal",
    evidence_phase = report_phase,
    certifies_final_sandbox = !self_test,
    tool_sha256 = tool_sha,
    r_version = R.version.string,
    recorded_at_utc = utc(),
    component_integrity = integrity_ref,
    tests_expected = 20L,
    tests_passed = as.integer(sum(test_results == "PASS")),
    tests_failed = as.integer(sum(test_results != "PASS")),
    commands = commands,
    self_test = if (self_test)
      ref_stamp("self_test.json")
    else NULL,
    fragments = list(
      test_versions = ref_stamp("test_versions.json"),
      checkpoints = ref_stamp("checkpoints.json"),
      metamorphic = ref_stamp("metamorphic.json"),
      replay = ref_stamp("replay.json")
    )
  ),
  file.path(stamp_dir, "summary.json")
)

cat(
  "Versioned test reports:", stamp_rel, "\n",
  "Tests passed:", sum(test_results == "PASS"), "/20\n",
  "Status:", final_status, "\n",
  sep = ""
)

quit(
  save = "no",
  status = if (identical(final_status, "PASS")) 0L else 1L
)
}
tryCatch(.main(), error = function(e) {
  cat("SETUP ERROR: ", conditionMessage(e), "\n", sep = "", file = stderr())
  quit(save = "no", status = 2L)
})
