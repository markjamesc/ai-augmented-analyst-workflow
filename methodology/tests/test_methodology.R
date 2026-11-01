#!/usr/bin/env Rscript
repo_root <- normalizePath(if (length(commandArgs(TRUE))) commandArgs(TRUE)[[1]] else ".")
source(file.path(repo_root, "methodology/tests/fixtures.R"))
# Reuse baseline gate fixture definitions without executing their test suite.
env <- new.env(parent = globalenv())
lines <- readLines(file.path(repo_root, "workflow-gate/tests/test_workflow_gate.R"))
stop_at <- grep('^pass_root <-', lines)[[1]]
eval(parse(text = lines[seq_len(stop_at - 1L)]), env)
root <- tempfile("methodology-tests-"); dir.create(root)
env$write_project(root)
s3 <- m_read(file.path(root, "artifacts/stage3_locked_design.json"))
s4 <- m_read(file.path(root, "artifacts/stage4_validation_status.json"))
pass <- function(checks) length(checks) > 0L && all(vapply(checks, function(x) identical(x$result,"PASS"), logical(1)))
stopifnot(pass(m_design(s3, root = root)), pass(m_execution(s3,s4,root)))
count <- 0L
bad_design <- function(label, alter) {
  x <- alter(s3)
  if (pass(m_design(x, root = root))) stop("Invalid design accepted: ",label)
  count <<- count + 1L
}
bad_design("missing replay output plan", function(x) {x$methodology$replay_outputs <- NULL;x})
bad_design("missing target", function(x) {x$methodology$analytical_target <- NULL;x})
bad_design("wrong population", function(x) {x$methodology$analytical_target$observed_population <- "other";x})
bad_design("causal claim without identification", function(x) {x$methodology$analytical_target$allowed_claim_types <- list("causal");x})
bad_design("hidden exposure", function(x) {x$methodology$exposure$results_seen <- NULL;x})
bad_design("invalid premise kind", function(x) {x$methodology$premises[[1]]$kind <- "verified_fact";x})
bad_design("missing branch", function(x) {x$methodology$sensitivity$required <- TRUE;x})
bad_design("different-target sensitivity", function(x) {x$methodology$sensitivity$required <- TRUE;x$methodology$sensitivity$specifications <- list(list(id="alt",justification="test",target_id="other",relation="same_target"));x})
bad_design("negative tolerance", function(x) {x$methodology$checkpoints[[1]]$absolute_tolerance <- -1;x})
bad_design("missing component coverage", function(x) {x$methodology$checkpoint_coverage <- list("results");x})
bad_design("output omitted", function(x) {x$methodology$output_fields <- x$methodology$output_fields[1];x})
bad_design("no method plan", function(x) {x$methodology$modules$measurement$plan <- NULL;x})
bad_design("missing outcome contract", function(x) {x$methodology$triggers$decision_outcome <- TRUE;x})
# Same count but wrong identities; duplicate IDs; different shapes/order; empty set; boundaries.
p <- s3$methodology$checkpoints[[1]]
a <- data.frame(id=c("01","02"),action=c("A","B"))
stopifnot(m_compare(a,a[2:1,],p),m_compare(a,a[,2:1],p),m_compare(a[FALSE,],a[FALSE,],p))
b <- a;b$id[2] <- "03";stopifnot(!m_compare(a,b,p))
b <- a;b$id[2] <- "01";stopifnot(!m_compare(a,b,p))
b <- a;b$action[2] <- "A";stopifnot(!m_compare(a,b,p))
p$numeric_fields <- list("value");p$absolute_tolerance <- 1e-6
a$value <- c(1,2);b <- a;b$value[1] <- 1+1e-7;stopifnot(m_compare(a,b,p));b$value[1] <- 1+1e-4;stopifnot(!m_compare(a,b,p))
b <- a;b$value[1] <- NA;stopifnot(!m_compare(a,b,p))
# Keep wrapper hashes current to test semantics rather than only digest rejection.
mp <- s4$evidence_receipts$methodology$path;orig <- m_read(file.path(root,mp))
bad_execution <- function(label,alter) {
  t_write(root,mp,alter(orig));x <- s4;x$evidence_receipts$methodology <- m_file_ref(mp,root)
  if (pass(m_execution(s3,x,root))) stop("Invalid execution accepted: ",label)
  count <<- count + 1L;t_write(root,mp,orig)
}
bad_execution("replay omitted outputs", function(x) {x$replay$outputs <- list();x})
bad_execution("missing checkpoint", function(x) {x$checkpoints <- list();x})
bad_execution("metamorphic only one path", function(x) {x$metamorphic <- x$metamorphic[1];x})
bad_execution("failed metamorphic", function(x) {x$metamorphic[[1]]$result <- "FAIL";x})
bad_execution("replay not clean", function(x) {x$replay$clean_session <- FALSE;x})
bad_execution("replay failed", function(x) {x$replay$exit_status <- 1L;x})
bad_execution("poison test not run", function(x) {x$fixtures$poison_probe_b <- "NOT_RUN";x})
bad_execution("smoke used for reporting", function(x) {x$smoke$non_reporting <- FALSE;x})
bad_execution("model provenance omitted", function(x) {x$reproducibility$r_version <- NULL;x})
bad_execution("no source dependency", function(x) {x$dependencies <- x$dependencies[-1];x})
# Evidence changes without touching its wrapper: stale dependency must fail.
source_path <- file.path(root,"inputs/source.csv");old <- readLines(source_path);writeLines("changed",source_path)
stopifnot(!pass(m_execution(s3,s4,root)));writeLines(old,source_path)
# Structural skip is accepted only with locked full coverage and an honest NOT_REQUIRED receipt.
s4$structural_cross_review <- "NOT_REQUIRED";s4$structural_review_reason <- "All locked rules covered"
sr <- s4$evidence_receipts$structural$path;x <- m_read(file.path(root,sr));x$status <- "NOT_REQUIRED";t_write(root,sr,x);s4$evidence_receipts$structural <- m_file_ref(sr,root)
t_write(root,"artifacts/stage4_validation_status.json",s4)
stopifnot(env$run_gate(root) == 0L)
s4$structural_review_reason <- NULL;t_write(root,"artifacts/stage4_validation_status.json",s4);stopifnot(env$run_gate(root) != 0L)
# Mechanical relation detects an order-dependent implementation while accepting a valid one.
dir <- file.path(root,"reports")
valid <- function(d) d[order(d$id),,drop=FALSE]
bug <- function(d) {d$action <- c("A","B");d}
for (fn in list(valid,bug)) {
 path <- m_metamorphic(fn,a,function(d)d[2:1,],function(x,y)m_compare(x,y,p),"row-order","IDs stable","R-A",dir)
 stopifnot(identical(m_read(path)$result,if (identical(fn,valid)) "PASS" else "FAIL"))
}
# Clean replay is executed, not just a fixture status.
script <- file.path(root,"replay.R");writeLines('args <- commandArgs(TRUE); dir.create(file.path(args[2], "outputs"), showWarnings=FALSE); file.copy(file.path(args[1],"outputs/judged.csv"),file.path(args[2],"outputs/judged.csv"))',script)
replay <- m_replay(script,root,file.path(root,"replay-output"),list("outputs/judged.csv"),dir)
stopifnot(m_read(replay)$status == "PASS")
# Finish: accurate number cannot compensate for failed inference; valid insufficient evidence passes.
t_file(root,"answer.md","Two recorded units.")
t_write(root,"artifacts/stage5_interpretation_status.json",list(deliverables=list("answer.md")))
t_finish(root);s5 <- m_read(file.path(root,"artifacts/stage5_interpretation_status.json"))
# Restore source methodology wrapper hash after deliberate mutations.
s4$evidence_receipts$methodology <- m_file_ref(mp,root)
stopifnot(pass(m_finish(s3,s4,s5,root)))
for (what in c("inference","ceiling","coverage","flags","evaluated")) {
 v <- s5
 if (what == "inference") v$claim_ledger[[1]]$inference_review <- "FAIL"
 if (what == "ceiling") v$claim_ledger[[1]]$type <- "causal"
 if (what == "coverage") v$substantive_claim_ids <- list("claim-1","unregistered")
 if (what == "flags") v$revision$unresolved_flags <- 1L
 if (what == "evaluated") v$assurance$outcome_evaluation <- "evaluated"
 stopifnot(!pass(m_finish(s3,s4,v,root)));count <- count+1L
}
cat("Methodology checks passed:",count,"contract defects rejected; keyed membership, boundaries, metamorphic fault detection and actual fresh-process replay verified.\n")
unlink(root,recursive=TRUE)

