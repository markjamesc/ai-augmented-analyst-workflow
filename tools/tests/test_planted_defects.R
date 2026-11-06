#!/usr/bin/env Rscript
# Confirm 5/5 planted defects are DETECTED for a given builder pair (code-independent wrappers).
# Usage: Rscript --vanilla tools/tests/test_planted_defects.R ROOT LABEL
# ROOT must contain analysis/r_{a,b}/main.R, validation/fixtures/{manifest,oracle,F*.csv},
# artifacts/stage3_locked_design.json, data/fixture_8row.csv, and the harness overlays:
#   validation/run_fixtures.R, validation/planted_transforms.R
# Writes ROOT/outputs/verification/ (move aside first) via run_fixtures.R and asserts planted PASS.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) quit(status = 2L)
root <- normalizePath(args[[1]], mustWork = TRUE)
label <- if (length(args) >= 2L) args[[2]] else basename(root)
rscript <- file.path(R.home("bin"), "Rscript")
# Ensure harness overlays present
for (f in c("run_fixtures.R", "planted_transforms.R")) {
  if (!file.exists(file.path(root, "validation", f))) {
    cat("FAIL", label, ": missing validation/", f, "\n", sep = "")
    quit(status = 1L)
  }
}
# Move aside prior verification outputs if present
ver <- file.path(root, "outputs", "verification")
if (dir.exists(ver) && length(list.files(ver))) {
  stamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
  dest <- file.path(root, "outputs", "superseded", paste0("attempt_", stamp), "outputs", "verification")
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  file.rename(ver, dest)
  dir.create(ver, recursive = TRUE)
  cat("moved aside prior verification ->", dest, "\n")
}
cat("RUNNING run_fixtures for", label, "...\n")
out <- system2(rscript, c("--vanilla", file.path(root, "validation", "run_fixtures.R"), root),
               stdout = TRUE, stderr = TRUE)
ex <- attr(out, "status"); if (is.null(ex)) ex <- 0L
writeLines(out, file.path(root, "outputs", "verification", "_test_planted_console.txt"))
cat(paste(tail(out, 20), collapse = "\n"), "\n")
pd <- file.path(root, "outputs", "verification", "planted_defects.json")
if (!file.exists(pd)) { cat("FAIL", label, ": planted_defects.json missing\n"); quit(status = 1L) }
suppressPackageStartupMessages(library(jsonlite))
j <- fromJSON(pd, simplifyVector = FALSE)
status <- j$status
defects <- names(j$defects)
need <- c("threshold", "tie", "expected_id_injection", "summation", "missing_to_zero")
ok_all <- identical(status, "PASS")
rows <- list()
for (d in need) {
  for (pth in c("R-A", "R-B")) {
    rec <- j$defects[[d]][[pth]]
    rows[[length(rows) + 1L]] <- data.frame(
      label = label, defect = d, builder = pth,
      planted = isTRUE(rec$planted),
      detected = identical(rec$result, "detected"),
      n_detected = length(unlist(rec$detected_by)),
      stringsAsFactors = FALSE)
    if (!isTRUE(rec$planted) || !identical(rec$result, "detected")) ok_all <- FALSE
  }
}
tab <- do.call(rbind, rows)
print(tab)
# Also require wrong-oracle supporting file present
wo <- file.path(root, "outputs", "verification", "wrong_oracle_crosscheck.json")
wo_ok <- file.exists(wo) && identical(fromJSON(wo)$status, "PASS")
cat("wrong_oracle_crosscheck:", if (wo_ok) "PASS" else "FAIL", "\n")
cat("LABEL", label, "planted_defects:", status, "overall_ok:", ok_all, "run_fixtures_exit:", ex, "\n")
# run_fixtures may FAIL overall for unrelated reasons; planted section is what we assert here.
quit(status = if (ok_all) 0L else 1L)
