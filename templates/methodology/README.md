# Methodology-v3 receipt authoring

These are shape examples, not evidence. Placeholder/PENDING values intentionally cannot pass. Do not copy illustrative scientific choices into a project without review and lock.

- Embed the adapted `design.example.json` as `stage3_locked_design.json.methodology`. Reuse the exact authoritative population/grain and IDs. `exact_decision_fields` covers identifiers/actions; other critical numeric fields can use locked checkpoint tolerances. `replay_outputs` lists every critical deterministic output file.
- Each lower receipt retains its existing payload/status/version/time and adds `design_sha256` plus `dependencies: [{path, sha256}, ...]`. Paths must exactly match the role's Stage-3 `receipt_dependencies`. Those paths include the real source, scripts/helpers, configuration, tests/comparator and resulting artifacts as applicable. Hash after execution; never hand-assert a stale PASS.
- `execution.example.json` is the **methodology receipt**, referenced from Stage 4's `evidence_receipts.methodology`. It consolidates existing evidence rather than replacing the Source/Fixture/Reconciliation receipts. Use all required checkpoint IDs, module dispositions, sensitivity branches and applicable relation IDs for both paths. Include real result/locator/artifact references. No metadata-only receipt proves the scientific validity of its assertions.
- Adapt `ai_provenance.example.json` per actual role. Design roles are `designer_a`, `designer_b`, `risk_reviewer`; Execution roles are `R-A`, `R-B`; Finish roles are `interpreter`, `inference_reviewer`, `numerical_auditor`. Retain Start/Framing AI artifacts in the same project record; the gate currently enforces role-level metadata for Design/Execution/Finish. Do not claim that a non-enforced early-stage field was mechanically certified.
- `claim.example.json` becomes an entry in the existing Stage-5 claim ledger. `substantive_claim_ids` and the audited claim inventory must agree. The final deliverable hash and reviewer report are required. Recommendations additionally record `action`, `evidence_tag`, `tag_assigned_by`, `owner_tradeoff`; these express a reviewed inference and preference, not a mechanical proof that the action is best.
- An unrun structural review uses `NOT_REQUIRED` both in the Stage-4 receipt and in its structural evidence receipt. Record scope/rationale and dependencies; never fake PASS. An executed review uses PASS only after resolution.
- Use `change.example.json` for amendments; keep exposure and dependency impact for corrections/exploration too. `m_change` checks the change record's structure; a permitted completed-lock amendment additionally requires the existing owner-approval, hash chain and archive checks.
- `outcome_contract.example.json` is conditional. If triggered, embed it in Design and link its archived copy and follow-up run ID from Finish's `outcome_followup`. `evaluated` requires an `evaluation_report` reference. Leave outcomes pending when the counterfactual/outcome data do not exist.

## Helpers

```r
source(file.path(workflow_repo, "methodology/contracts.R"))
source(file.path(workflow_repo, "methodology/tools.R"))

# Run separately with each independently built project adapter.
report_path <- m_metamorphic(
  run = independent_adapter, input = frozen_input,
  transform = function(d) d[rev(seq_len(nrow(d))), , drop = FALSE],
  compare = function(a, b) m_compare(a, b, locked_checkpoint),
  relation_id = "row_order", preconditions = "Stable IDs; row order is not semantic",
  path_id = "R-A", directory = file.path(project_root, "validation/metamorphic")
)
```

`m_replay(script, frozen_root, output_root, outputs, report_directory)` executes a reviewed R script under `--vanilla`. The script receives frozen-root and fresh-output-root arguments. It must actually recompute the result from frozen inputs, not copy expected outputs; review establishes that property. The helper detects modification of existing frozen files and compares replayed output hashes to the **pre-run** originals. Reference its report and both sets of output files from the methodology receipt. Preserve failures; do not set `clean_session` or PASS from an unexecuted command.

`m_environment` captures session/package inventory. Supply a retrievable package lock separately. Project-specific source/query checks, fixture adapters, numerical/stochastic policy and substantive method reviews remain project work. This reusable framework cannot honestly generate their scientific evidence in advance.
# Step 3 synchronization clarification

Active scientific modules use `required: true`, a rationale and a plan; inactive modules use `required: false`, a rationale and `status: NOT_APPLICABLE`. The JSON schema and R gate now accept both shapes consistently. The R gate remains responsible for checking whether the declared trigger actually requires the module.

For a required outcome follow-up, `outcome_followup.contract` references a JSON copy of the locked `methodology.outcome_contract` object, with its SHA-256. Preserve its owner, comparison and follow-up run ID. Use `pending` until evaluated; `not_applicable` cannot discharge a required follow-up.
