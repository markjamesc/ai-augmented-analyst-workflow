# Live acceptance repairs: ACC-SMALL-REMEDIATION-001

Prospective candidate based on 088fffe14356a2537fb8642b6cb2dbd389675716. Procedure version 2.2-livefix-v1. No original evidence or existing published branch is changed. This repair does not turn the failed run into a PASS. The owner's “raised the amount to 25” referred to money/data usage, not an analytical setting or approval.

## Findings and exact implementation

- **D-20:** `methodology/tools.R:m_freeze_file` creates content-addressed candidate snapshots without overwriting existing files. Send packets reference the snapshot returned by this helper. Final lock is a distinct artifact. `methodology/contracts.R:m_operations` recursively checks nested JSON references at completion. `procedure-gate/procedure_gate.R` stores that dependency closure and verifies it before later transitions. A rewritten candidate fails early; no later hash repair may erase the historical send.
- **D-22:** `methodology/contracts.R:m_checkpoint_contract` checks the authoritative `operational.checkpoint_output_rules` schema against each checkpoint's `field_nullability`. Every numeric column declares nullability. A nullable column requires `numeric_missingness` with an exact compared flag, present/missing values and an explicit missing token (`""`, `"null"`, or `"NA"`). `m_compare` compares membership and flags exactly, enforces the token, then compares finite values only on matching present rows. Unknown flags, unexpected nonfinite values, token differences, wrong keys and null-versus-zero fail. `methodology/schema.json` and Design templates expose the fields; Execution packet checks require the full schema. This is not general tolerance widening or nonfinite acceptance.
- **Source applicability (a):** Design locks `operational.source_contract.kind` as sql or file with rationale. SQL requires sql_source_gate=PASS; file-only requires NOT_APPLICABLE. Both require source receipt PASS, matching source_kind/sql_extraction_used and fidelity_check={status:PASS,report:{path,sha256}}. Existing source hashes/dependencies remain mandatory. `workflow-gate/workflow_gate.R` delegates applicability to the shared validator instead of demanding a false SQL PASS.
- **Nested gate visibility (b):** Procedure Gate reports and completion records now explicitly contain workflow_gate.status=NOT_RUN and blocked_by when earlier checks prevent invocation. A diagnostic Workflow Gate run on a separately labeled COPY may aid troubleshooting but cannot release the actual run or satisfy its approval conditions. No automatic extra diagnostic run is introduced.
- **Windows references D-03 (c):** `m_relative_path` generates safe slash-separated project-relative authorization paths; `m_file_ref` canonicalizes new reference paths; inventory normalizes legacy internal separators for verification. No original evidence is rewritten and no coordinator mirror alias is required for new references.
- **Restore D-27 (d):** `m_run_child` explicitly sets inherited environment variables, invokes Rscript without system2(env=), and restores the parent's environment on success/failure. `tools/run_restore.R` runs an owner-reviewed project restore script against a new library and attempt directory, probes actual child environment/library paths and captures package versions before/after. CHILD_CHECKS_PASS is deliberately not a restoration certificate. The actual project script was not supplied; its adaptation and spec/output comparison remain required.
- **D-06/D-07:** Sends require timestamp_basis, timestamp_uncertainty_seconds and dispatch_evidence. Earliest possible send must follow authorization/dependency verification. A possible >900-second delay requires a retained report; uncertainty cannot be called timely. Capture requires an actual hashed screenshot, screen recording or browser export in capture_evidence and an explicit capture_method. Bare screen_verified=true is insufficient. These checks verify records, not the truth of AI identities or observations.

## Corrected nullable checkpoint example

The project must use its actual output column names and encoding. The following is an illustrative contract, NOT a replacement for the owner's new Design lock:

```json
{
  "checkpoint_output_rules": [
    {"checkpoint_id":"CP-ledger","field":"amount_value","nullable":true}
  ],
  "checkpoint": {
    "id":"CP-ledger",
    "keys":["id"],
    "exact_fields":["amount_state"],
    "numeric_fields":["amount_value"],
    "field_nullability":{"amount_value":true},
    "numeric_missingness":{
      "amount_value":{
        "flag_field":"amount_state",
        "missing_value":"missing",
        "present_value":"present",
        "missing_token":""
      }
    },
    "absolute_tolerance":0,
    "relative_tolerance":0
  }
}
```

If no existing output flag distinguishes missingness, adding one requires compatible builder/harness changes and new validation. Do not assume the old builds can be reused until their actual output schema is reviewed. Keep the threshold, eligibility, ranking, capacity and expected answer unchanged unless separately amended by the owner.

## Successor restart and reuse

The current successor command starts at **Start** with no inherited completions. Substantive redesign begins at Design. Do not silently begin at Stage 3 or bypass Stage 1–2.

- Preserve the failed predecessor and all attempts unchanged.
- Reuse Stage 1–2 approved substantive content if still applicable; generate new run-specific authorizations, receipts and approval applications. Disclose reused AI material instead of claiming new independent work.
- Reuse the frozen eight-row CSV and independently checked expected answers by exact hash.
- Produce a revised Design, independent required reviews and new owner lock. Freeze sent candidates before dispatch.
- Reuse R-A v2/R-B only after compatibility review with the corrected output schema; preserve original independent-build provenance. Any judged implementation changes follow existing role separation. Do not manufacture fresh first-pass provenance.
- Review harness v2 for the same missingness semantics. Rerun fixtures, all applicable MR on both paths, reconciliation, replay, affected gates and environment checks against exact successor versions; never recycle old PASS wrappers.
- Reuse the environment specification if unchanged. Adapt the project restore script to the launcher and provide fresh child library/version/output evidence.
- Create new packets, capture records, timing evidence and approval applications. Existing grants may be applied only if their actual scope/expiry/conditions cover the successor.
- Perform actual Stage-5 three-AI interpretation and certification only after Execution release. The failed-run closeout document is not a Stage-5 result.

## Remaining coordination inputs

GrokBot should supply the full locked Design, actual CP-ledger files/column definitions, harness v2 and restore-script v2, plus full hashes, for an exact project migration review. These files were not included in the summary handoff. No repository commit work is delegated to GrokBot. Owner approval of the revised Design and applicable sign-offs remains required; a successful run is the goal, never a reason to weaken criteria.

Before next week's run, agree targeted live evidence for the new failure cases and complete outstanding original scenarios. Require a clean end-to-end certificate and review all findings before proposing any merge. There is no merge/PR authorization in this repair.
