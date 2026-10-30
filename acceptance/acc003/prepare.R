#!/usr/bin/env Rscript
args<-commandArgs(TRUE);wf_assert_unused<-NULL
if(length(args)<2)stop('Usage: prepare.R REPO NEW_PROJECT [live|offline]')
repo<-normalizePath(args[1],winslash='/');root<-args[2];mode<-if(length(args)>2)args[3] else 'live'
if(file.exists(root))stop('Project path already exists; choose a new one')
Sys.setenv(WF_REPO=repo,WF_SOURCE_ONLY='1');source(file.path(repo,'procedure-gate/procedure_gate.R'))
dir.create(root,recursive=TRUE);root<-normalizePath(root,winslash='/')
for(p in c('fixtures','data','analysis/r_a','analysis/r_b','evidence','reviews','pretests'))dir.create(file.path(root,p),recursive=TRUE,showWarnings=FALSE)
for(p in list.files(file.path(repo,'acceptance/acc003/fixtures'),full.names=TRUE))file.copy(p,file.path(root,'fixtures',basename(p)))
file.copy(file.path(root,'fixtures/F00.csv'),file.path(root,'data/fixture_8row.csv'))
d<-wf_read(file.path(repo,'templates/design.json'));d$run_id<-if(mode=='offline')'ACC003-OFFLINE' else 'ACC003'
wf_write(d,file.path(root,'design.json'))
view<-d;view$expected_primary<-NULL;view$fixtures<-NULL
wf_write(view,file.path(root,'builder_contract.json'))
writeBin(charToRaw(d$implementation_rules),file.path(root,'builder_spec.md'))
writeLines('SYNTHETIC STAKEHOLDER: accept or remediate the mechanical workflow. No real business decision; no deadline affects the rule.',file.path(root,'start.md'))
writeLines('One question: reproduce the frozen selection rule and detect planted defects. Eight synthetic rows; capacity two; no model.',file.path(root,'framing.md'))
builders<-setNames(lapply(c('R-A','R-B'),function(id) list(script=if(id=='R-A')'analysis/r_a/main.R' else 'analysis/r_b/main.R',service=if(id=='R-A')'ChatGPT' else 'DeepSeek',model='RECORD_ACTUAL_MODEL',chat_id=paste0('RECORD_ACTUAL_CHAT_',id),input_files=list('builder_contract.json','builder_spec.md','data/fixture_8row.csv'),declaration=paste0('evidence/',id,'-independence.json'))),c('R-A','R-B'))
wf_write(list(builders=builders),file.path(root,'builders.json'))
if(mode=='offline') {
 for(id in names(builders)) {
  b<-builders[[id]];file.copy(file.path(repo,'acceptance/acc003/reference',if(id=='R-A')'r_a.R' else 'r_b.R'),wf_path(root,b$script))
  b$model<-'OFFLINE_REFERENCE';b$chat_id<-paste0('OFFLINE-',id);builders[[id]]<-b
  wf_write(list(builder=id,independent=TRUE,peer_solution_seen=FALSE,basis='SIMULATED process record for mechanical rehearsal; reference implementations are not fresh live AI builds.',simulated=TRUE),wf_path(root,b$declaration))
 }
 wf_write(list(builders=builders),file.path(root,'builders.json'))
}
wf_init(root,d$run_id,mode);cat('PREPARED',root,mode,'\n')
