# Step 3 — local synchronization and acceptance

Date: 2026-10-10 America/Chicago. Base: Step 2 commit `3d10f534f632236b9de3c62ac1914e527794f04c`. Review branch: `regression-acceptance-2026-10-10`, descending from Step 2. No merge or adoption is implied.

**Local mechanical acceptance passed. Live operational acceptance remains open.** These tests execute the R gates and helpers with synthetic evidence; they do not simulate proof of actual AI independence or establish scientific accuracy/profitability.

## Results and evidence

| Suite | Result | What it establishes |
|---|---|---|
| Workflow Gate | PASS; 17 existing defect cases rejected | Stage-4 refusal/release, source/fixture/reconciliation receipts, model-mode rules |
| Procedure Gate | PASS; synthetic Start → Framing → Design → Execution → Finish certified; 23 invalid amendments rejected | Stage order, locks, approval records, refusal without state advancement, lawful amendments and certification |
| Methodology | PASS; 28 defect cases rejected | Target and conditional-plan requirements, keyed reconciliation, tests/replay coverage, claims, retries and successors |
| Additional local acceptance | 46/46 PASS | Active conditional modules, AI metadata/barrier declarations, actual computed replay, malformed evidence, safe paths, locked outcome handoff and successor integrity |
| Schema compatibility | 18/18 PASS | Active and inactive module shapes agree with the R contract; missing plans and malformed sensitivity branches rejected |

Counts are test cases, not independent estimates of error-detection probability. They must not be summed into an accuracy percentage. See [individual logs and source hashes](step3-evidence/RESULTS.json) and [evidence hashes](step3-evidence/SHA256SUMS.txt). Expected nonzero subprocess warnings in gate logs are deliberately rejected cases; all five final suite processes exited zero.

The new replay test computes `sum(value)` from a raw CSV in a fresh R process. Fault variants produce a wrong value, omit the output, exit nonzero, or alter the frozen input; all are rejected. This improves on the earlier helper test that copied a synthetic output. Neither test replays Chicago 311 or PricePoint.

## Defects corrected during this acceptance pass

1. **Schema/validator disagreement:** six conditional modules were incorrectly required by the schema to retain `NOT_APPLICABLE` structure even when active. Schema conditions now require a plan when active and a status when inactive; always-required modules remain required.
2. **Optional sensitivity loophole:** populated optional branches previously bypassed target/relation/justification checks. Every declared branch now validates; optional does not mean malformed is acceptable.
3. **Pending outcome falsely rejected:** a generic placeholder-text check also rejected the legitimate enum `pending`. Enum validation now accepts exactly its declared vocabulary while ordinary placeholder text remains invalid.
4. **Required outcome silently waived:** a required outcome contract could be followed by `not_applicable`. It must now remain pending or have evaluation evidence.
5. **Changed comparison accepted after rehashing:** the handoff previously checked a file hash and nonempty owner without verifying agreement with the locked outcome contract. It now checks the owner, run ID and JSON contract contents against the lock. The evaluated report itself remains subject to substantive review.
6. **Successor archive integrity:** the archived predecessor certificate was copied but not hash-bound. It is now recorded and rechecked alongside the predecessor state and change record; failed copying blocks creation.
7. **Unsafe successor change path:** an external change record could start a successor that would fail later integrity checks. Unsafe paths now fail before state creation.
8. **Malformed Procedure receipt handling:** scalar JSON now yields a recorded refusal without advancing state, rather than reaching object-field code with the wrong type.

`before-acceptance.log` records the first 42-case diagnostic run: 37 passed and five failed. `acceptance-successor-before.log` records the next 45-case diagnostic run: 43 passed and the two successor cases failed. These are earlier test-suite versions, retained as diagnostic history; they are not the final 46-case suite. The schema's original 11/18 result was observed before correction; no separate original schema log is claimed. The scalar receipt case was added as a regression check with the parser fix.

