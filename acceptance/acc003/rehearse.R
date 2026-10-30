a<-commandArgs(TRUE);if(length(a)!=2)stop('Usage: rehearse.R REPO NEW_PROJECT')
repo<-normalizePath(a[1],winslash='/');root<-a[2]
rbin<-file.path(R.home('bin'),if(.Platform$OS.type=='windows')'Rscript.exe' else 'Rscript')
status<-system2(rbin,c('--vanilla',shQuote(file.path(repo,'acceptance/acc003/prepare.R')),shQuote(repo),shQuote(root),'offline'))
stopifnot(status==0L)
source(file.path(repo,'methodology/tests/fixtures.R'));wf_test_load(repo)
wf_test_approval(root);stopifnot(wf_lock(root,repo)=='LOCKED')
d<-wf_read(file.path(root,'design.json'));p<-tempfile('pretest-',tmpdir=file.path(root,'pretests'));pre<-wf_pretest(repo,d,p);stopifnot(pre$status=='PASS')
cfg<-wf_read(file.path(root,'builders.json'));cfg$pretest<-wf_ref(root,paste0('pretests/',basename(p),'/pretest.json'));wf_write(cfg,file.path(root,'builders.json'))
# One deliberate checker crash, preserved. Other independent checks may still complete.
fail<-wf_validate(root,repo,TRUE);stopifnot(any(vapply(fail$checks,function(x)x$id=='fixtures'&&x$status=='TOOL_ERROR',logical(1))))
stopifnot(inherits(try(wf_finalize(root,repo),silent=TRUE),'try-error'))
# Recovery reruns actual checks with the same frozen inputs and checker.
ok<-wf_validate(root,repo);stopifnot(wf_all_pass(ok$checks));wf_test_finish(root)
stopifnot(wf_finish(root,repo)=='FINISH_RECORDED',wf_finalize(root,repo)=='CERTIFIED')
cat('OFFLINE_REHEARSAL_PASS: five stages, checker-fault recovery, synthetic SQL good/bad controls, fixtures, invariance and certification.\n')
cat('Not a live three-AI acceptance result. Evidence:',normalizePath(root,winslash='/'),'\n')
