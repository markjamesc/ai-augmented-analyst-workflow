#!/usr/bin/env Rscript
# validation/structural_review_v2.R -- ACC-SMALL-REMEDIATION-002, Stage 4 rerun (R1).
# AUTHOR: coordinator (GrokBot), owner approval 2026-10-30 11:30 CT (fix c). Disclosure X-C01.
# Supersedes validation/structural_review.R (kept unchanged as historical evidence).
# Same tokenizer, window (W=20), judged-call list and controls as P4-r2. CHANGED DECISION:
#  * shared judged fragments are SIMILARITY FLAGS for review, never a FAIL by themselves;
#  * FAIL only if a reviewer finding is CONFIRMED_SHARING or CORRECTNESS_DEFECT (unresolved);
#  * every flag needs a disposition in outputs/verification/structural_dispositions.json,
#    each citing a hashed reviewer transcript; undisposed flags => NEEDS_REVIEW (not PASS).
# Usage: Rscript --vanilla validation/structural_review_v2.R <ROOT>
# Exit 0 PASS, 1 FAIL, 2 setup error, 3 NEEDS_REVIEW.
suppressPackageStartupMessages({ library(jsonlite); library(digest) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) { cat("Usage: Rscript validation/structural_review.R <ROOT>\n"); quit(status = 2L) }
root <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
P <- function(...) file.path(root, ...)
sha <- function(p) if (file.exists(p)) digest(file = p, algo = "sha256") else NA_character_
now_utc <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
out_dir <- P("outputs", "verification"); dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "structural.json")
if (file.exists(out_file)) { cat("SETUP ERROR: outputs/verification/structural.json exists (move it aside)\n"); quit(status = 2L) }
run_dir <- file.path(out_dir, "runs", paste0("structural_", format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")))
dir.create(run_dir, recursive = TRUE)
design <- fromJSON(P("artifacts", "stage3_locked_design.json"), simplifyVector = FALSE)

W <- 20L
COMPARISON <- c("GT", "GE", "LT", "LE", "EQ", "NE")
JUDGED_CALLS <- c("order", "sort", "rank", "rev", "head", "tail", "sum", "cumsum", "max", "min", "which.max",
                  "which.min", "aggregate", "tapply", "table", "duplicated", "anyDuplicated", "unique",
                  "strsplit", "regmatches", "gsub", "sub", "grepl", "grep", "regexpr", "gregexpr",
                  "is.finite", "is.na")
# Revision P4-r2 (S4-a1P1-rev finding 4): generic I/O calls (scan, read.csv, read.table, readLines,
# readBin) were removed from JUDGED_CALLS; a fragment is now judged only by a comparison operator
# or an ordering / aggregation / token-parsing / validity call. The rule is a stated-in-advance
# heuristic (finding 5); its limits are disclosed in structural.json.
RENAME <- c("SYMBOL", "SYMBOL_FORMALS", "SYMBOL_SUB")

tokens_of <- function(path) {
  pd <- getParseData(parse(path, keep.source = TRUE), includeText = TRUE)
  pd <- pd[pd$terminal & pd$token != "COMMENT", ]
  pd <- pd[order(pd$line1, pd$col1), ]
  norm <- ifelse(pd$token %in% RENAME, "v", pd$text)
  judged <- pd$token %in% COMPARISON | (pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% JUDGED_CALLS)
  list(norm = norm, judged = judged, line = pd$line1)
}
fragments <- function(tk) {
  n <- length(tk$norm)
  if (n < W) return(data.frame(key = character(0), from = integer(0), to = integer(0)))
  st <- seq_len(n - W + 1L)
  keep <- vapply(st, function(i) any(tk$judged[i:(i + W - 1L)]), logical(1))
  st <- st[keep]
  data.frame(key = vapply(st, function(i) paste(tk$norm[i:(i + W - 1L)], collapse = " "), character(1)),
             from = tk$line[st], to = tk$line[st + W - 1L], stringsAsFactors = FALSE)
}
shared_report <- function(pa, pb) {
  fa <- fragments(tokens_of(pa)); fb <- fragments(tokens_of(pb))
  common <- intersect(fa$key, fb$key)
  list(n_fragments_a = nrow(fa), n_fragments_b = nrow(fb), n_shared = length(common),
       shared = lapply(head(common, 50), function(k) list(tokens = k,
         lines_a = unique(paste(fa$from[fa$key == k], fa$to[fa$key == k], sep = "-")),
         lines_b = unique(paste(fb$from[fb$key == k], fb$to[fb$key == k], sep = "-")))))
}

checks <- list()
add <- function(name, ok, detail) checks[[length(checks) + 1L]] <<- list(check = name, result = if (isTRUE(ok)) "PASS" else "FAIL", detail = detail)
ra <- P("analysis", "r_a", "main.R"); rb <- P("analysis", "r_b", "main.R")
add("R-A builder present", file.exists(ra), "analysis/r_a/main.R")
add("R-B builder present", file.exists(rb), "analysis/r_b/main.R")
main <- if (file.exists(ra) && file.exists(rb)) tryCatch(shared_report(ra, rb), error = function(e) list(error = conditionMessage(e))) else list(error = "builder missing")
add("builders parse", is.null(main$error), if (is.null(main$error)) "both parsed" else main$error)
flag_keys <- if (is.null(main$error)) vapply(main$shared, function(x) digest(x$tokens, algo = "sha256", serialize = FALSE), character(1)) else character(0)
if (is.null(main$error) && main$n_shared > length(main$shared)) {
  # report keeps 50; disposition must cover all, so recompute full key set
  fa <- fragments(tokens_of(ra)); fb <- fragments(tokens_of(rb))
  flag_keys <- vapply(intersect(fa$key, fb$key), digest, character(1), algo = "sha256", serialize = FALSE)
}
disp_path <- P("outputs", "verification", "structural_dispositions.json")
disp <- if (file.exists(disp_path)) tryCatch(fromJSON(disp_path, simplifyVector = FALSE), error = function(e) NULL) else NULL
CLASSES <- c("FLAG_ONLY", "CONFIRMED_SHARING", "CORRECTNESS_DEFECT")
ref_ok <- function(r) is.list(r) && is.character(r$path) && is.character(r$sha256) &&
  !grepl("^(/|[A-Za-z]:|\\\\)", r$path) && !grepl("(^|/)\\.\\.(/|$)", r$path) &&
  identical(tolower(r$sha256), sha(P(r$path)))
items <- if (is.list(disp)) c(disp$flags, disp$findings) else list()
items_ok <- all(vapply(items, function(f) is.list(f) && isTRUE(f$class %in% CLASSES) &&
  is.character(f$reviewer) && nzchar(f$reviewer) && is.character(f$rationale) && nzchar(f$rationale) &&
  length(f$evidence) > 0 && all(vapply(f$evidence, ref_ok, logical(1))), logical(1)))
disp_bound <- is.list(disp) && identical(disp$r_a_sha256, sha(ra)) && identical(disp$r_b_sha256, sha(rb))
disposed <- if (is.list(disp)) vapply(disp$flags, function(f) as.character(f$flag_key %||% ""), character(1)) else character(0)
undisposed <- setdiff(flag_keys, disposed)
blocking <- Filter(function(f) isTRUE(f$class %in% c("CONFIRMED_SHARING", "CORRECTNESS_DEFECT")) &&
  !identical(f$resolved, TRUE), items)
need_disp <- file.exists(disp_path)
add("dispositions well formed and bound to these builders", !need_disp || (disp_bound && items_ok),
    "class in FLAG_ONLY/CONFIRMED_SHARING/CORRECTNESS_DEFECT, reviewer, rationale, hashed evidence")
add("no confirmed code sharing or correctness defect", length(blocking) == 0L,
    paste("blocking findings:", length(blocking)))

# Control (a): planted shared judged function, variables renamed in the second copy.
judged_a <- c("pick <- function(ids, amounts, ok) {", "  q <- ok & !is.na(amounts) & amounts >= 10",
  "  r <- which(q)", "  r <- r[order(-amounts[r], ids[r], method = \"radix\")]", "  s <- head(r, 2L)",
  "  list(ids = ids[s], total = sum(amounts[s]))", "}")
judged_b <- gsub("\\bids\\b", "key", gsub("\\bamounts\\b", "amt", gsub("\\bq\\b", "keep", judged_a)))
idioms <- c("args <- commandArgs(trailingOnly = TRUE)", "con <- file(path, open = \"wb\")",
  "on.exit(close(con), add = TRUE)", "fields <- character(0)", "x <- as.character(x)",
  "lines <- readLines(path, warn = FALSE, encoding = \"UTF-8\")",
  "raw <- readBin(path, what = \"raw\", n = file.info(path)$size)",
  "if (!dir.exists(output_dir)) {", "  dir.create(output_dir, recursive = TRUE)", "} else {", "  fields <- list(", "  )", "}")
own_a <- c("f1 <- function(x) {", "  y <- x[x > 3]", "  y[order(y)]", "}")
own_b <- c("g2 <- function(z) {", "  w <- sort(z, decreasing = TRUE)", "  w[w <= 7]", "}")
wr <- function(lines, name) { p <- file.path(run_dir, name); writeLines(lines, p); p }
ca <- shared_report(wr(c(idioms, own_a, judged_a), "control_planted_a.R"), wr(c(own_b, judged_b, idioms), "control_planted_b.R"))
add("control: planted shared judged function is flagged", ca$n_shared > 0L, paste("shared:", ca$n_shared))
cb <- shared_report(wr(c(idioms, own_a), "control_idiom_a.R"), wr(c(idioms, own_b), "control_idiom_b.R"))
add("control: shared generic idioms only are not flagged", cb$n_shared == 0L, paste("shared:", cb$n_shared))

status <- if (!all(vapply(checks, function(x) x$result == "PASS", logical(1)))) "FAIL" else if (length(undisposed) > 0L) "NEEDS_REVIEW" else "PASS"
write_json(list(status = status, design_version = design$design_version, fixture_version = design$fixture_version,
  checked_at_utc = now_utc(), scope = "mechanical shared-judged-logic evidence only; the three AI structural reviews are separate",
  rule = list(window_tokens = W, comparison_tokens = COMPARISON, judged_calls = JUDGED_CALLS,
              renamed_token_types = RENAME, decision = "shared judged fragments are review flags; FAIL only on confirmed code sharing or correctness defect; undisposed flags = NEEDS_REVIEW",
              limitation = "Heuristic stated in advance: W-token windows judged by comparison or listed calls; generic I/O calls are not judged; a shared fragment is evidence for review, not proof of copying, and absence of shared fragments is not proof of independence."),
  inputs = list(list(path = "analysis/r_a/main.R", sha256 = sha(ra)), list(path = "analysis/r_b/main.R", sha256 = sha(rb)),
                list(path = "validation/structural_review_v2.R", sha256 = sha(P("validation", "structural_review_v2.R")))),
  # Owner card t1637s6856 (2026-10-31): an absent dispositions file is recorded as not present, never as a path with a null
  # sha256 (the gate counts any path+sha256 pair as a reference, and a null hash can never verify).
  dispositions_present = file.exists(disp_path),
  dispositions = if (file.exists(disp_path)) list(path = "outputs/verification/structural_dispositions.json", sha256 = sha(disp_path)),
  builders = main, controls = list(planted = ca[c("n_shared")], idiom_only = cb[c("n_shared")],
                                   dir = sub(paste0(root, "/"), "", run_dir, fixed = TRUE)),
  similarity_flags = list(n = length(flag_keys), keys = as.list(flag_keys), undisposed = as.list(undisposed)),
  blocking_findings = blocking, checks = checks), out_file, pretty = TRUE, auto_unbox = TRUE, null = "null", digits = NA)
cat("structural_review:", status, "\n")
quit(status = switch(status, PASS = 0L, NEEDS_REVIEW = 3L, 1L))
