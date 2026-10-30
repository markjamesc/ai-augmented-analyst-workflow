a<-commandArgs(TRUE);repo<-normalizePath(if(length(a))a[1] else '.',winslash='/');source(file.path(repo,'methodology/contracts.R'));source(file.path(repo,'methodology/tools.R'))
stopifnot(!wf_all_pass(list()),!wf_all_pass(list(wf_result('x','TOOL_ERROR','crash'))),!wf_all_pass(list(wf_result('x','ANALYSIS_DEFECT','wrong'))),wf_all_pass(list(wf_result('x','PASS','good'))))
p<-tempfile('hash-test-');dir.create(p);writeLines('original',file.path(p,'x'));r<-wf_ref(p,'x');stopifnot(wf_ref_ok(p,r));writeLines('changed',file.path(p,'x'));stopifnot(!wf_ref_ok(p,r),!wf_ref_ok(p,list(path='../x',sha256=r$sha256)))
cat('Workflow suite: 7/7 result and identity checks passed\n')
