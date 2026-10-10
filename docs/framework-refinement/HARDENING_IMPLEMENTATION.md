# Step 2 implementation map

Base: ablation branch `e4af085`; evidence closeout `8db71b7`. Owner authorized implementation on 2026-10-10. This is a prospective review branch; no historical evidence or prior branch is rewritten.

## Proposed resolution of the five open implementation rulings

| Ruling | Branch implementation | Boundary |
|---|---|---|
| C30 gate/receipt | Honest NOT_REQUIRED with locked conditional policy, full fixture coverage and skip reason; otherwise executed PASS | No fake review; uncovered rules require coverage/review; known findings still block |
| C16 meaning | Complete authoritative Stage-3 content; no separate completeness review | C53 output mapping and fixture/reconciliation controls remain; omissions are not authorized |
| C47 thresholds | Project-specific predeclared thresholds and consequence | Tested 1000/30/one-third settings are examples, not universal defaults |
| C37 tag | Coordinator records tag from reviewed claims and locked action vocabulary | C05 inferential audit retained; tag alone does not establish expected utility or causal identification |
| C48/C50 FLAG | One consolidated revision plus mechanical recheck; unresolved flags block | New material inference/design change uses change control; no routine duplicate final audit |

These are concrete proposed implementation decisions, not forged owner approvals. Adoption review can revise them. C38's conditional monitoring contract remains. C01's attribution caveat remains; peer blindness relaxation does not abolish coordinator-draft exclusion or R-A/R-B barriers. C40 remains inconclusive HALT with existing rule unchanged.

## Requirements to implementation

| Requirement | Main implementation | Verification |
|---|---|---|
| Target, premise taxonomy, exposure | Stage-3 methodology object; `m_design` | Missing target, wrong population, hidden exposure, invalid premise kind fail |
| Bounded sensitivity | Branch IDs, same-target labeling, instability rule; execution coverage | Missing branch/different-target mislabeled sensitivity fail; failed analyses retained with interpretation |
| Corrections/amendments/exploration | `m_change`, existing amendment route, execution change log | Old amendment tests plus change structure checks |
| Late discovered design defect | Procedure `successor` | New run starts with zero completions; predecessor hashes retained |
| Semantic intermediate reconciliation | `m_compare`, keyed checkpoints at Workflow Gate | Equal counts/different keys, duplicates, labels and near-boundary numbers tested; order/shape equivalence and empty sets accepted |
| Metamorphic tests | `m_metamorphic` plus locked applicability and both-path report coverage | Seeded row-position dependence rejected; valid keyed adapter accepted |
| Reproducibility | `m_environment`, `m_replay`, environment/package refs, locked output coverage | Fresh-process deterministic helper replay and missing/failed replay cases |
| AI provenance | Role-specific metadata and input/output hashes | Design coordinator-draft restriction, execution peer barrier, actual role coverage |
| Claim warrants and coverage | `m_finish` extends existing ledger | Failed inference, unsupported claim type, missing registered claim and unresolved FLAG blocked; honest insufficient evidence accepted |
| Conditional scientific modules | Triggered Design plans and Execution report/disposition | Missing method plan blocks; inadequate module cannot become blanket inference adequacy |
| Conditional outcome evaluation | Frozen comparison contract and Finish handoff | Missing triggered contract blocks; evaluated status requires actual linked report |
| Receipt dependency integrity | Current design hash and locked per-role dependencies; final rechecks | Changed source blocks unchanged PASS; file references validated transitively within declared records |
| Retry/referee integrity | Unique attempt reports; Procedure Gate hashes itself and new contracts/schema/tools | Failed attempt retained; controlling referee included in state |
| Prospective migration | v3 required for new gate use; old runs retain pinned code | No automatic retrofits or inheritance of old completion status |

## What this implementation does not certify

The R gate checks structure, file identity, coverage and selected computations. It cannot prove an identifying assumption, authenticity of owner approval, completeness of undisclosed AI context, that a reviewer actually performed the claimed reasoning, or that a declared dependency map includes every file an arbitrary script secretly reads. The map and substantive reviews remain auditable attestations. Mutation tests target actual known failure modes but are not exhaustive formal verification.

The integration tests use **synthetic role receipts**. A helper replay test does not replay a real portfolio analysis. Real GrokBot + three AI acceptance, Windows/MySQL deployment behavior, project-specific scientific adapters and outcome accuracy/effectiveness evaluation belong to Steps 3 and 4. Do not label those complete from this branch's tests.

## Reproduce targeted checks

```sh
Rscript workflow-gate/tests/test_workflow_gate.R .
Rscript procedure-gate/tests/test_procedure_gate.R .
Rscript methodology/tests/test_methodology.R .
```

Test dependencies: jsonlite, digest, purrr, magrittr. CI includes new methodology/templates and all docs in path triggers; its R version is pinned. CI dependency installation is a compatibility check, not a promise of a frozen project environment. The committed test-environment inventory records the implementation test environment; prospective projects must supply their own retrievable lock and replay evidence.

## Verified implementation test results — 2026-10-10

All three commands above passed in Linux with R 4.4.3 and the recorded package inventory. Workflow tests accepted known valid cases and rejected 17 deliberate defects. Procedure tests completed the synthetic five-stage certification and rejected 23 invalid amendments without changing state. Methodology tests rejected 28 contract defects, checked keyed reconciliation and numerical boundaries, detected a seeded metamorphic fault, and exercised a fresh-process replay. Successor/retry tests preserved the predecessor and failed attempts without inheriting completed stages.

These are implementation tests using synthetic evidence, not actual three-AI acceptance or measured improvement in scientific accuracy. The test runtime was subsequently cleared; the successful test logs and unchanged tested implementation survived.
