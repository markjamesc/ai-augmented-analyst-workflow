a<-commandArgs(TRUE);if(length(a)!=3)stop('Usage: inspect.R REPO PROJECT design|finish|validation')
repo<-normalizePath(a[1],winslash='/');root<-normalizePath(a[2],winslash='/');source(file.path(repo,'methodology/contracts.R'));source(file.path(repo,'methodology/tools.R'))
if(a[3]=='design'){d<-wf_read(file.path(root,'design.json'));e<-wf_design_errors(d,repo);wf_assert(!length(e),paste(e,collapse='; '));cat('DESIGN_SHA256',wf_hash(file.path(root,'design.json')),'\n');print(d)}
if(a[3]=='finish'){f<-wf_read(file.path(root,'finish.json'));cat('FINISH_CONTENT_SHA256',wf_finish_content_hash(f),'\n');print(f)}
if(a[3]=='validation'){m<-wf_manifest(root);print(wf_read(wf_path(root,m$validation$report$path)));cat('MANIFEST_SHA256',wf_hash(file.path(root,'run_manifest.json')),'\n')}
