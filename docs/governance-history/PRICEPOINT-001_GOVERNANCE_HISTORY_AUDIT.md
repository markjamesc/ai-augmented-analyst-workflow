# Governance-history audit — PRICEPOINT-001 (workflow versions used by a certified run)

**Run:** PRICEPOINT-001 (project [`markjamesc/pricepoint`](https://github.com/markjamesc/pricepoint)), certified by the Procedure Gate on 2026-10-03T03:01:47Z (2026-10-02 22:01:47 CT); `final_certificate.json` sha256 `223411d0726e04727d0a21505d9565b2463b417b7f01d2ba3ec5bd2efcaf18cf`.

**Purpose:** record exactly which version of this workflow governed each part of the run, when the governing version changed, and why the change did not invalidate earlier work. All times are CT (UTC-05:00) unless marked Z. Evidence paths are in the PricePoint repository unless stated otherwise.

This is a record about the workflow's own versions. The case evidence stays in the project repository.

## Summary

| Epoch | Workflow commit | PricePoint prompt | Governs | Starts | Ends |
|---|---|---|---|---|---|
| 1 | `f388be8c2379ac6a8959516b486af31c99423bb0` | `f9a4897` (pinned to f388be8) | Stages 1–3 (start, framing, design) and the opening of Stage 4 (execution `begin`) | run `start` 2026-09-25 01:25:28 CT | local adoption of epoch 2, 2026-09-25 21:04:00 CT |
| 2 | `6ad1e202db986d5c96482f903a7519df747768cd` (merge of PR #9, `procedure-gate amend`) | `f9a4897` prompt + `pp_gate.R` re-pinned to 6ad1e20 | CC-S3-01 amendment, all of Stage 4, CC-S4-01, CC-S4-02, Stage 5, certification | 2026-09-25 21:04:00 CT | certification 2026-10-02 22:01:47 CT |

The controlling documents that the Procedure Gate hashes at `start` are **byte-identical** at f388be8 and 6ad1e20. Every hash in `run_state.json` `framework_hashes` and `procedure_sha256` matches both commits (CRLF checkout, as on the run machine):

| File | sha256 recorded at `start` |
|---|---|
| `docs/MASTER_PROMPT.md` | `f6fcee1745ce9525890beb8340f4a916e867a4a8673b7f084f68540176a9fcd2` |
| `docs/three-ai-start-and-framing-dialogue-framework.md` | `5040bcfb77cac634408d93e2684fce12e80b572ad28eb41a4ad33acba99603ab` |
| `docs/three-ai-measurement-design-framework.md` | `584d479a3c62309756bf5da51014fee75b70bf8499486967c2ec2f8db42bd7c8` |
| `docs/three-ai-validation-and-analysis-framework.md` | `f195ee2fb0286d3f0dc02b09c73b724be69adc6ac99dc3e4b30498c2cf389f24` |
| `docs/three-ai-interpretation-and-recommendation-framework.md` | `77e666b42c338436607787c4f70c22a2d8613ce1b79e4020f44dd93e0aceedc8` |
| `docs/r-workflow-gate-enforcement.md` | `7fa6e448b7f38ad566724e453844c2a16b0357a04900934418f1b774821f63d4` |
| `workflow-gate/workflow_gate.R` | `1d35168201b2b97d636bbd68209971ba59e8e718ed70978c26a2e0774dbe835c` |
| `procedure-gate/procedure.json` | `2717c59b7faea107007e683b808f539cd57dc7157d6f23ac4bf089425263db7a` |

Between f388be8 and 6ad1e20 the only commits are `de1c0c3` (`docs/ENGINE.md` only, not hashed, Mode B helper) and `a04f0a3` (PR #9: `procedure-gate/procedure_gate.R`, its test, `procedure-gate/README.md`, `docs/r-procedure-gate-enforcement.md`; none hashed). `git diff f388be8 6ad1e20` over the hashed files is empty. So no stage rule changed between the epochs; epoch 2 added one gate command.

## Epoch 1 — f388be8 / PricePoint f9a4897

- PricePoint `64d0f22` (2026-09-24 16:26 CT) pinned the orchestration prompt to f388be8, and `f9a4897` aligned the framework manifest. The run used the prompt at f9a4897 (`docs/orchestration/master-orchestration-prompt.md`, unchanged in the project repository during the run).
- The run-control helper `pp_gate.R` (kept outside both repositories; record copy in `docs/orchestration/run-control/`) refused to run unless the workflow checkout was at f388be8 with a clean tree. Its epoch-1 bytes are preserved as `pp_gate.R.f388be8.bak-20260925-210136` (sha256 `0bcdef4e18b16ad0e4b0139ac3db9e0fad2285f577430b07a464b440e4f7db88`).
- Procedure Gate record: `start` begun 2026-09-25T06:25:35Z; start, framing and design completed 08:01:31Z, 08:54:17Z and 13:41:34Z; execution begun 13:41:41Z (08:41:41 CT).
- The Stage 3 lock receipt v1 (`2781221592adcb9d25c3c4611e72e9dc5d13d2f308413caac2b173258562f56b`) was found incomplete for the Workflow Gate at Stage 4 completion (13 required fields missing). Under epoch 1 the Procedure Gate could neither reopen a completed step nor accept changed bytes, so the run could not proceed without a gate change.

## Transition — CC-S3-01 and PR #9

| Time (CT) | Event | Evidence |
|---|---|---|
| 2026-09-25 11:47 | Owner approves change-control route A (add an owner-approved amendment step to the workflow, then record receipt v2) | `CC-S3-01_change_record.json` `route_approval_*` |
| 12:18 | Owner approves Stage 3 receipt v2 `a68575d5…` | same record, `approval_*` |
| 12:21:55 | `a04f0a3` (procedure-gate `amend`) | this repository |
| 12:25:30 | PR #9 merged as `6ad1e20` | [PR #9](https://github.com/markjamesc/ai-augmented-analyst-workflow/pull/9) |
| 12:25–21:00 | **Epoch 1 still governs.** The merge alone changes nothing for the run: the local checkout stays at f388be8 and `pp_gate.R` still pins it | `docs/run-logs/CC-S3-01_APPLY_LOG.md` |
| 21:00:53 | Local checkout fetched and detached at 6ad1e20; tree clean; all `framework_hashes` re-verified (match) | APPLY_LOG A7 |
| 21:01:43 | `pp_gate.R` patched (amend verb, receipt mirror) and re-pinned to 6ad1e20; new sha256 `422bde69e1822e5333977a0aedc1acd0f8aa5aadb393a2bbd9b102b5393a65b8` | APPLY_LOG A8 |
| 21:02:53 | Change record written, sha256 `1207a592affd0b6975f65d76d25c5c1e95b0cacfe4770d20b9573ea374507db0` | APPLY_LOG B3 |
| **21:04:00** | **`pp_gate.R amend design` → `AMENDED`** (29/29 checks PASS). **Epoch 2 effective from here** | `artifacts/procedure/checks/design-amend-CC-S3-01.json` `89921699…` |

The adoption point is the first gate action run under the new commit, not the merge. Dependent revalidation: Stage 4 was still active, so its later `complete` re-verified everything against the amended receipt through the nested Workflow Gate, and `finalize` re-verified the amendment chain.

## Epoch 2 — 6ad1e20

Two more owner-approved design amendments used the same `amend` mechanism during Stage 4. Neither changed the workflow version.

| Change | Time (CT) | What changed (locked design) | Receipt sha256 (old → new) | Dependent rerun |
|---|---|---|---|---|
| CC-S4-01 | approved 2026-10-02 11:43; amended 11:50:20 | §17A.2: every glmnet fit uses `thresh = 1e-12` (design v5.2 → v5.3). Reason: at the default convergence threshold, predictions depended on column order by up to 0.0715 units, above the 0.05 tolerance | `a68575d5…` → `4fb33333…` | Both R paths rebuilt and rerun from fixtures (R-A r2, R-B r10) |
| CC-S4-02 | approved 13:21; amended 13:22:48 | §23: `cent_delta_rev` reconciles on exact sign and within the $0.05 tolerance; legal_change, guardrail_pass, action, package, below-line and rank stay exact (v5.3 → v5.4). Reason: 84 half-cent rounding straddles. Decided after seeing results and disclosed as such | `4fb33333…` → `1ee9f4da…` | Existing outputs re-reconciled (75/75) |

Execution completed 2026-10-03T01:28:53Z through the Workflow Gate (report `5401b40b…`); Finish began 01:44:55Z and completed 03:01:40Z; `finalize` certified at 03:01:47Z with `amendment_history` = CC-S3-01, CC-S4-01, CC-S4-02.

## Lessons folded into the workflow (this PR)

These are prospective template changes. They do not alter the certified run, and they change hashed controlling documents, so a run started on an earlier commit must not re-pin to them mid-run.

| Source in PRICEPOINT-001 | Template change |
|---|---|
| CC-S3-01 (gate could not represent a lock change) | MASTER_PROMPT helper supports `amend` (expects `AMENDED`); change-control line names `amend`; amendment block added. This is the MASTER_PROMPT line deferred from PR #9 |
| CC-S4-01 | Measurement-design §17A Mode A lock fields: numerical solver settings and exact tie rules |
| CC-S4-02 | Measurement-design §20.4 and validation-framework exactness standard: classify rounding-derived fields; decision fields stay exact |
| Stage 4 cross-review XR-01 (Source Gate item 8) | Value equality is a keyed row-by-row comparison; count + sum is not |
| XR-02 (item 22), XR-03 | Whitespace check on every delivered categorical field in every file; one locked missing-value token set |
| XR-04..XR-14 (accepted design gaps) | Measurement-design §20.4A specification completeness checks (field names, every field for every action class, tie-breaks, degenerate inputs, small denominators, calendar arithmetic, grain assertions) |
| Owner follow-up 2026-09-25 21:08/21:09 CT | MASTER_PROMPT standing rule 7, validation framework §4, measurement-design §20.4B: database access only through the CLI by the orchestrator; R never connects; R = analysis + procedure enforcement |
| Stage 5 owner ruling R11 | §20.4A "small denominators in acceptance metrics" (the A2 failure was driven by one item with 1 realized unit) |

Standing rule 8 (formerly 7) limits reusable Stage 3/4 edits to ablation `KEEP` results. These changes are not ablation results; they are the owner's post-certification follow-up instruction, approved 2026-10-02 22:04 CT.
