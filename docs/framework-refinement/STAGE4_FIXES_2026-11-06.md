# Stage 4 fixes, 2026-11-06 (local branch stage4-fixes-2026-11-06)

Owner Friday plan step 1. Nothing pushed. Box-only.

## Partial branch
`acc002-stage4-fixes` was ACC002 attempt-kit material only (not planted-defect work). Fresh branch taken from main `28d2798`.

## Fixes
- **B1** `tools/rehearsal/harness/run_fixtures.R` + `planted_transforms.R`: code-independent output wrappers for threshold/tie/expected-ID/summation/missing-to-zero. Zero-change transform = FAIL. Wrong-oracle cross-check is supporting only.
- **B2** `tools/rehearsal/box_manifest.py`: observe R/platform/packages on the live host (box R 4.4.3). Next live run is on this box.
- **L1** structural reviewer sends remain mandatory in `drive_s4b.py` (3 sends) even when dispositions are FLAG_ONLY.
- **L2** `tools/carry_builds.py`: refuses to carry frozen code without matching reply transcripts.
- **L3** `drive_s4a.py` / `drive_s4b.py`: first structural in s4a; methodology + lineage AFTER dispositions and structural rerun in s4b (avoids ABSENT and stale NEEDS_REVIEW hashes).
- **L4** `tools/move_aside.py`: move write-once outputs into `outputs/superseded/attempt_<UTC>/` (supports `--verification-tree`). Never deletes.
- **L5** `tools/runkit.py` ledger loads only `*.json`; packet validates attachments exist before any write-once file.
- **L6** `drive_s123.py` renames lock lineage producer `check_lineage.R` → `check_lineage_v2.R`.
- **M1** harness `run_fixtures.R` header relabelled (no ACC002/ACC003 run id).
- **M2** `tools/check_attachments.py` pre-send required-subject check; runkit refuses missing attachments before write.

## Tests
- `tools/tests/test_stage4_past_failures.py` (23/23)
- `tools/tests/test_planted_defects.R` + `stage_planted_root.py` confirmations on ACC002, ACC004S, style_functional, style_dataframe
- Existing: runkit 32/32, scope_refs 34/34, structural_absent 8/8, procedure_gate PASS, workflow_gate PASS

## Rehearsals (box, R 4.4.3)
- Full five-stage `/workspace/reh_s4fix`: certified; 1007/1007 result PASS; stage completes 35+43+125+34+57
- Forced repair-and-rerun `/workspace/reh_repair2`: write-once blocked (exit 2), move-aside, rerun, execution 34/34 PASS
