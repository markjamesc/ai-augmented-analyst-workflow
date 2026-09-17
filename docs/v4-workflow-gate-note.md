# V4 Workflow Gate Note

**Date:** 2026-09-16  
**Scope:** Prospective deterministic enforcement layer for new five-stage projects. No historical case-study retrofit is required.

## Why this refinement exists

The existing framework already tells the AI systems and human analyst what must happen at each stage. V4 adds a separate deterministic check for a different failure mode:

> a required stage lock, fixture, validation step, version handoff, or reconciliation result is skipped, stale, failed, or bypassed even though the orchestration proceeds.

The goal is not more AI reasoning. The goal is to make the existing procedural rules machine-checkable.

## What V4 adds

1. Compact machine-readable transition artifacts for Stages 1–4.
2. A versioned Stage 3 implementation contract (`stage3_locked_design.json`).
3. A Stage 4 validation receipt (`stage4_validation_status.json`).
4. A separate deterministic R Workflow Gate.
5. A hard rule that Stage 5 cannot begin until the gate returns PASS.
6. Failure routing back to the stage that owns the failed control.

## What V4 does not change

- The five-stage spine.
- The three-AI roles.
- Human authority.
- Stage 3 substantive measurement-design judgment.
- Stage 4 SQL source validation.
- Independent R-A / R-B judged implementations.
- Exact Stage 4 reconciliation.
- Structural cross-review.
- Stage 5 independent interpretation and claim auditing.

## Separation of concerns

### Stage 4 analytical validation

Question:

> Did independent implementations correctly translate and reconcile the locked analytical logic?

### Cross-stage R Workflow Gate

Question:

> Did the project actually complete the required procedural controls, on the correct locked design version, before advancing?

The workflow gate reads validation receipts; it does not replace or duplicate Stage 4 reconciliation.

## Initial enforcement contract

Before Stage 5, the gate requires:

- Stage 1 locked decision receipt;
- Stage 2 locked framing receipt;
- Stage 3 locked design receipt;
- matching Stage 3 design version in Stage 4;
- SQL Source Gate PASS;
- frozen fixture PASS;
- R-A PASS;
- R-B PASS;
- exact reconciliation PASS;
- Validation Gate PASS;
- zero unresolved validation issues;
- Stage 4 overall PASS.

A failed control blocks Stage 5 until the owning stage is repaired and the gate is rerun.

## Evaluation plan

Use V4 prospectively on the next two new projects. Record:

- which gate checks fail on first pass;
- whether the failure reflects genuine skipped procedure, stale versioning, implementation drift, or plumbing;
- whether the gate catches anything the AI orchestration failed to catch on its own;
- false-positive or unnecessary gate friction;
- and whether any gate rule should be simplified or removed.

Do not add more enforcement merely because it is possible. Expand the gate only when an observed failure mode justifies the new control.
