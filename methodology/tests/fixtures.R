# SYNTHETIC gate fixtures only. Never use these receipts as project evidence.
source(file.path(repo_root, "methodology/contracts.R"))
source(file.path(repo_root, "methodology/tools.R"))
t_write <- function(root, path, value) {
  dir.create(dirname(file.path(root, path)), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(value, file.path(root, path), auto_unbox = TRUE, pretty = TRUE, null = "null")
}
t_file <- function(root, path, text) {
  dir.create(dirname(file.path(root, path)), recursive = TRUE, showWarnings = FALSE)
  writeLines(text, file.path(root, path)); m_file_ref(path, root)
}
t_ai <- function(root, roles, stage) lapply(roles, function(role) {
  list(role = role, provider = "synthetic", model = "test-fixture-not-real-AI", session = paste(stage, role),
    settings = "not applicable: fixture", seeds = "not applicable: fixture", context_disclosure = "Synthetic test only",
    first_pass_frozen_at = "2026-01-01T00:00:00Z", peer_access = if (stage == "execution") "none_before_freeze" else "disclosed stage-specific inputs",
    contamination = "Synthetic shared fixture; not an independence evaluation", coordinator_draft_seen = FALSE,
    input = t_file(root, paste0("ai/", stage, "-", role, "-input.txt"), "synthetic input"),
    output = t_file(root, paste0("ai/", stage, "-", role, "-output.txt"), "synthetic output"))
})
t_design <- function(root) {
  path <- "artifacts/stage3_locked_design.json"; s <- m_read(file.path(root, path))
  m <- m_read(file.path(repo_root, "templates/methodology/design.example.json"))
  m$analytical_target$observed_population <- s$population; m$analytical_target$decision_unit <- s$grain
  m$output_fields <- lapply(s$required_outputs, function(f) list(field = f, outcome_semantics = "Explicit complete fixture semantics"))
  s$methodology <- m; s$design_exposure_disclosed <- "PASS"; s$information_barrier <- NULL
  s$ai_provenance <- t_ai(root, c("designer_a", "designer_b", "risk_reviewer"), "design")
  t_write(root, path, s)
  for (i in 1:2) {
    p <- paste0("artifacts/stage", i, if (i == 1) "_decision.json" else "_framing.json")
    v <- m_read(file.path(root, p))
    if (i == 1) v$decision_id <- "decision-1" else {v$question_id <- "question-1"; v$question_type <- "descriptive"}
    t_write(root, p, v)
  }
}
t_execution <- function(root) {
  s3 <- m_read(file.path(root, "artifacts/stage3_locked_design.json"))
  s4 <- m_read(file.path(root, "artifacts/stage4_validation_status.json"))
  t_file(root, "inputs/source.csv", c("id,value", "01,1", "02,2"))
  t_file(root, "code/analysis.R", "# synthetic adapter")
  t_file(root, "config/analysis.json", "{}")
  a <- t_file(root, "outputs/judged.csv", c("id,action", "01,A", "02,B"))
  b <- t_file(root, "outputs/replayed.csv", c("id,action", "01,A", "02,B"))
  twin <- t_file(root, "outputs/twin.csv", c("id,action", "02,B", "01,A"))
  report <- t_file(root, "reports/checks.txt", "Synthetic check report, not a real project run")
  m <- list(status = "PASS", design_version = s3$design_version, fixture_version = s3$fixture_version,
    checked_at_utc = "2026-01-01T00:00:00Z", target_id = "target-1",
    changes = list(), checkpoints = list(list(id = "judged", a = a, b = twin)),
    metamorphic = lapply(c("R-A", "R-B"), function(id) list(id = "row_order", path_id = id, result = "PASS", report = report)),
    sensitivity = list(), modules = lapply(s3$methodology$modules, function(x) if (isTRUE(x$required)) list(disposition = "adequate", interpretation = "Synthetic scope", report = report) else list(disposition = "NOT_APPLICABLE")),
    fixtures = list(production_reader_a = "PASS", production_reader_b = "PASS", poison_probe_a = "PASS", poison_probe_b = "PASS", report = report),
    smoke = list(status = "PASS", non_reporting = TRUE, report = report),
    dominance = list(status = "NO_FLAG", disposition = "Synthetic no-flag case", report = report),
    reproducibility = list(r_version = R.version.string, os = "test OS", locale = "C", timezone = "UTC", encoding = "UTF-8", rng = "none", seeds = "none", sql_client = "not applicable: fixture", sql_mode = "not applicable: fixture", threads = "one", workflow_commit = "synthetic", project_commit = "synthetic", working_tree = "synthetic", replay_command = "synthetic", retention = "temporary test", package_lock = report, session_info = report),
    replay = list(status = "PASS", clean_session = TRUE, exit_status = 0L, report = report, outputs = list(list(original = a, replayed = b))),
    results = list(list(id = "result-1", target_id = "target-1", locator = "rows 1-2", artifact = a)))
  mp <- "evidence-v2/methodology.json"; t_write(root, mp, m)
  s4$evidence_receipts$methodology <- m_file_ref(mp, root)
  s4$ai_provenance <- t_ai(root, c("R-A", "R-B"), "execution")
  for (role in names(s4$evidence_receipts)) {
    p <- s4$evidence_receipts[[role]]$path
    receipt <- m_read(file.path(root, p))
    receipt$design_sha256 <- m_hash(file.path(root, "artifacts/stage3_locked_design.json"))
    receipt$dependencies <- lapply(s3$methodology$receipt_dependencies[[role]], m_file_ref, root = root)
    t_write(root, p, receipt); s4$evidence_receipts[[role]] <- m_file_ref(p, root)
  }
  srp<-s4$evidence_receipts$source$path;sr<-m_read(file.path(root,srp))
  sr$source_kind<-s3$methodology$operational$source_contract$kind
  sr$sql_extraction_used<-identical(sr$source_kind,"sql")
  sr$fidelity_check<-list(status="PASS",report=report)
  t_write(root,srp,sr);s4$evidence_receipts$source<-m_file_ref(srp,root)
  s4$sql_source_gate<-if(sr$sql_extraction_used) "PASS" else "NOT_APPLICABLE"
  t_write(root, "artifacts/stage4_validation_status.json", s4)
}
t_finish <- function(root) {
  p <- "artifacts/stage5_interpretation_status.json"; s <- m_read(file.path(root, p))
  ref <- t_file(root, "reports/claim-audit.txt", "Synthetic reviewer trace")
  s$ai_provenance <- t_ai(root, c("interpreter", "inference_reviewer", "numerical_auditor"), "finish")
  s$substantive_claim_ids <- list("claim-1")
  s$claim_ledger <- list(list(id = "claim-1", target_id = "target-1", type = "descriptive", wording = "Two recorded units", result_ids = list("result-1"), premise_ids = list("P1"), warrant = "Count the locked population", contrary_evidence = "None in synthetic fixture", defeater = "Source omissions", uncertainty = "No sampling interval for finite census; measurement limitations remain", scope = "Fixture population only", sensitivity = "No alternatives in fixture", reviewer = "synthetic", disposition = "Accepted limited wording", numerical_audit = "PASS", inference_review = "PASS", unresolved_objections = 0L, review_evidence = ref, deliverable = m_file_ref(s$deliverables[[1]], root)))
  s$claim_coverage_review <- list(status = "PASS", report = ref)
  s$revision <- list(status = "UNCHANGED", unresolved_flags = 0L, report = ref)
  s$assurance <- list(computation = "verified", inference = "scope_restricted", decision = "insufficient_evidence", outcome_evaluation = "not_applicable")
  t_write(root, p, s)
}

# These adapters fabricate TEST evidence only; production gates do not call them.
t_design_base <- t_design
t_design <- function(root) {
  t_design_base(root);p<-"artifacts/stage3_locked_design.json";s<-m_read(file.path(root,p));o<-s$methodology$operational
  o$fixture_inputs<-t_file(root,"fixtures/input.csv",c("id,amount","A,9","B,10","C,11"))
  o$fixture_expected<-t_file(root,"fixtures/expected.json",'{"selected":["C","B"]}')
  o$oracle_basis<-"Synthetic hand-counted boundary fixture";o$oracle_reviewer<-"synthetic reviewer"
  o$source_contract<-list(kind="sql",rationale="Synthetic exported source test only")
  o$output_rules<-lapply(s$required_outputs,function(f)list(field=f,kind="computed",rule="Synthetic explicit all-outcome rule"))
  # Old test builders share one synthetic code file; this does not establish live independence.
  o$validation_components<-list(`R-A`=list("code/analysis.R"),`R-B`=list("code/analysis.R"),harness=list("code/analysis.R"),configuration=list("config/analysis.json"),input=list("inputs/source.csv"))
  s$methodology$operational<-o
  s$methodology$metamorphic<-lapply(s$methodology$metamorphic,function(x){x$coverage_type<-"nonconstant";x$detectable_defect<-"Synthetic row-position dependency";x})
  t_write(root,p,s)
}
t_execution_base <- t_execution
t_execution <- function(root) {
  t_execution_base(root);s3<-m_read(file.path(root,"artifacts/stage3_locked_design.json"));s4<-m_read(file.path(root,"artifacts/stage4_validation_status.json"));p<-s4$evidence_receipts$methodology$path;r<-m_read(file.path(root,p))
  components<-lapply(s3$methodology$operational$validation_components,function(paths)lapply(paths,m_file_ref,root=root))
  ids<-c("fixtures:R-A","fixtures:R-B","replay","reconciliation",unlist(lapply(Filter(function(x)isTRUE(x$applicable),s3$methodology$metamorphic),function(x)paste("metamorphic",x$id,c("R-A","R-B"),sep=":"))))
  r$test_versions<-list(components=components,tests=lapply(ids,function(id)m_bound_test(id,components,root,function()TRUE)))
  r$triage<-list()
  r$reproducibility$environment_spec<-t_file(root,"environment/spec.txt","Synthetic test environment, not an actual restore")
  t_write(root,"reports/restore.json",list(status="PASS",fresh_environment=TRUE,environment_spec=r$reproducibility$environment_spec,console=t_file(root,"reports/restore.txt","Synthetic restore console")))
  r$reproducibility$restore_report<-m_file_ref("reports/restore.json",root)
  t_write(root,p,r);s4$evidence_receipts$methodology<-m_file_ref(p,root);t_write(root,"artifacts/stage4_validation_status.json",s4)
}
t_operations <- function(root,stage) {
  state<-m_read(file.path(root,"artifacts/procedure/run_state.json"))
  if(!identical(state$current_step,stage))return(invisible(NULL))
  auth<-state$current_authorization;now<-format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC");id<-paste0(stage,"-synthetic");nonce<-paste0("TEST-",stage)
  p<-list(run_id=state$run_id,stage=stage,authorization=auth,send_id=id,nonce=nonce,attachments=list())
  if(stage=="execution") {m<-m_read(file.path(root,"artifacts/stage3_locked_design.json"))$methodology;p$output_rules<-m$operational$output_rules;p$checkpoint_output_rules<-m$operational$checkpoint_output_rules;p$checkpoints<-m$checkpoints;p$receipt_dependencies<-m$receipt_dependencies;p$accepted_code<-list()}
  t_write(root,paste0("packets/",stage,".json"),p);packet<-m_file_ref(paste0("packets/",stage,".json"),root)
  reply<-t_file(root,paste0("replies/",stage,".txt"),paste("Synthetic reply\nEND_REPLY",id,nonce))
  capture_evidence<-t_file(root,paste0("captures/",stage,"-browser.txt"),"SYNTHETIC visible browser export for testing only")
  cap<-list(send_id=id,nonce=nonce,packet=packet,reply=reply,screen_verified=TRUE,capture_method="browser_export",capture_evidence=capture_evidence)
  t_write(root,paste0("captures/",stage,".json"),cap)
  owner<-t_file(root,paste0("approvals/",stage,".txt"),"Synthetic authorization, never live owner consent")
  approvals<-lapply(c("stage_signoff",if(stage=="finish")"final_certification"),function(scope)list(id=paste(stage,scope),run_id=state$run_id,stage=stage,scope=scope,wording_author="synthetic",owner_record=owner,granted_at_utc="2020-01-01T00:00:00Z",expires_at_utc="2099-01-01T00:00:00Z",conditions=list()))
  rev<-"artifacts/operations/revocations.json";if(!file.exists(file.path(root,rev)))t_write(root,rev,list(run_id=state$run_id,events=list()))
  t_write(root,paste0("artifacts/operations/",stage,".json"),list(version="acceptance-v1",run_id=state$run_id,stage=stage,authorization=auth,completed_at_utc=now,approvals=approvals,sends=list(list(id=id,ai="synthetic",nonce=nonce,packet=packet,attachments=list(),reply=reply,capture=m_file_ref(paste0("captures/",stage,".json"),root),depends_on=list(),approval_id="none",timestamp_basis="machine_observed",timestamp_uncertainty_seconds=0,dispatch_evidence=capture_evidence,ready_at_utc=now,sent_at_utc=now,captured_at_utc=now,verified_at_utc=now)),all_sends_recorded=TRUE,transcript_index=t_file(root,paste0("transcripts/",stage,".txt"),"Synthetic complete transcript"),deviations=list()))
}
