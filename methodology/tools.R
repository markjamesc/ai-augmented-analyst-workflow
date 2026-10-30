# Execution helpers shared only by verification, never by the judged builders.
wf_environment <- function() {
  p <- c('jsonlite','digest','DBI','RSQLite')
  list(r=as.character(getRversion()),platform=R.version$platform,
    packages=setNames(lapply(p,function(x)if(requireNamespace(x,quietly=TRUE))as.character(packageVersion(x)) else 'absent'),p),
    locale=Sys.getlocale(),timezone=Sys.getenv('TZ'),rng=as.list(RNGkind()),
    threads=as.list(Sys.getenv(c('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS'))))
}
wf_engine_files <- function(repo) {
  p <- c('methodology/contracts.R','methodology/tools.R','methodology/schema.json',
    'procedure-gate/procedure_gate.R','procedure-gate/procedure.json','workflow-gate/workflow_gate.R',
    'acceptance/acc003/harness.R','acceptance/acc003/pretest.R','acceptance/acc003/sql_test.R')
  lapply(p,function(x)wf_ref(repo,x))
}
wf_identity <- function(repo,d) list(engine=wf_engine_files(repo),environment=wf_environment(),
  comparison=d$checkpoints,fixture_oracle=d$fixtures$oracle_sha256,fixture_manifest=d$fixtures$manifest_sha256)
wf_fresh <- function(root,prefix) {
  dir.create(root,recursive=TRUE,showWarnings=FALSE)
  p<-tempfile(paste0(prefix,'-'),tmpdir=root);wf_assert(dir.create(p),'Cannot create new attempt');p
}
wf_save_manifest <- function(m,root) {
  p<-file.path(root,'run_manifest.json')
  if(file.exists(p)) {
    history<-file.path(root,'history');dir.create(history,showWarnings=FALSE)
    dst<-file.path(history,paste0(wf_hash(p),'.json'))
    if(!file.exists(dst)) wf_assert(file.copy(p,dst),'Cannot preserve prior manifest')
  }
  wf_write(m,p)
}
wf_manifest <- function(root) wf_read(file.path(root,'run_manifest.json'))
wf_command <- function(script,input,output) {
  wf_assert(file.exists(script),'Builder script missing')
  dir.create(output,recursive=TRUE,showWarnings=FALSE)
  bin<-file.path(R.home('bin'),if(.Platform$OS.type=='windows')'Rscript.exe' else 'Rscript')
  args<-c('--vanilla',normalizePath(script,winslash='/'),normalizePath(input,winslash='/'),normalizePath(output,winslash='/'))
  out<-file.path(output,'console.txt')
  code<-system2(bin,vapply(args,shQuote,character(1)),stdout=out,stderr=out,timeout=300)
  list(executable=bin,args=as.list(args),exit=as.integer(code))
}
wf_snapshot <- function(root,paths) lapply(unique(paths),function(p)wf_ref(root,p))
wf_approval <- function(root,path,contract_hash) {
  a<-wf_read(wf_path(root,path))
  wf_assert(identical(a$contract_sha256,contract_hash),'Owner approval names a different design')
  wf_assert(wf_text(a$owner) && wf_text(a$verbatim) && isTRUE(a$approved),'Explicit owner approval required')
  wf_assert(wf_ref_ok(root,a$evidence),'Owner approval evidence missing/stale')
  text<-paste(readLines(wf_path(root,a$evidence$path),warn=FALSE),collapse='\n')
  wf_assert(grepl(a$verbatim,text,fixed=TRUE),'Verbatim approval not present in recorded evidence')
  # Attribution and conversational meaning remain coordinator attestations, not NLP proofs.
  a
}
wf_current <- function(root,repo,m) {
  wf_assert(wf_refs_ok(root,m$lock$files),'Design/approval/input evidence missing or changed')
  wf_assert(wf_refs_ok(repo,m$engine),'Workflow code or schema changed; re-pretest and revalidate')
  wf_assert(identical(m$environment,wf_environment()),'Runtime/configuration changed; re-pretest affected checks')
  wf_assert(wf_refs_ok(root,m$validation$files),'Validation evidence missing or changed')
  report<-wf_read(wf_path(root,m$validation$report$path))
  wf_assert(wf_ref_ok(root,m$validation$report),'Validation report changed')
  wf_assert(identical(report$run_id,m$run_id) && identical(report$contract_sha256,m$lock$contract$sha256),'Validation belongs to another run/design')
  wf_assert(wf_all_pass(report$checks),'Required checks have not all passed')
  d<-wf_read(wf_path(root,m$lock$contract$path));expected<-wf_required(d)
  ids<-vapply(report$checks,function(x)x$id,character(1))
  wf_assert(!anyDuplicated(ids)&&setequal(ids,expected),'Required check coverage differs')
  invisible(TRUE)
}
wf_required <- function(d) c('source','fixtures','reconciliation','invariance','pretest','independence',if(isTRUE(d$model$predictions_affect_decision))'model')