# Referee identity, attempt preservation and late-discovery successor path.
g <- new.env();sys.source(file.path(repo_root,"procedure-gate/procedure_gate.R"),envir=g)
g$procedure_script_path <- function() file.path(repo_root,"procedure-gate/procedure_gate.R")
old <- tempfile("predecessor-");new <- tempfile("successor-");dir.create(old);dir.create(new)
g$procedure_start(old,"OLD")
old_sha <- m_hash(file.path(old,"artifacts/procedure/run_state.json"))
change <- list(change_class="design_amendment", reason="Late target defect", data_seen="All old data",results_seen="Old results",target_effect="Correct target",affected_artifacts=list("design","execution","finish"),rerun_steps=list("start","framing","design","execution","finish"),approval_text="Owner approved successor test",approval_timestamp="2026-01-02T00:00:00Z")
t_write(new,"change.json",change)
stopifnot(g$procedure_successor(new,old,"NEW","change.json")$status=="STARTED")
state <- g$read_state(new)
stopifnot(length(state$completed_steps)==0,identical(m_hash(file.path(old,"artifacts/procedure/run_state.json")),old_sha),state$predecessor$run_id=="OLD",g$verify_completed_artifacts(state,new))
stopifnot(all(c("procedure-gate/procedure_gate.R","methodology/contracts.R","methodology/schema.json") %in% names(state$framework_hashes)))
x <- g$save_checks(new,"execution","complete",list(list(result="FAIL")))
y <- g$save_checks(new,"execution","complete",list(list(result="PASS")))
stopifnot(x$path != y$path,file.exists(x$path),file.exists(y$path))
writeLines("tampered",file.path(new,"change.json"));stopifnot(!g$verify_completed_artifacts(state,new))
unlink(old,recursive=TRUE);unlink(new,recursive=TRUE)
cat("Successor and retry tests passed: predecessor retained, no inherited completions, referee hashed, failed attempt preserved.\n")
