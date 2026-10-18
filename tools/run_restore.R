#!/usr/bin/env Rscript
# Wrap an OWNER-REVIEWED project restore script. No package installation policy is invented here.
# Usage from repo root: Rscript tools/run_restore.R ROOT SCRIPT NEW_LIBRARY NEW_ATTEMPT
# Project SCRIPT receives ROOT and NEW_LIBRARY as its two trailing arguments.
args<-commandArgs(TRUE)
if(length(args)!=4)stop("Usage: run_restore.R ROOT SCRIPT NEW_LIBRARY NEW_ATTEMPT")
source("methodology/contracts.R");source("methodology/tools.R")
root<-normalizePath(args[[1]],winslash="/",mustWork=TRUE)
script<-normalizePath(args[[2]],winslash="/",mustWork=TRUE)
lib<-args[[3]];attempt<-args[[4]]
if(file.exists(lib)||dir.exists(lib)||file.exists(attempt)||dir.exists(attempt))stop("Library and attempt paths must both be new")
dir.create(lib,recursive=TRUE);dir.create(attempt,recursive=TRUE)
lib<-normalizePath(lib,winslash="/");attempt<-normalizePath(attempt,winslash="/")
settings<-c(R_LIBS_USER=lib,R_LIBS=lib,R_LIBS_SITE=lib)
probe<-file.path(attempt,"probe.R")
writeLines(c('a<-commandArgs(TRUE)',
 'expected<-normalizePath(a[[1]],winslash="/")',
 'actual<-normalizePath(.libPaths(),winslash="/")',
 'dput(list(R=R.version.string,environment=Sys.getenv(c("R_LIBS_USER","R_LIBS","R_LIBS_SITE")),library_paths=actual),file=a[[2]])',
 'descs<-unlist(lapply(.libPaths(),function(p)file.path(list.dirs(p,recursive=FALSE,full.names=TRUE),"DESCRIPTION")))',
 'rows<-lapply(descs[file.exists(descs)],function(p){d<-read.dcf(p,fields=c("Package","Version"));data.frame(Package=d[1,1],Version=d[1,2],LibPath=dirname(dirname(p)))})',
 'write.csv(do.call(rbind,rows),a[[3]],row.names=FALSE)', 
 'stopifnot(identical(actual[[1]],expected),all(actual %in% c(expected,normalizePath(.Library,winslash="/"))))'),probe)
run_probe<-function(label)m_run_child(probe,c(lib,file.path(attempt,paste0(label,"-environment.txt")),file.path(attempt,paste0(label,"-packages.csv"))),settings,file.path(attempt,paste0(label,"-probe.log")))
pre<-run_probe("before")
if(pre!=0L)stop("Fresh child library isolation failed; preserve attempt")
status<-m_run_child(script,c(root,lib),settings,file.path(attempt,"restore-console.txt"))
post<-run_probe("after")
jsonlite::write_json(list(status=if(status==0L&&post==0L)"CHILD_CHECKS_PASS" else "FAIL",restore_exit_status=status,probe_exit_status=post,script_sha256=m_hash(script),library=lib,recorded_at_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),limitation="Not a restoration certificate: compare package versions with the frozen spec and rerun required output checks before producing restore_report.json"),file.path(attempt,"child-run-status.json"),auto_unbox=TRUE,pretty=TRUE)
quit(status=if(status==0L&&post==0L)0 else 1)
