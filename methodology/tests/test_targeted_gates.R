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
rep_send<-function(base_ref,role2="R-A",base_role="R-A",base_kind="builder",pp=lean,noacc=FALSE){pp$accepted_code<-if(noacc) NULL else list();x<-mk("builder",pp,list());x$sends[[1]]$builder_base<-base_ref;x$sends[[1]]$builder_role<-role2
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
# T6 / C6: timing optional only for a hash-bound reply.
nt<-function(x){x$sends[[1]]$ready_at_utc<-NULL;x$sends[[1]]$dispatch_evidence<-NULL;x}
check("T6 hash-bound reply without ready/dispatch now passes",m_pass(run(nt(copycap(c2)))))
check("T6 unbound (browser_export) reply without timing fails",fails(run(nt(o)),"send chronology") && fails(run(nt(o)),"dispatch timing provenance"))
c3<-c2;c3$capture_sha256<-paste(rep("0",64),collapse="");r6<-run(nt(copycap(c3)))
check("T6 mismatched reply hash without timing fails",fails(r6,"send chronology") && fails(r6,"capture match"))
x<-copycap(c2);x$sends[[1]]$dispatch_evidence<-NULL;x$sends[[1]]$ready_at_utc<-"2099-01-01T00:00:00Z";check("T6 recorded ready time after send still fails",fails(run(x),"send chronology"))
x<-nt(copycap(c2));x$sends[[1]]$dispatch_evidence<-list(path="missing.txt",sha256=paste(rep("0",64),collapse=""));check("T6 recorded but broken dispatch evidence still fails",fails(run(x),"dispatch timing provenance"))
x<-nt(copycap(c2));x$sends[[1]]$sent_at_utc<-NULL;check("T6 missing send time still fails",fails(run(x),"send chronology"))
# T7 / C7: base builder packet from an earlier attempt's ledger.
early<-function(e){b0<-o$sends[[1]];b0$builder_role<-"R-A";b0$ready_at_utc<-"2020-01-01T00:00:00Z";b0$sent_at_utc<-"2020-01-01T00:01:00Z";b0$verified_at_utc<-"2020-01-01T00:02:00Z";b0<-e(b0)
  t_write(root,"earlier/execution_attempt1.json",list(run_id=state$run_id,stage="execution",attempt="1",sends=list(b0)));m_file_ref("earlier/execution_attempt1.json",root)}
r7<-function(e=identity,role2="R-A"){x<-mk("builder",within(lean,accepted_code<-list()),list());x$sends[[1]]$builder_base<-s$packet;x$sends[[1]]$builder_role<-role2;x$sends[[1]]$builder_base_ledger<-early(e);x}
check("T7 base in earlier attempt ledger now passes",m_pass(run(r7())))
check("T7 base verified after repair send fails",fails(run(r7(function(b){b$verified_at_utc<-"2099-01-01T00:00:00Z";b})),"execution packet completeness"))
check("T7 reversed chronology inside earlier ledger fails",fails(run(r7(function(b){b$sent_at_utc<-"2019-01-01T00:00:00Z";b})),"execution packet completeness"))
check("T7 wrong role fails",fails(run(r7(role2="R-B")),"execution packet completeness"))
check("T7 role not provable from earlier ledger or base packet fails",fails(run(r7(function(b){b$builder_role<-NULL;b})),"execution packet completeness"))
x<-r7();x$sends[[1]]$builder_base_ledger$sha256<-paste(rep("0",64),collapse="");check("T7 earlier ledger hash mismatch fails",fails(run(x),"execution packet completeness"))
# T8 / C8: write-once packet supplement adds only authorization / accepted_code.
sx<-function(fields,noacc=TRUE,noauth=FALSE){pp<-lean;if(noauth)pp$authorization<-NULL;x<-rep_send(s$packet,pp=pp,noacc=noacc);k<-length(x$sends)
  sup<-c(list(kind="packet_supplement",supplements=x$sends[[k]]$packet,send_id=x$sends[[k]]$id,nonce=x$sends[[k]]$nonce,reason="record fix",owner_ruling="synthetic"),fields)
  t_write(root,"packets/execution-k.sup.json",sup);x$sends[[k]]$packet_supplement<-m_file_ref("packets/execution-k.sup.json",root);x}
cid<-paste("execution packet completeness",s$id)
x<-rep_send(s$packet,noacc=TRUE);check("T8 builder repair without accepted_code and no supplement fails",fails(run(x),cid))
check("T8 supplement adding accepted_code now passes",!fails(run(sx(list(accepted_code=list(att)))),cid) && !fails(run(sx(list(accepted_code=list(att)))),"packet supplement"))
check("T8 supplement adding authorization fixes packet binding",!fails(run(sx(list(authorization=state$current_authorization,accepted_code=list(att)),noauth=TRUE)),paste("packet binding",s$id)))
check("T8 missing authorization without supplement fails",fails(run(sx(list(accepted_code=list(att)),noauth=TRUE)),paste("packet binding",s$id)))
x<-sx(list(accepted_code=list(att)));sp<-m_read(file.path(root,"packets/execution-k.sup.json"));sp$supplements$sha256<-paste(rep("0",64),collapse="");t_write(root,"packets/execution-k.sup.json",sp);x$sends[[length(x$sends)]]$packet_supplement<-m_file_ref("packets/execution-k.sup.json",root)
check("T8 supplement naming another packet fails",fails(run(x),"packet supplement") && fails(run(x),cid))
check("T8 supplement changing other fields fails",fails(run(sx(list(accepted_code=list(att),attachments=list(att)))),"packet supplement"))
cat(sum(unlist(results)),"/",length(results),"targeted gate tests passed\n")
if(!all(unlist(results)))quit(status=1)
