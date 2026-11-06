#!/usr/bin/env Rscript
# validation/run_fixtures.R -- Stage 4 fixture/oracle runner (harness overlay; code-independent planted defects).
# AUTHOR: coordinator (GrokBot), under owner decision P1 (2026-10-24): written after the
# AI2 helper rounds S4-a1/R1/R2/R3 did not produce an acceptable file. Disclosed deviation;
# must pass a fresh-DeepSeek review before its outputs are used as evidence.
# Revision P4-r2 (owner P4, one coordinator fix round after review S4-a1P1-rev; disclosed cap
# breach D-267): (1) poison probes add a rewrite-only control per poisoned file; (2) manifest and
# oracle bytes are checked against the lock pins fixture_inputs / fixture_expected; (3) an absent
# oracle fixture or checkpoint is an error, never an empty table; (10) Rscript.exe on Windows.
# Non-judged harness. Expected values come only from validation/fixtures/oracle.json.
# Usage: Rscript --vanilla validation/run_fixtures.R <ROOT>
# Writes only under <ROOT>/outputs/verification/. Never overwrites: stops if a fixed
# output already exists (move it aside first). Exit 0 = PASS, 1 = FAIL, 2 = setup error.
#
# Comparison scalar (ruling B3): lowercase SHA-256 of a framed canonical K0-K4 projection.
#   For k in K0..K4 (locked order): line "<id>\t<n_rows>\t<fields joined by ,>", then one
#   line per row, rows ordered by the locked keys (radix, C-locale bytes), each row the
#   compact JSON array of its field values in locked field order (keys, exact, numeric).
#   Exact fields: byte text as written (arrays as compact JSON text, null as "null").
#   Numeric fields: literal "NA" kept; otherwise parsed to binary64 and written with
#   sprintf("%.17g") so equal doubles give equal text (tolerance 0, Part A section 22).
#   A table that cannot be projected yields a sentinel "ERROR:<reason>" instead of a digest.

suppressPackageStartupMessages({ library(jsonlite); library(digest) })
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) { cat("Usage: Rscript validation/run_fixtures.R <ROOT>\n"); quit(status = 2L) }
root <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
P <- function(...) file.path(root, ...)
rel <- function(p) ifelse(startsWith(p, paste0(root, "/")), substring(p, nchar(root) + 2L), p)
sha <- function(p) if (file.exists(p)) digest(file = p, algo = "sha256") else NA_character_
now_utc <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
wj <- function(x, p) write_json(x, p, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "string", digits = NA)

out_dir <- P("outputs", "verification")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
fixed_outputs <- file.path(out_dir, c("fixture_results.csv", "metamorphic_results.csv", "smoke.json",
  "fixture_depth.json", "poison.json", "planted_defects.json", "wrong_oracle_crosscheck.json", "numeric_selftest.json",
  paste0("sensitivity_", c("S-ORDER", "S-BOUNDARY", "S-MISSING", "S-CAPACITY"), ".json"),
  "run_fixtures_status.json"))
if (any(file.exists(fixed_outputs))) {
  cat("SETUP ERROR: existing outputs (move them aside, nothing is overwritten):\n",
      paste(rel(fixed_outputs[file.exists(fixed_outputs)]), collapse = "\n"), "\n")
  quit(status = 2L)
}
stamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
run_root <- file.path(out_dir, "runs", paste0("run_fixtures_", stamp))
if (dir.exists(run_root)) { cat("SETUP ERROR: run dir exists\n"); quit(status = 2L) }
dir.create(run_root, recursive = TRUE)
rep_dir <- file.path(run_root, "reports"); dir.create(rep_dir)

design <- fromJSON(P("artifacts", "stage3_locked_design.json"), simplifyVector = FALSE)
oracle <- fromJSON(P("validation", "fixtures", "oracle.json"), simplifyVector = FALSE)$fixtures
manifest <- fromJSON(P("validation", "fixtures", "manifest.json"), simplifyVector = FALSE)
cps <- design$methodology$checkpoints
fixture_ids <- unlist(design$fixture_ids)
cp_files <- c(K0 = "audit_rows.csv", K1 = "reason_totals.csv", K2 = "rank_rows.csv",
              K3 = "totals.csv", K4 = "build_report.csv")
cp_ids <- vapply(cps, function(x) x$id, character(1))
if (!identical(cp_ids, names(cp_files))) { cat("SETUP ERROR: locked checkpoints are not K0-K4\n"); quit(status = 2L) }
fields_of <- function(cp) unique(c(unlist(cp$keys), unlist(cp$exact_fields), unlist(cp$numeric_fields)))
rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
# Lock pins (finding 2): manifest and oracle must be byte-identical to the locked hashes.
op <- design$methodology$operational
lock_pins <- lapply(list(fixture_inputs = op$fixture_inputs, fixture_expected = op$fixture_expected), function(x)
  list(path = x$path, locked_sha256 = x$sha256, actual_sha256 = sha(P(x$path)),
       match = !is.null(x$sha256) && identical(x$sha256, sha(P(x$path)))))
lock_pins_ok <- identical(lock_pins$fixture_inputs$path, "validation/fixtures/manifest.json") &&
  identical(lock_pins$fixture_expected$path, "validation/fixtures/oracle.json") &&
  all(vapply(lock_pins, function(x) isTRUE(x$match), logical(1)))
# Oracle completeness (finding 3): every locked fixture and every locked checkpoint must be present.
oracle_absent <- unlist(lapply(fixture_ids, function(fid) {
  if (is.null(oracle[[fid]])) return(paste0(fid, ":ALL"))
  ab <- cp_ids[vapply(cp_ids, function(k) !(k %in% names(oracle[[fid]])), logical(1))]
  if (length(ab)) paste0(fid, ":", ab) else character(0)
}))
oracle_complete <- length(oracle_absent) == 0L
builders <- c("R-A" = "analysis/r_a/main.R", "R-B" = "analysis/r_b/main.R")

# ---------- numeric canonical form and self-test ----------
canon_num <- function(x) vapply(x, function(s) {
  if (identical(s, "NA")) return("NA")
  v <- suppressWarnings(as.numeric(s))
  if (is.na(v) || !is.finite(v)) return(paste0("UNPARSEABLE:", s))
  sprintf("%.17g", v)
}, character(1), USE.NAMES = FALSE)
selftest <- list(
  same_double_different_text = identical(canon_num("10.0"), canon_num("1e1")),
  adjacent_doubles_differ = !identical(canon_num("10"), canon_num("10.000000000000002")),
  below_ten_differs = !identical(canon_num("9.999999999999998"), canon_num("10")),
  na_kept_distinct_from_zero = !identical(canon_num("NA"), canon_num("0")))
selftest_ok <- all(unlist(selftest))
wj(c(selftest, list(status = if (selftest_ok) "PASS" else "FAIL")), file.path(out_dir, "numeric_selftest.json"))

