> **Prospective v3:** [Current methodology contract](METHODOLOGY_HARDENING.md) supplements the older contract below. New runs require its target, dependencies, semantic checkpoints, replay and claim evidence. Historical packs keep their pinned version.

# R Procedure Gate — Whole-Run Procedural Referee

## Purpose

The five-stage analytical workflow and its framework documents remain unchanged. This control adds a deterministic R referee around the existing procedure.

> **GrokBot coordinates the method. The stage documents define the method. R verifies the observable procedural record.**

The Procedure Gate does not perform analysis, call an AI, or decide whether the final recommendation is wise. It records stage state, checks the required stage receipts, invokes the existing R Workflow Gate at the Execution boundary, and writes a final certificate only after the complete procedure passes.

## Relationship to the existing Workflow Gate

The controls answer different questions:

| Control | Question |
|---|---|
| Stage 4 analytical validation | Are the analytical results mechanically supported under the locked design? |
| R Workflow Gate | Are the Stage 4 requirements satisfied so Stage 5 may begin? |
| R Procedure Gate | Does the whole run show Start → Framing → Design → Execution → Finish in the prescribed order? |

The Procedure Gate wraps the Workflow Gate; it does not replace or duplicate it.

```text
Start → Framing → Design → Execution
                                ↓
                    existing Workflow Gate
                                ↓ PASS
                             Finish
                                ↓
                    final procedure certificate
```

## Executable files

```text
procedure-gate/procedure.json
procedure-gate/procedure_gate.R
procedure-gate/README.md
procedure-gate/tests/test_procedure_gate.R
```

The machine-readable procedure names the five existing stages, their controlling documents, prerequisites, receipts, and the existing gate used to complete Execution.

## Project evidence

During a run, the gate writes:

```text
artifacts/procedure/run_state.json
artifacts/procedure/checks/
artifacts/final_certificate.json
```

The authoritative analytical artifacts and stage receipts remain in the project repository. The outer state records their identities and hashes, and later transitions recheck those hashes so a completed receipt cannot be changed silently; it does not replace them.

## Owner-approved receipt amendment

A completed stage is never reopened. When the owner approves a change control for a completed receipt, the gate records it with `amend`:

```bash
Rscript procedure-gate/procedure_gate.R amend <project-root> <completed-step> <new-receipt> <change-record>
```

Both paths are project-relative files. The change record is a JSON object with `change_id`, `step`, `reason`, `approval_text`, `approval_timestamp` (ISO 8601 with `Z` or a UTC offset), `superseded_sha256`, `new_sha256` and `archive_path`.

`amend` passes only when the run is active; the step is complete, has no nested completion gate, and no later step is complete (a begun later step is allowed and is rechecked on `complete`); every recorded hash still matches; the change record names the step, carries an explicit approval (not `PENDING`/`TBD`/`TODO`) and matches the actual files; the new receipt carries `supersedes_sha256` equal to the old hash and passes the same receipt checks as `complete`; and `archive_path` is a new project-relative file.

On `AMENDED`, the old receipt is copied byte-for-byte to `archive_path`, the new receipt is installed at the step's artifact path, the step's recorded hash is updated, and an entry is appended to `amendment_history` in `run_state.json`. Later transitions verify the current receipt, every archived receipt and every change record, and the final certificate includes `amendment_history`. A failed `amend` changes nothing and writes its check report under `artifacts/procedure/checks/`.

## Operating rule

Before a stage begins, the orchestrator calls `begin`. After the required stage receipt is written, it calls `complete`. A failed completion leaves the stage open for repair and rerun.

Execution is not marked complete until the Procedure Gate runs `workflow-gate/workflow_gate.R` and confirms both:

- process exit code `0`; and
- `workflow_gate_status.json` contains `result = PASS` and `stage5_allowed = true`.

After Finish, `finalize` succeeds only when all five stages and the nested Workflow Gate have passed. The run is protocol-compliant only when `artifacts/final_certificate.json` reports `result = PASS` and `certified = true`.

## Scope and limit

This is a procedural certification layer. It verifies observable artifacts, order, versions, AI-role and review attestations, approvals recorded in receipts, and deterministic gate results. An attestation is an auditable claim, not proof of an AI's private context or conceptual independence. The gate also does not prove the correctness of the final business judgment.

The initial enforcement is definitional rather than a security sandbox: work outside the gate may technically occur, but it cannot produce a valid protocol certificate.

