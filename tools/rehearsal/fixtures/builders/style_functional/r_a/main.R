#!/usr/bin/env Rscript
# SYNTHETIC style-variant builder (functional). Fixture for planted-defect tests only.
args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) == 2L)
infile <- args[[1]]; outdir <- args[[2]]; dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
invisible(Sys.setlocale("LC_NUMERIC", "C"))
esc <- function(x) { x <- as.character(x); ifelse(grepl('[,\"\r\n]', x), paste0('"', gsub('"', '""', x, fixed=TRUE), '"'), x) }
jarr <- function(ids) if (!length(ids)) "[]" else paste0('["', paste(ids, collapse='","'), '"]')
nnum <- function(x) if (!is.finite(x)) "NA" else if (x == 0) "0" else sprintf("%.17g", x)
raw <- readBin(infile, "raw", file.info(infile)$size)
digest_src <- digest::digest(raw, algo = "sha256", serialize = FALSE)
text <- rawToChar(raw); if (grepl("\r", text, fixed=TRUE)) text <- gsub("\r\n", "\n", text, fixed=TRUE)
lines <- strsplit(text, "\n", fixed=TRUE)[[1]]; if (length(lines) && lines[length(lines)] == "") lines <- lines[-length(lines)]
parse_line <- function(line) {
  chars <- strsplit(line, "", fixed=TRUE)[[1]]; fields <- character(0); cur <- ""; i <- 1L; n <- length(chars); inq <- FALSE
  while (i <= n) {
    ch <- chars[[i]]
    if (inq) {
      if (ch == '"') { if (i < n && chars[[i+1]] == '"') { cur <- paste0(cur, '"'); i <- i+2L } else { inq <- FALSE; i <- i+1L } }
      else { cur <- paste0(cur, ch); i <- i+1L }
    } else if (ch == '"') { inq <- TRUE; i <- i+1L }
    else if (ch == ',') { fields <- c(fields, cur); cur <- ""; i <- i+1L }
    else { cur <- paste0(cur, ch); i <- i+1L }
  }
  c(fields, cur)
}
hdr <- parse_line(lines[[1]]); stopifnot(identical(hdr, c("id","amount","eligible")))
rows <- lapply(lines[-1], function(ln) { f <- parse_line(ln); list(id=f[[1]], amount=f[[2]], eligible=tolower(f[[3]])) })
THRESH <- 10; CAP <- 2L
classify <- function(r) {
  elig <- identical(r$eligible, "true")
  miss <- identical(r$amount, "")
  aval <- if (miss) NA_real_ else suppressWarnings(as.numeric(r$amount))
  if (!elig) list(elig=FALSE, miss=miss, aval=aval, qual=FALSE, reason="NOT_ELIGIBLE")
  else if (miss) list(elig=TRUE, miss=TRUE, aval=NA_real_, qual=FALSE, reason="AMOUNT_MISSING")
  else if (!is.finite(aval)) list(elig=TRUE, miss=FALSE, aval=aval, qual=FALSE, reason="AMOUNT_UNPARSEABLE")
  else if (aval >= THRESH) list(elig=TRUE, miss=FALSE, aval=aval, qual=TRUE, reason="QUALIFIED")
  else list(elig=TRUE, miss=FALSE, aval=aval, qual=FALSE, reason="BELOW_THRESHOLD")
}
cls <- lapply(rows, classify)
ids <- vapply(rows, `[[`, "", "id")
qual_idx <- which(vapply(cls, `[[`, FALSE, "qual"))
ord <- if (length(qual_idx)) {
  am <- vapply(cls[qual_idx], function(c) c$aval, 0.0); idq <- ids[qual_idx]
  qual_idx[order(-am, idq, method="radix")]
} else integer(0)
sel_idx <- head(ord, CAP)
k0 <- lapply(seq_along(rows), function(i) {
  c <- cls[[i]]; r <- rows[[i]]
  c(r$id, toupper(as.character(c$elig)), if (c$miss) "MISSING" else "PRESENT",
    if (c$qual) "YES" else "NO", c$reason,
    if (i %in% sel_idx) "SELECTED" else "NOT_SELECTED",
    r$amount, if (c$miss || !is.finite(c$aval)) "NA" else nnum(c$aval))
})
reasons <- vapply(cls, `[[`, "", "reason"); rtab <- as.data.frame(table(reasons), stringsAsFactors=FALSE)
k1 <- lapply(seq_len(nrow(rtab)), function(i) c(rtab$reasons[[i]], as.character(rtab$Freq[[i]])))
k2 <- lapply(seq_along(ord), function(rank) {
  i <- ord[[rank]]; c(ids[[i]], if (i %in% sel_idx) "SELECTED" else "WAITLISTED", as.character(rank), nnum(cls[[i]]$aval))
})
sel_sum <- 0; for (i in sel_idx) sel_sum <- sel_sum + cls[[i]]$aval
k3 <- list(c("fixture","EVALUATED", as.character(length(rows)),
             as.character(sum(vapply(cls,`[[`,FALSE,"elig"))), as.character(length(ord)),
             as.character(length(sel_idx)), nnum(sel_sum)))
k4 <- list(c("fixture","EVALUATED","PRESENT", jarr(ids[qual_idx]), jarr(ids[sel_idx]), digest_src,
             as.character(length(ord)), as.character(length(sel_idx)), nnum(sel_sum)))
write_one <- function(name, header, rows) {
  lines <- c(paste(esc(header), collapse=","), vapply(rows, function(r) paste(esc(r), collapse=","), ""))
  writeLines(lines, file.path(outdir, name), useBytes=TRUE)
}
write_one("audit_rows.csv", c("id","eligible_state","amount_state","qualification","reason_code","selection_state","raw_amount","amount_value"), k0)
write_one("reason_totals.csv", c("reason_code","row_n"), k1)
write_one("rank_rows.csv", c("id","place_state","rank_n","amount_value"), k2)
write_one("totals.csv", c("case_key","calculation_state","source_n","eligible_true_n","qualified_n","selected_n","selected_sum"), k3)
write_one("build_report.csv", c("case_key","build_state","data_state","qualified_ids","selected_ids","source_digest","qualified_n","selected_n","selected_sum"), k4)
