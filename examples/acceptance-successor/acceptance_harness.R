# Prospective successor adaptation; original v2 SHA256 de5e2489cef4c58800e757107220d0679feea961d6d6a6d8a7e61494bfe83b7a preserved externally.
#!/usr/bin/env Rscript
# ACC-SMALL-REMEDIATION-001 Stage 4 acceptance harness (coordinator-written, mechanical; judged logic lives only in R-A/R-B).
# Locked invocation (project root):
#   Rscript --vanilla validation/acceptance_harness.R --design config/measurement_design.json --expected validation/expected_fixture.json --ra artifacts/stage4/r_a --rb artifacts/stage4/r_b --out artifacts/stage4/validation_report.json
# Extra phases (same file, run before the locked command): --phase fixture  (Fixture Gate)  |  --phase smoke (NON_REPORTING smoke runs)
# v2 (D-26, bounded A8): required --attempt N; every phase writes only into attempt-scoped folders, so earlier attempts stay in place unmoved.
# Every check emits PASS/FAIL/NOT_ASSESSED. Work directories are write-once: the harness refuses to reuse an existing one.
suppressPackageStartupMessages({ library(jsonlite); library(digest) })
`%||%` <- function(a, b) if (is.null(a)) b else a
die <- function(...) { cat("HARNESS ERROR:", ..., "\n", file = stderr()); quit(save = "no", status = 2L) }
a <- commandArgs(TRUE); opt <- list(phase = "all"); i <- 1L
while (i <= length(a)) { if (!startsWith(a[[i]], "--") || i == length(a)) die("bad arguments"); opt[[sub("^--", "", a[[i]])]] <- a[[i + 1L]]; i <- i + 2L }
for (k in c("design", "expected", "attempt")) if (is.null(opt[[k]])) die("missing --", k)
if (!grepl("^[0-9]+$", opt$attempt)) die("--attempt must be a positive integer")
ATT <- paste0("attempt", opt$attempt)
if (opt$phase == "all") for (k in c("ra", "rb", "out")) if (is.null(opt[[k]])) die("missing --", k)
sha <- function(p) digest(file = p, algo = "sha256")
now <- function() format(as.POSIXct(Sys.time()), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
ref <- function(p) list(path = p, sha256 = sha(p))
wj <- function(x, p) { dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE); if (file.exists(p)) die("refusing to overwrite ", p); writeLines(toJSON(x, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA), p, useBytes = TRUE) }
fresh_dir <- function(p) { if (file.exists(p)) die("work directory already exists (write-once): ", p); dir.create(p, recursive = TRUE); p }
cfg <- fromJSON(opt$design, simplifyVector = FALSE)
oracle <- fromJSON(opt$expected, simplifyVector = FALSE)
rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
ART <- unlist(cfg$required_artifacts)
CANON <- cfg$canonical_input$path
comp <- lapply(cfg$validation_components, function(v) lapply(unlist(v), ref))
comp_sha0 <- sha(opt$design)
cases_man <- fromJSON("validation/cases/manifest.json", simplifyVector = FALSE)
mut_man <- fromJSON("validation/mutants/threshold_gt10/manifest.json", simplifyVector = FALSE)
SCRIPT <- list("R-A" = unlist(cfg$validation_components[["R-A"]])[[1]], "R-B" = unlist(cfg$validation_components[["R-B"]])[[1]])
TAG <- c("R-A" = "r_a", "R-B" = "r_b")

