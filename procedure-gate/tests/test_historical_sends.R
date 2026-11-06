#!/usr/bin/env Rscript
# H1 (owner card t1850s7711): a sent review of a replaced write-up may stay as history; a stale review never counts as current.
suppressPackageStartupMessages(library(jsonlite))
args <- commandArgs(trailingOnly = TRUE)
repo <- if (length(args)) normalizePath(args[[1]]) else normalizePath(getwd())
sys.source(file.path(repo, "methodology/contracts.R"), envir = environment())
root <- tempfile("h1-"); dir.create(root)
w <- function(p, txt) { f <- file.path(root, p); dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE); writeLines(txt, f); list(path = p, sha256 = m_hash(f)) }
wj <- function(p, x) { f <- file.path(root, p); dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE); write_json(x, f, auto_unbox = TRUE, pretty = TRUE); list(path = p, sha256 = m_hash(f)) }
old <- w("docs/cand.md", "old candidate")
arch <- w("outputs/superseded/x/docs/cand.md", "old candidate")
new <- w("docs/cand.md", "new candidate")
send <- function(id, att) { pk <- wj(paste0("packets/", id, ".json"), list(send_id = id, attachments = list(att)))
  rp <- w(paste0("transcripts/", id, ".md"), paste("reply", id))
  list(id = id, ai = "A", nonce = paste0("n", id), packet = pk, attachments = list(att), reply = rp, capture = rp) }
s_old <- send("S-i2", old); s_new <- send("S-i3", new)
sup <- wj("docs/supersession.json", list(historical_sent_fail = "S-i2", new_candidate = new, superseded_inputs = setNames(list(arch), "docs/cand.md")))
dir.create(file.path(root, "artifacts/operations"), recursive = TRUE)
wj("artifacts/operations/finish.json", list(sends = list(s_old, s_new)))
ops <- function() { r <- m_operations(root, list(), "finish"); setNames(vapply(r, function(x) x$result, ""), vapply(r, function(x) x$check, "")) }
# Without the declaration, the historical send fails identity and closure (pre-H1 behaviour).
r <- ops(); stopifnot(r[["Methodology send identity S-i2"]] == "FAIL", r[["Methodology operations evidence closure"]] == "FAIL")
# With a declared, hash-bound supersession, it passes as history; the current send still passes on current files.
wj("artifacts/operations/finish.historical.json", list(historical_sends = list(list(send_id = "S-i2", supersession = sup))))
r <- ops(); stopifnot(r[["Methodology send identity S-i2"]] == "PASS", r[["Methodology send identity S-i3"]] == "PASS", r[["Methodology operations evidence closure"]] == "PASS")
h <- m_historical(root, "finish", m_read(file.path(root, "artifacts/operations/finish.json"))$sends)
# A stale review still used as current coverage fails F5b: its attachment does not hash to the current file.
cur <- function(s) identical(tolower(s$attachments[[1]]$sha256), m_hash(file.path(root, "docs/cand.md")))
stopifnot(!cur(s_old), cur(s_new))
# A stale ref outside the historical send's scope (e.g. a receipt citing the old candidate) still fails closure.
rc <- wj("artifacts/receipt.json", list(deliverable = old))
stopifnot(inherits(tryCatch(m_inventory(list(rc), root, h), error = function(e) e), "error"))
# A supersession record that does not name the send gives no historical scope.
sup2 <- wj("docs/supersession2.json", list(historical_sent_fail = "S-other", new_candidate = new, superseded_inputs = setNames(list(arch), "docs/cand.md")))
file.remove(file.path(root, "artifacts/operations/finish.historical.json"))
wj("artifacts/operations/finish.historical.json", list(historical_sends = list(list(send_id = "S-i2", supersession = sup2))))
r <- ops(); stopifnot(r[["Methodology send identity S-i2"]] == "FAIL")
cat("historical send tests passed\n")
