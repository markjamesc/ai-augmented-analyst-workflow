# Prospective small-fixture successor adapters

These are new candidate files, not edits to ACC-SMALL-REMEDIATION-001 evidence or an acceptance verdict. Base: beede13c8cc13bec3a05d6a709dcca54b0b6c70e.

## D-22 mapping

Keep existing CP-ledger keys/exact fields and zero tolerances. Declare amount_value nullable and use:

```json
{"amount_value":{"flag_field":"amount_status","missing_values":["blank","nonnumeric","nonfinite"],"present_value":"finite","missing_token":""}}
```

Set field_nullability.amount_value=true and add the matching operational.checkpoint_output_rules entry. For CP-selected.amount, CP-qualified.amount and CP-summary.selected_amount_sum, nullable=false. CP-metadata has no numeric fields. Preserve all original amount_status values; matching missing values with different reasons must fail. The singular missing_value syntax remains supported but cannot coexist with missing_values. The owner must approve the successor Design lock; this example does not amend the predecessor.

The two ledger CSV files reproduce the supplied original CRLF bytes; hashes are 0d6c2f0d42f510c974c3c5fa6a65ec669cfd2cd3b920ad000981c075667d48d9 and 287006d943146abdc9d56a34589ebf8e28a9763b4cbcffa6e39a93ca71bc5782. They are regression inputs, not fresh execution outputs.

## Harness

Copy acceptance_harness.R to the NEW project's validation/acceptance_harness.R before review and lock. Its sole functional change from received v2 is refusing malformed/nonfinite numeric output tokens before they can masquerade as missing. Existing supported serialization tokens remain unchanged. Invalid raw source values remain legal test inputs: this check concerns numeric OUTPUT fields. The original harness is untouched. Local tests exercise the pure decoder; full project execution still needs builders/config/oracle/case manifests.

## Restore adapter

Copy restore_project.R to the NEW project's environment/restore_project.R. From the workflow repository root:

```
Rscript --vanilla tools/run_restore.R PROJECT_ROOT PROJECT_ROOT/environment/restore_project.R NEW_LIBRARY NEW_ATTEMPT
```

Use absolute paths, quote paths with spaces, and use new directories for every attempt. The launcher passes ROOT and NEW_LIBRARY. The adapter installs every package listed in the project's existing environment/restore-spec.txt before loading non-base packages. Both the launcher and builder-child probe reject extra library paths. It checks exact package versions, builder exits and eight byte-replay outputs; failed checks exit nonzero. Installation failure/version mismatch leaves logs and no PASS report. Full success produces a new project restore_report.json; CHILD_CHECKS_PASS alone remains insufficient.

Installation currently uses the predecessor's CRAN binary policy on Windows (source on other platforms). Exact versions are checked, not guaranteed available from CRAN. If unavailable, stop: do not rewrite the frozen spec. An approved archive/snapshot source would require an explicit follow-up. The frozen spec and predecessor restore report have been requested but not supplied; no actual project restoration has been verified here.

## Successor and independence

Start a fresh run at Start, reuse approved substantive inputs only with disclosed provenance, obtain a new Design lock, and regenerate all affected evidence. No original PASS receipts are reused. Review both adapters before locking their hashes. Reuse unchanged R-A/R-B only under the previous compatibility/provenance conditions. Actual three-AI Finish and Windows R 4.6.1 acceptance are still required. No merge or PR is authorized by this patch.
