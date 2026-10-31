#!/usr/bin/env Rscript
# Targeted gate changes (2026-10-31). T1,T2,T4-T8,T10 removed with their rules (P01-P13 cut, owner card t1651s6906); R1 review coverage added. Each change: old false failure now passes AND the real defect still fails. Synthetic only.
repo_root<-normalizePath(if(length(commandArgs(TRUE)))commandArgs(TRUE)[[1]] else ".")
source(file.path(repo_root,"methodology/tests/fixtures.R"))
env<-new.env(parent=globalenv());lines<-readLines(file.path(repo_root,"workflow-gate/tests/test_workflow_gate.R"));eval(parse(text=lines[seq_len(grep('^pass_root <-',lines)[[1]]-1L)]),env)
root<-tempfile("targeted-");dir.create(root);env$write_project(root)
results<-list();check<-function(name,value){ok<-isTRUE(value);results[[name]]<<-ok;cat(if(ok)"PASS" else "FAIL",name,"\n")}
fails<-function(chk,pat) any(vapply(chk,function(x) grepl(pat,x$check,fixed=TRUE) && x$result!="PASS",logical(1)))
# T3 / C3: peer receipts are never inherited as dependencies.
s3<-m_read(file.path(root,"artifacts/stage3_locked_design.json"));s4<-m_read(file.path(root,"artifacts/stage4_validation_status.json"))
roles<-names(s4$evidence_receipts);role<-roles[[1]];peer<-s4$evidence_receipts[[roles[[2]]]]$path
check("T3 baseline execution passes",!fails(m_execution(s3,s4,root),"dependencies"))
y<-s3;y$methodology$receipt_dependencies[[role]]<-c(y$methodology$receipt_dependencies[[role]],list(peer))
check("T3 locked list naming a peer receipt no longer forces receipt to inherit it",!fails(m_execution(y,s4,root),paste("dependencies",role)))
rp<-file.path(root,s4$evidence_receipts[[role]]$path);r0<-m_read(rp)
r<-r0;r$dependencies<-c(r$dependencies,list(m_file_ref(peer,root)));t_write(root,s4$evidence_receipts[[role]]$path,r)
s4b<-s4;s4b$evidence_receipts[[role]]<-m_file_ref(s4$evidence_receipts[[role]]$path,root)
check("T3 receipt listing a peer receipt fails",fails(m_execution(s3,s4b,root),paste("dependencies",role)))
r<-r0;r$dependencies<-r$dependencies[-1];t_write(root,s4$evidence_receipts[[role]]$path,r);s4b$evidence_receipts[[role]]<-m_file_ref(s4$evidence_receipts[[role]]$path,root)
check("T3 receipt missing a real dependency still fails",fails(m_execution(s3,s4b,root),paste("dependencies",role)))
t_write(root,s4$evidence_receipts[[role]]$path,r0)
# Operations ledger for the execution stage.
now<-format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC")
t_write(root,"artifacts/procedure/checks/execution-begin.json",list(step="execution",phase="begin",result="PASS",checked_at_utc=now))
state<-list(run_id="SYNTHETIC",current_step="execution",current_authorization=m_file_ref("artifacts/procedure/checks/execution-begin.json",root))
t_write(root,"artifacts/procedure/run_state.json",state);t_operations(root,"execution")
op<-"artifacts/operations/execution.json";o<-m_read(file.path(root,op));s<-o$sends[[1]]
run<-function(x){t_write(root,op,x);r<-m_operations(root,state,"execution");t_write(root,op,o);r}
check("baseline execution ledger passes",m_pass(run(o)))
# T9 / C9: supersedes ref to a never-sent packet with an abbreviated hash, resolved via a deviation record holding the full hash.
t_write(root,"packets/old/packet.json",list(send_id="OLD",note="never sent"));oh<-m_file_ref("packets/old/packet.json",root)$sha256
s9<-function(dev=list(path="packets/old/packet.json",sha256=oh,never_sent=TRUE),abbr=paste0(substr(oh,1,16)," (full hash in deviation record)"),nsent=TRUE,usedev=TRUE){
  x<-o;x$sends[[1]]$supersedes<-list(path="packets/old/packet.json",sha256=abbr)
  if(usedev){t_write(root,"deviations/dev9.json",dev);x$supersession_resolutions<-list(list(path="packets/old/packet.json",never_sent=nsent,deviation_record=m_file_ref("deviations/dev9.json",root)))};x}
