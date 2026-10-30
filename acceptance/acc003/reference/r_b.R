#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) quit(status = 2L)
input_csv <- args[[1]]
output_dir <- args[[2]]

if (!dir.exists(output_dir)) {
  ok <- dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!ok && !dir.exists(output_dir)) quit(status = 1L)
}

K0_header <- c("id", "eligible_state", "amount_state", "qualification",
               "reason_code", "selection_state", "raw_amount", "amount_value")
K1_header <- c("reason_code", "row_n")
K2_header <- c("id", "place_state", "rank_n", "amount_value")
K3_header <- c("case_key", "calculation_state", "source_n", "eligible_true_n",
               "qualified_n", "selected_n", "selected_sum")
K4_header <- c("case_key", "build_state", "data_state", "qualified_ids",
               "selected_ids", "source_digest", "qualified_n", "selected_n",
               "selected_sum")

amount_regex <- "^[+-]?(?:[0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$"

csv_escape <- function(x) {
  x <- as.character(x)
  if (length(x) == 0L) return("")
  y <- gsub('"', '""', x, fixed = TRUE)
  if (grepl("[,\"\n\r]", y)) paste0('"', y, '"') else y
}

write_csv_file <- function(path, header, rows) {
  lines <- character(length(rows) + 1L)
  lines[1L] <- paste(vapply(header, csv_escape, character(1)), collapse = ",")
  if (length(rows) > 0L) {
    for (i in seq_along(rows)) {
      lines[i + 1L] <- paste(vapply(rows[[i]], csv_escape, character(1)), collapse = ",")
    }
  }
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeLines(lines, con, sep = "\n", useBytes = TRUE)
}

fmt_int <- function(n) {
  if (length(n) == 0L || is.na(n)) return("NA")
  sprintf("%d", as.integer(n))
}

fmt_num <- function(x) {
  if (length(x) == 0L || is.na(x) || !is.finite(x)) return("NA")
  sprintf("%.17g", x)
}

json_array <- function(x) {
  if (length(x) == 0L) return("[]")
  paste0("[", paste0('"', gsub('"', '\\"', x, fixed = TRUE), '"', collapse = ","), "]")
}

parse_csv_line <- function(line) {
  chars <- strsplit(line, "", fixed = TRUE)[[1]]
  if (length(chars) == 0L) return("")
  fields <- character(0)
  cur <- ""
  inq <- FALSE
  afterq <- FALSE
  i <- 1L
  n <- length(chars)
  while (i <= n) {
    ch <- chars[i]
    if (inq) {
      if (ch == '"') {
        if (i < n && chars[i + 1L] == '"') {
          cur <- paste0(cur, '"')
          i <- i + 2L
        } else {
          inq <- FALSE
          afterq <- TRUE
          i <- i + 1L
        }
      } else {
        cur <- paste0(cur, ch)
        i <- i + 1L
      }
    } else {
      if (afterq) {
        if (ch == ',') {
          fields <- c(fields, cur)
          cur <- ""
          afterq <- FALSE
          i <- i + 1L
        } else {
          return(NULL)
        }
      } else {
        if (ch == '"') {
          if (nchar(cur) > 0L) return(NULL)
          inq <- TRUE
          i <- i + 1L
        } else if (ch == ',') {
          fields <- c(fields, cur)
          cur <- ""
          i <- i + 1L
        } else {
          cur <- paste0(cur, ch)
          i <- i + 1L
        }
      }
    }
  }
  if (inq) return(NULL)
  fields <- c(fields, cur)
  fields
}

read_raw <- function(path) {
  tryCatch({
    con <- file(path, open = "rb")
    on.exit(close(con), add = TRUE)
    sz <- file.info(path)$size
    if (is.na(sz)) stop("size unavailable")
    readBin(con, what = "raw", n = sz)
  }, error = function(e) NULL)
}

