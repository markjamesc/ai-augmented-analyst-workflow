# Helpers for local regression only. No synthetic review is accepted in live mode.
wf_test_load <- function(repo) {
  Sys.setenv(WF_REPO=normalizePath(repo,winslash='/'),WF_SOURCE_ONLY='1')
  source(file.path(repo,'procedure-gate/procedure_gate.R'),local=.GlobalEnv)
}
wf_test_approval <- function(root) {
  writeLines('SIMULATED OFFLINE OWNER: Approved for mechanical rehearsal only.',file.path(root,'evidence/owner.txt'))
  writeLines('SIMULATED OFFLINE REVIEW: accepted for mechanical tests only.',file.path(root,'reviews/design.txt'))
  h<-wf_hash(file.path(root,'design.json'))
  wf_write(list(owner='SIMULATED',approved=TRUE,simulated=TRUE,verbatim='Approved for mechanical rehearsal only.',contract_sha256=h,evidence=wf_ref(root,'evidence/owner.txt')),file.path(root,'owner_approval.json'))
  wf_write(list(reviewer='SIMULATED',accepted=TRUE,simulated=TRUE,contract_sha256=h,evidence=wf_ref(root,'reviews/design.txt')),file.path(root,'design_review.json'))
}
wf_test_finish <- function(root) {
  m<-wf_manifest(root);writeLines('SIMULATED OFFLINE FINISH REVIEW',file.path(root,'reviews/finish.txt'))
  paths<-vapply(m$validation$files,function(x)x$path,character(1));path<-paths[grepl('production/R-A/totals.csv$',paths)][1]
  f<-list(answer='Mechanical fixture: qualified B,C,E; selected C,B; sum 21.',limitations='OFFLINE mechanics only; no live AI behavior or real decision quality.',
    claims=list(list(text='Selected sum is 21.',type='descriptive',interpretation='Frozen synthetic selection rule.',evidence_paths=list(path))),
    exploratory_changes_decision=FALSE,safeguard_disposition='Static mechanical fixture; no inferential or predictive claims.')
  review<-list(accepted=TRUE,simulated=TRUE,content_sha256=wf_finish_content_hash(f),evidence=wf_ref(root,'reviews/finish.txt'))
  f$numerical_review<-review;f$inference_review<-review;wf_write(f,file.path(root,'finish.json'))
}