run_builder <- function(script, input, cap, out) {
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(out)) die("builder output exists (write-once): ", out)
  lo <- paste0(out, ".stdout.txt"); le <- paste0(out, ".stderr.txt")
  t0 <- Sys.time()
  st <- suppressWarnings(system2(rscript, c("--vanilla", script, "--input", input, "--design", opt$design, "--capacity", as.character(cap), "--out", out), stdout = lo, stderr = le, timeout = 600))
  list(script = script, script_sha256 = sha(script), input = input, input_sha256 = sha(input), capacity = cap, out = out, exit = as.integer(st %||% NA), seconds = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 3),
       stdout = ref(lo), stderr = ref(le))
}
rcsv <- function(p) read.csv(p, colClasses = "character", na.strings = character(0), check.names = FALSE, stringsAsFactors = FALSE)
read_out <- function(d) {
  f <- file.path(d, ART); if (!all(file.exists(f))) return(NULL)
  tryCatch(list(selected = rcsv(f[1]), qualified = rcsv(f[2]), ledger = rcsv(f[3]), summary = fromJSON(f[4], simplifyVector = FALSE), meta = fromJSON(f[5], simplifyVector = FALSE)), error = function(e) NULL)
}
NULLTOK <- c("", "NA", "null")
num <- function(x) { x <- as.character(x); out <- rep(NA_real_, length(x)); ok <- !(x %in% NULLTOK); out[ok] <- suppressWarnings(as.numeric(x[ok])); if (anyNA(x) || any(!is.finite(out[ok]))) stop("Invalid numeric output token; not an approved missing token"); out }
lgl <- function(x) { x <- toupper(as.character(x)); ifelse(x == "TRUE", TRUE, ifelse(x == "FALSE", FALSE, NA)) }
txt <- function(x) { x <- as.character(x); ifelse(x %in% NULLTOK, NA_character_, x) }
sj <- function(x) if (is.null(x)) NA else x
same <- function(a, b) isTRUE(identical(a, b)) || (length(a) == length(b) && isTRUE(all(mapply(function(x, y) identical(x, y) || (is.na(x) && is.na(y)), a, b))))
ck <- function(env, name, pass, detail = "") { env$checks[[length(env$checks) + 1L]] <- list(check = name, result = if (isTRUE(pass)) "PASS" else "FAIL", detail = detail); invisible(isTRUE(pass)) }
newenv <- function() { e <- new.env(); e$checks <- list(); e }
result_of <- function(e) if (length(e$checks) && all(vapply(e$checks, function(x) identical(x$result, "PASS"), logical(1)))) "PASS" else "FAIL"
fmt <- function(x) paste(x, collapse = ",")

LEDGER_TYPES <- list(num = c("amount_value", "qualified_rank", "selection_rank"), lgl = c("eligible_value", "qualified", "selected"), txt = c("id", "amount_raw", "eligible_raw", "amount_status", "exclusion_reason", "outcome"))
OUTCOME <- c(ineligible = "excluded_ineligible", blank = "excluded_invalid_amount", nonnumeric = "excluded_invalid_amount", nonfinite = "excluded_invalid_amount", below_threshold = "excluded_below_threshold")