# ---------- table readers ----------
read_out_table <- function(path) {
  if (!file.exists(path)) return("ERROR:MISSING_FILE")
  tryCatch(read.csv(path, colClasses = "character", check.names = FALSE, na.strings = character(),
                    stringsAsFactors = FALSE, encoding = "UTF-8"),
           error = function(e) "ERROR:UNREADABLE")
}
arr_text <- function(v) {
  if (is.null(v)) return("null")
  if (is.list(v)) { if (length(v) == 0L) return("[]"); v <- unlist(v) }
  if (length(v) == 0L) return("[]")
  as.character(toJSON(as.character(v), auto_unbox = FALSE))
}
oracle_table <- function(rows, cp) {
  f <- fields_of(cp)
  if (is.null(rows)) return("ERROR:ORACLE_ENTRY_ABSENT")   # absent is an error; [] is a legitimate empty table
  if (length(rows) == 0L) {
    df <- as.data.frame(setNames(replicate(length(f), character(0), simplify = FALSE), f), stringsAsFactors = FALSE)
    return(df)
  }
  cols <- lapply(f, function(nm) vapply(rows, function(r) {
    if (!(nm %in% names(r))) return("ERROR_FIELD_ABSENT_IN_ORACLE")
    v <- r[[nm]]
    if (is.null(v) || is.list(v) || length(v) != 1L) arr_text(v) else as.character(v)
  }, character(1)))
  as.data.frame(setNames(cols, f), stringsAsFactors = FALSE, check.names = FALSE)
}
canon_table <- function(df, cp) {
  if (is.character(df)) return(df)                      # already an error sentinel
  f <- fields_of(cp)
  if (!identical(names(df), f)) return(paste0("ERROR:HEADER(", paste(names(df), collapse = ","), ")"))
  keys <- unlist(cp$keys)
  if (nrow(df) && anyDuplicated(do.call(paste, c(df[keys], sep = "\r")))) return("ERROR:DUPLICATE_KEYS")
  for (nm in unlist(cp$numeric_fields)) df[[nm]] <- canon_num(df[[nm]])
  if (nrow(df)) df <- df[do.call(order, c(unname(as.list(df[keys])), list(method = "radix"))), , drop = FALSE]
  c(paste(cp$id, nrow(df), paste(f, collapse = ","), sep = "\t"),
    if (nrow(df)) vapply(seq_len(nrow(df)), function(i) as.character(toJSON(unname(unlist(df[i, f, drop = TRUE])))), character(1)) else character(0))
}
case_digest <- function(canon_list) {
  errs <- Filter(function(x) length(x) == 1L && startsWith(x, "ERROR:"), canon_list)
  if (length(errs)) return(paste0("ERROR:", paste(names(errs), sub("^ERROR:", "", unlist(errs)), sep = "=", collapse = ";")))
  digest(paste0(paste(unlist(canon_list), collapse = "\n"), "\n"), algo = "sha256", serialize = FALSE)
}
expected_canon <- function(fid) setNames(lapply(cps, function(cp) canon_table(oracle_table(oracle[[fid]][[cp$id]], cp), cp)), cp_ids)
observed_canon <- function(dir) setNames(lapply(cps, function(cp) canon_table(read_out_table(file.path(dir, cp_files[[cp$id]])), cp)), cp_ids)
diff_canon <- function(e, o) {
  out <- list()
  for (k in cp_ids) if (!identical(e[[k]], o[[k]])) out[[k]] <- list(
    expected_only = head(setdiff(e[[k]], o[[k]]), 20), observed_only = head(setdiff(o[[k]], e[[k]]), 20))
  out
}

# ---------- builder runner ----------
run_builder <- function(script_rel, input, od) {
  dir.create(od, recursive = TRUE, showWarnings = FALSE)
  script <- P(script_rel)
  if (!file.exists(script)) return(list(exit = 127L, console = "builder script missing", command = NA_character_))
  a <- c("--vanilla", shQuote(script), shQuote(input), shQuote(od))
  con <- suppressWarnings(system2(rscript, a, stdout = TRUE, stderr = TRUE, timeout = 300))
  ex <- attr(con, "status"); if (is.null(ex)) ex <- 0L
  writeLines(con, file.path(od, "_console.txt"))
  list(exit = as.integer(ex), console = con, command = paste(c("Rscript", a), collapse = " "))
}
score_dir <- function(fid, run) {
  if (run$exit != 0L) return(list(digest = paste0("ERROR:EXIT_", run$exit), canon = NULL))
  oc <- observed_canon(run$dir)
  list(digest = case_digest(oc), canon = oc)
}

overall <- list()           # named logical: component -> passed
builder_sha <- vapply(builders, function(b) sha(P(b)), character(1))

# ---------- 1. fixture integrity ----------
mf <- manifest$fixtures
integrity <- lapply(mf, function(x) list(id = x$id, path = x$path, manifest_sha256 = x$sha256,
                                          actual_sha256 = sha(P(x$path))))
integrity_ok <- setequal(vapply(mf, function(x) x$id, character(1)), fixture_ids) &&
  all(vapply(integrity, function(x) identical(x$manifest_sha256, x$actual_sha256), logical(1)))
overall$fixture_integrity <- integrity_ok
overall$lock_pins <- lock_pins_ok
overall$oracle_complete <- oracle_complete
fx_path <- function(fid) P("validation", "fixtures", paste0(fid, ".csv"))

# ---------- 2. fixture scorecard (B3) ----------
exp_canon <- setNames(lapply(fixture_ids, expected_canon), fixture_ids)
exp_digest <- vapply(exp_canon, case_digest, character(1))
fx_rows <- list(); fx_obs <- list()
for (fid in fixture_ids) {
  obs <- list()
  for (pth in names(builders)) {
    od <- file.path(run_root, "fixtures", fid, pth)
    r <- run_builder(builders[[pth]], fx_path(fid), od); r$dir <- od
    s <- score_dir(fid, r)
    obs[[pth]] <- list(run = r, score = s,
                       diff = if (is.null(s$canon)) "no comparable output" else diff_canon(exp_canon[[fid]], s$canon))
  }
  fx_obs[[fid]] <- obs
  rp <- file.path(rep_dir, paste0("fixture_", fid, ".json"))
  wj(list(id = fid, fixture = list(path = rel(fx_path(fid)), sha256 = sha(fx_path(fid))),
          expected = exp_digest[[fid]],
          paths = lapply(obs, function(o) list(command = o$run$command, exit = o$run$exit,
                         observed = o$score$digest, match = identical(o$score$digest, exp_digest[[fid]]),
                         differences = o$diff))), rp)
  fx_rows[[fid]] <- data.frame(id = fid, expected = exp_digest[[fid]],
    observed_a = obs[["R-A"]]$score$digest, observed_b = obs[["R-B"]]$score$digest,
    exit_a = obs[["R-A"]]$run$exit, exit_b = obs[["R-B"]]$run$exit,
    match_a = identical(obs[["R-A"]]$score$digest, exp_digest[[fid]]),
    match_b = identical(obs[["R-B"]]$score$digest, exp_digest[[fid]]),
    report_path = rel(rp), report_sha256 = sha(rp), recorded_at_utc = now_utc(), stringsAsFactors = FALSE)
}
fx_df <- do.call(rbind, fx_rows); rownames(fx_df) <- NULL
overall$fixtures <- all(fx_df$match_a) && all(fx_df$match_b) && nrow(fx_df) == length(fixture_ids)

