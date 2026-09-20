# Prospective workflow gate v2

This executable contract applies to new project runs. Frozen historical packs and their gate scripts are not retrofitted.

## Run

Install `jsonlite` and `digest`. Run the gate from the repository root with the project root argument. The generic gate reads Stage 1–4 JSONs from `artifacts/` and writes `artifacts/workflow_gate_status.json`. Project adapters retain their documented paths.

## Required additions to receipts

- Stage 2: `capacity_stance` is exactly `unordered_ok` or `hard_attention_budget`.
- Stage 3: `ml_mode` is exactly `None`, `A`, or `B`; declare `fixture_version`, all `fixture_ids`, and `reconciliation_critical_fields`.
- A hard attention budget also requires Stage 3 `ranking_contract`: nonempty `key`, `tie_break`, `capacity_unit`; `membership_first: true`; `padding_allowed: false`; and either a positive integer `n` or `owner_n_deferred: true`. Deferred N never permits Stage 5 to invent ranking.
- Stage 4: matching `fixture_version_used`; `structural_cross_review: "PASS"`; `decision_critical_model_required` is true only for Mode A; `decision_critical_model_validation` is PASS for A and NOT_REQUIRED for None/B.
- Stage 4 `evidence_receipts` maps each required role to `{"path": "relative/file.json", "sha256": "actual 64-character SHA-256"}`.

Required roles: `source`, `fixtures`, `reconciliation`, `structural`, `validation`, `lineage`; also `model` in Mode A.

Each receipt must be a nonempty JSON file inside the project root with an exact hash, `status: "PASS"`, matching `design_version` and `fixture_version`, and nonempty `checked_at_utc`. Absolute paths and parent-directory escapes are rejected.

Additional contents:

| Receipt | Required payload |
|---|---|
| reconciliation | `fields` matches the locked critical-field set; `mismatch_count: 0`; nonnegative integer `row_count` |
| fixtures | `cases` array with all frozen IDs exactly once and columns `id`, `expected`, `observed_a`, `observed_b`; both observations match expected |
| lineage | Nonempty `source_snapshot`, `extract_identity`, and `script_versions` identifiers |

The output records contract version, design/fixture versions, receipt identities, check results, timestamp, and Stage 5 permission.

## Boundary

Hash verification establishes that the gate consumed the declared receipt bytes. It does not authenticate the author, prove the statements inside receipts, rerun SQL/R analysis, independently establish model validity, or verify semantic independence of builders. Those remain lower-tier analytical and human review responsibilities. Mode A's model receipt records completed validation; this gate does not train or score a model. Mode B must not alter judged actions or silently rank a budgeted list.

The test suite uses synthetic receipts only. Passing it is implementation evidence, not a completed real-project gate approval.
