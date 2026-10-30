# AI-Augmented Analyst Workflow — 3.0 lean candidate

Start → Framing → Design → Execution → Finish. Purpose: prevent false analysis without unnecessary process. This candidate starts from `51b6b0f4741cf97720349c180313353300f5078b`; it does not retroactively change any earlier certification or failed attempt.

## Entry points

- Read [MASTER_PROMPT](docs/MASTER_PROMPT.md) to run a project with the three AI services.
- Read [Start/Framing](docs/three-ai-start-and-framing-dialogue-framework.md), [Design](docs/three-ai-measurement-design-framework.md), [Execution](docs/three-ai-validation-and-analysis-framework.md) and [Finish](docs/three-ai-interpretation-and-recommendation-framework.md).
- Executable entry: `Rscript --vanilla procedure-gate/procedure_gate.R <command> PROJECT`. Commands: init, lock, validate, finish, finalize, status.
- [ACC003](acceptance/acc003/README.md) is the known-answer mechanical acceptance fixture. The [versioned run kit](acceptance/acc003/run-kit/README.md) contains every live prompt and PC step.

Supported release target: **R 4.6.1**, Windows or Linux; PowerShell instructions provided for the owner's Windows PC. Dependencies: jsonlite, digest; DBI and RSQLite for the isolated synthetic SQL pretest. No required Python runtime. The build report states the actual tested R version; support target is not a claim that unrun platform tests passed.

## Minimal controls

One design contract; one independent Design review; owner lock; one consolidated run manifest. Confirm the source. Build R-A/R-B independently and reconcile exact keyed semantics. Use frozen known-answer fixtures and relevant invariance checks. Pretest the checker with good and deliberately bad cases. Check claims against validated evidence at Finish.

Checks return PASS, ANALYSIS_DEFECT or TOOL_ERROR. A crash means repair and rerun, not a false analytical verdict. An unexecuted check is not PASS. Required unresolved checks cannot support certification. Only two stage restrictions: no Execution before owner lock; no Finish before all required current checks PASS. Finalize verifies that those outputs and the reviewed Finish content are still current.

No live database is accessed by ACC003. The synthetic SQLite setup is the owner's explicit exception: create a new disposable test database, close it, reopen read-only and compare good/wrong extracts. Never repoint it at a live database.

## Scope and history

The executable harness supports the supplied CSV/checkpoint interface. Other projects supply and pretest their source/builder/invariance adapters before use; the ACC003 fixture does not prove arbitrary-project correctness. Decision-model fits require the locked independent paths and prediction checkpoints; ACC003 itself has no model and does not establish live ML acceptance.

Files in docs/framework-refinement, docs/governance-history, experiments, and the original PDF/PPTX are historical/reference material, not current operating requirements. Original historical evidence remains unchanged. Baseline gate APIs are intentionally superseded; old runs use their pinned version, never this candidate's checker.

## ACC003 acceptance

ACC003 completed LIVE_PROCEDURAL_ACCEPTANCE on Windows 11, PowerShell 5.1 and R 4.6.1. The returned evidence was reviewed with checksum and recorded-output rechecks; Step 3 is accepted for this defined synthetic mechanical scope, with disclosed procedural/transport deviations. See [acceptance and publication scope](docs/framework-refinement/ACC003_ACCEPTANCE.md). This publication candidate includes the run-approved F15 contract clarification and later Finish/capture prompt clarifications; it is not byte-identical to the certified workflow archive. No claim of general analytical accuracy, profitable action, production SQL or unseen-input correctness follows.
