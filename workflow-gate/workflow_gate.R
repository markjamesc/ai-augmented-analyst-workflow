#!/usr/bin/env Rscript
# Inspect actual current validation; never manufacture PASS from a coordinator status.
a<-commandArgs(TRUE);s<-sub('^--file=','',commandArgs(FALSE)[grepl('^--file=',commandArgs(FALSE))][1]);repo<-normalizePath(file.path(dirname(s),'..'),winslash='/')
source(file.path(repo,'methodology/contracts.R'));source(file.path(repo,'methodology/tools.R'));source(file.path(repo,'acceptance/acc003/pretest.R'))
r<-tryCatch({wf_assert(length(a)==1,'Usage: workflow_gate.R ROOT');wf_current(a[1],repo,wf_manifest(a[1]));'PASS'},error=function(e){cat(conditionMessage(e),'\n');'TOOL_ERROR'})
cat(r,'\n');quit(status=if(r=='PASS')0L else 2L)
