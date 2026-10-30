a<-commandArgs(TRUE);repo<-normalizePath(if(length(a))a[1] else '.',winslash='/');source(file.path(repo,'methodology/tests/fixtures.R'));wf_test_load(repo)
root<-tempfile('procedure-test-');wf_init(root,'TEST','live');n<-0
reject<-function(x){stopifnot(inherits(try(force(x),silent=TRUE),'try-error'));n<<-n+1}
reject(wf_validate(root,repo));reject(wf_finish(root,repo));reject(wf_finalize(root,repo));reject(wf_init(root,'OTHER'))
reject(wf_approval(root,'missing.json','not-a-hash'))
cat('Procedure suite:',n,'/',n,'negative prerequisites passed\n')