cl<-"operations evidence closure"
check("T9 baseline abbreviated supersedes without resolution fails closure",fails(run(s9(usedev=FALSE)),cl))
check("T9 resolved via deviation record full hash now passes",!fails(run(s9()),cl) && !fails(run(s9()),"supersession resolutions"))
check("T9 wrong full hash in deviation record fails",fails(run(s9(dev=list(path="packets/old/packet.json",sha256=paste0(substr(oh,1,16),strrep("0",48)),never_sent=TRUE))),cl))
check("T9 missing full hash in deviation record fails",fails(run(s9(dev=list(path="packets/old/packet.json",never_sent=TRUE))),cl))
check("T9 deviation hash not matching abbreviation fails",fails(run(s9(abbr=strrep("f",16))),cl))
check("T9 too-short abbreviation fails",fails(run(s9(abbr=substr(oh,1,8))),cl))
check("T9 resolution not marked never-sent fails",fails(run(s9(nsent=FALSE)),cl))
x<-s9();x$supersession_resolutions[[1]]$path<-x$sends[[1]]$packet$path;check("T9 resolution naming a sent packet fails",fails(run(x),"supersession resolutions"))
# T11 / C11: procedure-gate evidence closure (complete/amend/finalize) applies the same C9 resolutions as m_operations.
pg<-new.env(parent=globalenv());sys.source(file.path(repo_root,"procedure-gate/procedure_gate.R"),envir=pg)
for(f in c("m_inventory","m_refs","m_read","m_ref_ok"))assign(f,get(f),envir=pg)
rc11<-list(stage=4,note="T11 receipt")
c11<-function(x){t_write(root,op,x);r<-pg$step_closure(root,"execution",rc11);t_write(root,op,o);r}
check("T11 baseline abbreviated supersedes without resolution fails procedure closure",is.null(c11(s9(usedev=FALSE))))
check("T11 resolved via deviation record now passes procedure closure (agrees with m_operations)",!is.null(c11(s9())) && !fails(run(s9()),cl))
check("T11 wrong full hash in deviation record fails procedure closure",is.null(c11(s9(dev=list(path="packets/old/packet.json",sha256=paste0(substr(oh,1,16),strrep("0",48)),never_sent=TRUE)))))
check("T11 resolution not marked never-sent fails procedure closure",is.null(c11(s9(nsent=FALSE))))
x<-s9();x$sends[[1]]$packet$sha256<-strrep("0",64);check("T11 other stale ref still fails procedure closure",is.null(c11(x)))
x<-s9();x$sends[[1]]$supersedes<-list(path=x$sends[[1]]$packet$path,sha256=substr(x$sends[[1]]$packet$sha256,1,16));x$supersession_resolutions[[1]]$path<-x$sends[[1]]$packet$path
t_write(root,"deviations/dev9.json",list(path=x$sends[[1]]$packet$path,sha256=x$sends[[1]]$packet$sha256,never_sent=TRUE))
check("T11 resolution naming a sent packet is not applied by procedure closure",{t_write(root,op,s9());n1<-length(pg$closure_resolutions(root,"execution"));t_write(root,op,o);n1==1L} && {t_write(root,op,x);n<-length(pg$closure_resolutions(root,"execution"));t_write(root,op,o);n==0L})
src<-readLines(file.path(repo_root,"procedure-gate/procedure_gate.R"))
check("T11 complete and amend use step_closure; finalize passes resolutions",sum(grepl("closure <- step_closure(project_root, step_id, receipt)",src,fixed=TRUE))==2L && any(grepl("closure_resolutions(project_root,required)",src,fixed=TRUE)) && !any(grepl("paste0(step_id,\".json\"))))),project_root),error",src,fixed=TRUE)))
# R1 (option B): review coverage. Positive and negative cases, derived from roles and receipt-reached replies (synthetic).
rv<-function(stage,receipt_extra=NULL){t_write(root,"artifacts/procedure/run_state.json",list(run_id="SYNTHETIC",current_step=stage))
  rp<-unname(m_stage_receipts[stage]);r0<-m_read(file.path(root,rp))
  if(!is.null(receipt_extra)){r<-r0;for(k in names(receipt_extra))r[[k]]<-receipt_extra[[k]];t_write(root,rp,r)}
  t_operations(root,stage);list(stage=stage,o=m_read(file.path(root,"artifacts/operations",paste0(stage,".json"))),rp=rp,r0=r0)}
