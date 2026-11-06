#!/usr/bin/env Rscript
# Shared planted-defect output transforms (code-independent).
# Sourced by run_fixtures wrappers and unit tests. Do not edit builder source.
suppressPackageStartupMessages({ library(jsonlite); library(digest) })

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