These are implementation corrections to the authorized contracts, not new ablation verdicts. C40 remains HALT/inconclusive. The five open owner rulings remain proposed adoption decisions in the Step 2 map.

## Reproduce

The supported R version is R 4.6.1, with jsonlite, digest, purrr and magrittr. See [R version change and verification status](R_4_6_1_ENVIRONMENT_CHANGE.md). The retained conda package URLs, SHA-256 fragments and Python inventory describe the original historical test environment, not the new supported version. `r-linux-64-explicit.txt` can be supplied to `micromamba create -p <new-env> -f <file>` to reproduce that historical environment only; it is neither an R 4.6.1 lockfile nor a Windows environment specification. Run from the repository root:

```sh
Rscript workflow-gate/tests/test_workflow_gate.R .
Rscript procedure-gate/tests/test_procedure_gate.R .
Rscript methodology/tests/test_methodology.R .
Rscript methodology/tests/test_acceptance.R .
python methodology/tests/test_schema.py .
```

The last command requires `jsonschema==4.23.0`. The GitHub workflow now includes both new suites and the review-branch trigger. Local results do not by themselves assert a hosted CI result. No new packages were added to production R gate requirements.

## Remaining live acceptance — GrokBot and the actual three AIs

Use the reviewed Step 3 commit as the candidate, in a fresh project root. Preserve older certified runs and ablation evidence. Do not claim deployment until the actual installation points to this candidate's scripts, documents and templates.

| Area | Local evidence available | Live evidence still needed |
|---|---|---|
| Deployment and referee authority | Referee hashes, order and refusal tests | Actual GrokBot tool restrictions; prove blocked operations cannot proceed through an alternate route; installed R/SQL/platform versions |
| Start and Framing | Required receipts, identities and transitions | Actual stakeholder decision, action vocabulary, one framed question and owner confirmation |
| Design Gate/Stage-3 lock | Targets, conditional plans, exposure records and schema compatibility | Actual three role outputs, no coordinator draft first, disclosed peer exposure, approved lock and project-specific plans |
| SQL Query Gate and Source Gate | Source-receipt and stale-dependency rejection | Real SQL client/query authorization, actual frozen extraction/snapshot, source comparison queries, timezone/clock behavior. This repository has no universal executable SQL Query Gate to substitute for the project's controls |
| Frozen fixtures and R-A/R-B | Fixture-receipt checks, poison-probe requirements and metadata rejection | Production-reader roundtrip and poison probe on both real builds; separate construction contexts, identical frozen source, actual resource check before concurrent execution |
| Reconciliation and structural disposition | Semantic comparison, exact/tolerant field rules, conditional skip tests | Actual population/exclusion/component/result tables; fixes followed by reruns; executed review or documented coverage-based NOT_REQUIRED |
| Replay and evidence release | Fresh-process helper tested on computed output and faults | Real project recomputation, package lock, project-specific invariance tests and smoke reports, frozen validated pack |
| Amendments and retries | Refused/accepted amendment cases and successor integrity | At least one controlled live defect and repair; show affected dependencies rerun, old failures retained, and no unauthorized lock editing |
| Finish and certification | Claim coverage, numerical/inference verdicts, revision flags, conditional outcome handoff | Actual independent Stage-5 roles and exposure logs, final reviewed deliverable, mechanical revision verification, owner approval and R final certificate |

For the live run, archive visible inputs/outputs and original files with hashes; never invent model IDs, independence logs or owner approvals. Record omitted cases as NOT RUN with reasons. A synthetic PASS cannot close any of the live evidence cells above. Windows/MySQL compatibility requires the deployment environment or a faithfully reproduced installation, neither of which was available here.

Step 4 remains separate: assess analytical accuracy on suitable held-out/known-truth benchmarks and decision quality against precommitted alternatives. A passing Step 3 run establishes operational conformance, not that an action is optimal.
