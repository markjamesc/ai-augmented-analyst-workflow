# Prospective acceptance remediation (acceptance-v1)

This protocol applies to new runs pinned to the remediation commit. It does not recertify the original candidate, change historical run evidence, or establish profitable action. Preserve the five stages and all existing gates. Templates are scaffolds, never evidence. NOT_SET__ placeholders fail semantic validation.

## Authority, escalation and sign-offs

Generate `templates/preapproval_sheet.json` at Start. Each application records unique ID, run, stage, exact scope, owner verbatim file/hash, wording author, granted/expiry UTC, conditions and evidence, revocation rule, action time and application. Cover stage sign-offs, Validation Gate, structural review, human Finish, final certification, limitations, repair scope, publication, checkpoint replacement, cleanup and results delivery; mark inapplicable items with reasons. Coordinator-written approval wording must be disclosed. A grant is not evidence that its conditions held. A later revocation overrides a prior grant, including a prior 'tonight' grant. Record known revocations in `artifacts/operations/revocations.json` as `{run_id, events:[{approval_id,recorded_at_utc,owner_record:{path,sha256}}]}`. No fabricated human reading or stakeholder confirmation.

Owner-only actions, unless already explicitly authorized for the exact scope: writes to live systems or the DB; push, merge, PR, email, publish or post; deletions; changing locked values or gate rules; loosening a check or accepting risk; sign-offs not pre-approved; anything that changes a result. Escalate missing/expired/failed conditional consent. Existing authorization persists within scope.

Act and log within existing authority: repair packets and reruns, coordinator tooling fixes, and bounded PC-offline retries every five minutes, at most three, checking state before each retry. A serious item blocks its own branch and dependent work, not unrelated authorized work. Batch questions without delaying ready authorized sends. Never use silence as new consent. Stage 5 cannot run alongside unfinished validation of repaired code.

## Begin, packet, send, capture, chain

Call Procedure Gate `begin ROOT STAGE`; require AUTHORIZED before stage work or dispatch. The successful report is saved as `current_authorization` in run state. Packet preflight is non-authorizing. Archive exact JSON packet, actual message text and attachments; use a fresh send ID and nonce per request. A packet contains run_id, stage, authorization ref, send_id, nonce, attachments. Execution packets additionally contain exact locked output_rules, checkpoints, receipt_dependencies and explicit accepted_code references (empty means no accepted code yet). Never replace full locked sections with coordinator summaries. Source identities come from the frozen manifest, not hand-entered constants.

Use `templates/send_queue.json` and `methodology/operations.schema.json`. Archive `artifacts/operations/STAGE.json` at completion, including:

- version=acceptance-v1; run_id; stage; authorization `{path,sha256}`; completed_at_utc;
- approvals as the applications above; transcript_index `{path,sha256}`; all_sends_recorded; deviations `[{id,disposition,evidence}]`;
- sends with id, ai (actual provider/model/session), nonce, packet/attachments/reply/capture references, depends_on IDs, approval_id (explicit `none` for ordinary authorized sends), scope if an approval is used, ready/sent/captured/verified UTC timestamps; overdue_report reference when needed.

Ask the actual AI to end its reply with `END_REPLY SEND_ID NONCE`. Inspect the visible response, model/session, file downloads and complete ending. Do not accept stale clipboard data. Capture request JSON contains send_id, nonce, packet ref, reply ref, screen_verified=true only after inspection. `python tools/acceptance.py capture ROOT REQUEST.json --out NEW_CAPTURE.json` rejects a mismatched packet/reply marker. Archive visual evidence and actual sends in the transcript index. Code validates recorded identities, not the truth of a visual attestation or model independence.

Use machine-generated UTC timestamps (`stamp` helper), never manually reconstructed times. A dependent send must follow verification of each predecessor. Dispatch ready work promptly. The executor polls at least once per minute while work is active; watchdog input is `{tasks:[{id,status:"ready",ready_at_utc}]}` (optional now_utc is for labeled tests). Strictly more than 900 seconds ready without send is FLAG, exit 1. Record cause, escalation and disposition. The helper is not a background timer. At 900 seconds it is not overdue. A missed timer is a procedural failure even if a later log passes consistency checks.

## Locked specification and version-bound validation