# ---------- 3. metamorphic relations (B4) ----------
# Frozen fixture pairs: Part A section 24 (MR1 F00->F01, MR2 F00->F09, MR3 F02->F12,
# MR4 F00->F11, MR5 F08->F13, MR6 F00->F10, MR7 F00->F01, MR8 F14->F06).
mr_pairs <- list(MR1 = c("F00", "F01"), MR2 = c("F00", "F09"), MR3 = c("F02", "F12"), MR4 = c("F00", "F11"),
                 MR5 = c("F08", "F13"), MR6 = c("F00", "F10"), MR7 = c("F00", "F01"), MR8 = c("F14", "F06"))
mr_lock <- setNames(design$methodology$metamorphic, vapply(design$methodology$metamorphic, function(x) x$id, character(1)))
src_lines <- function(fid) readLines(fx_path(fid), warn = FALSE)
tab <- function(dir, k) read_out_table(file.path(dir, cp_files[[k]]))
k4 <- function(dir) { t <- tab(dir, "K4"); if (is.character(t) || nrow(t) != 1L) NULL else as.list(t[1, ]) }
row_of <- function(df, id) if (is.character(df)) NULL else { r <- df[df$id == id, , drop = FALSE]; if (nrow(r) == 1L) as.list(r) else NULL }
ids_of <- function(txt) if (is.null(txt) || identical(txt, "null")) NULL else tryCatch(as.character(unlist(fromJSON(txt))), error = function(e) NA)
numeq <- function(a, b) !is.null(a) && !is.null(b) && identical(canon_num(a), canon_num(b))
same_tables <- function(db, dt, ks, drop = character()) all(vapply(ks, function(k) {
  cb <- canon_table(tab(db, k), cps[[match(k, cp_ids)]]); ct <- canon_table(tab(dt, k), cps[[match(k, cp_ids)]])
  if (length(drop)) { cb <- gsub(paste(drop, collapse = "|"), "<dropped>", cb); ct <- gsub(paste(drop, collapse = "|"), "<dropped>", ct) }
  identical(cb, ct) && !any(startsWith(cb, "ERROR:"))
}, logical(1)))
chk <- function(name, ok) list(check = name, result = if (isTRUE(ok)) "PASS" else "FAIL")

