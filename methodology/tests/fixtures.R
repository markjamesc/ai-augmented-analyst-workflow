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
