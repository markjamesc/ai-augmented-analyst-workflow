#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)
source("methodology/contracts.R")
root <- normalizePath(args[[2]],mustWork=TRUE)
checks <- if(args[[1]]=="operations") m_operations(root,m_read(file.path(root,"artifacts/procedure/run_state.json")),args[[3]],final=identical(args[[3]],"finish")) else if(args[[1]]=="validation") {
  s3<-m_read(file.path(root,"artifacts/stage3_locked_design.json"));s4<-m_read(file.path(root,"artifacts/stage4_validation_status.json"))
  m_validation(s3,m_read(file.path(root,s4$evidence_receipts$methodology$path)),root)
} else stop("Use operations ROOT STAGE or validation ROOT")
cat(jsonlite::toJSON(checks,auto_unbox=TRUE,pretty=TRUE),"\n")
quit(status=if(m_pass(checks))0 else 1)
