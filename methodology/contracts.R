# Prospective methodology-v3. Pure validators: never execute project commands.
m_text <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x)) &&
  !grepl("^(TODO|TBD|REPLACE|PENDING|NOT_SET__|\\{\\{)", trimws(x), ignore.case = TRUE)
m_strings <- function(x, empty = FALSE) {
  if (is.null(x) || !(is.list(x) || is.character(x))) return(FALSE)
  if (!length(x)) return(empty)
  all(vapply(x, m_text, logical(1)))
}
m_enum <- function(x, choices) is.character(x) && length(x) == 1L && !is.na(x) && x %in% choices
m_number <- function(x) is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)
m_rows <- function(x) is.list(x) && !is.data.frame(x) && is.null(names(x))
m_read <- function(path) tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
m_hash <- function(path) digest::digest(file = path, algo = "sha256")
m_ref_ok <- function(ref, root) {
  if (!is.list(ref) || !m_text(ref$path) || !m_text(ref$sha256) ||
      !grepl("^[a-fA-F0-9]{64}$", ref$sha256) ||
      grepl("^(/|[A-Za-z]:|\\\\)", ref$path) ||
      any(strsplit(gsub("\\\\", "/", ref$path), "/", fixed = TRUE)[[1]] %in% c("", ".", ".."))) return(FALSE)
  file <- file.path(root, ref$path)
  file.exists(file) && !dir.exists(file) &&
    startsWith(normalizePath(file, winslash = "/"), paste0(normalizePath(root, winslash = "/"), "/")) &&
    identical(tolower(ref$sha256), m_hash(file))
}
m_refs <- function(x) {
  if (!is.list(x)) return(list())
  if (all(c("path", "sha256") %in% names(x))) return(list(x))
  unlist(lapply(x, m_refs), recursive = FALSE)
}
m_refs_ok <- function(x, root, required = TRUE) {
  refs <- m_refs(x)
  (!required || length(refs) > 0L) && all(vapply(refs, m_ref_ok, logical(1), root = root))
}
m_equal_ids <- function(actual, expected) {
  m_strings(actual, TRUE) && m_strings(expected, TRUE) &&
    !anyDuplicated(unlist(actual)) && setequal(unlist(actual), unlist(expected))
}
m_checks <- function(fun) {
  checks <- list()
  add <- function(name, pass, detail) {
    checks[[length(checks) + 1L]] <<- list(check = paste("Methodology", name),
      result = if (isTRUE(pass)) "PASS" else "FAIL", detail = detail)
  }
  tryCatch(fun(add), error = function(e) add("well-formed contract", FALSE, conditionMessage(e)))
  checks
}
m_design <- function(s3, s2 = NULL, s1 = NULL, root) m_checks(function(add) {
  for (x in m_checkpoint_contract(s3)) add(x$check, x$result == "PASS", x$detail)
  for (x in m_operational_design(s3, root)) add(x$check, x$result == "PASS", x$detail)
  m <- s3$methodology
  add("version", identical(m$version, "methodology-v3"), "New runs require methodology-v3; old packs use their pinned referee")
  t <- m$analytical_target
  fields <- c("id", "decision_id", "question_id", "question_type", "target_population", "observed_population",
    "analysis_unit", "decision_unit", "outcome", "time_origin", "horizon", "contrast", "aggregation",
    "weighting", "quantity", "estimator", "decision_rule_ref", "validation_argument", "measurement_validity")
  add("target complete", is.list(t) && all(vapply(fields, function(f) m_text(t[[f]]), logical(1))), "Target, estimator and decision rule are separate")
  add("target decision rule reference", identical(t$decision_rule_ref, "stage3.decision_rules"), "Reference the existing decision rule authority")
  add("question type", m_enum(t$question_type, c("descriptive", "associational", "predictive", "causal", "decision")), "Explicit question type")
  add("target population authority", identical(t$observed_population, s3$population) && identical(t$decision_unit, s3$grain), "Existing population/grain remain authoritative; no conflicting duplicate")
  if (!is.null(s2)) add("Framing link", identical(t$question_id, s2$question_id) && identical(t$question_type, s2$question_type), "Target must address the framed question")
  if (!is.null(s1)) add("decision link", identical(t$decision_id, s1$decision_id), "Target must address the Start decision")
  add("claim ceiling", m_strings(t$allowed_claim_types) && all(unlist(t$allowed_claim_types) %in% c("descriptive", "associational", "predictive", "causal", "recommendation")), "No numeric ordering of association/prediction/causation")
  causal <- identical(t$question_type, "causal") || "causal" %in% unlist(t$allowed_claim_types) || isTRUE(m$triggers$causal_policy)
  predictive <- identical(t$question_type, "predictive") || "predictive" %in% unlist(t$allowed_claim_types) || identical(s3$ml_mode, "A")
  if (causal) add("causal identification", all(vapply(c("treatment", "comparator", "identification_argument"), function(f) m_text(t[[f]]), logical(1))), "Identification is required; a forecast is not an intervention effect")
  add("prior exposure", is.list(m$exposure) && all(vapply(c("data_seen", "results_seen", "test_set_access", "recorded_at_utc"), function(f) m_text(m$exposure[[f]]), logical(1))), "A new lock cannot erase prior outcome exposure")
  ps <- m$premises
  add("premise register", m_rows(ps) && length(ps) > 0 && !anyDuplicated(vapply(ps, function(p) p$id, character(1))) &&
    all(vapply(ps, function(p) m_text(p$id) && m_enum(p$kind, c("definition", "source_assertion", "assumption", "method_choice", "preference", "limitation")) &&
      m_enum(p$status, c("proposed", "supported", "contradicted", "unresolved", "accepted_with_scope", "superseded")) &&
      m_enum(p$testability, c("direct", "diagnostic", "external", "not_identified", "not_applicable")) &&
      all(vapply(c("statement", "basis", "consequence", "response"), function(f) m_text(p[[f]]), logical(1))) , logical(1))), "Kind, support and testability are distinct; source agreement is not real-world truth")
  triggers <- c("missingness", "dependence", "multiplicity", "transportability", "causal_policy", "decision_outcome")
  add("applicability screen", all(vapply(triggers, function(f) is.logical(m$triggers[[f]]) && length(m$triggers[[f]]) == 1 && !is.na(m$triggers[[f]]), logical(1))), "Explicit trigger assessment")
  required <- c(measurement = TRUE, causal = causal, predictive = predictive,
    missingness = isTRUE(m$triggers$missingness), dependence = isTRUE(m$triggers$dependence),
    multiplicity = isTRUE(m$triggers$multiplicity), transportability = isTRUE(m$triggers$transportability), decision_uncertainty = TRUE)
  for (id in names(required)) {
    mod <- m$modules[[id]]
    add(paste("module", id), is.list(mod) && identical(mod$required, unname(required[[id]])) && m_text(mod$rationale) &&
      if (required[[id]]) m_text(mod$plan) else identical(mod$status, "NOT_APPLICABLE"), "Triggered modules need a project-specific plan; absent triggers need a reason")
  }
  sp <- m$sensitivity
  add("sensitivity IDs unique", m_rows(sp$specifications) && !anyDuplicated(vapply(sp$specifications, function(x) x$id, character(1))), "No duplicated branch IDs")
  add("sensitivity screen", is.logical(sp$required) && length(sp$required) == 1 && m_text(sp$rationale) && m_text(sp$instability_rule) && m_rows(sp$specifications), "Bounded admissible alternatives; report failures and instability, never vote over specifications")
  add("sensitivity branches", (!isTRUE(sp$required) || length(sp$specifications) > 0) && all(vapply(sp$specifications, function(x)
    m_text(x$id) && m_text(x$justification) && m_text(x$target_id) && m_enum(x$relation, c("same_target", "supplementary_target")) &&
      if (identical(x$relation, "same_target")) identical(x$target_id, t$id) else !identical(x$target_id, t$id), logical(1))), "Different targets are supplementary, not robustness votes")
  cp <- m$checkpoints
  add("checkpoint plan", m_rows(cp) && length(cp) > 0 && !anyDuplicated(vapply(cp, function(x) x$id, character(1))) && all(vapply(cp, function(x)
    m_text(x$id) && m_strings(x$keys) && m_strings(x$exact_fields, TRUE) && m_strings(x$numeric_fields, TRUE) &&
    m_number(x$absolute_tolerance) && x$absolute_tolerance >= 0 && m_number(x$relative_tolerance) && x$relative_tolerance >= 0 && m_text(x$rationale), logical(1))), "Semantic keyed states, not identical algorithms; exact identities and decisions")
  exact_covered <- unique(unlist(lapply(cp, function(x) c(x$keys, x$exact_fields))))
  numeric_covered <- unique(unlist(lapply(cp, function(x) x$numeric_fields)))
  add("critical fields covered", all(unlist(s3$reconciliation_critical_fields) %in% c(exact_covered, numeric_covered)) &&
    m_strings(m$exact_decision_fields) && all(unlist(m$exact_decision_fields) %in% exact_covered) &&
    !any(unlist(m$exact_decision_fields) %in% numeric_covered), "Decision/identity fields exact; other critical quantities use locked tolerances")
  add("checkpoint coverage", m_strings(m$checkpoint_coverage) && all(c("population", "exclusions", "components", "results") %in% unlist(m$checkpoint_coverage)), "Document where membership, exclusions, numerators/denominators and results are compared")
  add("numeric boundary policy", all(vapply(c("boundary_rule", "nonfinite_rule", "stochastic_rule"), function(f) m_text(m$numerics[[f]]), logical(1))), "Retains C39; does not adopt rejected C46 or permit post hoc tolerance widening")
  mt <- m$metamorphic
  add("metamorphic IDs unique", m_rows(mt) && !anyDuplicated(vapply(mt, function(x) x$id, character(1))), "No duplicated relation IDs")
  add("metamorphic applicability", m_rows(mt) && length(mt) > 0 && all(vapply(mt, function(x) m_text(x$id) && is.logical(x$applicable) && length(x$applicable) == 1 && m_text(x$preconditions) && m_text(x$rationale) && (!isTRUE(x$applicable) || (m_text(x$transformation) && m_text(x$expected_relation))), logical(1))), "Assess row order and unused fields; only valid relations must run")
  add("structural disposition", m_enum(m$structural_review$policy, c("required", "conditional")) && m_text(m$structural_review$rationale) && m_strings(m$structural_review$fixture_covered_rule_ids, TRUE), "C30 relaxation requires coverage or review for uncovered rules")
  add("rule coverage", m_strings(m$judged_rule_ids) && all(unlist(m$structural_review$fixture_covered_rule_ids) %in% unlist(m$judged_rule_ids)), "Coverage names actual locked rules")
  add("dominance plan", all(vapply(c("unit", "metric", "thresholds", "rationale", "flag_consequence"), function(f) m_text(m$dominance[[f]]), logical(1))), "Project-specific; 1000/30/one-third are not universal defaults; never auto-exclude")
  add("output-field completeness", m_rows(m$output_fields) && m_equal_ids(lapply(m$output_fields, function(x) x$field), s3$required_outputs) && all(vapply(m$output_fields, function(x) m_text(x$outcome_semantics), logical(1))), "C53: every required output defines all outcomes including null/empty cases")
  add("replay output plan", m_strings(m$replay_outputs), "Lock all deterministic critical output file paths before running")
  add("dependency coverage plan", is.list(m$receipt_dependencies) && all(c("source", "fixtures", "reconciliation", "structural", "validation", "lineage", "methodology") %in% names(m$receipt_dependencies)) &&
    all(vapply(m$receipt_dependencies, m_strings, logical(1))), "Lock project-relative dependencies per receipt, including inputs, code/config and outputs")
  if (isTRUE(m$triggers$decision_outcome)) add("outcome contract", all(vapply(c("action", "alternative", "window", "metric", "counterfactual_design", "minimum_worthwhile_gain", "guardrails", "owner", "followup_run_id"), function(f) m_text(m$outcome_contract[[f]]), logical(1))), "Comparison fixed before outcomes; profit requires costs; follow-up does not reopen original question")
})