parse_source <- function(raw) {
  if (is.null(raw)) return(list(ok = FALSE, state = "UNVERIFIABLE"))
  if (length(raw) == 0L) return(list(ok = FALSE, state = "INVALID_INPUT"))
  if (length(raw) >= 3L && all(raw[1:3] == as.raw(c(0xEF, 0xBB, 0xBF)))) {
    return(list(ok = FALSE, state = "INVALID_INPUT"))
  }
  if (raw[length(raw)] != as.raw(0x0A)) {
    return(list(ok = FALSE, state = "INVALID_INPUT"))
  }
  txt <- tryCatch(rawToChar(raw), error = function(e) NULL)
  if (is.null(txt)) return(list(ok = FALSE, state = "INVALID_INPUT"))
  if (!validUTF8(txt)) return(list(ok = FALSE, state = "INVALID_INPUT"))
  if (grepl("\r", txt, fixed = TRUE)) return(list(ok = FALSE, state = "INVALID_INPUT"))
  lines <- strsplit(txt, "\n", fixed = TRUE)[[1]]
  if (length(lines) == 0L) return(list(ok = FALSE, state = "INVALID_INPUT"))
  if (identical(lines[length(lines)], "")) lines <- lines[-length(lines)]
  if (length(lines) < 1L) return(list(ok = FALSE, state = "INVALID_INPUT"))

  hdr <- parse_csv_line(lines[1L])
  if (is.null(hdr) || length(hdr) < 3L || length(hdr) > 4L) {
    return(list(ok = FALSE, state = "INVALID_INPUT"))
  }
  if (!identical(hdr[1:3], c("id", "amount", "eligible"))) {
    return(list(ok = FALSE, state = "INVALID_INPUT"))
  }
  if (length(hdr) == 4L && (!nzchar(hdr[4L]) || hdr[4L] %in% hdr[1:3])) {
    return(list(ok = FALSE, state = "INVALID_INPUT"))
  }
  expected_fields <- length(hdr)

  data_lines <- if (length(lines) > 1L) lines[-1L] else character(0)
  if (any(data_lines == "")) return(list(ok = FALSE, state = "INVALID_INPUT"))

  n <- length(data_lines)
  ids <- character(n)
  raw_amount <- character(n)
  amount_state <- character(n)
  amount_value <- numeric(n)
  eligible_state <- character(n)
  qualification <- character(n)
  reason_code <- character(n)
  seen <- character(0)

  for (k in seq_len(n)) {
    f <- parse_csv_line(data_lines[k])
    if (is.null(f) || length(f) != expected_fields) {
      return(list(ok = FALSE, state = "INVALID_INPUT"))
    }
    id <- f[1L]
    amt <- f[2L]
    elig <- f[3L]

    if (!grepl("^[A-Za-z0-9_-]+$", id, perl = TRUE)) {
      return(list(ok = FALSE, state = "INVALID_INPUT"))
    }
    if (id %in% seen) return(list(ok = FALSE, state = "INVALID_INPUT"))
    seen <- c(seen, id)

    if (!(identical(elig, "true") || identical(elig, "false"))) {
      return(list(ok = FALSE, state = "INVALID_INPUT"))
    }
    elig_state <- if (identical(elig, "true")) "TRUE" else "FALSE"

    if (identical(amt, "")) {
      astate <- "MISSING"
      aval <- NA_real_
    } else {
      if (!grepl(amount_regex, amt, perl = TRUE)) {
        return(list(ok = FALSE, state = "INVALID_INPUT"))
      }
      aval <- suppressWarnings(as.numeric(amt))
      if (is.na(aval) || !is.finite(aval)) {
        return(list(ok = FALSE, state = "INVALID_INPUT"))
      }
      astate <- "PRESENT"
    }

    if (elig_state == "FALSE") {
      reason <- "NOT_ELIGIBLE"
      qual <- "NO"
    } else if (astate == "MISSING") {
      reason <- "AMOUNT_MISSING"
      qual <- "NO"
    } else if (aval >= 10) {
      reason <- "QUALIFIED"
      qual <- "YES"
    } else {
      reason <- "BELOW_THRESHOLD"
      qual <- "NO"
    }

    ids[k] <- id
    raw_amount[k] <- amt
    amount_state[k] <- astate
    amount_value[k] <- aval
    eligible_state[k] <- elig_state
    qualification[k] <- qual
    reason_code[k] <- reason
  }

  list(
    ok = TRUE,
    state = "EVALUATED",
    ids = ids,
    raw_amount = raw_amount,
    amount_state = amount_state,
    amount_value = amount_value,
    eligible_state = eligible_state,
    qualification = qualification,
    reason_code = reason_code
  )
}

raw <- read_raw(input_csv)
digest_str <- if (is.null(raw)) {
  "UNVERIFIED"
} else {
  tolower(digest::digest(raw, algo = "sha256", serialize = FALSE))
}

parsed <- parse_source(raw)
build_state <- if (is.null(raw)) {
  "UNVERIFIABLE"
} else if (!parsed$ok) {
  parsed$state
} else {
  "EVALUATED"
}