See [`../procedure-gate/README.md`](../procedure-gate/README.md) for commands and receipt details.


## Prospective acceptance remediation

New runs must follow [SEND_QUEUE_PROTOCOL.md](SEND_QUEUE_PROTOCOL.md). This adds recorded authorization/send ordering, scoped approval applications, exact test-version binding, capture checks and limited certificate assurance. It does not change original candidate results or certify the historical acceptance run.

Prospective live-finding repairs: follow [LIVE_FAILURE_REPAIRS.md](framework-refinement/LIVE_FAILURE_REPAIRS.md) for immutable candidates, nullable checkpoint schemas, source applicability, Windows references/restoration and capture/timing evidence. Prior run evidence remains unchanged.

## CHANGES 2026-10-31: targeted gate changes C1-C5

Owner-approved (card t1614s6737) on branch `gates-targeted-2026-10-31` from `e539773e`. Stage 3 locked design unchanged. All earlier text above remains in force except where noted here.

- **C1 capture match.** `capture_method = "browser_copy_button"` is accepted when `capture_sha256` equals the reply file sha256 and `capture_evidence` is a hash-checked binding record (JSON) with the same `send_id`, `nonce`, `reply` ref, `capture_sha256`, and `captured_at_utc` within [sent - uncertainty, verified]. Screenshot / screen_recording / browser_export rules are unchanged. Plain-string evidence still fails.
- **C2 execution packet completeness.** Every execution send declares `send_kind` in {builder, review, tool_repair}. Builder sends still need the full locked sections and explicit `accepted_code`. Review and tool_repair sends need non-empty hash-checked `attachments` (the reviewed artifacts), must not carry `accepted_code` or `builder_base`, and are not required to repeat the locked sections.
- **C3 receipt dependencies.** A role receipt must list exactly its locked dependencies minus other roles' receipt paths; listing another role's receipt fails. Peer receipts are verified directly by their own checks. The locked dependency lists are not edited.
- **C4 approvals.** An approval may carry `scope_bound = {run_id, attempt}`; it is valid only when these equal the run and the ledger's `attempt`. An owner `expires_at_utc`, if present, stays a hard limit. Approvals without `scope_bound` keep the fixed-expiry rule.
- **C5 builder base.** A builder repair send may set `builder_base` (ref to its original builder packet) and `builder_role` on its ledger entry instead of repeating the locked sections. The gate checks the ref hash, that it is exactly one other send's packet, that send is a builder of the same `builder_role` without its own `builder_base`, its packet carries the locked sections, and it was verified no later than the repair was sent. `accepted_code` is still required on the repair packet.
- Deviations from GATE_CHANGE_PROPOSAL.md: reviewed artifacts are the send's `attachments`; the separate coherence check was dropped (already covered by per-receipt `design_sha256` and Workflow Gate fixture version); `builder_base`/`builder_role` live on the ledger send entry. Test fixture send now declares `send_kind = "builder"`.
- Tests: `methodology/tests/test_targeted_gates.R` (T1-T5, both directions for each change), added to CI.

### CHANGES 2026-10-31 (second set): C6-C8

Owner rulings card t1616s6752 (R1-R3), on top of standing approval t1615s6744. Tests T6-T8 in `methodology/tests/test_targeted_gates.R`.

- **C6 timing for hash-bound replies (R1).** When the capture is hash-bound (C1: `browser_copy_button`, `capture_sha256` = reply sha256, matching binding record), `ready_at_utc` and `dispatch_evidence` may be absent; the watchdog is then not measured. Any timing that is recorded must still be consistent, and `sent_at_utc`, `captured_at_utc`, `verified_at_utc`, basis and uncertainty stay required. Unbound or mismatched replies keep the full timing rule.
- **C7 earlier-attempt base (R3).** A builder repair may add `builder_base_ledger` (hash-checked ref to an earlier attempt's ledger). The base packet must be exactly one send there, same run and stage, matching send_id/nonce, no own `builder_base`, carry the locked sections, have ordered ready/sent/verified times inside that ledger, and be verified before the repair was sent. Role is the entry's `builder_role`, or else the role token as a whole word in the base packet's `role` text.
- **C8 packet supplement (R2).** A ledger send may cite `packet_supplement`: a write-once record (`kind = packet_supplement`) naming the sent packet by sha256 plus send_id and nonce, with reason and owner ruling, that may add only `authorization` and `accepted_code`. The sent packet stays the bound packet for capture match. Any other key fails.
