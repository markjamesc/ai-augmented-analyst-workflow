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
    output = t_file(root, paste0("ai/", stage, "-", role, "-output.txt"), paste0("synthetic output\nEND_REPLY ", stage, "-synthetic-", match(role, roles), " TEST-", stage, "-", match(role, roles))))
})
# Plan A (t1674s7005): real-layout stage records, as live receipts carry them (ACC002: data/ + docs/stage1/START_RECORD.md,
# docs/stage2/FRAMING_RECORD.md, docs/stage3/DESIGN_GATE_RECORD.md; rehearsal finish: docs/stage5/interpretation.md). Written when a receipt
# is built, never by t_operations; the review gate's subject rules then apply unchanged.
t_stage_record <- function(root, rp, refs) { if (!file.exists(file.path(root, rp))) return(invisible(NULL)); r <- m_read(file.path(root, rp))
  if (!is.list(r)) return(invisible(NULL)); r$stage_records <- lapply(refs, function(x) t_file(root, x[[1]], x[[2]])); t_write(root, rp, r) }
t_stage_records <- function(root) {
  t_stage_record(root, "artifacts/stage1_decision.json", list(c("data/stage1_input.csv", "id,value\n1,2"), c("docs/stage1/START_RECORD.md", "Synthetic start record")))
  t_stage_record(root, "artifacts/stage2_framing.json", list(c("docs/stage2/FRAMING_RECORD.md", "Synthetic framing record")))
  t_stage_record(root, "artifacts/stage3_locked_design.json", list(c("docs/stage3/DESIGN_GATE_RECORD.md", "Synthetic design gate record")))
}
t_design <- function(root) {
  t_stage_records(root)
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
  t_stage_record(root, "artifacts/stage5_interpretation_status.json", list(c("docs/stage5/interpretation.md", "Synthetic interpretation")))
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
  # 2026-10-31 (option B): lean ledger. One captured, hash-bound review per required role; the receipt is left untouched.
  state<-m_read(file.path(root,"artifacts/procedure/run_state.json"))
  if(!identical(state$current_step,stage))return(invisible(NULL))
  rp<-unname(m_stage_receipts[stage]);receipt<-m_read(file.path(root,rp))
  roles<-c(m_stage_ai_roles[[stage]],if(identical(receipt$cross_review,"PASS"))"cross_review",
    if(identical(stage,"execution") && identical(m_read(file.path(root,"artifacts/stage3_locked_design.json"))$methodology$structural_review$policy,"required"))"structural reviewer")
  if(!length(roles))roles<-"reviewer"
  # Plan A (t1674s7005): no invented review subject. The gate's subject rules apply as-is; a receipt without its stage record fails.
  # Fixture receipts carry real-layout stage records (t_stage_records), as live receipts do (ACC002: docs/stageN/*_RECORD.md).
  sends<-lapply(seq_along(roles),function(i){id<-paste0(stage,"-synthetic-",i);nonce<-paste0("TEST-",stage,"-",i)
    p<-list(run_id=state$run_id,stage=stage,send_id=id,nonce=nonce,role=roles[[i]],attachments=list())
    t_write(root,paste0("packets/",stage,"/",id,".json"),p);packet<-m_file_ref(paste0("packets/",stage,"/",id,".json"),root)
    px<-Filter(function(x)identical(x$role,roles[[i]]),if(is.list(receipt$ai_provenance))receipt$ai_provenance else list())
    reply<-if(length(px)) px[[1]]$output else t_file(root,paste0("transcripts/",stage,"/",id,"_reply.txt"),paste("Synthetic reply",roles[[i]],"\nEND_REPLY",id,nonce))
    t_write(root,paste0("captures/",stage,"/",id,".json"),list(send_id=id,nonce=nonce,packet=packet,reply=reply,capture_sha256=reply$sha256))
    sj<-m_review_subjects(stage,receipt,rp,root);sj<-sj[!is.na(sj)&file.exists(file.path(root,sj))]
    rr<-Filter(function(z)m_ref_ok(z,root)&&!grepl("^(transcripts|captures|packets|approvals|artifacts/operations)/",z$path)&&!identical(z$path,rp),m_refs(receipt))  # same exclusions as the gate
    att<-unname(lapply(unique(c(sj,if(length(rr))rr[[1]]$path)),m_file_ref,root=root))  # F5b: attach every reviewed subject at its current hash (never the receipt itself)
    list(id=id,ai="synthetic",role=roles[[i]],send_kind="review",nonce=nonce,packet=packet,attachments=att,reply=reply,capture=m_file_ref(paste0("captures/",stage,"/",id,".json"),root))})
  t_write(root,paste0("artifacts/operations/",stage,".json"),list(version="acceptance-v2",run_id=state$run_id,stage=stage,sends=sends))
}