evaluated <- FALSE
if (identical(build_state, "EVALUATED")) {
  qual_idx <- which(parsed$reason_code == "QUALIFIED")
  qual_ids_all <- parsed$ids[qual_idx]
  qual_amounts <- parsed$amount_value[qual_idx]

  if (length(qual_idx) > 0L) {
    ord <- order(-qual_amounts, qual_ids_all, method = "radix")
  } else {
    ord <- integer(0)
  }

  qual_ids_rank <- qual_ids_all[ord]
  selected_ids <- if (length(qual_ids_rank) > 2L) qual_ids_rank[1:2] else qual_ids_rank
  qualified_ids_ascii <- sort(qual_ids_all, method = "radix")

  sel_amt <- parsed$amount_value[match(selected_ids, parsed$ids)]
  selected_sum <- 0
  if (length(sel_amt) > 0L) {
    for (v in sel_amt) selected_sum <- selected_sum + v
  }

  if (!is.finite(selected_sum)) {
    build_state <- "UNVERIFIABLE"
  } else {
    evaluated <- TRUE
  }
}

tryCatch({
  if (evaluated) {
    ord_id <- order(parsed$ids, method = "radix")
    k0_rows <- vector("list", length(ord_id))
    for (j in seq_along(ord_id)) {
      i <- ord_id[j]
      sel_state <- if (parsed$ids[i] %in% selected_ids) "SELECTED" else "NOT_SELECTED"
      k0_rows[[j]] <- c(
        parsed$ids[i],
        parsed$eligible_state[i],
        parsed$amount_state[i],
        parsed$qualification[i],
        parsed$reason_code[i],
        sel_state,
        parsed$raw_amount[i],
        fmt_num(parsed$amount_value[i])
      )
    }

    reason_categories <- sort(
      c("QUALIFIED", "NOT_ELIGIBLE", "AMOUNT_MISSING", "BELOW_THRESHOLD"),
      method = "radix"
    )
    k1_rows <- lapply(reason_categories, function(cat) {
      c(cat, fmt_int(sum(parsed$reason_code == cat)))
    })

    rank_map <- setNames(seq_along(qual_ids_rank), qual_ids_rank)
    qual_ids_sorted <- sort(qual_ids_all, method = "radix")
    k2_rows <- lapply(qual_ids_sorted, function(id) {
      r <- rank_map[[id]]
      place <- if (r <= 2L) "SELECTED" else "WAITLISTED"
      amt <- parsed$amount_value[match(id, parsed$ids)]
      c(id, place, fmt_int(r), fmt_num(amt))
    })

    source_n <- length(parsed$ids)
    eligible_true_n <- sum(parsed$eligible_state == "TRUE")
    qualified_n <- length(qualified_ids_ascii)
    selected_n <- length(selected_ids)

    k3_row <- c(
      "fixture",
      "EVALUATED",
      fmt_int(source_n),
      fmt_int(eligible_true_n),
      fmt_int(qualified_n),
      fmt_int(selected_n),
      fmt_num(selected_sum)
    )

    k4_row <- c(
      "fixture",
      "EVALUATED",
      "PRESENT",
      json_array(qualified_ids_ascii),
      json_array(selected_ids),
      digest_str,
      fmt_int(qualified_n),
      fmt_int(selected_n),
      fmt_num(selected_sum)
    )

    write_csv_file(file.path(output_dir, "audit_rows.csv"), K0_header, k0_rows)
    write_csv_file(file.path(output_dir, "reason_totals.csv"), K1_header, k1_rows)
    write_csv_file(file.path(output_dir, "rank_rows.csv"), K2_header, k2_rows)
    write_csv_file(file.path(output_dir, "totals.csv"), K3_header, list(k3_row))
    write_csv_file(file.path(output_dir, "build_report.csv"), K4_header, list(k4_row))
  } else {
    k4_row <- c(
      "fixture",
      build_state,
      "UNKNOWN",
      "null",
      "null",
      digest_str,
      "NA",
      "NA",
      "NA"
    )

    write_csv_file(file.path(output_dir, "audit_rows.csv"), K0_header, list())
    write_csv_file(file.path(output_dir, "reason_totals.csv"), K1_header, list())
    write_csv_file(file.path(output_dir, "rank_rows.csv"), K2_header, list())
    write_csv_file(file.path(output_dir, "totals.csv"), K3_header, list())
    write_csv_file(file.path(output_dir, "build_report.csv"), K4_header, list(k4_row))
  }
}, error = function(e) {
  quit(status = 1L)
})