# Score one builder output directory against an expectation (oracle or locked MR relation).
score <- function(e, run, o, exp, input, cap, prefix = "") {
  P <- function(n) paste0(prefix, n)
  ck(e, P("builder exit status 0"), identical(run$exit, 0L), paste("exit", run$exit))
  ck(e, P("all five artifacts present and parse"), !is.null(o))
  if (is.null(o)) return(invisible())
  s <- o$selected; q <- o$qualified; l <- o$ledger; sm <- o$summary
  ck(e, P("qualified.csv ids in exact order"), same(q$id, unlist(exp$qualified)), paste("got", fmt(q$id), "want", fmt(unlist(exp$qualified))))
  ck(e, P("qualified_rank 1..n"), same(num(q$qualified_rank), as.numeric(seq_len(nrow(q)))))
  ck(e, P("selected.csv ids in exact order"), same(s$id, unlist(exp$selected)), paste("got", fmt(s$id), "want", fmt(unlist(exp$selected))))
  ck(e, P("selection_rank 1..k"), same(num(s$selection_rank), as.numeric(seq_len(nrow(s)))))
  ck(e, P("summary.qualified_count"), same(as.numeric(sj(sm$qualified_count)), as.numeric(exp$qualified_count)), paste(sj(sm$qualified_count)))
  ck(e, P("summary.selected_count"), same(as.numeric(sj(sm$selected_count)), as.numeric(exp$selected_count)), paste(sj(sm$selected_count)))
  ck(e, P("summary.selected_amount_sum (tolerance 0)"), same(as.numeric(sj(sm$selected_amount_sum)), as.numeric(exp$selected_amount_sum)), paste(sj(sm$selected_amount_sum)))
  ck(e, P("summary.capacity"), same(as.numeric(sj(sm$capacity)), as.numeric(cap)))
  ck(e, P("summary.source_sha256 = actual input"), identical(sj(sm$source_sha256), sha(input)))
  ck(e, P("run_metadata source_sha256/capacity = summary"), identical(sj(o$meta$source_sha256), sj(sm$source_sha256)) && same(as.numeric(sj(o$meta$capacity)), as.numeric(cap)))
  if (!is.null(exp$amounts)) ck(e, P("qualified amounts exact"), same(num(q$amount), as.numeric(unlist(exp$amounts))), fmt(q$amount))
  src <- rcsv(input)
  ck(e, P("ledger: one row per source record"), nrow(l) == nrow(src) && setequal(l$id, src$id), paste(nrow(l), "rows"))
  ck(e, P("ledger: id ascending byte-wise (CR-02)"), same(l$id, l$id[order(l$id, method = "radix")]))
  ck(e, P("ledger: all locked columns present"), all(unlist(LEDGER_TYPES) %in% names(l)))
  if (!all(unlist(LEDGER_TYPES) %in% names(l))) return(invisible())
  qq <- lgl(l$qualified); ss <- lgl(l$selected); rr <- txt(l$exclusion_reason); st <- txt(l$amount_status)
  ck(e, P("ledger: qualified flags = qualified.csv"), setequal(l$id[qq %in% TRUE], q$id) && !any(is.na(qq)))
  ck(e, P("ledger: selected flags = selected.csv"), setequal(l$id[ss %in% TRUE], s$id) && !any(is.na(ss)))
  m <- match(q$id, l$id); ck(e, P("ledger: qualified_rank matches"), !anyNA(m) && same(num(l$qualified_rank[m]), num(q$qualified_rank)) && all(is.na(num(l$qualified_rank[!(qq %in% TRUE)]))))
  m <- match(s$id, l$id); ck(e, P("ledger: selection_rank matches"), !anyNA(m) && same(num(l$selection_rank[m]), num(s$selection_rank)) && all(is.na(num(l$selection_rank[!(ss %in% TRUE)]))))
  ck(e, P("ledger: exclusion_reason null iff qualified"), all(is.na(rr) == (qq %in% TRUE)))
  ok_out <- ifelse(ss %in% TRUE, "selected", ifelse(qq %in% TRUE, "qualified_not_selected", unname(OUTCOME[rr])))
  ck(e, P("ledger: outcome consistent with reason/selection"), same(txt(l$outcome), ok_out))
  ck(e, P("ledger: amount_status in locked enum"), all(st %in% c("finite", "blank", "nonnumeric", "nonfinite")))
  av <- num(l$amount_value)
  ck(e, P("ledger: amount_value finite iff status finite, else null"), all(is.finite(av) == (st %in% "finite")) && all(is.na(av[!(st %in% "finite")])))
  ms <- match(l$id, src$id)
  ck(e, P("ledger: raw tokens equal source"), !anyNA(ms) && same(l$amount_raw, src$amount[ms]) && same(l$eligible_raw, src$eligible[ms]))
  ck(e, P("ledger: eligible_value = (eligible_raw == 'true')"), same(lgl(l$eligible_value), l$eligible_raw == "true"))
  if (!is.null(exp$reasons)) for (id in names(exp$reasons)) ck(e, P(paste0("ledger: ", id, " exclusion_reason = ", exp$reasons[[id]])), identical(rr[match(id, l$id)], exp$reasons[[id]]), paste("got", rr[match(id, l$id)]))
  if (isTRUE(exp$source_hash_differs_from_canonical)) ck(e, P("derived source hash differs from canonical"), !identical(sj(sm$source_sha256), cfg$canonical_input$sha256))
  invisible()
}
oracle_exp <- function(capkey) list(qualified = vapply(oracle$ordered_qualified, function(x) x$id, ""), amounts = vapply(oracle$ordered_qualified, function(x) as.numeric(x$amount), 0),
  selected = vapply(oracle[[capkey]], function(x) x$id, ""), qualified_count = oracle$qualified_count, selected_count = length(oracle[[capkey]]),
  selected_amount_sum = sum(vapply(oracle[[capkey]], function(x) as.numeric(x$amount), 0)))
