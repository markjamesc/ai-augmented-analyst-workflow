#!/usr/bin/env Rscript
# Local acceptance: synthetic evidence, actual gate/helper execution. No real AI claims.
repo_root <- normalizePath(if (length(commandArgs(TRUE))) commandArgs(TRUE)[[1]] else ".")
source(file.path(repo_root, "methodology/tests/fixtures.R"))
env <- new.env(parent = globalenv())
lines <- readLines(file.path(repo_root, "workflow-gate/tests/test_workflow_gate.R"))
eval(parse(text = lines[seq_len(grep('^pass_root <-', lines)[[1]] - 1L)]), env)
root <- tempfile("acceptance-"); dir.create(root); env$write_project(root)
s3 <- m_read(file.path(root, "artifacts/stage3_locked_design.json"))
s4 <- m_read(file.path(root, "artifacts/stage4_validation_status.json"))
t_file(root, "answer.md", "Two recorded units.")
t_write(root, "artifacts/stage5_interpretation_status.json", list(deliverables=list("answer.md")))
t_finish(root); s5 <- m_read(file.path(root, "artifacts/stage5_interpretation_status.json"))
pass <- function(x) length(x)>0 && all(vapply(x, function(c) identical(c$result,"PASS"), logical(1)))
results <- list()
check <- function(name, value) {
  ok <- tryCatch(isTRUE(force(value)), error=function(e) FALSE)
  results[[name]] <<- ok; cat(if(ok) "PASS" else "FAIL", name, "\n")
}
check("baseline design/execution/finish", pass(m_design(s3,root=root)) && pass(m_execution(s3,s4,root)) && pass(m_finish(s3,s4,s5,root)))
for (module in c("missingness","dependence","multiplicity","transportability")) {
  x <- s3; x$methodology$triggers[[module]] <- TRUE
  check(paste(module,"missing plan rejected"), !pass(m_design(x,root=root)))
  x$methodology$modules[[module]] <- list(required=TRUE,rationale="Triggered risk",plan="Prespecified project-specific assessment")
  check(paste(module,"active plan accepted"), pass(m_design(x,root=root)))
}
x <- s3; x$methodology$sensitivity$specifications <- list(list(id="optional-malformed"))
check("optional sensitivity branch still validated", !pass(m_design(x,root=root)))
x$methodology$sensitivity$specifications <- list(list(id="optional-valid",justification="Useful alternative",target_id="target-1",relation="same_target"))
check("valid optional sensitivity accepted", pass(m_design(x,root=root)))
for(stage in c("design","execution","finish")) {
  records <- switch(stage, design=s3$ai_provenance,execution=s4$ai_provenance,finish=s5$ai_provenance)
  roles <- vapply(records,function(x)x$role,character(1))
  check(paste(stage,"complete AI metadata"),pass(m_ai(records,roles,root,stage)))
  check(paste(stage,"missing role rejected"),!pass(m_ai(records[-1],roles,root,stage)))
  records[[1]]$output$sha256 <- paste(rep("0",64),collapse="")
  check(paste(stage,"stale AI output rejected"),!pass(m_ai(records,roles,root,stage)))
}
x <- s4$ai_provenance; x[[1]]$peer_access <- "peer draft seen before freeze"
check("builder contamination rejected",!pass(m_ai(x,c("R-A","R-B"),root,"execution")))
x <- s3$ai_provenance; x[[1]]$coordinator_draft_seen <- TRUE
check("coordinator first draft rejected",!pass(m_ai(x,c("designer_a","designer_b","risk_reviewer"),root,"design")))

# Conditional outcome handoff must retain the actual locked comparison and owner.
d <- s3; d$methodology$triggers$decision_outcome <- TRUE
contract <- m_read(file.path(repo_root,"templates/methodology/outcome_contract.example.json"))
contract <- lapply(contract,function(x)"Synthetic prespecified value")
contract$owner <- "Test owner"; contract$followup_run_id <- "followup-1"
d$methodology$outcome_contract <- contract
t_write(root,"outcome-contract.json",contract)
f <- s5; f$outcome_followup <- list(run_id="followup-1",owner="Test owner",contract=m_file_ref("outcome-contract.json",root))
f$assurance$outcome_evaluation <- "pending"
check("pending required outcome accepted",pass(m_finish(d,s4,f,root)))
x <- f; x$assurance$outcome_evaluation <- "not_applicable"
check("required outcome cannot become not applicable",!pass(m_finish(d,s4,x,root)))
f$assurance$outcome_evaluation <- "evaluated"
f$outcome_followup$evaluation_report <- t_file(root,"outcome-report.md","Synthetic comparison report; no real profit claim")
x <- f; x$outcome_followup$owner <- "Different owner"
check("changed outcome owner rejected",!pass(m_finish(d,s4,x,root)))
changed <- contract; changed$alternative <- "Post-result alternative"
t_write(root,"outcome-contract.json",changed); x <- f; x$outcome_followup$contract <- m_file_ref("outcome-contract.json",root)
check("rehashed changed comparison rejected",!pass(m_finish(d,s4,x,root)))
t_write(root,"outcome-contract.json",contract)
f$outcome_followup$evaluation_report <- t_file(root,"outcome-report.md","Synthetic comparison report; no real profit claim")
f$assurance$outcome_evaluation <- "evaluated"
check("evaluated outcome with report accepted",pass(m_finish(d,s4,f,root)))

