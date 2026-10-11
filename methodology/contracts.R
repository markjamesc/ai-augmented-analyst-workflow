# Prospective methodology-v3. Pure validators: never execute project commands.
m_text <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x)) &&
  !grepl("^(TODO|TBD|REPLACE|PENDING|\\{\\{)", trimws(x), ignore.case = TRUE)
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
    # Nonfinite values fail; represent meaningful missingness as exact semantic fields.
    all(is.finite(x)) && all(is.finite(y)) && all(abs(x-y) <= plan$absolute_tolerance + plan$relative_tolerance * pmax(abs(x), abs(y)))
  }, logical(1)))
}
m_csv <- function(ref, root) read.csv(file.path(root, ref$path), colClasses = "character", check.names = FALSE, na.strings = character())
m_execution <- function(s3, s4, root) m_checks(function(add) {
  m <- s3$methodology
  add("design gate", all(vapply(m_design(s3, root = root), function(x) x$result == "PASS", logical(1))), "Design contract must pass even when Workflow Gate is called directly")
  roles <- names(s4$evidence_receipts)
  add("receipt dependency coverage", all(names(m$receipt_dependencies) %in% roles), "All locked receipt roles are present")
  for (role in roles) {
    ref <- s4$evidence_receipts[[role]]
    ok <- m_ref_ok(ref, root)
    r <- if (ok) m_read(file.path(root, ref$path)) else NULL
    add(paste("dependencies", role), ok && identical(r$design_sha256, m_hash(file.path(root, "artifacts/stage3_locked_design.json"))) &&
      m_refs_ok(r$dependencies, root) && m_equal_ids(lapply(r$dependencies, function(d) d$path), m$receipt_dependencies[[role]]), "PASS binds exact design and declared source/code/config/output dependencies")
  }
  ref <- s4$evidence_receipts$methodology
  r <- if (m_ref_ok(ref, root)) m_read(file.path(root, ref$path)) else NULL
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
    if (identical(c$type, "recommendation")) add(paste("action values", c$id), m_text(c$owner_tradeoff) && m_text(c$action) && m_text(c$evidence_tag) && m_text(c$tag_assigned_by), "C37 tag assigned by coordinator from reviewed claims; action lexicon locked in Design")
  }
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