test_report <- function(id, e, extra = list()) {
  r <- c(list(id = id, result = result_of(e), components = comp, recorded_at_utc = now(), checks = e$checks), extra)
  p <- file.path(TESTDIR, paste0(gsub("[:]", "__", id), ".json")); wj(r, p)
  list(id = id, result = r$result, components = comp, recorded_at_utc = r$recorded_at_utc, report = ref(p))
}
source_fidelity <- function(e) {
  p <- CANON; raw <- readBin(p, "raw", file.info(p)$size); t <- rawToChar(raw); Encoding(t) <- "UTF-8"
  lines <- strsplit(t, "\n", fixed = TRUE)[[1]]; src <- rcsv(p)
  ck(e, "CP-00 sha256", identical(sha(p), cfg$canonical_input$sha256)); ck(e, "CP-00 bytes 97", length(raw) == cfg$canonical_input$bytes)
  ck(e, "CP-00 UTF-8 valid", validUTF8(t)); ck(e, "CP-00 LF only, trailing LF", !any(raw == as.raw(13)) && raw[length(raw)] == as.raw(10))
  ck(e, "CP-00 header", identical(strsplit(lines[1], ",")[[1]], unlist(cfg$canonical_input$header)))
  ck(e, "CP-00 row count 8", nrow(src) == cfg$canonical_input$data_rows && length(lines) - 1L == 8L); ck(e, "CP-00 unique nonempty ids", !anyDuplicated(src$id) && all(nzchar(src$id)))
}
authorized <- function(e) {
  ck(e, "case manifest binds current design receipt", identical(cases_man$design_receipt$sha256, sha(cases_man$design_receipt$path)))
  for (c in cases_man$cases) ck(e, paste("authorized case input", c$case_id), file.exists(c$input$path) && identical(sha(c$input$path), c$input$sha256))
  for (m in mut_man$mutants) {
    t <- readLines(m$base$path, warn = FALSE); tb <- paste0(paste(t, collapse = "\n"), "\n")
    for (s in m$substitutions) tb <- sub(s$original, s$replacement, tb, fixed = TRUE)
    mt <- paste0(paste(readLines(m$mutant$path, warn = FALSE), collapse = "\n"), "\n")
    ck(e, paste("mutant", m$path_id, "base and mutant hashes match manifest"), identical(sha(m$base$path), m$base$sha256) && identical(sha(m$mutant$path), m$mutant$sha256))
    ck(e, paste("mutant", m$path_id, "= base with exactly the declared substitutions"), identical(tb, mt) && !identical(tb, paste0(paste(t, collapse = "\n"), "\n")))
  }
}
poison <- function(o) {
  o$selected$id <- rep("POISON", nrow(o$selected)); o$qualified$id <- rep("POISON", nrow(o$qualified))
  for (k in c("qualified", "selected", "exclusion_reason", "outcome", "amount_status")) o$ledger[[k]] <- "POISON"
  for (k in c("qualified_count", "selected_count", "selected_amount_sum")) o$summary[[k]] <- -1
  o
}
fixture_gate <- function(W) {
  out <- list(); depth <- list()
  for (b in names(SCRIPT)) {
    e <- newenv(); source_fidelity(e)
    r2 <- run_builder(SCRIPT[[b]], CANON, 2, file.path(W, "fixture", TAG[[b]], "cap2")); o2 <- read_out(r2$out)
    score(e, r2, o2, oracle_exp("ordered_shortlist_capacity_2"), CANON, 2, "cap2: ")
    r1 <- run_builder(SCRIPT[[b]], CANON, 1, file.path(W, "fixture", TAG[[b]], "cap1")); o1 <- read_out(r1$out)
    score(e, r1, o1, oracle_exp("selection_capacity_1"), CANON, 1, "cap1: ")
    prod <- result_of(e)
    # depth gate: poison judge — replace every judged label in this path's own fixture outputs with a value no expectation allows, rescore.
    pe <- newenv(); pr <- "FAIL"
    if (!is.null(o2)) {
      score(pe, r2, poison(o2), oracle_exp("ordered_shortlist_capacity_2"), CANON, 2)
      core <- c("qualified.csv ids in exact order", "selected.csv ids in exact order", "summary.qualified_count", "summary.selected_count", "summary.selected_amount_sum (tolerance 0)", "ledger: qualified flags = qualified.csv", "ledger: outcome consistent with reason/selection")
      res <- vapply(pe$checks, function(x) x$result, ""); names(res) <- vapply(pe$checks, function(x) x$check, "")
      pr <- if (all(core %in% names(res)) && all(res[core] == "FAIL") && result_of(pe) == "FAIL") "PASS" else "FAIL"
    }
    ck(e, "depth gate: poison judge rejected (every core judged check FAILS under poison)", identical(pr, "PASS"))
    out[[b]] <- test_report(paste0("fixtures:", b), e, list(runs = list(r2, r1), production_reader = prod, poison_probe = pr, poison_checks = pe$checks,
      production_reader_note = "The frozen fixture is the production source file itself (CSV text, header, empty-string null rendering); each path reads it with its own production reader and normalizers."))
  }
  out
}