mr_eval <- function(mid, db, dt, b, t) {
  bl <- src_lines(b); tl <- src_lines(t)
  kb <- k4(db); kt <- k4(dt)
  ev <- !is.null(kb) && !is.null(kt)
  digests <- if (ev) c(kb$source_digest, kt$source_digest) else c(NA, NA)
  pre <- list(chk("transformed input differs from baseline", !identical(sha(fx_path(b)), sha(fx_path(t)))))
  rel <- list()
  if (mid == "MR1") {
    pre <- c(pre, list(chk("same header; data rows are a permutation", identical(bl[1], tl[1]) && identical(sort(bl[-1]), sort(tl[-1])) && !identical(bl, tl))))
    rel <- list(chk("K0-K3 keyed tables identical", same_tables(db, dt, c("K0", "K1", "K2", "K3"))),
                chk("K4 identical except source_digest", ev && same_tables(db, dt, "K4", drop = digests)),
                chk("source_digest differs (bytes differ)", ev && !identical(kb$source_digest, kt$source_digest)))
  } else if (mid == "MR2") {
    hb <- strsplit(bl[1], ",")[[1]]; ht <- strsplit(tl[1], ",")[[1]]
    proj <- vapply(strsplit(tl, ",", fixed = TRUE), function(x) paste(x[match(hb, ht)], collapse = ","), character(1))
    pre <- c(pre, list(chk("transformed header = baseline header plus extra field(s)", identical(ht[seq_along(hb)], hb) && length(ht) > length(hb)),
                       chk("three-column projection of transformed equals baseline", identical(proj, bl))))
    rel <- list(chk("K0-K3 identical", same_tables(db, dt, c("K0", "K1", "K2", "K3"))),
                chk("K4 identical except source_digest", ev && same_tables(db, dt, "K4", drop = digests)))
  } else if (mid == "MR3") {
    pre <- c(pre, list(chk("baseline L,9.999999999999998,true -> transformed L,10,true; other rows unchanged",
      "L,9.999999999999998,true" %in% bl && "L,10,true" %in% tl && identical(setdiff(bl, "L,9.999999999999998,true"), setdiff(tl, "L,10,true")))))
    lb <- row_of(tab(db, "K0"), "L"); lt <- row_of(tab(dt, "K0"), "L")
    tb2 <- row_of(tab(db, "K2"), "T"); tt2 <- row_of(tab(dt, "K2"), "T"); lt2 <- row_of(tab(dt, "K2"), "L")
    k3b <- tab(db, "K3"); k3t <- tab(dt, "K3")
    rel <- list(chk("L reason BELOW_THRESHOLD -> QUALIFIED", identical(lb$reason_code, "BELOW_THRESHOLD") && identical(lt$reason_code, "QUALIFIED")),
                chk("L ranks second", !is.null(lt2) && numeq(lt2$rank_n, "2")),
                chk("T displaced: SELECTED -> not selected", identical(tb2$place_state, "SELECTED") && !is.null(tt2) && !identical(tt2$place_state, "SELECTED")),
                chk("qualified count 2 -> 3", !is.character(k3b) && !is.character(k3t) && numeq(k3b$qualified_n, "2") && numeq(k3t$qualified_n, "3")),
                chk("selected sum remains 20", !is.character(k3b) && !is.character(k3t) && numeq(k3b$selected_sum, "20") && numeq(k3t$selected_sum, "20")))
  } else if (mid == "MR4") {
    pre <- c(pre, list(chk("baseline D,20,false -> transformed D,50,false; other rows unchanged",
      "D,20,false" %in% bl && "D,50,false" %in% tl && identical(setdiff(bl, "D,20,false"), setdiff(tl, "D,50,false")))))
    db0 <- row_of(tab(db, "K0"), "D"); dt0 <- row_of(tab(dt, "K0"), "D")
    rel <- list(chk("qualified_ids, selected_ids, counts and selected_sum unchanged", ev &&
                      identical(kb$qualified_ids, kt$qualified_ids) && identical(kb$selected_ids, kt$selected_ids) &&
                      numeq(kb$qualified_n, kt$qualified_n) && numeq(kb$selected_n, kt$selected_n) && numeq(kb$selected_sum, kt$selected_sum)),
                chk("K0 D amount differs (20 -> 50)", numeq(db0$amount_value, "20") && numeq(dt0$amount_value, "50")),
                chk("source_digest differs", ev && !identical(kb$source_digest, kt$source_digest)))
  } else if (mid == "MR5") {
    pre <- c(pre, list(chk("baseline A blank -> transformed A,0; other rows unchanged",
      "A,,true" %in% bl && "A,0,true" %in% tl && identical(setdiff(bl, "A,,true"), setdiff(tl, "A,0,true")))))
    ab <- row_of(tab(db, "K0"), "A"); at <- row_of(tab(dt, "K0"), "A")
    rel <- list(chk("K0 A MISSING/AMOUNT_MISSING -> PRESENT/BELOW_THRESHOLD",
                    identical(ab$amount_state, "MISSING") && identical(ab$reason_code, "AMOUNT_MISSING") &&
                    identical(at$amount_state, "PRESENT") && identical(at$reason_code, "BELOW_THRESHOLD")),
                chk("selection, counts and sum unchanged", ev && identical(kb$qualified_ids, kt$qualified_ids) &&
                    identical(kb$selected_ids, kt$selected_ids) && numeq(kb$qualified_n, kt$qualified_n) &&
                    numeq(kb$selected_n, kt$selected_n) && numeq(kb$selected_sum, kt$selected_sum)))
  } else if (mid == "MR6") {
    added <- setdiff(tl, bl); new_id <- if (length(added) == 1L) strsplit(added, ",")[[1]][1] else NA
    sb <- if (ev) ids_of(kb$selected_ids) else NULL; st <- if (ev) ids_of(kt$selected_ids) else NULL
    pre <- c(pre, list(chk("transformed = baseline plus one row with a new unique ID", length(added) == 1L && all(bl %in% tl) &&
                             !(new_id %in% vapply(strsplit(bl[-1], ","), `[`, character(1), 1))),
                       chk("baseline has at least two qualifying records", ev && isTRUE(suppressWarnings(as.numeric(kb$qualified_n)) >= 2))))
    rel <- list(chk("count stays two", ev && numeq(kb$selected_n, "2") && numeq(kt$selected_n, "2")),
                chk("new record ranks first", length(st) == 2L && identical(st[1], new_id)),
                chk("previous first moves to second; previous second displaced", length(sb) == 2L && length(st) == 2L &&
                      identical(st[2], sb[1]) && !(sb[2] %in% st)))
  } else if (mid == "MR7") {
    k2b <- tab(db, "K2"); k2t <- tab(dt, "K2")
    tied <- if (is.character(k2b)) character(0) else { a <- canon_num(k2b$amount_value); k2b$id[a %in% a[duplicated(a)]] }
    pos <- function(lines, ids) match(ids, vapply(strsplit(lines[-1], ","), `[`, character(1), 1))
    pre <- c(pre, list(chk("baseline has equal-amount qualifying IDs", length(tied) >= 2L),
                       chk("tied candidates' input positions reordered", length(tied) >= 2L &&
                             !identical(order(pos(bl, tied)), order(pos(tl, tied))))))
    rank_of <- function(k2, ids) if (is.character(k2)) NULL else canon_num(k2$rank_n[match(ids, k2$id)])
    rel <- list(chk("tied IDs ranked in ASCII ID order in both runs", length(tied) >= 2L &&
                      { s <- sort(tied, method = "radix"); rb <- as.numeric(rank_of(k2b, s)); rt <- as.numeric(rank_of(k2t, s))
                        !anyNA(rb) && !anyNA(rt) && !is.unsorted(rb, strictly = TRUE) && !is.unsorted(rt, strictly = TRUE) }),
                chk("tied IDs' ranks unchanged", length(tied) >= 2L && identical(rank_of(k2b, tied), rank_of(k2t, tied))))
  } else if (mid == "MR8") {
    pre <- c(pre, list(chk("second data row ID B -> A; all else unchanged", length(bl) == length(tl) && length(bl) >= 3L &&
      startsWith(bl[3], "B,") && identical(tl[3], sub("^B,", "A,", bl[3])) && identical(bl[-3], tl[-3]))))
    empt <- all(vapply(c("K0", "K1", "K2", "K3"), function(k) { x <- tab(dt, k); !is.character(x) && nrow(x) == 0L }, logical(1)))
    rel <- list(chk("baseline EVALUATED, selected B,A, sum 21", ev && identical(kb$build_state, "EVALUATED") &&
                      identical(ids_of(kb$selected_ids), c("B", "A")) && numeq(kb$selected_sum, "21")),
                chk("transformed INVALID_INPUT, K0-K3 empty, K4 UNKNOWN with NA numerics and null arrays", ev && empt &&
                      identical(kt$build_state, "INVALID_INPUT") && identical(kt$data_state, "UNKNOWN") &&
                      identical(c(kt$qualified_n, kt$selected_n, kt$selected_sum), c("NA", "NA", "NA")) &&
                      identical(c(kt$qualified_ids, kt$selected_ids), c("null", "null"))))
  }
  list(preconditions = pre, relation = rel)
}

mr_rows <- list(); mr_res <- list()
for (mid in names(mr_lock)) {
  if (!isTRUE(mr_lock[[mid]]$applicable)) next
  pr <- mr_pairs[[mid]]
  if (is.null(pr)) { cat("SETUP ERROR: no frozen pair for", mid, "\n"); quit(status = 2L) }
  for (pth in names(builders)) {
    bd <- file.path(run_root, "metamorphic", mid, pth, "baseline"); td <- file.path(run_root, "metamorphic", mid, pth, "transformed")
    rb <- run_builder(builders[[pth]], fx_path(pr[1]), bd); rt <- run_builder(builders[[pth]], fx_path(pr[2]), td)
    e <- mr_eval(mid, bd, td, pr[1], pr[2])
    allc <- c(e$preconditions, e$relation)
    ok <- rb$exit == 0L && rt$exit == 0L && all(vapply(allc, function(x) x$result == "PASS", logical(1)))
    failed <- vapply(Filter(function(x) x$result != "PASS", allc), function(x) x$check, character(1))
    obs <- if (rb$exit != 0L || rt$exit != 0L) sprintf("builder exit %d/%d", rb$exit, rt$exit) else
      if (ok) "relation held: all precondition and relation checks passed" else paste("not held:", paste(failed, collapse = "; "))
    rp <- file.path(rep_dir, paste0(mid, "_", pth, ".json"))
    wj(list(id = mid, path_id = pth, baseline_fixture = pr[1], transformed_fixture = pr[2],
            lock = mr_lock[[mid]], pair_source = "Part A section 24 (frozen design text)",
            baseline_run = list(command = rb$command, exit = rb$exit), transformed_run = list(command = rt$command, exit = rt$exit),
            preconditions = e$preconditions, relation_checks = e$relation, observed_relation = obs,
            result = if (ok) "PASS" else "FAIL"), rp)
    mr_res[[paste(mid, pth)]] <- ok
    mr_rows[[paste(mid, pth)]] <- data.frame(id = mid, path_id = pth, baseline_fixture = pr[1], transformed_fixture = pr[2],
      expected_relation = mr_lock[[mid]]$expected_relation, observed_relation = obs, result = if (ok) "PASS" else "FAIL",
      report_path = rel(rp), report_sha256 = sha(rp), recorded_at_utc = now_utc(), stringsAsFactors = FALSE)
  }
}
mr_df <- do.call(rbind, mr_rows); rownames(mr_df) <- NULL
overall$metamorphic <- all(mr_df$result == "PASS") && nrow(mr_df) == 2L * sum(vapply(mr_lock, function(x) isTRUE(x$applicable), logical(1)))

