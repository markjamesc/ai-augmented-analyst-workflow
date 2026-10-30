a<-commandArgs(TRUE);if(length(a)!=3)stop('Usage: reuse_pretest.R REPO PROJECT EXISTING_PRETEST_DIRECTORY')
repo<-normalizePath(a[1],winslash='/');root<-normalizePath(a[2],winslash='/');src<-normalizePath(a[3],winslash='/')
source(file.path(repo,'methodology/contracts.R'));source(file.path(repo,'methodology/tools.R'));source(file.path(repo,'acceptance/acc003/pretest.R'))
d<-wf_read(file.path(root,'design.json'));p<-wf_read(file.path(src,'pretest.json'))
wf_assert(p$status=='PASS'&&identical(p$identity,wf_identity(repo,d))&&wf_refs_ok(src,p$evidence)&&setequal(unlist(p$passed_cases),wf_pretest_case_ids()),'Pretest no longer applies; run affected pretests on the changed configuration')
rel<-paste0('pretests/reused-',wf_hash(file.path(src,'pretest.json')));dst<-wf_path(root,rel)
dir.create(dst,recursive=TRUE,showWarnings=FALSE)
for(f in c('pretest.json',vapply(p$evidence,function(x)x$path,character(1)))) {
 dest<-wf_path(dst,f);dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)
 if(!file.exists(dest))wf_assert(file.copy(wf_path(src,f),dest),'Copy failed')
 wf_assert(identical(wf_hash(wf_path(src,f)),wf_hash(dest)),'Pretest copy differs')
}
cfg<-wf_read(file.path(root,'builders.json'));cfg$pretest<-wf_ref(root,paste0(rel,'/pretest.json'));wf_write(cfg,file.path(root,'builders.json'))
cat('PRETEST_REUSED: unchanged checker/configuration/environment.\n')
