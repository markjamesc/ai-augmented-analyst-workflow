# Run tooling and guard changes, 2026-10-31 (box rehearsal, owner cards t1636s6840 / t1637s6850)

Run tooling only (Python under `tools/`); no gate, procedure, methodology contract or validation R code changed.

- `tools/runkit.py`: packet / sent / capture / ledger helper for hosted-chat sends. Naming convention: stage and send ids must match
  `[A-Za-z0-9][A-Za-z0-9._-]*` and must not match the historical-scope pattern or the bare word `attempt` (fixes the guard's
  'attempt' problem at the source without loosening it). Tests: `tools/tests/test_runkit.py`.
- `tools/scope_refs.py`: write-once evidence snapshots of historical records (refs rewritten to snapshot copies, manifest of
  originals) and a ref-scope guard. HIST pattern unchanged. Snapshots are now atomic (built in a staging dir, renamed into place,
  files 0444; nothing left behind on failure). Tests: `tools/tests/test_scope_refs.py`.
- **Scoped guard exception, owner-approved option (a), card t1637s6850, 2026-10-31 11:55 CT (approval relayed by the coordinator;
  card text not seen by the implementer).** The Stage 3 lock requires `receipts/methodology.json` to depend on the live
  `outputs/verification/replay.json`, which `validation/check_methodology.R` writes with refs into its own current dir
  `outputs/verification/runs/methodology_<ts>/`. The guard admits such a ref only when: the citing file is exactly root-scope
  `outputs/verification/replay.json`; the cited path is `outputs/verification/runs/methodology_<YYYYMMDDTHHMMSSZ>/<file>`; and that
  replay.json was written in this execution (recorded_at_utc >= latest PASS execution-begin check record, and `<ts>` within
  [begin, recorded_at]). Hashes are still checked. Tests: positive; another runs/ dir; verify_run_pass1; nested path; replay from
  another run; replay from an earlier execution begin; methodology dir outside the window; no begin record; different citing file.
- `tools/structural_dispositions.py`: writes `outputs/verification/structural_dispositions.json` from `FLAG <key> <CLASS>:` lines,
  only when every reviewer classifies every flag key unanimously (otherwise FAIL: owner disposition needed).
- `tools/compose_stage4.py`: generic Stage 4 receipt composer (phases 1-3); values come from run_state, runkit fragments, captured
  `VERDICT:` lines and tool outputs; historical records cited through snapshots; guard run on all Stage 4 receipts.
- `tools/rehearsal/`: SYNTHETIC box rehearsal drivers (labelled stand-in replies; never for a live run). `box_manifest.py` writes a
  box-observed package manifest for box rehearsal because the ACC002 manifest records the PC's R 4.6.1 (rebuild_env.R correctly
  FAILs against it on the box); a live run uses the PC manifest.

## Additions (owner cards t1637s6850, t1637s6856; 2026-10-31)

- **validation/structural_review_v2.R (harness change, card t1637s6856).** Overlay at `tools/rehearsal/harness/structural_review_v2.R` (sha256 3e26a259…; ACC002 original 2c0b40e0…). An absent dispositions file is recorded as `dispositions_present: false` with no path+null-sha256 reference; a present file is a normal path+sha256 reference. Tests: `tools/tests/test_structural_absent.py` (8/8). The gate is unchanged. **Disclosure:** DeepSeek's review S4-h1 covered the old hash 2c0b40e0…; the live run must have the changed script re-reviewed or disclose the gap.
- **scope_refs reference detection aligned with the gate.** Any object with both `path` and `sha256` is a reference. A non-string path or a non-64-hex sha256 now fails the guard ("invalid reference") and the snapshot ("FAIL invalid ref").
- **scope_refs replay exception (card t1637s6850).** This admits only `outputs/verification/runs/methodology_<ts>/<file>` when it is cited by this run's root `outputs/verification/replay.json`, when that file was written at or after the latest PASS execution-begin, and when ts lies in [begin, recorded_at_utc].
- **scope_refs snapshot `keep` (own-tooling bug fix).** Before this fix, snapshot copies rewrote the references to locked identities (the validation components and the replay outputs) into snapshot paths. The gate then failed "validation component identities", "replay output coverage" and "versioned result *". Those references now stay root references. They are hash-checked when the snapshot is taken, recorded in the manifest's `kept`, and admitted by the guard only at the recorded hash; a later change is caught as stale. compose_stage4 passes the locked components plus replay_outputs. Tests are in test_scope_refs.py.
- **Rehearsal drivers.** drive_s4a no longer sends the premature S4-RV reviews. drive_s4c runs the whole Stage 4 close. drive_s5.py (Stage 5 + finalize) and drive_probes.py (handoff probes a–e) were added.