# ---------- 4. smoke run (C51; non-reporting) ----------
smoke <- lapply(names(builders), function(pth) {
  od <- file.path(run_root, "smoke", pth); r <- run_builder(builders[[pth]], P("data", "fixture_8row.csv"), od)
  files_ok <- all(file.exists(file.path(od, cp_files)))
  list(path_id = pth, command = r$command, exit = r$exit, five_files_written = files_ok, result = if (r$exit == 0L && files_ok) "PASS" else "FAIL")
})
smoke_ok <- all(vapply(smoke, function(x) x$result == "PASS", logical(1)))
wj(list(status = if (smoke_ok) "PASS" else "FAIL", non_reporting = TRUE,
        note = "Run provenance only; smoke outputs are never analytical evidence.", runs = smoke), file.path(out_dir, "smoke.json"))
overall$smoke <- smoke_ok

# ---------- 5. production readers and poison probes (C41) ----------
# Reader: the production outputs (source = data/fixture_8row.csv, which the manifest binds to
# the same bytes as F00) are read with the fixture reader and must reproduce the oracle F00 digest.
# Poison: a copy of those outputs with a wrong judged value must be REJECTED by the same reader+compare;
# the unpoisoned copy must be accepted (control).
src_is_f00 <- identical(sha(P("data", "fixture_8row.csv")), sha(fx_path("F00")))
poisons <- list(
  list(name = "selected_sum_changed", file = "totals.csv", fun = function(df) { df$selected_sum[1] <- "22"; df }),
  list(name = "reason_code_changed", file = "audit_rows.csv", fun = function(df) { i <- which(df$id == "A"); df$reason_code[i] <- "QUALIFIED"; df }),
  list(name = "selected_ids_reordered", file = "build_report.csv", fun = function(df) { df$selected_ids[1] <- "[\"B\",\"C\"]"; df }))
write_like <- function(df, p) write.csv(df, p, row.names = FALSE, na = "NA", fileEncoding = "UTF-8")
depth <- list(); depth_detail <- list()
for (pth in names(builders)) {
  prod <- P("outputs", if (pth == "R-A") "r_a" else "r_b")
  reader_digest <- case_digest(observed_canon(prod))
  reader_ok <- src_is_f00 && identical(reader_digest, exp_digest[["F00"]])
  cdir <- file.path(run_root, "poison", pth, "control"); dir.create(cdir, recursive = TRUE)
  file.copy(file.path(prod, cp_files), cdir)
  control_ok <- identical(case_digest(observed_canon(cdir)), exp_digest[["F00"]])
  # Rewrite-only controls (finding 1): each poisoned file re-read and re-written by the same
  # write_like() WITHOUT the edit must still be accepted, so a rejection can only come from the edit.
  rc <- lapply(poisons, function(po) {
    rd <- file.path(run_root, "poison", pth, paste0("rewrite_control_", po$name)); dir.create(rd, recursive = TRUE)
    file.copy(file.path(prod, cp_files), rd)
    df <- read_out_table(file.path(rd, po$file))
    if (is.character(df)) return(list(name = po$name, accepted = FALSE))
    file.rename(file.path(rd, po$file), file.path(rd, paste0(po$file, ".original")))
    write_like(df, file.path(rd, po$file))
    d <- case_digest(observed_canon(rd))
    list(name = po$name, file = po$file, digest = d, accepted = identical(d, exp_digest[["F00"]]))
  })
  rewrite_ok <- all(vapply(rc, function(x) isTRUE(x$accepted), logical(1)))
  pr <- lapply(poisons, function(po) {
    pd <- file.path(run_root, "poison", pth, po$name); dir.create(pd, recursive = TRUE)
    file.copy(file.path(prod, cp_files), pd)
    df <- read_out_table(file.path(pd, po$file))
    if (is.character(df)) return(list(name = po$name, rejected = FALSE))
    file.rename(file.path(pd, po$file), file.path(pd, paste0(po$file, ".unpoisoned")))
    write_like(po$fun(df), file.path(pd, po$file))
    d <- case_digest(observed_canon(pd))
    list(name = po$name, file = po$file, digest = d, rejected = !identical(d, exp_digest[["F00"]]))
  })
  poison_ok <- control_ok && rewrite_ok && all(vapply(pr, function(x) isTRUE(x$rejected), logical(1)))
  depth[[paste0("production_reader_", if (pth == "R-A") "a" else "b")]] <- if (reader_ok) "PASS" else "FAIL"
  depth[[paste0("poison_probe_", if (pth == "R-A") "a" else "b")]] <- if (poison_ok) "PASS" else "FAIL"
  depth_detail[[pth]] <- list(production_dir = rel(prod), source_bytes_equal_F00 = src_is_f00, reader_digest = reader_digest,
                              expected_F00 = exp_digest[["F00"]], control_accepted = control_ok,
                              rewrite_only_controls = rc, poisons = pr)
}
wj(c(depth, list(detail = depth_detail)), file.path(out_dir, "fixture_depth.json"))
wj(list(poison_probe_a = depth$poison_probe_a, poison_probe_b = depth$poison_probe_b, detail = lapply(depth_detail, function(x) x[c("control_accepted", "rewrite_only_controls", "poisons")])),
   file.path(out_dir, "poison.json"))
overall$fixture_depth <- all(unlist(depth) == "PASS")

# ---------- 6. sensitivity reports (from the executed relations and fixtures) ----------
sens_map <- list(`S-ORDER` = list(mr = c("MR1", "MR7"), fx = c("F00", "F01", "F03")),
                 `S-BOUNDARY` = list(mr = "MR3", fx = c("F02", "F12")),
                 `S-MISSING` = list(mr = "MR5", fx = c("F05", "F08", "F13")),
                 `S-CAPACITY` = list(mr = "MR6", fx = c("F00", "F10")))
sens_ok <- TRUE
for (sp in design$methodology$sensitivity$specifications) {
  m <- sens_map[[sp$id]]
  if (is.null(m)) { sens_ok <- FALSE; next }
  mr_part <- mr_df[mr_df$id %in% m$mr, c("id", "path_id", "result", "report_path", "report_sha256")]
  fx_part <- fx_df[fx_df$id %in% m$fx, c("id", "match_a", "match_b", "report_path", "report_sha256")]
  held <- all(mr_part$result == "PASS") && all(fx_part$match_a) && all(fx_part$match_b)
  st <- if (held) "evaluated" else "failed"
  if (!held) sens_ok <- FALSE
  wj(list(id = sp$id, target_id = sp$target_id, relation = sp$relation, justification = sp$justification,
          status = st, evidence_relations = mr_part, evidence_fixtures = fx_part,
          interpretation = if (held) paste0("All mapped relations (", paste(m$mr, collapse = ","), ") held on R-A and R-B and fixtures ",
                                           paste(m$fx, collapse = ","), " matched the oracle; no instability observed.")
                           else paste0("At least one mapped relation or fixture failed; per the locked instability rule a verified violation requires REMEDIATE. Failed branch retained.")),
     file.path(out_dir, paste0("sensitivity_", sp$id, ".json")))
}
overall$sensitivity <- sens_ok

