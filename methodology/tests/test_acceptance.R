a<-commandArgs(TRUE);repo<-normalizePath(if(length(a))a[1] else '.',winslash='/');root<-tempfile('acc003-acceptance-',tmpdir=if(nzchar(Sys.getenv('WF_TEST_EVIDENCE'))) Sys.getenv('WF_TEST_EVIDENCE') else tempdir())
r<-file.path(R.home('bin'),if(.Platform$OS.type=='windows')'Rscript.exe' else 'Rscript')
code<-system2(r,c('--vanilla',shQuote(file.path(repo,'acceptance/acc003/rehearse.R')),shQuote(repo),shQuote(root)))
stopifnot(code==0L);cat('Acceptance suite: PASS\n')
# Direct evidence/gate regression on the completed offline run; preserve mutation artifacts.
source(file.path(repo,'methodology/tests/fixtures.R'));wf_test_load(repo)
results<-list();test<-function(n,x){results[[n]]<<-isTRUE(x);cat(n,if(isTRUE(x))'PASS' else 'FAIL','\n')}
rejected<-function(expr)inherits(try(force(expr),silent=TRUE),'try-error')
m<-wf_manifest(root);test('current good evidence accepted',isTRUE(wf_current(root,repo,m)))
x<-m;x$environment$r<-'0.0';test('runtime drift rejected',rejected(wf_current(root,repo,x)))
x<-m;x$validation$files[[1]]$sha256<-paste(rep('0',64),collapse='');test('stale evidence rejected',rejected(wf_current(root,repo,x)))
x<-m;x$engine[[1]]$sha256<-paste(rep('0',64),collapse='');test('checker/code drift rejected',rejected(wf_current(root,repo,x)))
rp<-wf_path(root,m$validation$report$path);orig<-readBin(rp,'raw',file.info(rp)$size);rpt<-wf_read(rp)
for(kind in c('missing_check','tool_error','defect','duplicate_check','wrong_run')) {
 q<-rpt
 if(kind=='missing_check')q$checks<-q$checks[-1]
 if(kind=='tool_error')q$checks[[1]]$status<-'TOOL_ERROR'
 if(kind=='defect')q$checks[[1]]$status<-'ANALYSIS_DEFECT'
 if(kind=='duplicate_check')q$checks<-c(q$checks,q$checks[1])
 if(kind=='wrong_run')q$run_id<-'OTHER'
 wf_write(q,rp);x<-m;x$validation$report<-wf_ref(root,m$validation$report$path)
 x$validation$files<-lapply(x$validation$files,function(ref)if(ref$path==m$validation$report$path)x$validation$report else ref)
 test(paste(kind,'rejected'),rejected(wf_current(root,repo,x)))
 wf_write(q,file.path(root,'evidence',paste0('negative-',kind,'.json')))
 writeBin(orig,rp)
}
fp<-file.path(root,'finish.json');origf<-readBin(fp,'raw',file.info(fp)$size);f<-wf_read(fp)
f$answer<-'Unreviewed changed conclusion';wf_write(f,fp);test('unreviewed Finish change rejected',rejected(wf_finish(root,repo)));writeBin(origf,fp)
f<-wf_read(fp);f$claims[[1]]$type<-'causal';wf_write(f,fp);test('claim ceiling enforced',rejected(wf_finish(root,repo)));writeBin(origf,fp)
f<-wf_read(fp);f$exploratory_changes_decision<-TRUE;wf_write(f,fp);test('exploratory override rejected',rejected(wf_finish(root,repo)));writeBin(origf,fp)
test('restored good evidence accepted',isTRUE(wf_current(root,repo,wf_manifest(root))))
# Config/pretest report no longer matches after a locked comparison change.
d<-wf_read(file.path(root,'design.json'));id<-wf_identity(repo,d);d$checkpoints[[1]]$file<-'different.csv';test('pretest configuration fingerprint changes',!identical(id,wf_identity(repo,d)))
# Actual wrong builder, not simulated AI: change the selected sum in a copy of accepted R-A.
cfgp<-file.path(root,'builders.json');origcfg<-readBin(cfgp,'raw',file.info(cfgp)$size);cfg<-wf_read(cfgp)
badcode<-file.path(root,'analysis/r_a/wrong_sum.R')
writeLines(c("a<-commandArgs(TRUE)",sprintf("code<-system2(file.path(R.home('bin'),if(.Platform$OS.type=='windows')'Rscript.exe' else 'Rscript'),c('--vanilla',shQuote(%s),shQuote(a[1]),shQuote(a[2])))",paste(deparse(wf_path(root,cfg$builders[['R-A']]$script)),collapse='')),
 "if(code!=0)quit(status=code)","p<-file.path(a[2],'totals.csv');x<-read.csv(p,colClasses='character',na.strings=character());if(nrow(x)>0){x$selected_sum[1]<-'999';write.csv(x,p,row.names=FALSE,na='NA')}"),badcode)
cfg$builders[['R-A']]$script<-'analysis/r_a/wrong_sum.R';wf_write(cfg,cfgp)
bad<-wf_validate(root,repo);test('executed wrong sum rejected by fixtures and reconciliation',all(vapply(Filter(function(x)x$id%in%c('fixtures','reconciliation'),bad$checks),function(x)x$status=='ANALYSIS_DEFECT',logical(1))))
# Preserve bad attempt/config/code; restore entry config only so the project is not silently certified.
file.copy(cfgp,file.path(root,'evidence/wrong-builder-config.json'));writeBin(origcfg,cfgp)
wf_write(results,file.path(root,'negative-test-results.json'))
cat('Extended acceptance:',sum(unlist(results)),'/',length(results),'passed\n')
if(!all(unlist(results)))stop('Extended acceptance regression failed')
# End the offline project with current good evidence after the retained negative attempt.
recovered<-wf_validate(root,repo);stopifnot(wf_all_pass(recovered$checks))
wf_test_finish(root);stopifnot(wf_finish(root,repo)=='FINISH_RECORDED')
Sys.unsetenv('WF_SOURCE_ONLY')
gate_log<-file.path(root,'native-workflow-gate.log')
code<-system2(r,c('--vanilla',shQuote(file.path(repo,'workflow-gate/workflow_gate.R')),shQuote(root)),stdout=gate_log,stderr=gate_log)
stopifnot(code==0L,any(trimws(readLines(gate_log))=='PASS'))
cert_log<-file.path(root,'native-finalize.log')
code<-system2(r,c('--vanilla',shQuote(file.path(repo,'procedure-gate/procedure_gate.R')),'finalize',shQuote(root)),stdout=cert_log,stderr=cert_log)
stopifnot(code==0L,any(trimws(readLines(cert_log))=='CERTIFIED'))
cat('Native Workflow Gate and finalize CLI: 2/2 passed; final offline state recovered.\n')