# Compare named semantic tables, preserving string identifiers (including leading zeros).
m_compare <- function(a, b, plan) {
  fields <- unique(c(unlist(plan$keys), unlist(plan$exact_fields), unlist(plan$numeric_fields)))
  if (!is.data.frame(a) || !is.data.frame(b) || anyDuplicated(names(a)) || anyDuplicated(names(b)) || !all(fields %in% names(a)) || !all(fields %in% names(b))) return(FALSE)
  keys <- unlist(plan$keys)
  canonical <- function(d) {
    k <- d[, keys, drop = FALSE]
    if (anyNA(k) || anyDuplicated(k) || any(vapply(k, function(x) any(!nzchar(trimws(as.character(x)))), logical(1)))) return(NULL)
    d[do.call(order, c(unname(k), list(na.last = TRUE, method = "radix"))), fields, drop = FALSE]
  }
  a <- canonical(a); b <- canonical(b)
  if (is.null(a) || is.null(b) || nrow(a) != nrow(b)) return(FALSE)
  exact <- unique(c(keys, unlist(plan$exact_fields)))
  if (!all(vapply(exact, function(f) identical(as.character(a[[f]]), as.character(b[[f]])), logical(1)))) return(FALSE)
  all(vapply(unlist(plan$numeric_fields), function(f) {
    x <- suppressWarnings(as.numeric(a[[f]])); y <- suppressWarnings(as.numeric(b[[f]]))
    # Missingness is permitted ONLY under an explicit locked flag/token contract.
    rule <- plan$numeric_missingness[[f]]
    keep <- rep(TRUE, nrow(a))
    if (!is.null(rule)) {
      if (!m_missing_rule(rule, plan) || !rule$flag_field %in% names(a)) return(FALSE)
      fa <- as.character(a[[rule$flag_field]]); fb <- as.character(b[[rule$flag_field]])
      if (anyNA(fa) || !identical(fa, fb) || !all(fa %in% c(m_missing_values(rule), rule$present_value))) return(FALSE)
      missing <- fa %in% m_missing_values(rule)
      if (anyNA(a[[f]][missing]) || anyNA(b[[f]][missing]) ||
          !all(as.character(a[[f]][missing]) == rule$missing_token) ||
          !all(as.character(b[[f]][missing]) == rule$missing_token)) return(FALSE)
      keep <- !missing
    }
    all(is.finite(x[keep])) && all(is.finite(y[keep])) && all(abs(x[keep]-y[keep]) <= plan$absolute_tolerance + plan$relative_tolerance * pmax(abs(x[keep]), abs(y[keep])))
  }, logical(1)))
}
m_csv <- function(ref, root) read.csv(file.path(root, ref$path), colClasses = "character", check.names = FALSE, na.strings = character())
m_execution <- function(s3, s4, root) m_checks(function(add) {
  for (x in m_source(s3, s4, root)) add(x$check, x$result == "PASS", x$detail)
  m <- s3$methodology
  add("design gate", all(vapply(m_design(s3, root = root), function(x) x$result == "PASS", logical(1))), "Design contract must pass even when Workflow Gate is called directly")
  roles <- names(s4$evidence_receipts)
  add("receipt dependency coverage", all(names(m$receipt_dependencies) %in% roles), "All locked receipt roles are present")
  for (role in roles) {
    ref <- s4$evidence_receipts[[role]]
    ok <- m_ref_ok(ref, root)
    r <- if (ok) m_read(file.path(root, ref$path)) else NULL
    # C3 (2026-10-31): a role receipt binds its own inputs only; other roles' receipts are checked directly, never inherited.
    peers <- unlist(lapply(s4$evidence_receipts[setdiff(roles, role)], function(x) x$path))
    add(paste("dependencies", role), ok && identical(r$design_sha256, m_hash(file.path(root, "artifacts/stage3_locked_design.json"))) &&
      m_refs_ok(r$dependencies, root) && m_equal_ids(lapply(r$dependencies, function(d) d$path), as.list(setdiff(unlist(m$receipt_dependencies[[role]]), peers))), "PASS binds exact design and declared source/code/config/output dependencies; no other role's receipt")
  }
  ref <- s4$evidence_receipts$methodology
  r <- if (m_ref_ok(ref, root)) m_read(file.path(root, ref$path)) else NULL
  for (x in m_validation(s3, r, root)) add(x$check, x$result == "PASS", x$detail)
  add("methodology evidence", is.list(r) && identical(r$status, "PASS") && identical(r$target_id, m$analytical_target$id), "Actual output identities and target must match")
  cps <- r$checkpoints
  add("checkpoint IDs", m_rows(cps) && m_equal_ids(lapply(cps, function(x) x$id), lapply(m$checkpoints, function(x) x$id)), "No missing or duplicate checkpoints")
  for (p in m$checkpoints) {
    matches <- Filter(function(x) identical(x$id, p$id), cps)
    x <- if (length(matches) == 1) matches[[1]] else NULL
    ok <- m_ref_ok(x$a, root) && m_ref_ok(x$b, root)
    add(paste("checkpoint", p$id), ok && m_compare(m_csv(x$a, root), m_csv(x$b, root), p), "Recomputed key membership and exact/numeric field comparisons")
  }
  tests <- r$metamorphic
  expected <- unlist(lapply(Filter(function(x) isTRUE(x$applicable), m$metamorphic), function(x) paste(x$id, c("R-A", "R-B"), sep = ":")))
  actual <- lapply(tests, function(x) paste(x$id, x$path_id, sep = ":"))
  add("metamorphic coverage", m_rows(tests) && m_equal_ids(actual, as.list(expected)) && all(vapply(tests, function(x) identical(x$result, "PASS") && m_ref_ok(x$report, root), logical(1))), "Both implementations run every applicable relation; referenced reports retained")
  specs <- r$sensitivity
  add("sensitivity coverage", m_rows(specs) && m_equal_ids(lapply(specs, function(x) x$id), lapply(m$sensitivity$specifications, function(x) x$id)) && all(vapply(specs, function(x) m_enum(x$status, c("evaluated", "failed")) && m_ref_ok(x$report, root) && m_text(x$interpretation), logical(1))), "Keep failed branches; instability restricts claims rather than being hidden")
  add("module coverage", is.list(r$modules) && all(vapply(names(m$modules), function(id) {
    p <- m$modules[[id]]; x <- r$modules[[id]]
    if (isTRUE(p$required)) m_enum(x$disposition, c("adequate", "scope_restricted", "insufficient")) && m_text(x$interpretation) && m_ref_ok(x$report, root)
    else identical(x$disposition, "NOT_APPLICABLE")
  }, logical(1))), "Scientific inadequacy may narrow inference; computational failure never becomes a PASS by choosing hold")
  add("fixture depth", identical(r$fixtures$production_reader_a, "PASS") && identical(r$fixtures$production_reader_b, "PASS") &&
    identical(r$fixtures$poison_probe_a, "PASS") && identical(r$fixtures$poison_probe_b, "PASS") && m_ref_ok(r$fixtures$report, root), "C41: reader roundtrip plus tests that reject a poison judge")
  add("smoke runs", identical(r$smoke$status, "PASS") && isTRUE(r$smoke$non_reporting) && m_ref_ok(r$smoke$report, root), "C51 run provenance only; smoke outputs cannot become analytical evidence")
  add("dominance evidence", m_enum(r$dominance$status, c("NO_FLAG", "FLAG", "NOT_APPLICABLE")) && m_text(r$dominance$disposition) && m_ref_ok(r$dominance$report, root), "Flag disclosure implements locked consequences; no silent row dropping")
  env <- r$reproducibility
  add("environment manifest", all(vapply(c("r_version", "os", "locale", "timezone", "encoding", "rng", "seeds", "sql_client", "sql_mode", "threads", "workflow_commit", "project_commit", "working_tree", "replay_command", "retention"), function(f) m_text(env[[f]]), logical(1))) && m_ref_ok(env$package_lock, root) && m_ref_ok(env$session_info, root), "Use explicit unavailable/not-applicable with reason; never invent hosted details")
  replay <- r$replay
  add("replay output coverage", m_equal_ids(lapply(replay$outputs, function(x) x$original$path), m$replay_outputs), "Replay every locked critical output, not a convenient subset")
  add("clean replay", isTRUE(replay$clean_session) && identical(replay$exit_status, 0L) && identical(replay$status, "PASS") && m_ref_ok(replay$report, root) &&
    m_rows(replay$outputs) && length(replay$outputs) > 0 && all(vapply(replay$outputs, function(x) m_ref_ok(x$original, root) && m_ref_ok(x$replayed, root) && identical(x$original$sha256, x$replayed$sha256), logical(1))), "Replay deterministic published outputs; stochastic inference uses locked persisted fit/splits; no AI regeneration required")
  add("result inventory", m_rows(r$results) && length(r$results) > 0 && !anyDuplicated(vapply(r$results, function(x) x$id, character(1))) && all(vapply(r$results, function(x) m_text(x$id) && m_text(x$locator) && identical(x$target_id, m$analytical_target$id) && m_ref_ok(x$artifact, root), logical(1))), "Authoritative result IDs and artifact locations for Finish")
  add("execution change log", m_rows(r$changes) && all(vapply(r$changes, function(x)
    all(vapply(m_change(x), function(c) identical(c$result, "PASS"), logical(1))), logical(1))), "Corrections, amendments and exploration retain exposure and dependency impact; empty list only when no changes")
  add("all evidence references current", m_refs_ok(r, root), "Includes nested checkpoint, replay, sensitivity and test report bytes")
})