# ---------- 7. planted analytical defects (code-independent output wrappers) ----------
# Defects are planted by wrapping the UNMODIFIED frozen builder and transforming its
# output CSVs (BUILDER_SPEC / schema.json). No builder source edits. Detection rule
# unchanged: DETECTED if >=1 fixture the clean builder matched now mismatches the oracle.
# A transform that changes no output on any fixture is "not planted" -> FAIL (never skip).
# Secondary: wrong-oracle cross-check proves the comparator discriminates on each axis.
parse_ids <- function(txt) {
  if (is.null(txt) || identical(txt, "null") || !nzchar(txt)) return(character(0))
  tryCatch(as.character(unlist(fromJSON(txt))), error = function(e) character(0))
}
fmt_ids <- function(ids) {
  ids <- as.character(ids)
  if (!length(ids)) return("[]")
  as.character(toJSON(ids, auto_unbox = FALSE))
}
read_cp <- function(od, name) {
  p <- file.path(od, name)
  if (!file.exists(p)) return(NULL)
  read.csv(p, colClasses = "character", check.names = FALSE, na.strings = character(),
           stringsAsFactors = FALSE, encoding = "UTF-8")
}
write_cp <- function(df, od, name) {
  write.csv(df, file.path(od, name), row.names = FALSE, na = "NA", fileEncoding = "UTF-8")
}
num_of <- function(x) suppressWarnings(as.numeric(x))

# Returns TRUE if at least one output byte changed; FALSE if the transform planted nothing.
transform_threshold <- function(od) {
  k0 <- read_cp(od, "audit_rows.csv"); k2 <- read_cp(od, "rank_rows.csv")
  k3 <- read_cp(od, "totals.csv"); k4 <- read_cp(od, "build_report.csv"); k1 <- read_cp(od, "reason_totals.csv")
  if (is.null(k0) || is.null(k4) || nrow(k4) != 1L) return(FALSE)
  if (!identical(k4$build_state[[1]], "EVALUATED")) return(FALSE)
  boundary <- which(k0$qualification == "YES" &
                      !is.na(num_of(k0$amount_value)) & abs(num_of(k0$amount_value) - 10) < 1e-15)
  if (!length(boundary)) return(FALSE)
  drop_ids <- k0$id[boundary]
  before <- digest(file = file.path(od, "build_report.csv"), algo = "sha256")
  k0$qualification[boundary] <- "NO"
  k0$reason_code[boundary] <- "BELOW_THRESHOLD"
  k0$selection_state[boundary] <- "NOT_SELECTED"
  if (!is.null(k2) && nrow(k2)) k2 <- k2[!(k2$id %in% drop_ids), , drop = FALSE]
  qids <- setdiff(parse_ids(k4$qualified_ids[[1]]), drop_ids)
  sids <- setdiff(parse_ids(k4$selected_ids[[1]]), drop_ids)
  # Keep selected capacity 2 from remaining ranked by existing rank_rows order if possible.
  if (!is.null(k2) && nrow(k2)) {
    ord <- k2[order(num_of(k2$rank_n), method = "radix"), , drop = FALSE]
    sids <- head(ord$id, 2L)
    k2$place_state <- ifelse(k2$id %in% sids, "SELECTED", "WAITLISTED")
    k2$rank_n <- as.character(seq_len(nrow(k2)))
  }
  sel_sum <- if (length(sids) && !is.null(k0)) {
    vals <- num_of(k0$amount_value[match(sids, k0$id)]); if (anyNA(vals)) NA_real_ else sum(vals)
  } else 0
  k4$qualified_ids[[1]] <- fmt_ids(qids)
  k4$selected_ids[[1]] <- fmt_ids(sids)
  k4$qualified_n[[1]] <- as.character(length(qids))
  k4$selected_n[[1]] <- as.character(length(sids))
  k4$selected_sum[[1]] <- if (is.na(sel_sum)) "NA" else sprintf("%.17g", sel_sum)
  if (!is.null(k3) && nrow(k3) == 1L) {
    k3$qualified_n[[1]] <- k4$qualified_n[[1]]; k3$selected_n[[1]] <- k4$selected_n[[1]]
    k3$selected_sum[[1]] <- k4$selected_sum[[1]]
  }
  if (!is.null(k1)) {
    # Recompute reason totals from K0.
    tab <- as.data.frame(table(k0$reason_code), stringsAsFactors = FALSE)
    names(tab) <- c("reason_code", "row_n"); tab$row_n <- as.character(tab$row_n)
    k1 <- tab
  }
  write_cp(k0, od, "audit_rows.csv"); if (!is.null(k1)) write_cp(k1, od, "reason_totals.csv")
  if (!is.null(k2)) write_cp(k2, od, "rank_rows.csv"); if (!is.null(k3)) write_cp(k3, od, "totals.csv")
  write_cp(k4, od, "build_report.csv")
  !identical(before, digest(file = file.path(od, "build_report.csv"), algo = "sha256"))
}

transform_tie <- function(od) {
  k2 <- read_cp(od, "rank_rows.csv"); k4 <- read_cp(od, "build_report.csv"); k0 <- read_cp(od, "audit_rows.csv")
  k3 <- read_cp(od, "totals.csv")
  if (is.null(k2) || is.null(k4) || nrow(k4) != 1L || !identical(k4$build_state[[1]], "EVALUATED")) return(FALSE)
  if (nrow(k2) < 2L) return(FALSE)
  amts <- num_of(k2$amount_value)
  # Find a tied amount pair (same amount, different ids) and swap their rank order.
  twin <- NULL
  for (a in unique(amts[!is.na(amts)])) {
    idx <- which(abs(amts - a) < 1e-15)
    if (length(idx) >= 2L) { twin <- idx[1:2]; break }
  }
  if (is.null(twin)) return(FALSE)
  before <- digest(file = file.path(od, "rank_rows.csv"), algo = "sha256")
  # Swap the two tied rows' positions in K2 and rebuild selected from new order.
  tmp <- k2[twin[1], , drop = FALSE]; k2[twin[1], ] <- k2[twin[2], ]; k2[twin[2], ] <- tmp
  k2$rank_n <- as.character(seq_len(nrow(k2)))
  sids <- head(k2$id, min(2L, nrow(k2)))
  k2$place_state <- ifelse(k2$id %in% sids, "SELECTED", "WAITLISTED")
  if (!is.null(k0)) {
    k0$selection_state <- ifelse(k0$id %in% sids, "SELECTED",
                                 ifelse(k0$qualification == "YES", "NOT_SELECTED", k0$selection_state))
  }
  sel_sum <- if (length(sids) && !is.null(k0)) {
    vals <- num_of(k0$amount_value[match(sids, k0$id)]); if (anyNA(vals)) NA_real_ else sum(vals)
  } else 0
  k4$selected_ids[[1]] <- fmt_ids(sids)
  k4$selected_n[[1]] <- as.character(length(sids))
  k4$selected_sum[[1]] <- if (is.na(sel_sum)) "NA" else sprintf("%.17g", sel_sum)
  if (!is.null(k3) && nrow(k3) == 1L) {
    k3$selected_n[[1]] <- k4$selected_n[[1]]; k3$selected_sum[[1]] <- k4$selected_sum[[1]]
  }
  write_cp(k2, od, "rank_rows.csv"); write_cp(k4, od, "build_report.csv")
  if (!is.null(k0)) write_cp(k0, od, "audit_rows.csv"); if (!is.null(k3)) write_cp(k3, od, "totals.csv")
  !identical(before, digest(file = file.path(od, "rank_rows.csv"), algo = "sha256"))
}

