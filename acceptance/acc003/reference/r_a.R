# ACC-SMALL-REMEDIATION-002 -- independent R-A checkpoint producer.
# Invocation: Rscript --vanilla analysis/r_a/main.R <input_csv> <output_dir>
# Reads only the supplied input CSV; writes five K0-K4 CSV files.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || !nzchar(args[[2L]])) {
  stop("Required arguments: <input_csv> <output_dir>", call. = FALSE)
}
input_csv <- args[[1L]]
output_dir <- args[[2L]]

# On R's numeric C locale, %.17g round-trips finite IEEE-754 binary64.
invisible(try(Sys.setlocale("LC_NUMERIC", "C"), silent = TRUE))

csv_field <- function(x) {
  x <- as.character(x)
  needs_quotes <- grepl(",", x, fixed = TRUE) ||
    grepl('"', x, fixed = TRUE) ||
    grepl("\r", x, fixed = TRUE) ||
    grepl("\n", x, fixed = TRUE)
  if (needs_quotes) paste0('"', gsub('"', '""', x, fixed = TRUE), '"') else x
}

csv_row <- function(values) {
  paste(vapply(values, csv_field, character(1L)), collapse = ",")
}

number_text <- function(x) {
  if (length(x) != 1L || !is.finite(x)) stop("Nonfinite output numeric")
  if (x == 0) "0" else sprintf("%.17g", x)
}

integer_text <- function(x) sprintf("%.0f", as.double(x))

id_array <- function(ids) {
  if (!length(ids)) return("[]")
  # Validated IDs contain only ASCII letters, digits, underscore and hyphen.
  paste0('["', paste(ids, collapse = '","'), '"]')
}

read_input_bytes <- function(path) {
  handle <- file(path, open = "rb")
  on.exit(close(handle), add = TRUE)
  pieces <- list()
  repeat {
    piece <- readBin(handle, what = "raw", n = 65536L)
    if (!length(piece)) break
    pieces[[length(pieces) + 1L]] <- piece
  }
  if (!length(pieces)) return(raw(0))
  do.call(c, pieces)
}

# RFC-style single-line CSV parsing, including doubled quotes. A quoted
# embedded newline is not allowed by this LF-separated source contract.
parse_csv_record <- function(line) {
  chars <- strsplit(line, "", fixed = TRUE)[[1L]]
  count <- length(chars)
  pos <- 1L
  fields <- character(0)

  repeat {
    value <- ""
    if (pos <= count && chars[[pos]] == '"') {
      pos <- pos + 1L
      closed <- FALSE
      while (pos <= count) {
        if (chars[[pos]] == '"') {
          if (pos < count && chars[[pos + 1L]] == '"') {
            value <- paste0(value, '"')
            pos <- pos + 2L
          } else {
            pos <- pos + 1L
            closed <- TRUE
            break
          }
        } else {
          value <- paste0(value, chars[[pos]])
          pos <- pos + 1L
        }
      }
      if (!closed || (pos <= count && chars[[pos]] != ",")) return(NULL)
    } else {
      while (pos <= count && chars[[pos]] != ",") {
        if (chars[[pos]] == '"') return(NULL)
        value <- paste0(value, chars[[pos]])
        pos <- pos + 1L
      }
    }

    fields <- c(fields, value)
    if (pos > count) break
    if (chars[[pos]] != ",") return(NULL)
    pos <- pos + 1L
    if (pos > count) {
      fields <- c(fields, "")
      break
    }
  }
  fields
}

invalid_input <- function() list(build_state = "INVALID_INPUT")
unverifiable <- function() list(build_state = "UNVERIFIABLE")

