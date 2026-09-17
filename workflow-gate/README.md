# R Workflow Gate

This folder adds a deterministic procedural-enforcement layer to the five-stage AI-Augmented Analyst workflow.

It does **not** replace the three-AI methodology, the Stage 4 SQL Source Gate, the independent R-A / R-B judged implementations, or their exact reconciliation. Those remain the analytical validation system.

The workflow gate answers a narrower question:

> **Was the required five-stage procedure actually followed before the workflow advanced?**

## Division of labor

- **GrokBot / orchestrator:** runs the workflow, assigns AI roles, saves stage artifacts, calls the gate, and routes failures back to the stage that owns them.
- **AI systems:** reason, design, build, criticize, and interpret.
- **Stage 4 R-A / R-B:** independently implement and reconcile the locked analytical logic.
- **R Workflow Gate:** verifies procedural compliance from machine-readable artifacts and returns `PASS` or `FAIL`.
- **Human analyst:** owns business judgment, design approval, exceptions, and the final decision.

## Required project artifacts

A project using the gate should write these files under an `artifacts/` folder:

```text
artifacts/
  stage1_decision.json
  stage2_framing.json
  stage3_locked_design.json
  stage4_validation_status.json
  workflow_gate_status.json   # produced by the gate
```

Templates are provided in `templates/workflow-gate/`.

## What the gate checks

The first version deliberately checks only hard procedural controls:

1. Stage 1 decision artifact exists, parses, contains required fields, and is `LOCKED`.
2. Stage 2 framing artifact exists, parses, contains the analytical question, and is `LOCKED`.
3. Stage 3 machine-readable measurement contract exists, contains required control fields, and is `LOCKED`.
4. Stage 4 declares the exact Stage 3 design version it implemented.
5. The Stage 4 SQL Source Gate passed.
6. Frozen known-case fixtures passed.
7. Both independent judged R paths passed their own execution checks.
8. Exact R-A / R-B reconciliation passed.
9. The Stage 4 Validation Gate passed.
10. No unresolved validation issues remain.
11. The Stage 4 overall status is `PASS`.

Only then does the gate set `stage5_allowed = true`.

## What the gate does not claim

A procedural `PASS` does **not** prove that the locked Stage 3 design is conceptually correct or that the Stage 5 recommendation is wise. Those remain matters for the existing independent AI reviews, source evidence, methodological review, and human judgment.

The gate proves something narrower and important: the workflow did not silently skip or bypass its required procedural controls.

## Run

From the project root:

```bash
Rscript workflow-gate/workflow_gate.R
```

Or provide another project root:

```bash
Rscript workflow-gate/workflow_gate.R /path/to/project
```

Dependency:

```r
install.packages("jsonlite")
```

The script writes:

```text
artifacts/workflow_gate_status.json
```

It also returns a process exit code:

- `0` = PASS; Stage 5 may begin.
- `1` = FAIL; the orchestrator must stop progression and route the failed check back to the responsible stage.

## Orchestrator rule

The orchestrator should treat the gate as a hard transition rule:

```text
Run Stage 1–4 as specified.
Save the required machine-readable artifacts.
Run workflow_gate.R before Stage 5.

If exit code = 0 and workflow_gate_status.json says PASS:
    Stage 5 may begin.

If exit code != 0 or workflow_gate_status.json says FAIL:
    Do not begin Stage 5.
    Read the failed checks.
    Route each failure back to the stage that owns it.
    Repair only from the locked design and authoritative evidence.
    Rerun affected work and rerun the workflow gate.
```

This turns the existing methodological rules into a deterministic release gate without changing the five-stage analytical method.