transform_summation <- function(od) {
  k0 <- read_cp(od, "audit_rows.csv"); k2 <- read_cp(od, "rank_rows.csv")
  k3 <- read_cp(od, "totals.csv"); k4 <- read_cp(od, "build_report.csv")
  if (is.null(k4) || nrow(k4) != 1L || !identical(k4$build_state[[1]], "EVALUATED")) return(FALSE)
  if (is.null(k2) || !nrow(k2)) return(FALSE)
  # Sum over ALL ranked rows instead of selected only.
  ranked_ids <- k2$id
  sids <- parse_ids(k4$selected_ids[[1]])
  if (!length(ranked_ids) || length(ranked_ids) <= length(sids)) return(FALSE)
  vals <- num_of(k2$amount_value)
  if (anyNA(vals)) return(FALSE)
  new_sum <- sum(vals)
  old_sum <- num_of(k4$selected_sum[[1]])
  if (!is.na(old_sum) && abs(new_sum - old_sum) < 1e-15) return(FALSE)
  before <- digest(file = file.path(od, "totals.csv"), algo = "sha256")
  k4$selected_sum[[1]] <- sprintf("%.17g", new_sum)
  if (!is.null(k3) && nrow(k3) == 1L) k3$selected_sum[[1]] <- k4$selected_sum[[1]]
  write_cp(k4, od, "build_report.csv"); if (!is.null(k3)) write_cp(k3, od, "totals.csv")
  !identical(before, digest(file = file.path(od, "totals.csv"), algo = "sha256"))
}

transform_missing_to_zero <- function(od) {
  k0 <- read_cp(od, "audit_rows.csv"); k1 <- read_cp(od, "reason_totals.csv")
  k2 <- read_cp(od, "rank_rows.csv"); k3 <- read_cp(od, "totals.csv"); k4 <- read_cp(od, "build_report.csv")
  if (is.null(k0) || is.null(k4) || nrow(k4) != 1L || !identical(k4$build_state[[1]], "EVALUATED")) return(FALSE)
  miss <- which(k0$amount_state == "MISSING" | k0$reason_code == "AMOUNT_MISSING" | k0$raw_amount == "")
  if (!length(miss)) return(FALSE)
  before <- digest(file = file.path(od, "audit_rows.csv"), algo = "sha256")
  # Treat missing as amount 0: PRESENT / BELOW_THRESHOLD (0 < 10), drop MISSING reason.
  k0$amount_state[miss] <- "PRESENT"
  k0$raw_amount[miss] <- "0"
  k0$amount_value[miss] <- "0"
  k0$qualification[miss] <- "NO"
  k0$reason_code[miss] <- "BELOW_THRESHOLD"
  k0$selection_state[miss] <- "NOT_SELECTED"
  if (!is.null(k1)) {
    tab <- as.data.frame(table(k0$reason_code), stringsAsFactors = FALSE)
    names(tab) <- c("reason_code", "row_n"); tab$row_n <- as.character(tab$row_n)
    k1 <- tab
  }
  write_cp(k0, od, "audit_rows.csv"); if (!is.null(k1)) write_cp(k1, od, "reason_totals.csv")
  !identical(before, digest(file = file.path(od, "audit_rows.csv"), algo = "sha256"))
}

# expected-ID injection: overwrite K4 qualified/selected with F00 expected lists (existing wrapper).
transform_expected_id_injection <- function(od) {
  k4 <- read_cp(od, "build_report.csv")
  if (is.null(k4) || nrow(k4) != 1L || !identical(k4$build_state[[1]], "EVALUATED")) return(FALSE)
  before <- digest(file = file.path(od, "build_report.csv"), algo = "sha256")
  # Deliberately wrong relative to a typical F00 match: swap/alter lists.
  k4$qualified_ids[[1]] <- '["B","C","E"]'
  k4$selected_ids[[1]] <- '["C","B"]'
  # Force a detectable change even on F00 (which already has those lists) by corrupting selected_sum.
  # Detection needs mismatch vs oracle: on F00 those ids match, so also flip selected_n to a wrong value
  # when the ids already match. Prefer injecting wrong ids that break most fixtures.
  k4$qualified_ids[[1]] <- '["Z99","Y98"]'
  k4$selected_ids[[1]] <- '["Z99","Y98"]'
  k4$qualified_n[[1]] <- "2"; k4$selected_n[[1]] <- "2"
  write_cp(k4, od, "build_report.csv")
  !identical(before, digest(file = file.path(od, "build_report.csv"), algo = "sha256"))
}

TRANSFORMS <- list(
  threshold = transform_threshold,
  tie = transform_tie,
  expected_id_injection = transform_expected_id_injection,
  summation = transform_summation,
  missing_to_zero = transform_missing_to_zero
)

# Wrapper script: run the real builder, then apply one named transform to its output dir.
make_wrapper <- function(orig_abs, defect_id) {
  c(
    "#!/usr/bin/env Rscript",
    "args <- commandArgs(trailingOnly = TRUE)",
    "if (length(args) != 2L) quit(status = 2L)",
    sprintf("orig <- %s", deparse(orig_abs)),
    sprintf("defect <- %s", deparse(defect_id)),
    "rs <- file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'Rscript.exe' else 'Rscript')",
    "st <- system2(rs, c('--vanilla', shQuote(orig), shQuote(args[[1]]), shQuote(args[[2]])))",
    "ex <- if (is.null(st)) 0L else as.integer(st)",
    "if (ex != 0L) quit(status = ex)",
    "ca <- commandArgs(trailingOnly = FALSE)",
    "farg <- sub('^--file=', '', ca[startsWith(ca, '--file=')])",
    "if (!length(farg)) quit(status = 2L)",
    "sidecar <- file.path(dirname(farg), 'planted_transforms.R')",
    "if (!file.exists(sidecar)) quit(status = 2L)",
    "env <- new.env(parent = globalenv())",
    "sys.source(sidecar, envir = env)",
    "ok <- env$TRANSFORMS[[defect]](args[[2]])",
    "if (!isTRUE(ok)) quit(status = 3L)",
    "quit(status = 0L)"
  )
}