compute_checkpoints <- function(bytes, source_digest) {
  if (!length(bytes) ||
      !identical(bytes[[length(bytes)]], as.raw(10L)) ||
      any(bytes == as.raw(0L)) || any(bytes == as.raw(13L)) ||
      (length(bytes) >= 3L &&
       identical(bytes[seq_len(3L)], as.raw(c(239L, 187L, 191L))))) {
    return(invalid_input())
  }

  content <- tryCatch(rawToChar(bytes), error = function(e) NA_character_)
  if (length(content) != 1L || is.na(content) ||
      is.na(suppressWarnings(iconv(content, from = "UTF-8",
                                   to = "UTF-8", sub = NA)))) {
    return(invalid_input())
  }

  lines <- strsplit(content, "\n", fixed = TRUE)[[1L]]

  # One optional trailing unused column: its NAME is irrelevant (F09 repair).
  header <- if (length(lines)) parse_csv_record(lines[[1L]]) else NULL
  if (is.null(header) || !(length(header) %in% c(3L, 4L)) ||
      !identical(header[1:3], c("id", "amount", "eligible")) ||
      (length(header) == 4L && (!nzchar(header[4L]) || header[4L] %in% header[1:3]))) {
    return(invalid_input())
  }
  expected_columns <- length(header)

  source_n <- length(lines) - 1L
  ids <- character(source_n)
  raw_amounts <- character(source_n)
  eligible_tokens <- character(source_n)

  if (source_n > 0L) {
    for (i in seq_len(source_n)) {
      fields <- parse_csv_record(lines[[i + 1L]])
      if (is.null(fields) || length(fields) != expected_columns) {
        return(invalid_input())
      }
      ids[[i]] <- fields[[1L]]
      raw_amounts[[i]] <- fields[[2L]]
      eligible_tokens[[i]] <- fields[[3L]]
    }
  }

  if (any(!grepl("^[A-Za-z0-9_-]+$", ids, perl = TRUE)) ||
      anyDuplicated(ids) > 0L ||
      any(!(eligible_tokens %in% c("true", "false")))) {
    return(invalid_input())
  }

  missing_amount <- raw_amounts == ""
  amounts <- rep(NA_real_, source_n)
  present <- which(!missing_amount)

  amount_grammar <- "^[+-]?(?:[0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$"

  if (length(present)) {
    if (any(!grepl(amount_grammar, raw_amounts[present], perl = TRUE))) {
      return(invalid_input())
    }
    converted <- suppressWarnings(as.double(raw_amounts[present]))
    if (any(!is.finite(converted))) return(invalid_input())
    amounts[present] <- converted
  }

  eligible_true <- eligible_tokens == "true"
  qualified <- rep(FALSE, source_n)
  qualified[present] <- eligible_true[present] & amounts[present] >= 10

  reasons <- rep("", source_n)
  reasons[!eligible_true] <- "NOT_ELIGIBLE"
  reasons[eligible_true & missing_amount] <- "AMOUNT_MISSING"
  reasons[qualified] <- "QUALIFIED"

  below <- present[eligible_true[present] & !qualified[present]]
  reasons[below] <- "BELOW_THRESHOLD"

  if (any(!nzchar(reasons))) return(unverifiable())

  ranked <- which(qualified)
  if (length(ranked)) {
    ranked <- ranked[order(-amounts[ranked], ids[ranked], method = "radix")]
  }

  selected <- head(ranked, 2L)
  ranks <- integer(source_n)
  if (length(ranked)) ranks[ranked] <- seq_along(ranked)

  id_order <- order(ids, method = "radix")
  qualified_by_id <- id_order[qualified[id_order]]

  # Sequential binary64 additions in ranked selected order.
  selected_sum <- 0.0
  if (length(selected)) {
    for (i in selected) {
      selected_sum <- selected_sum + amounts[[i]]
      if (!is.finite(selected_sum)) return(unverifiable())
    }
  }

  # K0: one row per source ID, physically sorted by ASCII ID.
  k0 <- character(0)
  for (i in id_order) {
    k0 <- c(k0, csv_row(c(
      ids[[i]],
      if (eligible_true[[i]]) "TRUE" else "FALSE",
      if (missing_amount[[i]]) "MISSING" else "PRESENT",
      if (qualified[[i]]) "YES" else "NO",
      reasons[[i]],
      if (ranks[[i]] > 0L && ranks[[i]] <= 2L) "SELECTED" else "NOT_SELECTED",
      raw_amounts[[i]],
      if (missing_amount[[i]]) "NA" else number_text(amounts[[i]])
    )))
  }

  # K1: four exhaustive reason codes, including zero counts.
  reason_keys <- c("QUALIFIED", "NOT_ELIGIBLE", "AMOUNT_MISSING", "BELOW_THRESHOLD")
  reason_keys <- reason_keys[order(reason_keys, method = "radix")]

  k1 <- vapply(reason_keys, function(code) {
    csv_row(c(code, integer_text(sum(reasons == code))))
  }, character(1L), USE.NAMES = FALSE)

  # K2: qualifying records, physically sorted by ID, with semantic rank.
  k2 <- character(0)
  for (i in id_order) {
    if (qualified[[i]]) {
      k2 <- c(k2, csv_row(c(
        ids[[i]],
        if (ranks[[i]] <= 2L) "SELECTED" else "WAITLISTED",
        integer_text(ranks[[i]]),
        number_text(amounts[[i]])
      )))
    }
  }

  qualified_n <- length(ranked)
  selected_n <- length(selected)
  sum_text <- number_text(selected_sum)

  # K3: evaluated aggregates.
  k3 <- csv_row(c(
    "fixture", "EVALUATED", integer_text(source_n),
    integer_text(sum(eligible_true)), integer_text(qualified_n),
    integer_text(selected_n), sum_text
  ))

  # K4: builder measurements only; no verifier action or reason codes.
  k4_fields <- c(
    "fixture", "EVALUATED", "PRESENT",
    id_array(ids[qualified_by_id]),
    id_array(ids[selected]), source_digest,
    integer_text(qualified_n), integer_text(selected_n), sum_text
  )

  list(
    build_state = "EVALUATED",
    k0 = k0, k1 = k1, k2 = k2,
    k3 = k3, k4_fields = k4_fields
  )
}