# Direct gate must write a refusal report for malformed lower evidence, not reuse a PASS.
for (value in list(42L,"PASS",list(),list(status="PASS"))) {
  path <- s4$evidence_receipts$methodology$path
  t_write(root,path,value); changed <- s4; changed$evidence_receipts$methodology <- m_file_ref(path,root)
  t_write(root,"artifacts/stage4_validation_status.json",changed)
  code <- suppressWarnings(env$run_gate(root)); report <- m_read(file.path(root,"artifacts/workflow_gate_status.json"))
  check(paste("malformed receipt",length(results)),code != 0L && identical(report$result,"FAIL") && identical(report$stage5_allowed,FALSE))
}

# Actual replay recomputes an aggregate from raw inputs. Catch wrong output, exit,
# missing output, and modification of frozen inputs (even if new outputs agree).
for (variant in c("valid","wrong","missing","exit","mutate")) {
  frozen <- tempfile("frozen-"); out <- tempfile("replay-"); reports <- tempfile("reports-")
  dir.create(frozen);dir.create(file.path(frozen,"outputs"))
  write.csv(data.frame(value=c(2,3)),file.path(frozen,"input.csv"),row.names=FALSE)
  writeLines("5",file.path(frozen,"outputs/total.txt"))
  script <- tempfile(fileext=".R")
  body <- c('args <- commandArgs(TRUE)', 'x <- read.csv(file.path(args[1],"input.csv"))', 'dir.create(file.path(args[2],"outputs"))')
  if(variant=="exit") body <- c(body,'quit(status=7)')
  if(variant=="mutate") body <- c(body,'writeLines("changed",file.path(args[1],"input.csv"))')
  if(variant!="missing") body <- c(body,if(variant=="wrong") 'writeLines("6",file.path(args[2],"outputs/total.txt"))' else 'writeLines(as.character(sum(x$value)),file.path(args[2],"outputs/total.txt"))')
  writeLines(body,script)
  report <- m_read(suppressWarnings(m_replay(script,frozen,out,list("outputs/total.txt"),reports)))
  check(paste("computed replay",variant),identical(report$status,if(variant=="valid")"PASS" else "FAIL"))
  unlink(c(frozen,out,reports,script),recursive=TRUE)
}

# Path checks defend evidence identity, including symlink escapes.
ref <- m_file_ref("answer.md",root)
for(path in c("../answer.md","/tmp/answer.md","C:/answer.md","./answer.md","x/../answer.md")) {
  bad <- ref; bad$path <- path; check(paste("unsafe path",path),!m_ref_ok(bad,root))
}
outside <- tempfile();writeLines("outside",outside)
if(file.symlink(outside,file.path(root,"outside.txt"))) check("symlink escape rejected",!m_ref_ok(m_file_ref("outside.txt",root),root))

# A successor must preserve the archived certificate as well as the state/change.
g <- new.env();sys.source(file.path(repo_root,"procedure-gate/procedure_gate.R"),envir=g)
g$procedure_script_path <- function() file.path(repo_root,"procedure-gate/procedure_gate.R")
old <- tempfile("old-");new <- tempfile("new-");badroot <- tempfile("bad-")
dir.create(old);dir.create(new);dir.create(badroot)
g$procedure_start(old,"OLD")
g$procedure_begin(old,"start")
t_write(old,"artifacts/stage1_decision.json",42L)
before <- m_hash(file.path(old,"artifacts/procedure/run_state.json"))
check("scalar stage receipt returns refusal without advancing",identical(g$procedure_complete(old,"start")$status,"FAIL") && identical(before,m_hash(file.path(old,"artifacts/procedure/run_state.json"))))
t_write(old,"artifacts/final_certificate.json",list(note="Synthetic archive identity test, not a certified project"))
change <- list(change_class="design_amendment",reason="Late defect",data_seen="Old data",results_seen="Old results",target_effect="Amended",affected_artifacts=list("design"),rerun_steps=list("design","execution","finish"),approval_text="Owner approved test",approval_timestamp="2026-01-02T00:00:00Z")
t_write(new,"change.json",change)
g$procedure_successor(new,old,"NEW","change.json")
state <- g$read_state(new)
check("successor archived evidence initially valid",g$verify_completed_artifacts(state,new))
writeLines("tampered",file.path(new,"artifacts/predecessor/final_certificate.json"))
check("successor archived certificate tamper rejected",!g$verify_completed_artifacts(state,new))
external <- tempfile(fileext=".json");jsonlite::write_json(change,external,auto_unbox=TRUE)
refused <- tryCatch({g$procedure_successor(badroot,old,"BAD",paste0("../",basename(external)));FALSE},error=function(e)TRUE)
check("unsafe successor change refused before creating state",refused && !file.exists(file.path(badroot,"artifacts/procedure/run_state.json")))
unlink(c(old,new,badroot,external),recursive=TRUE)
unlink(c(root,outside),recursive=TRUE)
cat("Local acceptance:",sum(unlist(results)),"/",length(results),"checks passed\n")
if(!all(unlist(results))) stop("Local acceptance failures: ",paste(names(results)[!unlist(results)],collapse=", "))