# Write shared transform library once under the run root (wrappers source it).
planted_lib_dir <- file.path(run_root, "planted")
dir.create(planted_lib_dir, recursive = TRUE, showWarnings = FALSE)
transforms_path <- file.path(planted_lib_dir, "planted_transforms.R")
# Prefer the canonical copy shipped next to this script under validation/; fall back to dump().
canon <- P("validation", "planted_transforms.R")
if (file.exists(canon)) {
  file.copy(canon, transforms_path, overwrite = TRUE)
} else {
  dump(c("parse_ids", "fmt_ids", "read_cp", "write_cp", "num_of",
         "transform_threshold", "transform_tie", "transform_summation",
         "transform_missing_to_zero", "transform_expected_id_injection", "TRANSFORMS"),
       file = transforms_path)
  writeLines(c("suppressPackageStartupMessages({ library(jsonlite); library(digest) })",
               readLines(transforms_path)), transforms_path)
}


planted <- list(); planted_ok <- TRUE
for (d in names(TRANSFORMS)) {
  per <- list()
  for (pth in names(builders)) {
    mdir <- file.path(run_root, "planted", d, pth); dir.create(mdir, recursive = TRUE)
    # Place a copy of the transforms lib next to the wrapper.
    file.copy(transforms_path, file.path(mdir, "planted_transforms.R"), overwrite = TRUE)
    mfile <- file.path(mdir, "mutant_main.R")
    writeLines(make_wrapper(P(builders[[pth]]), d), mfile)
    # planted_here is determined after runs: any fixture whose mutant digest differs from clean.
    det <- character(0); fx_detail <- list(); changed <- character(0)
    for (fid in fixture_ids) {
      od <- file.path(mdir, "fixtures", fid)
      r <- run_builder(rel(mfile), fx_path(fid), od); r$dir <- od
      # exit 3 = transform planted nothing on this fixture (allowed per fixture; overall needs some change)
      if (r$exit == 3L) {
        fx_detail[[fid]] <- list(exit = 3L, unmutated_matched = NA, mutant_matches = NA, planted_change = FALSE)
        next
      }
      s <- score_dir(fid, r)
      base_match <- identical(fx_obs[[fid]][[pth]]$score$digest, exp_digest[[fid]])
      clean_digest <- fx_obs[[fid]][[pth]]$score$digest
      changed_here <- r$exit == 0L && !identical(s$digest, clean_digest)
      if (changed_here) changed <- c(changed, fid)
      if (base_match && r$exit == 0L && !identical(s$digest, exp_digest[[fid]])) det <- c(det, fid)
      fx_detail[[fid]] <- list(exit = r$exit, unmutated_matched = base_match,
                               mutant_matches = identical(s$digest, exp_digest[[fid]]),
                               planted_change = changed_here)
    }
    planted_here <- length(changed) > 0L
    ok <- planted_here && length(det) > 0L
    if (!ok) planted_ok <- FALSE
    per[[pth]] <- list(builder_sha256 = builder_sha[[pth]], mutant = rel(mfile), mutant_sha256 = sha(mfile),
                       transform = d, planting = "output_wrapper",
                       planted = planted_here, changed_fixtures = changed, detected_by = det,
                       result = if (ok) "detected" else "NOT_DETECTED", fixtures = fx_detail)
  }
  planted[[d]] <- per
}
wj(list(status = if (planted_ok) "PASS" else "FAIL",
        note = "Code-independent planted defects (output wrappers). Classes: threshold, tie, expected-ID injection, summation, missing-to-zero. Zero-change transform = FAIL. Shared judged logic: structural_review.R; positional comparison: compare_keyed.R; changed source bytes: source_verify.R; stale dependency: check_lineage.R.",
        defects = planted), file.path(out_dir, "planted_defects.json"))
overall$planted_defects <- planted_ok

# Secondary wrong-oracle cross-check (supporting evidence; does not gate planted_ok alone).
wrong_oracle_ok <- TRUE
wo_detail <- list()
for (d in c("threshold", "tie", "summation", "missing_to_zero", "expected_id_injection")) {
  # Build a wrong expected digest by transforming a clean F00 output and hashing it as if it were the oracle.
  # The clean builder's F00 digest must NOT equal that wrong digest (comparator discriminates).
  per <- list()
  for (pth in names(builders)) {
    clean_od <- file.path(run_root, "fixtures", "F00", pth)
    tmp <- file.path(run_root, "wrong_oracle", d, pth)
    if (dir.exists(tmp)) unlink(tmp, recursive = TRUE)
    dir.create(tmp, recursive = TRUE)
    for (f in cp_files) file.copy(file.path(clean_od, f), file.path(tmp, f))
    planted_change <- TRANSFORMS[[d]](tmp)
    wrong_digest <- case_digest(observed_canon(tmp))
    clean_digest <- fx_obs[["F00"]][[pth]]$score$digest
    discriminates <- isTRUE(planted_change) && !identical(wrong_digest, clean_digest)
    if (!discriminates) wrong_oracle_ok <- FALSE
    per[[pth]] <- list(planted_change = planted_change, clean_digest = clean_digest,
                       wrong_digest = wrong_digest, discriminates = discriminates)
  }
  wo_detail[[d]] <- per
}
wj(list(status = if (wrong_oracle_ok) "PASS" else "FAIL", role = "supporting_cross_check",
        note = "Wrong-oracle cross-check (supporting only; does not gate run_fixtures): clean F00 digest must differ from each defect-transformed digest.",
        detail = wo_detail), file.path(out_dir, "wrong_oracle_crosscheck.json"))
# Supporting only: recorded but not added to overall gate vector.
overall$numeric_selftest <- selftest_ok

# ---------- 8. reports and status ----------
write.csv(fx_df, file.path(out_dir, "fixture_results.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(mr_df, file.path(out_dir, "metamorphic_results.csv"), row.names = FALSE, fileEncoding = "UTF-8")
status <- if (all(unlist(overall))) "PASS" else "FAIL"
wj(list(status = status, components = lapply(overall, function(x) if (isTRUE(x)) "PASS" else "FAIL"),
        run_dir = rel(run_root), builders = as.list(builder_sha), design_version = design$design_version,
        fixture_version = design$fixture_version, script_sha256 = sha(P("validation", "run_fixtures.R")),
        r_version = R.version.string, checked_at_utc = now_utc(),
        fixture_integrity = integrity, lock_pins = lock_pins, oracle_absent = oracle_absent), file.path(out_dir, "run_fixtures_status.json"))
cat("run_fixtures:", status, "\n"); for (n in names(overall)) cat(" ", n, if (isTRUE(overall[[n]])) "PASS" else "FAIL", "\n")
quit(status = if (status == "PASS") 0L else 1L)