m_ai <- function(records, roles, root, stage) m_checks(function(add) {
  add(paste(stage, "AI role coverage"), m_rows(records) && m_equal_ids(lapply(records, function(x) x$role), as.list(roles)), "Observable provenance, not a guarantee of independent errors")
  for (x in records) {
    add(paste(stage, "AI provenance", x$role), all(vapply(c("provider", "model", "session", "settings", "seeds", "context_disclosure", "first_pass_frozen_at", "peer_access", "contamination"), function(f) m_text(x[[f]]), logical(1))) && m_ref_ok(x$input, root) && m_ref_ok(x$output, root), "Archive visible inputs/outputs; unavailable metadata explicitly disclosed; no hidden reasoning requested")
    if (identical(stage, "execution")) add(paste("build barrier", x$role), identical(x$peer_access, "none_before_freeze"), "R-A/R-B build independence retained")
    if (identical(stage, "design")) add(paste("no coordinator draft", x$role), identical(x$coordinator_draft_seen, FALSE), "C02 retained; peer exposure allowed under C01 and disclosed")
  }
})
m_finish <- function(s3, s4, s5, root) m_checks(function(add) {
  ref <- s4$evidence_receipts$methodology
  evidence <- if (m_ref_ok(ref, root)) m_read(file.path(root, ref$path)) else NULL
  claims <- s5$claim_ledger
  add("claim coverage", m_rows(claims) && length(claims) > 0 && m_equal_ids(lapply(claims, function(c) c$id), s5$substantive_claim_ids), "Reviewer-declared inventory must cover every substantive deliverable claim")
  for (c in claims) {
    add(paste("claim", c$id), identical(c$target_id, s3$methodology$analytical_target$id) &&
      m_enum(c$type, unlist(s3$methodology$analytical_target$allowed_claim_types)) &&
      all(vapply(c("wording", "warrant", "contrary_evidence", "defeater", "uncertainty", "scope", "sensitivity", "reviewer", "disposition"), function(f) m_text(c[[f]]), logical(1))) &&
      m_strings(c$result_ids) && all(unlist(c$result_ids) %in% vapply(evidence$results, function(x) x$id, character(1))) &&
      m_strings(c$premise_ids, TRUE) && all(unlist(c$premise_ids) %in% vapply(s3$methodology$premises, function(x) x$id, character(1))) &&
      identical(c$numerical_audit, "PASS") && identical(c$inference_review, "PASS") && identical(c$unresolved_objections, 0L) &&
      m_ref_ok(c$review_evidence, root) && m_ref_ok(c$deliverable, root) && c$deliverable$path %in% unlist(s5$deliverables), "Numbers and inferential warrants reviewed separately; gate does not establish truth")
    if (identical(c$type, "recommendation") || m_words(c$wording, s3$methodology$operational$action_lexicon)) add(paste("action values", c$id), m_text(c$owner_tradeoff) && m_text(c$action) && m_text(c$evidence_tag) && m_text(c$tag_assigned_by), "C37 tag assigned by coordinator from reviewed claims; action lexicon locked in Design")
  }
  if (any(vapply(claims, function(c) m_words(c$wording, s3$methodology$operational$finality_lexicon), logical(1)))) add("finality review", m_ref_ok(s5$monitoring_next_question_review, root), "Finality wording requires explicit monitoring/next-question interpretation")
  add("claim inventory audit", identical(s5$claim_coverage_review$status, "PASS") && m_ref_ok(s5$claim_coverage_review$report, root), "No automatic natural-language completeness claim")
  if (identical(s5$assurance$outcome_evaluation, "evaluated")) add("evaluated outcome evidence", m_ref_ok(s5$outcome_followup$evaluation_report, root), "Evaluated outcomes require a linked report, not a status alone")
  add("revision disposition", m_enum(s5$revision$status, c("UNCHANGED", "PASS")) && identical(s5$revision$unresolved_flags, 0L) && m_ref_ok(s5$revision$report, root), "C48/C50 one consolidated revision plus mechanical verification; unresolved FLAG blocks Finish")
  inadequate <- any(vapply(evidence$modules, function(x) x$disposition %in% c("scope_restricted", "insufficient"), logical(1)))
  add("inference reflects module limitations", !inadequate || s5$assurance$inference %in% c("scope_restricted", "insufficient"), "Cannot upgrade an inadequate method module to blanket adequacy in the certificate")
  add("separate assurance dimensions", identical(s5$assurance$computation, "verified") &&
    m_enum(s5$assurance$inference, c("adequate", "scope_restricted", "insufficient")) &&
    m_enum(s5$assurance$decision, c("act", "pilot", "hold", "insufficient_evidence", "no_action_required")) &&
    m_enum(s5$assurance$outcome_evaluation, c("not_applicable", "pending", "evaluated")), "Procedure PASS does not imply profitable action or causal validity")
  if (isTRUE(s3$methodology$triggers$decision_outcome)) {
    locked <- s3$methodology$outcome_contract
    handoff <- s5$outcome_followup
    contract_ok <- m_ref_ok(handoff$contract, root)
    saved <- if (contract_ok) m_read(file.path(root, handoff$contract$path)) else NULL
    add("outcome handoff", identical(handoff$run_id, locked$followup_run_id) && identical(handoff$owner, locked$owner) &&
      contract_ok && is.list(saved) && setequal(names(saved), names(locked)) &&
      all(vapply(names(locked), function(id) identical(saved[[id]], locked[[id]]), logical(1))),
      "Handoff JSON preserves the locked comparison and owner; changes require amendment")
    add("required outcome status", m_enum(s5$assurance$outcome_evaluation, c("pending", "evaluated")),
      "Required follow-up cannot be relabeled not applicable; pending is an honest unknown outcome")
  }
})