W <- file.path("artifacts/stage4/harness", ATT); TESTDIR <- file.path(W, "tests")
if (opt$phase == "fixture") {
  W <- fresh_dir(file.path("artifacts/stage4/fixture_gate", ATT)); TESTDIR <- file.path(W, "tests"); e0 <- newenv(); authorized(e0)
  fx <- fixture_gate(W)
  rep <- list(phase = "fixture_gate", recorded_at_utc = now(), status = if (result_of(e0) == "PASS" && all(vapply(fx, function(x) x$result == "PASS", TRUE))) "PASS" else "FAIL", authorization_checks = e0$checks, tests = fx, components = comp)
  wj(rep, file.path(W, "fixture_gate_report.json")); cat(rep$status, "\n"); quit(save = "no", status = if (rep$status == "PASS") 0L else 1L)
}
if (opt$phase == "smoke") {
  S <- fresh_dir(file.path("smoke", ATT)); writeLines("NON_REPORTING: smoke runs only. Never reconciled, never results, never in an analytical receipt.", file.path(S, "NON_REPORTING"))
  src <- readLines(CANON, warn = FALSE); runs <- list(); det <- list()
  for (k in c(16L, 4L)) {
    idx <- seq(1L, length(src) - 1L, by = k); p <- file.path(S, sprintf("subset_k%d.csv", k)); con <- file(p, "wb"); writeLines(c(src[1], src[1 + idx]), con, sep = "\n"); close(con)
    for (b in names(SCRIPT)) runs[[length(runs) + 1L]] <- c(list(k = k, path_id = b, subset = ref(p), rule = "header + data lines 1, 1+k, 1+2k, ... in file order"), run_builder(SCRIPT[[b]], p, 2, file.path(S, sprintf("k%d", k), TAG[[b]])))
  }
  for (b in names(SCRIPT)) {
    r16 <- Filter(function(x) x$k == 16L && x$path_id == b, runs)[[1]]; r4 <- Filter(function(x) x$k == 4L && x$path_id == b, runs)[[1]]
    det[[b]] <- if (!identical(r16$exit, 0L) || r16$seconds >= 600) "DETECTED_AT_K16" else if (!identical(r4$exit, 0L) || r4$seconds >= 600 || r4$seconds > 6 * max(r16$seconds, 0.001)) "DETECTED_AT_K4" else "NONE"
  }
  rep <- list(phase = "smoke", NON_REPORTING = TRUE, recorded_at_utc = now(), declared_rule = "k = 16 then k = 4; cap 600 s; k4 > 6x k16 time = super-linear signal", runs = runs, detection = det,
    status = if (all(unlist(det) == "NONE")) "PASS" else "FAIL", components = comp)
  wj(rep, file.path(S, "smoke_report.json")); cat(rep$status, "\n"); quit(save = "no", status = if (rep$status == "PASS") 0L else 1L)
}
# ---------------- full locked harness run ----------------
W <- fresh_dir(W); e0 <- newenv(); source_fidelity(e0); authorized(e0)
tests <- list(); OUTDIR <- list("R-A" = opt$ra, "R-B" = opt$rb)
canon <- lapply(OUTDIR, read_out)
fx <- fixture_gate(W); tests <- c(tests, unname(fx))
# reconciliation: canonical outputs vs oracle, and R-A vs R-B typed exact (ledger keyed by id), tolerance 0
e <- newenv()
for (b in names(OUTDIR)) score(e, list(exit = 0L), canon[[b]], oracle_exp("ordered_shortlist_capacity_2"), CANON, 2, paste0("canonical ", b, " vs oracle: "))
A <- canon[["R-A"]]; B <- canon[["R-B"]]
if (!is.null(A) && !is.null(B)) {
  for (f in c("selected", "qualified")) {
    rk <- if (f == "selected") "selection_rank" else "qualified_rank"
    ck(e, paste0("R-A vs R-B ", f, ".csv exact typed values and row order"), same(A[[f]]$id, B[[f]]$id) && same(num(A[[f]]$amount), num(B[[f]]$amount)) && same(num(A[[f]][[rk]]), num(B[[f]][[rk]])))
  }
  m <- match(A$ledger$id, B$ledger$id); ok <- nrow(A$ledger) == nrow(B$ledger) && !anyNA(m); diffs <- character(0)
  if (ok) for (g in names(LEDGER_TYPES)) for (col in LEDGER_TYPES[[g]]) { fa <- switch(g, num = num, lgl = lgl, txt = function(x) as.character(x)); if (!same(fa(A$ledger[[col]]), fa(B$ledger[[col]][m]))) diffs <- c(diffs, col) }
  ck(e, "R-A vs R-B ledger.csv exact typed values keyed by id", ok && !length(diffs), paste("differing:", fmt(diffs)))
  ck(e, "R-A vs R-B summary.json exact typed values", all(vapply(c("qualified_count", "selected_count", "selected_amount_sum", "capacity"), function(k) same(as.numeric(sj(A$summary[[k]])), as.numeric(sj(B$summary[[k]]))), TRUE)) && identical(A$summary$source_sha256, B$summary$source_sha256))
  ck(e, "R-A vs R-B common run_metadata (source_sha256, capacity)", identical(A$meta$source_sha256, B$meta$source_sha256) && same(as.numeric(sj(A$meta$capacity)), as.numeric(sj(B$meta$capacity))))
  serial <- vapply(ART[1:4], function(f) identical(sha(file.path(opt$ra, f)), sha(file.path(opt$rb, f))), TRUE)
  e$serialization_note <- paste("byte-identical across builders (informational, not required):", fmt(paste0(ART[1:4], "=", serial)))
} else ck(e, "R-A and R-B canonical outputs readable", FALSE)
# checkpoint tables for the Workflow Gate (summary/metadata rendered to one-row CSV; selected/qualified/ledger are the builders' own files)
CPD <- file.path(W, "checkpoints"); dir.create(CPD, recursive = TRUE, showWarnings = FALSE)
cp_tab <- function(x, keys, p) { if (file.exists(p)) die("exists ", p); df <- as.data.frame(lapply(x[keys], function(v) as.character(sj(v))), stringsAsFactors = FALSE); write.csv(df, p, row.names = FALSE); ref(p) }
cps <- list()
for (b in names(OUTDIR)) if (!is.null(canon[[b]])) {
  cps[[b]] <- list(summary = cp_tab(canon[[b]]$summary, c("source_sha256", "capacity", "qualified_count", "selected_count", "selected_amount_sum"), file.path(CPD, paste0("CP-summary_", TAG[[b]], ".csv"))),
                   metadata = cp_tab(canon[[b]]$meta, c("source_sha256", "capacity"), file.path(CPD, paste0("CP-metadata_", TAG[[b]], ".csv"))))
}
tests[[length(tests) + 1L]] <- test_report("reconciliation", e, list(serialization_note = e$serialization_note %||% NA, checkpoint_tables = cps))
# metamorphic cases (authorized inputs only), both builders
mr_ids <- unique(vapply(cases_man$cases, function(c) c$mr_id, ""))
for (b in names(SCRIPT)) {
  for (mid in mr_ids) {
    e <- newenv(); runs <- list()
    for (c in Filter(function(c) c$mr_id == mid, cases_man$cases)) {
      r <- run_builder(SCRIPT[[b]], c$input$path, c$capacity, file.path(W, "cases", c$case_id, TAG[[b]])); runs[[length(runs) + 1L]] <- r
      if (identical(c$expected$exit, "nonzero")) {
        ck(e, paste0(c$case_id, ": schema failure exits nonzero"), !is.na(r$exit) && r$exit != 0L, paste("exit", r$exit))
        ck(e, paste0(c$case_id, ": no successful selection output"), !any(file.exists(file.path(r$out, ART))))
      } else score(e, r, read_out(r$out), c$expected, c$input$path, c$capacity, paste0(c$case_id, ": "))
    }
    tests[[length(tests) + 1L]] <- test_report(paste0("metamorphic:", mid, ":", b), e, list(runs = runs))
  }
  # MR-10 planted mutant
  e <- newenv(); mm <- Filter(function(m) m$path_id == b, mut_man$mutants)[[1]]
  r <- run_builder(mm$mutant$path, mut_man$input$path, mut_man$capacity, file.path(W, "mutant", TAG[[b]])); o <- read_out(r$out)
  ev1 <- ck(e, "MR-10 evidence 1: mutant actually invoked and completed (exit 0, five artifacts parse)", identical(r$exit, 0L) && !is.null(o))
  ev2 <- ev1 && ck(e, "MR-10 evidence 2: mutant threshold excludes B and E (below_threshold)", all(txt(o$ledger$exclusion_reason[match(c("B", "E"), o$ledger$id)]) == "below_threshold"))
  if (!ev1) ck(e, "MR-10 evidence 2: mutant threshold excludes B and E (below_threshold)", FALSE)
  me <- newenv(); if (ev1) score(me, r, o, mut_man$expected_mutant_result, mut_man$input$path, 2)
  ev3 <- ev1 && result_of(me) == "PASS" && !identical(o$qualified$id, oracle_exp("ordered_shortlist_capacity_2")$qualified)
  ck(e, "MR-10 evidence 3: defective result = locked mutant relation (q C, s C, 1/1/11) and differs from frozen oracle", ev3)
  oe <- newenv(); if (ev1) score(oe, r, o, oracle_exp("ordered_shortlist_capacity_2"), mut_man$input$path, 2)
  fails <- vapply(Filter(function(x) x$result == "FAIL", oe$checks), function(x) x$check, "")
  thr <- c("qualified.csv ids in exact order", "selected.csv ids in exact order", "summary.qualified_count", "summary.selected_count", "summary.selected_amount_sum (tolerance 0)", "qualified amounts exact")
  ck(e, "MR-10 evidence 4: harness rejects mutant vs oracle, specifically for threshold-related discrepancies", ev1 && length(fails) > 0 && all(fails %in% thr) && all(thr[1:3] %in% fails), paste("failed:", fmt(fails)))
  ck(e, "MR-10 evidence 5: detection not from invocation/parse error or missing output", ev1 && !any(grepl("exit status|artifacts present", fails)))
  tests[[length(tests) + 1L]] <- test_report(paste0("metamorphic:MR-10:", b), e, list(runs = list(r), mutant = mm, oracle_rejection_checks = oe$checks))
}
# replay: each builder reruns its locked canonical command in a fresh Rscript --vanilla process into an empty separate root; byte-compare the four deterministic outputs with its own originals
e <- newenv(); outs <- list(); rexit <- 0L
for (b in names(SCRIPT)) {
  r <- run_builder(SCRIPT[[b]], CANON, cfg$canonical_capacity, file.path(W, "replay", TAG[[b]])); if (!identical(r$exit, 0L)) rexit <- r$exit
  for (f in ART[1:4]) { o <- file.path(OUTDIR[[b]], f); p <- file.path(r$out, f)
    ok <- file.exists(o) && file.exists(p) && identical(sha(o), sha(p)); ck(e, paste("replay", b, f, "byte-identical"), ok)
    if (file.exists(o) && file.exists(p)) outs[[length(outs) + 1L]] <- list(original = ref(o), replayed = ref(p)) }
  e$runs[[b]] <- r
}
tests[[length(tests) + 1L]] <- test_report("replay", e, list(clean_session = TRUE, exit_status = rexit, outputs = outs, runs = e$runs, clean_session_definition = "new Rscript --vanilla child process per builder, empty separate output root"))
# components unchanged during the run
e1 <- newenv(); ck(e1, "components unchanged during harness run", identical(comp, lapply(cfg$validation_components, function(v) lapply(unlist(v), ref))))
st <- if (result_of(e0) == "PASS" && result_of(e1) == "PASS" && all(vapply(tests, function(x) x$result == "PASS", TRUE))) "PASS" else "FAIL"
rep <- list(run_id = cfg$run_id, attempt = ATT, harness_work = W, design_version = cfg$design_version, recorded_at_utc = now(), status = st,
  harness_checks = list(list(id = "CP-00", result = result_of(e0)), list(id = "CP-08", result = if (all(vapply(Filter(function(x) grepl("^metamorphic:", x$id) && !grepl("MR-10", x$id), tests), function(x) x$result == "PASS", TRUE))) "PASS" else "FAIL"),
    list(id = "CP-09", result = if (all(vapply(Filter(function(x) grepl("MR-10", x$id), tests), function(x) x$result == "PASS", TRUE))) "PASS" else "FAIL")),
  preflight_checks = e0$checks, end_checks = e1$checks, tests = tests, components = comp)
wj(rep, opt$out); cat(st, "\n"); for (x in tests) cat(x$result, x$id, "\n")
quit(save = "no", status = if (st == "PASS") 0L else 1L)