Design locks `methodology.operational`: action/finality lexicons, negation/evidence-tag rules, literal/enum/computed output rules for every output, fixture inputs/expected-answer hashes and independent oracle rationale/reviewer, packet requirements, and validation_components paths grouped R-A, R-B, harness, configuration, input. Applicable metamorphic relations specify coverage_type (nonconstant, boundary or negative_control) and detectable_defect. Test discrimination using a planted defect, not merely an empty shortlist. Never rewrite an oracle to make a failure pass.

The methodology receipt adds test_versions `{components,tests}`. Each component group contains exact path/hash refs matching the locked paths. Required tests: fixtures:R-A, fixtures:R-B, replay, reconciliation and metamorphic:RELATION:R-A/R-B for each applicable relation. Each row has id, result, components, recorded_at_utc, report ref; the actual report embeds the same id/result/components/time. All tests conservatively bind all five component groups. Code/config/input/harness changes invalidate the bundle, even if production outputs match. Rerun actual tests and write new reports; updating only wrapper hashes is forbidden. `m_bound_test` in methodology/tools.R executes a reviewed test closure and detects component mutation during it. It cannot determine whether a caller's test is scientifically sufficient.

Retain triage `[{id,severity,status,disposition,evidence,owner_approval?}]`; blocking findings must be resolved, accepted limitations require owner evidence. Reproducibility adds environment_spec and restore_report refs. The restore report must bind the spec, report PASS and fresh_environment=true, and reference the console of an actual clean restoration. A package list is not restoration. Record unavailable hosted AI details honestly.

## Review helpers and evidence retention

`acceptance.py inventory` checks a files array of path,sha256,line_count,first_line,last_line against actual bytes. Lines are exact, not prefixes. `revision` accepts original/revised refs and replacements [{old,new}], each matching once, and rejects any other edit. These checks support C49 and C48/C50; an unresolved FLAG blocks completion, not another discretionary audit loop.

Action lexicon hits require action/owner_tradeoff/evidence_tag/tag_assigned_by even if a claim calls itself descriptive. Negation gets contextual review. Finality wording requires a monitoring_next_question_review ref. Lexical helpers are bounded aids; human/AI inference and claim-completeness review remain necessary.

Finalization recursively verifies JSON path/sha256 references from completed-stage evidence and writes a hashed evidence inventory. Generate supplementary `file-inventory` from the authoritative execution root with explicit seed refs for nonstandard references and original transcripts. A partial coordinator mirror is insufficient. This is declared-reference closure, not proof that every unrecorded file exists. Preserve every failed attempt, correction, console and hash; deliver individually accessible files. No backdated timestamps, invented missing timing or altered original evidence.

Certificate assurance separates recorded checks, recorded order, manual-send prevention (not demonstrated), deviations and scientific/decision/outcome assurance. A gate PASS proves none of causal validity, profitability, genuine AI independence, or unobserved process compliance. Revocation is checked when received/recorded; real-time message monitoring remains procedural.

## Live-finding corrections (prospective 2.2-livefix-v1)

The controlling addendum is [LIVE_FAILURE_REPAIRS.md](framework-refinement/LIVE_FAILURE_REPAIRS.md). It supersedes earlier acceptance-v1 wording where the following fields were absent:

1. Freeze a sent candidate using `m_freeze_file` before dispatch; reference that immutable path/hash. Write the final lock separately. Stage completion checks nested references and freezes their dependency closure.
2. Lock `operational.checkpoint_output_rules` (checkpoint_id, field, nullable) for every numeric checkpoint column, corresponding `field_nullability`, and explicit `numeric_missingness` for nullable fields. Include checkpoint_output_rules verbatim in Execution packets and packet_requirements.
3. Lock source_contract.kind/rationale; file-only extraction uses SQL NOT_APPLICABLE while source fidelity still must PASS.
4. Each send adds timestamp_basis (machine_observed or dispatcher_reported), timestamp_uncertainty_seconds and dispatch_evidence ref. Machine observations have zero declared uncertainty; approximate observations must disclose a defensible bound. If no bound can be supported, do not fabricate one: the order claim is unverified and must be resolved before acceptance. Do not reconstruct timestamps from later capture checks. Watchdog input may include timestamp_uncertainty_seconds; potential overdue work is flagged conservatively.
5. Capture requests and records add capture_method (screenshot, screen_recording or browser_export) and capture_evidence ref. Retain material showing the actual response ending and session context. A browser export is an allowed alternative to screenshots; an unsupported dispatcher assertion alone is not. Synthetic test exports are not live proof.

The code checks record consistency; the coordinator remains responsible for faithful observation, model identity, complete logs and independent role execution. A disposed timing FLAG remains a FLAG in the record.