m_change <- function(change) m_checks(function(add) {
  add("change classification", m_enum(change$change_class, c("implementation_correction", "design_amendment", "exploratory", "presentation")), "Record what changed, not whether the result is convenient")
  add("exposure disclosure", m_text(change$results_seen) && m_text(change$data_seen) && m_text(change$reason), "Post-result locks remain post-result")
  add("dependency invalidation", m_strings(change$affected_artifacts) && m_strings(change$rerun_steps) && m_text(change$target_effect), "Invalidate and rerun affected dependency closure")
  if (identical(change$change_class, "implementation_correction")) add("unchanged design", identical(change$target_effect, "unchanged") && m_text(change$locked_clause), "A correction implements the same locked clause")
  if (identical(change$change_class, "exploratory")) add("exploration separate", identical(change$confirmatory, FALSE), "Exploration cannot silently amend confirmatory evidence")
})

# acceptance-v1: prospective recorded-process checks; never a browser interlock.
m_pass <- function(x) length(x) > 0 && all(vapply(x, function(z) identical(z$result, "PASS"), logical(1)))
m_time <- function(x) {
  if (!m_text(x) || !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", x)) return(NA_real_)
  as.numeric(as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
}
m_words <- function(text, lexicon) {
  words <- unlist(strsplit(tolower(gsub("_", " ", paste(text, collapse = " "))), "[^[:alnum:]]+"))
  any(tolower(unlist(lexicon)) %in% words)
}
m_operational_design <- function(s3, root) m_checks(function(add) {
  o <- s3$methodology$operational
  add("source applicability locked", m_enum(o$source_contract$kind,c("sql","file")) && m_text(o$source_contract$rationale), "File-only inputs do not imply a SQL gate PASS")
  add("operational version", identical(o$version, "acceptance-v1"), "Prospective contracts require acceptance-v1")
  add("language rules", m_strings(o$action_lexicon) && m_strings(o$finality_lexicon) && m_text(o$negation_rule) && m_text(o$evidence_tag_rule), "Lock lexical triggers; contextual review remains human/AI work")
  add("frozen fixture oracle", m_ref_ok(o$fixture_inputs, root) && m_ref_ok(o$fixture_expected, root) && m_text(o$oracle_basis) && m_text(o$oracle_reviewer), "Input and independently justified expected answers frozen in Design")
  add("output rules", m_rows(o$output_rules) && m_equal_ids(lapply(o$output_rules, function(x) x$field), s3$required_outputs) && all(vapply(o$output_rules, function(x) m_enum(x$kind, c("literal", "enum", "computed")) && m_text(x$rule), logical(1))), "Every output defines literal, enum or computed semantics")
  add("packet contract", m_strings(o$packet_requirements) && all(c("output_rules", "checkpoint_output_rules", "checkpoints", "receipt_dependencies", "accepted_code") %in% unlist(o$packet_requirements)), "Execution packets carry authoritative sections, not summaries")
  v <- o$validation_components
  add("test component coverage", is.list(v) && setequal(names(v), c("R-A", "R-B", "harness", "configuration", "input")) && all(vapply(v, m_strings, logical(1))) && all(vapply(unlist(v), function(p) !grepl("^(/|[A-Za-z]:)", p) && !any(strsplit(p, "/", fixed=TRUE)[[1]] %in% c("", ".", "..")), logical(1))), "Lock project-relative component paths, bind hashes at execution")
  for (x in s3$methodology$metamorphic) if (isTRUE(x$applicable)) add(paste("MR discrimination", x$id), m_enum(x$coverage_type, c("nonconstant", "boundary", "negative_control")) && m_text(x$detectable_defect), "Do not certify effectiveness from an empty or constant output alone")
})
m_validation <- function(s3, receipt, root) m_checks(function(add) {
  v <- receipt$test_versions; locked <- s3$methodology$operational$validation_components
  add("validation component identities", is.list(v$components) && setequal(names(v$components), names(locked)) && all(vapply(names(locked), function(k) m_rows(v$components[[k]]) && m_refs_ok(v$components[[k]], root) && m_equal_ids(lapply(v$components[[k]], function(x) x$path), locked[[k]]), logical(1))), "Every test binds current R-A/R-B, harness, configuration and input bytes")
  expected <- c("fixtures:R-A", "fixtures:R-B", "replay", "reconciliation", unlist(lapply(Filter(function(x) isTRUE(x$applicable), s3$methodology$metamorphic), function(x) paste("metamorphic", x$id, c("R-A", "R-B"), sep=":"))))
  add("versioned test coverage", m_rows(v$tests) && m_equal_ids(lapply(v$tests, function(x) x$id), as.list(expected)), "No missing or duplicate versioned tests")
  for (x in v$tests) {
    r <- if (m_ref_ok(x$report, root)) m_read(file.path(root, x$report$path)) else NULL
    add(paste("versioned result", x$id), identical(x$result, "PASS") && identical(x$components, v$components) && identical(r$id, x$id) && identical(r$result, "PASS") && identical(r$components, x$components) && identical(r$recorded_at_utc, x$recorded_at_utc) && is.finite(m_time(x$recorded_at_utc)) && m_time(x$recorded_at_utc) <= as.numeric(Sys.time())+2, "Actual report embeds tested versions; refreshing a receipt wrapper is insufficient")
  }
  add("triage register", m_rows(receipt$triage) && all(vapply(receipt$triage, function(x) m_text(x$id) && m_text(x$disposition) && (identical(x$status, "resolved") || (identical(x$status, "accepted_limitation") && !identical(x$severity, "blocking") && m_ref_ok(x$owner_approval, root))) && m_ref_ok(x$evidence, root), logical(1))), "Blocking findings must be repaired; limitation acceptance is owner-reserved")
  e <- receipt$reproducibility; restore <- if(m_ref_ok(e$restore_report, root)) m_read(file.path(root,e$restore_report$path)) else NULL
  add("environment restoration", m_ref_ok(e$environment_spec, root) && identical(restore$status,"PASS") && isTRUE(restore$fresh_environment) && identical(restore$environment_spec,e$environment_spec) && m_ref_ok(restore$console,root), "A package list alone is not an environment restoration test")
})
# Stage review roles the gate requires (one source for m_ai in procedure_gate and for review coverage).
# start/framing (2026-10-31, F1, owner card t1665s6948): the reviews each stage receipt claims (stage1 ai2_independent_reconstruction,
# ai3_independent_red_team; stage2 ai1_builder, ai2_decision_fit_review, ai3_framing_red_team), role ids as in the start/framing guide sec. 4.
m_stage_ai_roles <- list(start=c("independent_reconstruction","red_team"), framing=c("framing_builder","decision_fit_review","framing_red_team"), design=c("designer_a","designer_b","risk_reviewer"), finish=c("interpreter","inference_reviewer","numerical_auditor"))
m_stage_receipts <- c(start="artifacts/stage1_decision.json", framing="artifacts/stage2_framing.json", design="artifacts/stage3_locked_design.json",
  execution="artifacts/stage4_validation_status.json", finish="artifacts/stage5_interpretation_status.json")
# Paths reachable from a JSON file through hash references (current refs only; the operations ledger itself is not a source).
m_reachable <- function(start, root) {
  seen <- character(0); todo <- list(start)
  while (length(todo)) { ref <- todo[[1]]; todo <- todo[-1]
    if (!m_ref_ok(ref, root) || ref$path %in% seen || startsWith(ref$path, "artifacts/operations/")) next
    seen <- c(seen, ref$path)
    if (grepl("\\.json$", ref$path, ignore.case = TRUE)) todo <- c(todo, m_refs(m_read(file.path(root, ref$path)))) }
  seen
}
# R1 (2026-10-31, owner card t1651s6906 option B): review coverage. Every review the stage requires has exactly one ledger send with a
# captured reply that is hash-bound to it and ends with its own END_REPLY marker. Required = every transcripts/<stage>/*_reply the stage
# receipt reaches, plus the gate's role list for the stage, cross_review when the receipt claims it, and a structural reviewer when the
# locked plan requires structural review. Replaces the paperwork rules cut on the same date (see docs/CHANGES_FROM_ABLATIONS.md).
m_review_coverage <- function(add, root, stage, sends, receipt_path) {
  rp <- if (m_text(receipt_path)) receipt_path else unname(m_stage_receipts[stage])
  rpath <- file.path(root, rp); receipt <- if (length(rp) == 1 && !is.na(rp) && file.exists(rpath)) m_read(rpath) else NULL
  add(paste("review coverage", stage, "receipt"), is.list(receipt), "The stage receipt defines which reviews are required")
  if (!is.list(receipt)) return(invisible(NULL))
  reached <- m_reachable(list(path = rp, sha256 = m_hash(rpath)), root)
  need_replies <- unique(reached[startsWith(reached, paste0("transcripts/", stage, "/")) & grepl("_reply(\\.|$)", basename(reached))])
  need_roles <- c(m_stage_ai_roles[[stage]], if (identical(receipt$cross_review, "PASS")) "cross_review")
  if (identical(stage, "execution")) {
    sr <- m_read(file.path(root, "artifacts/stage3_locked_design.json"))$methodology$structural_review$policy
    if (identical(sr, "required")) need_roles <- c(need_roles, "structural reviewer")
  }
  rows <- if (m_rows(sends)) sends else list()
  bound <- function(s) {
    cap <- if (m_ref_ok(s$capture, root)) m_read(file.path(root, s$capture$path)) else NULL
    txt <- if (m_ref_ok(s$reply, root)) paste(readLines(file.path(root, s$reply$path), warn = FALSE), collapse = "\n") else ""
    m_text(s$id) && m_text(s$nonce) && m_ref_ok(s$reply, root) && is.list(cap) && identical(cap$send_id, s$id) && identical(cap$reply, s$reply) &&
      m_text(cap$capture_sha256) && identical(tolower(cap$capture_sha256), tolower(s$reply$sha256)) &&
      (is.null(cap$nonce) || identical(cap$nonce, s$nonce)) &&
      endsWith(trimws(txt), paste0("END_REPLY ", s$id, " ", s$nonce))
  }
  # F5: a review counts only if it saw a current artifact the receipt relies on (an attachment whose hash matches that file now).
  current <- function(s) m_rows(s$attachments) && length(s$attachments) > 0 && m_refs_ok(s$attachments, root, FALSE) &&
    any(vapply(s$attachments, function(a) is.list(a) && m_text(a$path) && a$path %in% reached, logical(1)))
  # F4: where the receipt records provenance for a role, that role's send must be the provenance output and the same AI.
  prov <- if (m_rows(receipt$ai_provenance)) receipt$ai_provenance else list()
  prov_ok <- function(s, r) { px <- Filter(function(x) identical(x$role, r), prov)
    !length(px) || (length(px) == 1 && identical(px[[1]]$output, s$reply) && identical(px[[1]]$provider, s$ai)) }  # missing records: m_ai role coverage
  for (p in need_replies) {
    hit <- Filter(function(s) is.list(s$reply) && identical(s$reply$path, p), rows)
    add(paste("review coverage", stage, "reply", p), length(hit) == 1 && bound(hit[[1]]), "Exactly one send captured this required reply, bound by hash, with its own end marker")
  }
  for (r in unique(need_roles)) {
    hit <- Filter(function(s) identical(s$role, r) && bound(s) && current(s) && prov_ok(s, r), rows)
    add(paste("review coverage", stage, "role", r), length(hit) >= 1, "Each required review role has a captured, hash-bound reply from a send that saw current artifacts and matches the recorded provenance")
  }
  for (s in rows) add(paste("review coverage", stage, "capture", s$id), bound(s), "Every sent review reply is its own: capture names this send and reply, hash matches, own END_REPLY marker")
  h <- unlist(lapply(rows, function(s) if (is.list(s$reply) && m_text(s$reply$sha256)) tolower(s$reply$sha256)))
  ids <- vapply(rows, function(s) if (m_text(s$id)) s$id else NA_character_, character(1))
  nonces <- vapply(rows, function(s) if (m_text(s$nonce)) s$nonce else NA_character_, character(1))
  add(paste("review coverage", stage, "unique send ids"), !anyNA(ids) && !anyDuplicated(ids) && !anyNA(nonces) && !anyDuplicated(nonces), "Each send id and nonce appears once in the stage ledger")
  add(paste("review coverage", stage, "distinct replies"), length(h) == length(rows) && !anyDuplicated(h), "No reply is reused for another send")
}
m_operations <- function(root,state,stage,final=FALSE,receipt=NULL) m_checks(function(add) {
  # 2026-10-31 (owner card t1651s6906, option B): paperwork rules P01-P13 cut on ablation evidence (round 2); kept send identity,
  # supersession resolutions and evidence closure; added review coverage. `final` is retained for callers and no longer changes checks.
  o <- m_read(file.path(root,"artifacts/operations",paste0(stage,".json")))
  sends <- o$sends
  add(paste("operations ledger",stage), is.list(o) && m_rows(sends) && length(sends) > 0, "The stage ledger exists and lists its sends")
  for(s in sends) add(paste("send identity",s$id), m_text(s$id) && m_text(s$ai) && m_text(s$nonce) && m_ref_ok(s$packet,root) && m_refs_ok(s$attachments,root,FALSE) && m_ref_ok(s$reply,root) && m_ref_ok(s$capture,root), "Preserve exact packet, files, reply and capture record")
  m_review_coverage(add,root,stage,sends,receipt)
  res <- Filter(function(r) is.list(r) && !any(vapply(sends,function(x) identical(x$packet$path,r$path),logical(1))), if(is.list(o$supersession_resolutions)) o$supersession_resolutions else list())
  if(length(o$supersession_resolutions)) add("supersession resolutions", length(res)==length(o$supersession_resolutions), "A resolved supersedes target must not be a sent packet in this ledger")
  closure <- tryCatch(m_inventory(m_refs(o),root,res),error=function(e) NULL)
  add("operations evidence closure", !is.null(closure), "At stage completion, reject stale nested packet references, including pre-lock candidates")
})
# Transitive JSON reference closure from the authoritative project root.
m_inventory <- function(refs,root,resolutions=list()) {
  seen<-list(); root<-normalizePath(root,winslash="/",mustWork=TRUE)
  # C9 (2026-10-31, owner card t1616s6758): a supersedes reference to a never-sent packet whose recorded sha256 is abbreviated
  # is verified through a hash-checked deviation record that holds the full sha256; the abbreviation must be a >=16-hex prefix of it.
  resolve<-function(ref) {
    pre<-regmatches(tolower(ref$sha256),regexpr("^[0-9a-f]+",tolower(ref$sha256)))
    for(r in resolutions) {
      d<-if(is.list(r$deviation_record) && m_ref_ok(r$deviation_record,root)) m_read(file.path(root,r$deviation_record$path)) else NULL
      if(identical(r$path,ref$path) && isTRUE(r$never_sent) && length(pre)==1 && nchar(pre)>=16 && is.list(d) && identical(d$path,ref$path) &&
         m_text(d$sha256) && nchar(d$sha256)==64 && startsWith(tolower(d$sha256),pre) && isTRUE(d$never_sent)) return(list(path=ref$path,sha256=d$sha256))
    }
    ref
  }
  visit<-function(ref) {
    ref$path <- gsub("\\\\", "/", ref$path)
    if(startsWith(ref$path,paste0(root,"/"))) ref$path<-substring(ref$path,nchar(root)+2)
    if(!m_ref_ok(ref,root)) ref<-resolve(ref)
    if(!m_ref_ok(ref,root)) stop("Missing, unsafe or stale inventory dependency: ",ref$path)
    if(!is.null(seen[[ref$path]])) {if(!identical(seen[[ref$path]]$sha256,ref$sha256))stop("Conflicting inventory identity");return(invisible(NULL))}
    seen[[ref$path]]<<-list(path=ref$path,sha256=ref$sha256,bytes=unname(file.info(file.path(root,ref$path))$size))
    if(grepl("\\.json$",ref$path,ignore.case=TRUE)) for(child in m_refs(m_read(file.path(root,ref$path)))) visit(child)
  }
  for(ref in refs) visit(ref)
  unname(seen[order(names(seen))])
}


# D-22: declared nullable numeric fields need an explicit, keyed missingness policy.
m_missing_values <- function(rule) unlist(if (!is.null(rule[["missing_values"]])) rule[["missing_values"]] else rule[["missing_value"]], use.names=FALSE)
m_missing_rule <- function(rule, plan) {
  is.list(rule) && m_text(rule$flag_field) && rule$flag_field %in% unlist(plan$exact_fields) &&
    xor(is.null(rule[["missing_value"]]), is.null(rule[["missing_values"]])) &&
    length(m_missing_values(rule)) > 0L && is.character(m_missing_values(rule)) &&
    !anyNA(m_missing_values(rule)) && all(nzchar(m_missing_values(rule))) &&
    !anyDuplicated(m_missing_values(rule)) && m_text(rule$present_value) &&
    !rule$present_value %in% m_missing_values(rule) &&
    is.character(rule$missing_token) && length(rule$missing_token)==1L && !is.na(rule$missing_token) &&
    rule$missing_token %in% c("", "null", "NA")
}
m_checkpoint_contract <- function(s3) m_checks(function(add) {
  rules_out <- s3$methodology$operational$checkpoint_output_rules
  # Empty numeric field sets must not invent a checkpoint entry.
  expected <- unlist(lapply(s3$methodology$checkpoints,function(p)if(length(p$numeric_fields))paste(p$id,unlist(p$numeric_fields),sep=":") else character()))
  add("checkpoint output schema coverage",m_rows(rules_out) && m_equal_ids(lapply(rules_out,function(r)paste(r$checkpoint_id,r$field,sep=":")),as.list(expected)),"Lock authoritative output nullability for every numeric checkpoint column")
  for (p in s3$methodology$checkpoints) {
    numeric <- unlist(p$numeric_fields)
    declarations <- p$field_nullability
    rules <- p$numeric_missingness
    add(paste("checkpoint nullability",p$id),
      (!length(numeric) && is.null(declarations) || is.list(declarations) &&
       setequal(names(declarations),numeric) && !anyDuplicated(names(declarations)) &&
       all(vapply(declarations,function(x)is.logical(x)&&length(x)==1&&!is.na(x),logical(1)))),
      "Every numeric checkpoint field explicitly declares nullable true/false")
    for (f in numeric) {
      matches <- Filter(function(r)identical(r$checkpoint_id,p$id)&&identical(r$field,f),rules_out)
      add(paste("output/checkpoint compatibility",p$id,f),length(matches)==1 && is.logical(matches[[1]]$nullable) && length(matches[[1]]$nullable)==1 && !is.na(matches[[1]]$nullable) && identical(matches[[1]]$nullable,declarations[[f]]),"Checkpoint nullability must match the authoritative output schema")
    }
    nullable <- if(is.list(declarations)) names(Filter(isTRUE,declarations)) else character()
    add(paste("checkpoint missingness contract",p$id), setequal(names(rules),nullable) &&
      all(vapply(rules,function(r)m_missing_rule(r,p),logical(1))),
      "Nullable fields need an exact status flag and a nonnumeric missing token; finite-only fields cannot opt out")
  }
})
# Source fidelity is mandatory for both SQL and file-only sources.
m_source <- function(s3,s4,root) m_checks(function(add) {
  kind <- s3$methodology$operational$source_contract$kind
  add("SQL applicability", (identical(kind,"sql") && identical(s4$sql_source_gate,"PASS")) ||
    (identical(kind,"file") && identical(s4$sql_source_gate,"NOT_APPLICABLE")), "N/A is restricted to a locked file-only source")
  ref <- s4$evidence_receipts$source
  r <- if(m_ref_ok(ref,root)) m_read(file.path(root,ref$path)) else NULL
  add("source fidelity", identical(r$status,"PASS") && identical(r$source_kind,kind) &&
    identical(r$sql_extraction_used,identical(kind,"sql")) && identical(r$fidelity_check$status,"PASS") &&
    m_ref_ok(r$fidelity_check$report,root), "Non-SQL inputs still require actual source identity/fidelity evidence")
})
# Canonical references are platform-independent; unsafe traversal is never normalized away.
m_relative_path <- function(path,root) {
  path <- gsub("\\\\","/",path); root <- sub("/+$","",gsub("\\\\","/",root))
  if(!startsWith(tolower(path),paste0(tolower(root),"/"))) stop("Path is outside project root")
  relative <- substring(path,nchar(root)+2)
  if(any(strsplit(relative,"/",fixed=TRUE)[[1]] %in% c("",".","..")))stop("Unsafe relative path")
  relative
}
