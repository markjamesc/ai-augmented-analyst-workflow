#!/usr/bin/env Rscript
# SYNTHETIC style-variant builder B (imperative twin of functional A). Planted-defect fixture only.
args <- commandArgs(trailingOnly=TRUE); if (length(args)!=2L) quit(status=2L)
input_csv <- args[[1]]; output_dir <- args[[2]]
dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)
options(stringsAsFactors=FALSE); invisible(Sys.setlocale("LC_NUMERIC","C"))
csv_escape <- function(x){ x<-as.character(x); y<-gsub('"','""',x,fixed=TRUE); if (grepl('[,\"\n\r]',y)) paste0('"',y,'"') else y }
write_csv_file <- function(path, header, rows){
  lines <- character(length(rows)+1L); lines[1L] <- paste(vapply(header,csv_escape,character(1)), collapse=",")
  if (length(rows)>0L) for (i in seq_along(rows)) lines[i+1L] <- paste(vapply(rows[[i]],csv_escape,character(1)), collapse=",")
  con <- file(path, open="wb"); on.exit(close(con), add=TRUE); writeLines(lines, con, sep="\n", useBytes=TRUE)
}
fmt_num <- function(x){ if (length(x)==0L || is.na(x) || !is.finite(x)) return("NA"); if (x==0) "0" else sprintf("%.17g", x) }
fmt_int <- function(n) sprintf("%d", as.integer(n))
json_array <- function(x){ if (!length(x)) return("[]"); paste0("[", paste0('"', x, '"', collapse=","), "]") }
raw <- readBin(input_csv, what="raw", n=file.info(input_csv)$size)
source_digest <- digest::digest(raw, algo="sha256", serialize=FALSE)
txt <- rawToChar(raw); if (grepl("\r", txt, fixed=TRUE)) txt <- gsub("\r\n","\n",txt,fixed=TRUE)
ln <- strsplit(txt, "\n", fixed=TRUE)[[1]]; if (length(ln) && ln[length(ln)]=="") ln <- ln[-length(ln)]
parse_csv_line <- function(line){
  chars <- strsplit(line,"",fixed=TRUE)[[1]]; fields <- character(0); cur <- ""; inq <- FALSE; i <- 1L; n <- length(chars)
  while (i <= n) {
    ch <- chars[i]
    if (inq) {
      if (ch == '"') { if (i < n && chars[i+1L]=='"') { cur <- paste0(cur,'"'); i <- i+2L } else { inq <- FALSE; i <- i+1L } }
      else { cur <- paste0(cur, ch); i <- i+1L }
    } else if (ch == '"') { inq <- TRUE; i <- i+1L }
    else if (ch == ',') { fields <- c(fields, cur); cur <- ""; i <- i+1L }
    else { cur <- paste0(cur, ch); i <- i+1L }
  }
  c(fields, cur)
}
header <- parse_csv_line(ln[1]); stopifnot(identical(header, c("id","amount","eligible")))
N <- length(ln) - 1L
ids <- character(N); amts <- character(N); elig <- logical(N)
for (i in seq_len(N)) { f <- parse_csv_line(ln[i+1L]); ids[i]<-f[1]; amts[i]<-f[2]; elig[i]<-identical(tolower(f[3]),"true") }
amount_value <- rep(NA_real_, N); amount_state <- character(N); qualification <- character(N); reason_code <- character(N)
for (i in seq_len(N)) {
  if (!elig[i]) { amount_state[i] <- if (identical(amts[i],"")) "MISSING" else "PRESENT"; qualification[i]<-"NO"; reason_code[i]<-"NOT_ELIGIBLE"
    if (!identical(amts[i],"")) amount_value[i] <- suppressWarnings(as.numeric(amts[i])); next }
  if (identical(amts[i],"")) { amount_state[i]<-"MISSING"; qualification[i]<-"NO"; reason_code[i]<-"AMOUNT_MISSING"; next }
  amount_state[i] <- "PRESENT"; aval <- suppressWarnings(as.numeric(amts[i])); amount_value[i] <- aval
  if (!is.finite(aval)) { qualification[i]<-"NO"; reason_code[i]<-"AMOUNT_UNPARSEABLE" }
  else if (aval >= 10) { qualification[i]<-"YES"; reason_code[i]<-"QUALIFIED" }
  else { qualification[i]<-"NO"; reason_code[i]<-"BELOW_THRESHOLD" }
}
qual_ids_all <- ids[qualification=="YES"]
qual_amounts <- amount_value[qualification=="YES"]
if (length(qual_ids_all)) {
  o <- order(-qual_amounts, qual_ids_all, method="radix")
  qual_ids_rank <- qual_ids_all[o]; qual_amounts <- qual_amounts[o]
} else qual_ids_rank <- character(0)
selected_ids <- if (length(qual_ids_rank) > 2L) qual_ids_rank[1:2] else qual_ids_rank
selected_sum <- 0; if (length(selected_ids)) { for (v in amount_value[match(selected_ids, ids)]) selected_sum <- selected_sum + v }
K0 <- vector("list", N)
for (i in seq_len(N)) {
  sel_state <- if (ids[i] %in% selected_ids) "SELECTED" else "NOT_SELECTED"
  K0[[i]] <- c(ids[i], if (elig[i]) "TRUE" else "FALSE", amount_state[i], qualification[i], reason_code[i], sel_state, amts[i],
               if (identical(amount_state[i],"MISSING") || !is.finite(amount_value[i])) "NA" else fmt_num(amount_value[i]))
}
rt <- as.data.frame(table(reason_code), stringsAsFactors=FALSE)
K1 <- lapply(seq_len(nrow(rt)), function(i) c(rt$reason_code[i], fmt_int(rt$Freq[i])))
K2 <- lapply(seq_along(qual_ids_rank), function(rank) {
  id <- qual_ids_rank[rank]
  c(id, if (id %in% selected_ids) "SELECTED" else "WAITLISTED", fmt_int(rank), fmt_num(qual_amounts[rank]))
})
K3 <- list(c("fixture","EVALUATED", fmt_int(N), fmt_int(sum(elig)), fmt_int(length(qual_ids_rank)), fmt_int(length(selected_ids)), fmt_num(selected_sum)))
K4 <- list(c("fixture","EVALUATED","PRESENT", json_array(qual_ids_all), json_array(selected_ids), source_digest,
             fmt_int(length(qual_ids_rank)), fmt_int(length(selected_ids)), fmt_num(selected_sum)))
write_csv_file(file.path(output_dir,"audit_rows.csv"), c("id","eligible_state","amount_state","qualification","reason_code","selection_state","raw_amount","amount_value"), K0)
write_csv_file(file.path(output_dir,"reason_totals.csv"), c("reason_code","row_n"), K1)
write_csv_file(file.path(output_dir,"rank_rows.csv"), c("id","place_state","rank_n","amount_value"), K2)
write_csv_file(file.path(output_dir,"totals.csv"), c("case_key","calculation_state","source_n","eligible_true_n","qualified_n","selected_n","selected_sum"), K3)
write_csv_file(file.path(output_dir,"build_report.csv"), c("case_key","build_state","data_state","qualified_ids","selected_ids","source_digest","qualified_n","selected_n","selected_sum"), K4)
