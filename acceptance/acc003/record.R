# Thin recorder for actual reviewed evidence. Never invents an AI/human response.
a<-commandArgs(TRUE);if(length(a)<3)stop('Usage: record.R REPO ROOT ACTION ...')
repo<-normalizePath(a[1],winslash='/');root<-normalizePath(a[2],winslash='/');action<-a[3]
source(file.path(repo,'methodology/contracts.R'));source(file.path(repo,'methodology/tools.R'))
copy_evidence<-function(p,label) {
 wf_assert(file.exists(p),'Evidence file missing');h<-wf_hash(p);rel<-paste0('evidence/',label,'-',h,'.txt');dst<-wf_path(root,rel)
 if(!file.exists(dst))wf_assert(file.copy(p,dst),'Cannot copy evidence');wf_ref(root,rel)
}
if(action=='design-review') {
 # Invoke only after the coordinator has read an explicit accepting independent review.
 e<-copy_evidence(a[4],'design-review');wf_assert(wf_text(a[5]),'Reviewer required')
 wf_write(list(accepted=TRUE,reviewer=a[5],simulated=FALSE,contract_sha256=wf_hash(file.path(root,'design.json')),evidence=e),file.path(root,'design_review.json'))
} else if(action=='owner-approval') {
 e<-copy_evidence(a[4],'owner-approval');verbatim<-a[5];text<-paste(readLines(wf_path(root,e$path),warn=FALSE),collapse='\n')
 wf_assert(wf_text(verbatim)&&grepl(verbatim,text,fixed=TRUE),'Exact owner reply must occur in evidence')
 wf_write(list(owner='Mark Ciganovic',approved=TRUE,simulated=FALSE,verbatim=verbatim,contract_sha256=wf_hash(file.path(root,'design.json')),evidence=e),file.path(root,'owner_approval.json'))
} else if(action=='builder') {
 # args: id extracted-R-file exact-reply-file model chat-id exact-prompt-file
 id<-a[4];wf_assert(id%in%c('R-A','R-B') && length(a)>=9,'builder needs ID, code, reply, model, chat, prompt')
 m<-wf_manifest(root);wf_assert(!is.null(m$lock),'Owner lock required before live building')
 cfg<-wf_read(file.path(root,'builders.json'));b<-cfg$builders[[id]]
 reply<-copy_evidence(a[6],paste0(id,'-reply'));prompt<-copy_evidence(a[9],paste0(id,'-prompt'))
 code<-wf_path(root,b$script);dir.create(dirname(code),recursive=TRUE,showWarnings=FALSE)
 if(file.exists(code)) {
  archive<-file.path(root,'evidence',paste0(id,'-code-',wf_hash(code),'.R'))
  if(!file.exists(archive))wf_assert(file.copy(code,archive),'Cannot preserve previous code')
 }
 wf_assert(file.copy(a[5],code,overwrite=TRUE),'Code copy failed')
 b$model<-a[7];b$chat_id<-a[8];b$input_files<-as.list(unique(c(unlist(b$input_files),prompt$path,reply$path)))
 # The declaration must reflect actual dispatch, not merely the model's claim.
 wf_write(list(builder=id,independent=TRUE,peer_solution_seen=FALSE,simulated=FALSE,
   basis='Coordinator attests exact attached prompt/input files; no peer code or result supplied. Override to false if any exposure occurred.',reply=reply,prompt=prompt),wf_path(root,b$declaration))
 cfg$builders[[id]]<-b;wf_write(cfg,file.path(root,'builders.json'))
} else if(action=='finish-review') {
 role<-a[4];wf_assert(role%in%c('numerical_review','inference_review'),'Unknown Finish review role')
 e<-copy_evidence(a[5],role);f<-wf_read(file.path(root,'finish.json'))
 f[[role]]<-list(accepted=TRUE,simulated=FALSE,content_sha256=wf_finish_content_hash(f),evidence=e)
 wf_write(f,file.path(root,'finish.json'))
} else if(action=='repair') {
 wf_assert(length(a)>=6,'repair needs defect-id, SUCCESS|UNSUCCESSFUL, evidence file')
 m<-wf_manifest(root);e<-copy_evidence(a[6],'repair');wf_assert(a[5]%in%c('SUCCESS','UNSUCCESSFUL'),'Invalid repair result')
 event<-list(defect_id=a[4],result=a[5],evidence=e)
 m$repairs<-c(m$repairs,list(event));wf_save_manifest(m,root)
 failed<-sum(vapply(m$repairs,function(x)x$defect_id==a[4]&&x$result=='UNSUCCESSFUL',logical(1)))
 if(failed>=3 && a[5]=='UNSUCCESSFUL'){cat('ESCALATE_TO_OWNER: three unsuccessful repairs of same defect. Not an analytical verdict.\n');quit(status=2L)}
} else stop('Unknown record action')
cat('RECORDED',action,'\n')