rvrun<-function(R,x){p<-file.path("artifacts/operations",paste0(R$stage,".json"));t_write(root,p,x);m_operations(root,list(run_id="SYNTHETIC",current_step=R$stage),R$stage)}
F<-rv("finish",list(cross_review="PASS"));fo<-F$o
check("R1 finish: all four required reviews captured passes",m_pass(rvrun(F,fo)))
for(i in seq_along(fo$sends)){x<-fo;role<-x$sends[[i]]$role;x$sends<-x$sends[-i]
  check(paste("R1 finish: dropped",role,"send fails"),fails(rvrun(F,x),paste("review coverage finish role",role)))}
x<-fo;x$sends[[2]]$reply<-x$sends[[1]]$reply;cp<-x$sends[[2]]$capture$path;c<-m_read(file.path(root,cp));c$reply<-x$sends[[1]]$reply;t_write(root,cp,c);x$sends[[2]]$capture<-m_file_ref(cp,root)
r6<-rvrun(F,x);check("R1 stale reply reused with consistent hashes fails (marker + distinct)",fails(r6,paste("review coverage finish role",fo$sends[[2]]$role)) && fails(r6,"review coverage finish distinct replies"))
c$reply<-fo$sends[[2]]$reply;t_write(root,cp,c)
x<-fo;c2<-m_read(file.path(root,x$sends[[3]]$capture$path));c2$send_id<-"OTHER";t_write(root,"captures/finish/wrong.json",c2);x$sends[[3]]$capture<-m_file_ref("captures/finish/wrong.json",root)
check("R1 capture record for another send fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[3]]$role)))
x<-fo;c2<-m_read(file.path(root,x$sends[[3]]$capture$path));c2$capture_sha256<-strrep("0",64);t_write(root,"captures/finish/hash.json",c2);x$sends[[3]]$capture<-m_file_ref("captures/finish/hash.json",root)
check("R1 capture hash not equal to reply bytes fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[3]]$role)))
x<-fo;rr<-t_file(root,"transcripts/finish/nomarker_reply.txt","Reply without its end marker");x$sends[[1]]$reply<-rr;c2<-m_read(file.path(root,x$sends[[1]]$capture$path));c2$reply<-rr;t_write(root,"captures/finish/nm.json",c2);x$sends[[1]]$capture<-m_file_ref("captures/finish/nm.json",root)
check("R1 reply missing END_REPLY marker fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[1]]$role)))
# receipt-reached reply with no send (role-agnostic requirement)
x<-fo;ex<-x$sends[[4]];ex$id<-"finish-extra";ex$role<-"extra_reviewer";ex$nonce<-"TEST-extra";er<-t_file(root,"transcripts/finish/finish-extra_reply.txt","Extra\nEND_REPLY finish-extra TEST-extra")
r<-m_read(file.path(root,F$rp));r$extra_review<-er;t_write(root,F$rp,r)
check("R1 receipt-reached reply with no ledger send fails",fails(rvrun(F,fo),"review coverage finish reply transcripts/finish/finish-extra_reply.txt"))
ex$reply<-er;t_write(root,"captures/finish/extra.json",list(send_id=ex$id,nonce=ex$nonce,reply=er,capture_sha256=er$sha256));ex$capture<-m_file_ref("captures/finish/extra.json",root);x$sends<-c(x$sends,list(ex))
x$sends<-lapply(x$sends,function(z){z$attachments<-list(m_file_ref(F$rp,root));z})  # reviews re-run on the amended receipt
check("R1 receipt-reached reply with its captured send passes",m_pass(rvrun(F,x)))
x$sends<-c(x$sends,list(ex));check("R1 two sends claiming one required reply fails",fails(rvrun(F,x),"review coverage finish reply transcripts/finish/finish-extra_reply.txt"))
t_write(root,F$rp,F$r0)
D<-rv("design");do<-D$o;check("R1 design: required roles captured passes",m_pass(rvrun(D,do)))
x<-do;x$sends<-x$sends[-2];check("R1 design: missing designer_b fails",fails(rvrun(D,x),"review coverage design role designer_b"))
t_write(root,D$rp,D$r0)
S<-rv("start");x<-S$o;x$sends<-list();check("R1 start: empty ledger fails",fails(rvrun(S,x),"operations ledger start"))
s3x<-m_read(file.path(root,"artifacts/stage3_locked_design.json"));s3o<-s3x;s3x$methodology$structural_review$policy<-"required";t_write(root,"artifacts/stage3_locked_design.json",s3x)
E4<-rv("execution");check("R1 execution: structural reviewer captured passes when required",m_pass(rvrun(E4,E4$o)))
x<-E4$o;x$sends<-Filter(function(z)!identical(z$role,"structural reviewer"),x$sends);check("R1 execution: missing structural reviewer fails when locked plan requires it",fails(rvrun(E4,x),"review coverage execution role structural reviewer"))
t_write(root,"artifacts/stage3_locked_design.json",s3o)
# F1-F6 (review RV-D1/RV-C1 combined fix list)
S<-rv("start");check("F1 start: required roles captured passes",m_pass(rvrun(S,S$o)))
x<-S$o;x$sends<-Filter(function(z)!identical(z$role,"red_team"),x$sends);check("F1 start: missing red_team fails",fails(rvrun(S,x),"review coverage start role red_team"))
t_write(root,S$rp,S$r0)
Fr<-rv("framing");check("F1 framing: required roles captured passes",m_pass(rvrun(Fr,Fr$o)))
for(rl in c("framing_builder","decision_fit_review","framing_red_team")){x<-Fr$o;x$sends<-Filter(function(z)!identical(z$role,rl),x$sends)
  check(paste("F1 framing: missing",rl,"fails"),fails(rvrun(Fr,x),paste("review coverage framing role",rl)))}
t_write(root,Fr$rp,Fr$r0)
F<-rv("finish",list(cross_review="PASS"));fo<-F$o
x<-fo;c2<-m_read(file.path(root,x$sends[[2]]$capture$path));c2$capture_sha256<-NULL;t_write(root,"captures/finish/nosha.json",c2);x$sends[[2]]$capture<-m_file_ref("captures/finish/nosha.json",root)
check("F2 capture record without capture_sha256 fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[2]]$role)))
x<-fo;x$sends[[2]]$id<-x$sends[[1]]$id;check("F3 duplicate send id fails",fails(rvrun(F,x),"review coverage finish unique send ids"))
x<-fo;x$sends[[2]]$nonce<-x$sends[[1]]$nonce;check("F3 duplicate nonce fails",fails(rvrun(F,x),"review coverage finish unique send ids"))
pv<-lapply(fo$sends[1:3],function(z)list(role=z$role,provider=z$ai,output=z$reply))
F<-rv("finish",list(cross_review="PASS",ai_provenance=pv));fo<-F$o
check("F4 sends matching recorded provenance pass",m_pass(rvrun(F,fo)))
x<-fo;r1<-x$sends[[1]]$role;x$sends[[1]]$role<-x$sends[[2]]$role;x$sends[[2]]$role<-r1
check("F4 swapped role labels (provenance mismatch) fails",fails(rvrun(F,x),paste("review coverage finish role",r1)))
x<-fo;x$sends[[1]]$ai<-"other-ai";check("F4 send AI differs from provenance provider fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[1]]$role)))
t_write(root,F$rp,F$r0);F<-rv("finish",list(cross_review="PASS"));fo<-F$o
x<-fo;x$sends[[3]]$attachments<-list();check("F5 review with no attachments fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[3]]$role)))
x<-fo;st<-t_file(root,"inputs/old_copy.txt","stale");x$sends[[3]]$attachments<-list(st);check("F5 review that saw no reached artifact fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[3]]$role)))
x<-fo;a<-x$sends[[3]]$attachments[[1]];a$sha256<-strrep("0",64);x$sends[[3]]$attachments<-list(a);check("F5 review that saw a superseded receipt fails",fails(rvrun(F,x),paste("review coverage finish role",fo$sends[[3]]$role)))
er<-t_file(root,"transcripts/finish/late_reply.md","Late\nEND_REPLY late x");r<-m_read(file.path(root,F$rp));r$late_review<-er;t_write(root,F$rp,r)
check("F6 receipt-reached _reply.md with no send fails",fails(rvrun(F,fo),"review coverage finish reply transcripts/finish/late_reply.md"))
t_write(root,F$rp,F$r0)
er<-t_file(root,"transcripts/finish/late_reply.txt.bak","Late\nEND_REPLY late x");r<-m_read(file.path(root,F$rp));r$late_review<-er;t_write(root,F$rp,r)
check("F6 receipt-reached _reply.txt.bak with no send fails",fails(rvrun(F,fo),"review coverage finish reply transcripts/finish/late_reply.txt.bak"))
t_write(root,F$rp,F$r0)
cat(sum(unlist(results)),"/",length(results),"targeted gate tests passed\n")
if(!all(unlist(results)))quit(status=1)
