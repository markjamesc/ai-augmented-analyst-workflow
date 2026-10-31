#!/usr/bin/env Rscript
# Targeted gate changes C1-C5 (2026-10-31). Each change: old false failure now passes AND the real defect still fails. Synthetic only.
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
# T1 / C1: byte-exact copy-button capture.
cap<-m_read(file.path(root,s$capture$path))
bind<-t_write_ref<-function(path,x){t_write(root,path,x);m_file_ref(path,root)}
b<-bind("captures/execution-binding.json",list(send_id=s$id,nonce=s$nonce,reply=s$reply,capture_sha256=s$reply$sha256,captured_at_utc=now))
copycap<-function(c2){x<-o;x$sends[[1]]$capture<-bind("captures/execution-copy.json",c2);x}
c2<-cap;c2$capture_method<-"browser_copy_button";c2$capture_sha256<-s$reply$sha256;c2$capture_evidence<-b;c2$screen_verified<-NULL
check("T1 copy-button capture bound by sha256 now passes",m_pass(run(copycap(c2))))
c3<-c2;c3$capture_sha256<-paste(rep("0",64),collapse="");check("T1 capture hash != reply bytes fails",fails(run(copycap(c3)),"capture match"))
c3<-c2;c3$capture_evidence<-bind("captures/execution-binding2.json",list(send_id="other",nonce=s$nonce,reply=s$reply,capture_sha256=s$reply$sha256,captured_at_utc=now))
check("T1 binding record for another send fails",fails(run(copycap(c3)),"capture match"))
c3<-c2;c3$capture_evidence<-bind("captures/execution-binding3.json",list(send_id=s$id,nonce=s$nonce,reply=s$reply,capture_sha256=s$reply$sha256,captured_at_utc="2020-01-01T00:00:00Z"))
check("T1 binding captured before send fails",fails(run(copycap(c3)),"capture match"))
c3<-c2;c3$capture_evidence<-"parent-attested plain string";check("T1 unbound string evidence fails",fails(run(copycap(c3)),"capture match"))
c3<-cap;c3$capture_method<-"clipboard_guess";check("T1 unknown method still fails",fails(run(copycap(c3)),"capture match"))
# T2 / C2: review and tool_repair sends without locked builder sections.
p<-m_read(file.path(root,s$packet$path));att<-t_file(root,"inputs/reviewed.R","x <- 1")
mk<-function(kind,pp,a=list(att)){pp$attachments<-a;t_write(root,"packets/execution-k.json",pp);x<-o;x$sends[[1]]$packet<-m_file_ref("packets/execution-k.json",root);x$sends[[1]]$attachments<-a;x$sends[[1]]$send_kind<-kind
  c4<-cap;c4$packet<-x$sends[[1]]$packet;x$sends[[1]]$capture<-bind("captures/execution-k.json",c4);x}
lean<-p[setdiff(names(p),c("output_rules","checkpoint_output_rules","checkpoints","receipt_dependencies","accepted_code"))]
check("T2 review send without locked sections now passes",m_pass(run(mk("review",lean))))
check("T2 tool_repair send without locked sections now passes",m_pass(run(mk("tool_repair",lean))))
check("T2 builder send without locked sections still fails",fails(run(mk("builder",lean)),"execution packet completeness"))
check("T2 missing send_kind fails",fails(run(mk(NULL,lean)),"execution packet completeness"))
check("T2 review with no attached inputs fails",fails(run(mk("review",lean,list())),"execution packet completeness"))
pa<-lean;pa$accepted_code<-list(att);check("T2 review carrying accepted_code fails",fails(run(mk("review",pa)),"execution packet completeness"))
# T5 / C5: builder repair citing its base builder packet.
rep_send<-function(base_ref,role2="R-A",base_role="R-A",base_kind="builder",pp=lean){pp$accepted_code<-list();x<-mk("builder",pp,list());x$sends[[1]]$builder_base<-base_ref;x$sends[[1]]$builder_role<-role2
  b0<-o$sends[[1]];b0$id<-"execution-base";b0$builder_role<-base_role;b0$send_kind<-base_kind;b0$verified_at_utc<-"2020-01-01T00:00:00Z";b0$ready_at_utc<-NULL
  x$sends<-c(list(b0),x$sends);x}
r5<-run(rep_send(s$packet));base_rows<-Filter(function(z)grepl("execution-base",z$check,fixed=TRUE),r5)
check("T5 repair citing verified base of same role passes completeness",!fails(r5,paste("execution packet completeness",s$id)))
check("T5 wrong role fails",fails(run(rep_send(s$packet,role2="R-B")),paste("execution packet completeness",s$id)))
check("T5 base that is not a builder fails",fails(run(rep_send(s$packet,base_kind="review")),paste("execution packet completeness",s$id)))
fake<-m_file_ref(s$packet$path,root);fake$sha256<-paste(rep("0",64),collapse="")
check("T5 hash mismatch fails",fails(run(rep_send(fake)),paste("execution packet completeness",s$id)))
check("T5 base packet not in ledger fails",fails(run(rep_send(att)),paste("execution packet completeness",s$id)))
# T4 / C4: run-attempt-scoped approvals.
sc<-function(a){x<-o;x$attempt<-"3";x$approvals[[1]]$expires_at_utc<-NULL;x$approvals[[1]]$scope_bound<-a;x}
check("T4 approval scoped to this run attempt passes without fixed expiry",m_pass(run(sc(list(run_id=state$run_id,attempt="3")))))
check("T4 approval for another attempt fails",fails(run(sc(list(run_id=state$run_id,attempt="2"))),"approval stage_signoff"))
check("T4 approval for another run fails",fails(run(sc(list(run_id="OTHER",attempt="3"))),"approval stage_signoff"))
x<-sc(list(run_id=state$run_id,attempt="3"));x$approvals[[1]]$expires_at_utc<-"2020-01-01T00:00:00Z";check("T4 owner expiry stays a hard limit",fails(run(x),"approval stage_signoff"))
x<-o;x$approvals[[1]]$expires_at_utc<-NULL;check("T4 unscoped approval without expiry still fails",fails(run(x),"approval stage_signoff"))
cat(sum(unlist(results)),"/",length(results),"targeted gate tests passed\n")
if(!all(unlist(results)))quit(status=1)
