# R Procedure Gate

The R Procedure Gate is a deterministic referee for the existing five-stage AI-Augmented Analyst workflow.

It does **not** change the workflow, perform analysis, call an AI, or decide whether a recommendation is substantively correct. GrokBot (or another orchestrator) continues to follow the Master Prompt and the five existing framework documents.

The gate answers one question:

> **Does the observable project record show that the prescribed stages were completed in order and that every required release condition passed?**

## Relationship to the existing Workflow Gate

The two gates are composed rather than duplicated:

- `procedure-gate/procedure_gate.R` tracks Start → Framing → Design → Execution → Finish and writes the final procedure certificate.
- `workflow-gate/workflow_gate.R` remains the authoritative Stage 4 → Stage 5 release check.

When the orchestrator requests completion of `execution`, the Procedure Gate runs the existing Workflow Gate. Execution is marked complete only when that gate exits successfully and writes `result = PASS` with `stage5_allowed = true`.

## Dependencies

```r
install.packages(c("jsonlite", "digest"))
```

## Project receipts

The project repository supplies the existing stage receipts plus one Stage 5 completion receipt:

```text
artifacts/
  stage1_decision.json
  stage2_framing.json
  stage3_locked_design.json
  stage4_validation_status.json
  workflow_gate_status.json            # written by the existing Workflow Gate
  stage5_interpretation_status.json
  final_certificate.json               # written by the Procedure Gate
  procedure/
    run_state.json
    checks/
```

The Stage 1–4 schemas remain governed by the existing framework and Workflow Gate contract. For prospective runs, the Stage 1–3 examples also contain Procedure Gate fields that record the already-required AI role work, controlled review, stage gate, stakeholder approval where applicable, human approval, and unresolved-issue count. These fields make the published procedure observable; they do not add analytical steps.

A Stage 5 example receipt is provided at:

```text
templates/procedure-gate/stage5_interpretation_status.example.json
```

## Commands

Run commands from this workflow repository and pass the analytical project root.

### Start a run

```bash
Rscript procedure-gate/procedure_gate.R start /path/to/project PRICEPOINT-001
```

### Begin a stage

```bash
Rscript procedure-gate/procedure_gate.R begin /path/to/project start
```

Legal step identifiers are:

```text
start
framing
design
execution
finish
```

### Complete a stage

After the stage's machine-readable receipt has been written:

```bash
Rscript procedure-gate/procedure_gate.R complete /path/to/project start
```

The gate returns `PASS` only when the current step was authorized, the controlling framework files remain unchanged, all previously completed receipt hashes still match, and the required receipt passes its mechanical checks.

### Inspect status

```bash
Rscript procedure-gate/procedure_gate.R status /path/to/project
```

### Finalize

```bash
Rscript procedure-gate/procedure_gate.R finalize /path/to/project
```

Finalization succeeds only after all five existing stages pass. It writes:

```text
artifacts/final_certificate.json
```

## Orchestrator rule

Add this operating rule to a new project's orchestration prompt:

```text
R PROCEDURE REFEREE

Follow the Master Prompt and referenced stage frameworks without changing their
analytical method. Before starting each stage, call the R Procedure Gate with
begin. After writing the required stage receipt, call it with complete. Do not
treat a stage as complete unless the gate returns PASS.

Execution completion is determined by the Procedure Gate invoking the existing
R Workflow Gate. Do not begin Stage 5 unless Execution returns PASS.

After Stage 5 and explicit human analyst approval, call finalize. A run is not
protocol-compliant unless artifacts/final_certificate.json exists and reports
result = PASS and certified = true. On BLOCKED or FAIL, stop progression, report
the failed checks, repair the owning stage, and rerun the check. Never verbally
waive a deterministic failure.
```

## Enforcement boundary

The first implementation is definitional and auditable: a project without the final R certificate is not a protocol-compliant run. It does not claim to prevent an unrestricted agent from performing work outside the gate. It makes bypass visible and formally invalid under the published method.

The gate verifies observable evidence and recorded attestations. A `PASS` role field is an auditable claim, not proof of an AI's private context or reasoning. The gate also does not prove the conceptual optimality of the design or the wisdom of the final recommendation.

## Tests

```bash
Rscript procedure-gate/tests/test_procedure_gate.R
```

The tests exercise the legal five-stage path, premature stage access, completion without authorization, missing receipts, the nested Workflow Gate, and final certification.
