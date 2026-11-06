#!/usr/bin/env Rscript
# SYNTHETIC style-variant builder (data.frame / split-apply). Planted-defect fixture only.
args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) == 2L)
input_path <- args[[1]]; output_path <- args[[2]]
dir.create(output_path, showWarnings = FALSE, recursive = TRUE)
invisible(try(Sys.setlocale("LC_NUMERIC", "C"), silent = TRUE))
field_escape <- function(value) {
  text_value <- as.character(value)
  if (grepl("[,\"\r\n]", text_value)) paste0('"', gsub('"', '""', text_value, fixed = TRUE), '"') else text_value
}
emit_csv <- function(file_name, column_names, record_list) {
  header_line <- paste(vapply(column_names, field_escape, character(1L)), collapse = ",")
  body_lines <- vapply(record_list, function(record) paste(vapply(record, field_escape, character(1L)), collapse = ","), character(1L))
  writeLines(c(header_line, body_lines), file.path(output_path, file_name), useBytes = TRUE)
}
format_number <- function(number) {
  if (!is.finite(number)) return("NA")
  if (identical(number, 0)) "0" else sprintf("%.17g", number)
}
as_json_list <- function(identifier_values) {
  if (!length(identifier_values)) return("[]")
  paste0("[", paste(sprintf('"%s"', identifier_values), collapse = ","), "]")
}
byte_content <- readBin(input_path, what = "raw", n = file.info(input_path)$size)
content_digest <- digest::digest(byte_content, algo = "sha256", serialize = FALSE)
character_content <- rawToChar(byte_content)
character_content <- gsub("\r\n", "\n", character_content, fixed = TRUE)
content_lines <- strsplit(character_content, "\n", fixed = TRUE)[[1L]]
if (length(content_lines) && !nzchar(content_lines[[length(content_lines)]])) {
  content_lines <- content_lines[-length(content_lines)]
}
tokenize <- function(single_line) {
  characters <- strsplit(single_line, "", fixed = TRUE)[[1L]]
  collected <- character(0L); buffer <- ""; quoted <- FALSE; cursor <- 1L
  while (cursor <= length(characters)) {
    ch <- characters[[cursor]]
    if (quoted) {
      if (ch == '"') {
        if (cursor < length(characters) && characters[[cursor + 1L]] == '"') {
          buffer <- paste0(buffer, '"'); cursor <- cursor + 2L
        } else { quoted <- FALSE; cursor <- cursor + 1L }
      } else { buffer <- paste0(buffer, ch); cursor <- cursor + 1L }
    } else if (ch == '"') { quoted <- TRUE; cursor <- cursor + 1L }
    else if (ch == ',') { collected <- c(collected, buffer); buffer <- ""; cursor <- cursor + 1L }
    else { buffer <- paste0(buffer, ch); cursor <- cursor + 1L }
  }
  c(collected, buffer)
}
column_header <- tokenize(content_lines[[1L]])
stopifnot(identical(column_header, c("id", "amount", "eligible")))
frame <- do.call(rbind, lapply(content_lines[-1L], function(line) {
  parts <- tokenize(line)
  data.frame(id = parts[[1L]], amount = parts[[2L]], eligible = tolower(parts[[3L]]), stringsAsFactors = FALSE)
}))
frame$missing_amount <- frame$amount == ""
frame$eligible_flag <- frame$eligible == "true"
frame$amount_number <- ifelse(frame$missing_amount, NA_real_, suppressWarnings(as.numeric(frame$amount)))
frame$amount_state <- ifelse(frame$missing_amount, "MISSING", "PRESENT")
frame$reason_code <- NA_character_
frame$qualification <- "NO"
for (row_index in seq_len(nrow(frame))) {
  if (!frame$eligible_flag[[row_index]]) { frame$reason_code[[row_index]] <- "NOT_ELIGIBLE"; next }
  if (frame$missing_amount[[row_index]]) { frame$reason_code[[row_index]] <- "AMOUNT_MISSING"; next }
  value <- frame$amount_number[[row_index]]
  if (!is.finite(value)) { frame$reason_code[[row_index]] <- "AMOUNT_UNPARSEABLE"; next }
  if (value >= 10) { frame$qualification[[row_index]] <- "YES"; frame$reason_code[[row_index]] <- "QUALIFIED" }
  else frame$reason_code[[row_index]] <- "BELOW_THRESHOLD"
}
qualified_frame <- frame[frame$qualification == "YES", , drop = FALSE]
if (nrow(qualified_frame)) {
  ranking <- order(-qualified_frame$amount_number, qualified_frame$id, method = "radix")
  qualified_frame <- qualified_frame[ranking, , drop = FALSE]
}
selected_identifiers <- head(qualified_frame$id, 2L)
frame$selection_state <- ifelse(frame$id %in% selected_identifiers, "SELECTED", "NOT_SELECTED")
audit_records <- lapply(seq_len(nrow(frame)), function(row_index) {
  c(frame$id[[row_index]], if (frame$eligible_flag[[row_index]]) "TRUE" else "FALSE", frame$amount_state[[row_index]],
    frame$qualification[[row_index]], frame$reason_code[[row_index]], frame$selection_state[[row_index]],
    frame$amount[[row_index]],
    if (frame$missing_amount[[row_index]] || !is.finite(frame$amount_number[[row_index]])) "NA" else format_number(frame$amount_number[[row_index]]))
})
reason_summary <- as.data.frame(table(frame$reason_code), stringsAsFactors = FALSE)
reason_records <- lapply(seq_len(nrow(reason_summary)), function(i) c(reason_summary$Var1[[i]], as.character(reason_summary$Freq[[i]])))
rank_records <- lapply(seq_len(nrow(qualified_frame)), function(rank_position) {
  c(qualified_frame$id[[rank_position]],
    if (qualified_frame$id[[rank_position]] %in% selected_identifiers) "SELECTED" else "WAITLISTED",
    as.character(rank_position), format_number(qualified_frame$amount_number[[rank_position]]))
})
selected_total <- 0
if (length(selected_identifiers)) {
  for (identifier in selected_identifiers) selected_total <- selected_total + frame$amount_number[frame$id == identifier]
}
totals_record <- list(c("fixture", "EVALUATED", as.character(nrow(frame)), as.character(sum(frame$eligible_flag)),
                        as.character(nrow(qualified_frame)), as.character(length(selected_identifiers)), format_number(selected_total)))
# qualified_ids in input order
input_order_qualified <- frame$id[frame$qualification == "YES"]
report_record <- list(c("fixture", "EVALUATED", "PRESENT", as_json_list(input_order_qualified), as_json_list(selected_identifiers),
                        content_digest, as.character(nrow(qualified_frame)), as.character(length(selected_identifiers)), format_number(selected_total)))
emit_csv("audit_rows.csv", c("id","eligible_state","amount_state","qualification","reason_code","selection_state","raw_amount","amount_value"), audit_records)
emit_csv("reason_totals.csv", c("reason_code","row_n"), reason_records)
emit_csv("rank_rows.csv", c("id","place_state","rank_n","amount_value"), rank_records)
emit_csv("totals.csv", c("case_key","calculation_state","source_n","eligible_true_n","qualified_n","selected_n","selected_sum"), totals_record)
emit_csv("build_report.csv", c("case_key","build_state","data_state","qualified_ids","selected_ids","source_digest","qualified_n","selected_n","selected_sum"), report_record)
