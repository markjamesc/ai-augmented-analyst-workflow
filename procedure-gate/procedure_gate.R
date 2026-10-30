#!/usr/bin/env Rscript
# Two stage prerequisites, plus truthful evidence-bound certification.
args_all<-commandArgs(FALSE);self<-sub('^--file=','',args_all[grepl('^--file=',args_all)][1])
repo<-normalizePath(if(nzchar(Sys.getenv('WF_REPO'))) Sys.getenv('WF_REPO') else file.path(dirname(self),'..'),winslash='/',mustWork=TRUE)
source(file.path(repo,'methodology/contracts.R'));source(file.path(repo,'methodology/tools.R'))
source(file.path(repo,'acceptance/acc003/harness.R'));source(file.path(repo,'acceptance/acc003/sql_test.R'));source(file.path(repo,'acceptance/acc003/pretest.R'))
wf_init <- function(root,id,mode='live') {
  wf_assert(!file.exists(file.path(root,'run_manifest.json')),'Run already exists; do not overwrite')
  wf_assert(wf_text(id)&&mode %in% c('live','offline'),'Run ID/mode required')
  wf_save_manifest(list(version='3.0-lean',run_id=id,mode=mode,baseline='51b6b0f4741cf97720349c180313353300f5078b',
    assurance='Procedural/implementation acceptance only; no accuracy or profitability certification'),root)
  'INITIALIZED'
}
wf_lock <- function(root,repo) {
  m<-wf_manifest(root);d<-wf_read(file.path(root,'design.json'))
  e<-wf_design_errors(d,repo);wf_assert(!length(e),paste(e,collapse='; '))
  wf_assert(identical(d$run_id,m$run_id),'Design run ID differs')
  wf_assert(is.null(m$lock),'Already locked: use an owner-approved successor run for a changed design')
  expected_view<-d;expected_view$fixtures<-NULL;expected_view$expected_primary<-NULL
  wf_assert(identical(wf_read(file.path(root,'builder_contract.json')),expected_view),'Refresh builder view from current contract before lock')
  approval<-wf_approval(root,'owner_approval.json',wf_hash(file.path(root,'design.json')))
  r<-wf_read(file.path(root,'design_review.json'))
  wf_assert(identical(r$contract_sha256,wf_hash(file.path(root,'design.json')))&&isTRUE(r$accepted)&&
    wf_text(r$reviewer)&&wf_ref_ok(root,r$evidence),'One independent design review must accept current contract')
  if(m$mode=='live') wf_assert(!isTRUE(approval$simulated)&&!isTRUE(r$simulated),'Simulated approvals/reviews cannot establish live acceptance')
  paths<-c('builder_contract.json','builder_spec.md','design.json','owner_approval.json',approval$evidence$path,'design_review.json',r$evidence$path,'start.md','framing.md',
    d$source$path,d$fixtures$oracle,d$fixtures$manifest)
  fm<-wf_read(wf_path(root,d$fixtures$manifest));paths<-c(paths,vapply(fm$fixtures,function(x)x$path,character(1)))
  if(d$source$kind=='sql') paths<-c(paths,d$source$query_path,d$source$reference_path)
  wf_assert(identical(wf_hash(wf_path(root,d$source$path)),d$source$sha256),'Source hash differs')
  wf_assert(identical(wf_hash(wf_path(root,d$fixtures$oracle)),d$fixtures$oracle_sha256)&&identical(wf_hash(wf_path(root,d$fixtures$manifest)),d$fixtures$manifest_sha256),'Fixture/oracle hash differs')
  m$lock<-list(contract=wf_ref(root,'design.json'),files=wf_snapshot(root,paths));wf_save_manifest(m,root);'LOCKED'
}
wf_finish <- function(root,repo) {
  m<-wf_manifest(root);wf_current(root,repo,m);d<-wf_read(file.path(root,'design.json'));f<-wf_read(file.path(root,'finish.json'))
  wf_assert(wf_text(f$answer)&&wf_text(f$limitations)&&length(f$claims)>0,'Finish needs answer, claims, limitations')
  for(c in f$claims) {
    wf_assert(wf_text(c$text)&&c$type %in% unlist(d$allowed_claim_types),'Unsupported claim type')
    wf_assert(wf_text(c$interpretation)&&wf_strings(c$evidence_paths)&&length(c$evidence_paths)>0,'Claim lacks evidence/interpretation')
    allowed<-vapply(m$validation$files,function(r)r$path,character(1))
    wf_assert(all(unlist(c$evidence_paths) %in% allowed),'Claim cites evidence outside validated pack')
  }
  for(k in c('numerical_review','inference_review')) {
    r<-f[[k]];wf_assert(isTRUE(r$accepted)&&wf_ref_ok(root,r$evidence)&&identical(r$content_sha256,wf_finish_content_hash(f)),'Finish review absent, stale or does not cover current content')
    if(m$mode=='live')wf_assert(!isTRUE(r$simulated),'Simulated Finish review not live evidence')
  }
  wf_assert(identical(f$exploratory_changes_decision,FALSE),'Exploratory model cannot change locked decision')
  wf_assert(wf_text(f$safeguard_disposition),'Finish must evaluate applicable safeguards')
  files<-c('finish.json',f$numerical_review$evidence$path,f$inference_review$evidence$path)
  m$finish<-list(files=wf_snapshot(root,files));wf_save_manifest(m,root);'FINISH_RECORDED'
}
wf_finalize <- function(root,repo) {
  m<-wf_manifest(root);wf_current(root,repo,m);wf_assert(wf_refs_ok(root,m$finish$files),'Finish not recorded or changed')
  cert<-list(run_id=m$run_id,mode=m$mode,certified=TRUE,scope=if(m$mode=='offline')'OFFLINE_MECHANICS_ONLY' else 'LIVE_PROCEDURAL_ACCEPTANCE',
    manifest=wf_ref(root,'run_manifest.json'),design=m$lock$contract,validation=m$validation$report,
    assurance='Recorded evidence and checks, not proof of analytical truth, genuine AI independence or profitable action',
    baseline=m$baseline,issued_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'))
  dir<-wf_fresh(file.path(root,'certificates'),'certificate');wf_write(cert,file.path(dir,'certificate.json'));cat('CERTIFICATE:',normalizePath(file.path(dir,'certificate.json'),winslash='/'),'\n');'CERTIFIED'
}
wf_main <- function(args) {
  wf_assert(length(args)>=2,'Usage: procedure_gate.R <init|lock|validate|finish|finalize|status> ROOT [run-id] [offline|live]')
  op<-args[1];root<-args[2];dir.create(root,recursive=TRUE,showWarnings=FALSE);root<-normalizePath(root,winslash='/')
  if(op=='init')return(wf_init(root,args[3],if(length(args)>=4)args[4] else 'live'))
  if(op=='lock')return(wf_lock(root,repo))
  if(op=='validate') {r<-wf_validate(root,repo,'--fault-probe'%in%args);for(x in r$checks)cat(x$id,x$status,x$detail,'\n');return(if(wf_all_pass(r$checks))'PASS' else if(any(vapply(r$checks,function(x)x$status=='ANALYSIS_DEFECT',logical(1))))'ANALYSIS_DEFECT' else 'TOOL_ERROR')}
  if(op=='finish')return(wf_finish(root,repo))
  if(op=='finalize')return(wf_finalize(root,repo))
  if(op=='status'){print(wf_manifest(root));return('RECORDED')}
  stop('Unknown operation')
}
if(!identical(Sys.getenv('WF_SOURCE_ONLY'),'1')) {
  outcome<-tryCatch(wf_main(commandArgs(TRUE)),error=function(e){cat(conditionMessage(e),'\n');'TOOL_ERROR'})
  cat(outcome,'\n');quit(status=if(outcome=='ANALYSIS_DEFECT')1L else if(outcome=='TOOL_ERROR')2L else 0L)
}