# Read only the declared input source and derive its observed byte digest.
bytes <- tryCatch(read_input_bytes(input_csv), error = function(e) NULL)
source_digest <- "UNVERIFIED"

if (!is.null(bytes)) {
  source_digest <- tryCatch(
    tolower(digest::digest(bytes, algo = "sha256", serialize = FALSE)),
    error = function(e) "UNVERIFIED"
  )
}

result <- if (is.null(bytes) || identical(source_digest, "UNVERIFIED")) {
  unverifiable()
} else {
  tryCatch(
    compute_checkpoints(bytes, source_digest),
    error = function(e) unverifiable()
  )
}

# Fixed K0-K4 headers: key, exact fields, then numeric fields.
schemas <- list(
  audit_rows.csv = c(
    "id", "eligible_state", "amount_state", "qualification",
    "reason_code", "selection_state", "raw_amount", "amount_value"
  ),
  reason_totals.csv = c("reason_code", "row_n"),
  rank_rows.csv = c("id", "place_state", "rank_n", "amount_value"),
  totals.csv = c(
    "case_key", "calculation_state", "source_n",
    "eligible_true_n", "qualified_n", "selected_n", "selected_sum"
  ),
  build_report.csv = c(
    "case_key", "build_state", "data_state", "qualified_ids",
    "selected_ids", "source_digest", "qualified_n",
    "selected_n", "selected_sum"
  )
)

if (identical(result$build_state, "EVALUATED")) {
  bodies <- list(
    result$k0, result$k1, result$k2, result$k3,
    csv_row(result$k4_fields)
  )
} else {
  # All four nonnullable intermediate checkpoints are header-only.
  # K4 distinguishes unknown measurements from valid computed zero.
  bodies <- list(
    character(0), character(0), character(0), character(0),
    csv_row(c(
      "fixture", result$build_state, "UNKNOWN", "null", "null",
      source_digest, "NA", "NA", "NA"
    ))
  )
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}
if (!dir.exists(output_dir)) {
  stop("Cannot create output directory", call. = FALSE)
}

# Binary writes guarantee LF endings and a final newline on Windows.
write_checkpoint <- function(name, fields, body) {
  path <- file.path(output_dir, name)
  text <- paste0(
    paste(c(paste(fields, collapse = ","), body), collapse = "\n"),
    "\n"
  )
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(text), con)
}

for (j in seq_along(schemas)) {
  write_checkpoint(names(schemas)[[j]], schemas[[j]], bodies[[j]])
}
