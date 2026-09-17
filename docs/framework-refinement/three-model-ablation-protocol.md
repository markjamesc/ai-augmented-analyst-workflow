# Three-Model Framework Ablation Protocol

## Purpose

This protocol governs ablation testing used to refine the reusable Stage 3 Measurement Design framework and Stage 4 Execution/Validation framework.

It is separate from the five-stage production workflow. Projects use the current canonical framework; this protocol tests whether a proposed reusable framework change should become canonical.

The system is fully AI-operated. There is no per-ablation human approval or post-run human audit.

## Models

The protocol uses three model families:

- ChatGPT
- DeepSeek
- Grok

They rotate through three mutually exclusive roles.

## Roles

### Builder

The Builder:

1. receives the frozen baseline, frozen ablation specification, frozen fixture suite, frozen constitution, and authorized tools/data;
2. implements only the declared ablation;
3. runs the required SQL/R/tooling;
4. preserves raw stdout/stderr and generated artifacts;
5. records hashes/manifests;
6. does **not** decide KEEP/REVERT/HALT.

### Independent Validator

The Validator:

1. receives the same frozen baseline, ablation specification, fixture suite, constitution, and authorized tools/data;
2. does not see the Builder's reasoning, conclusion, or claimed result before its own first pass is frozen;
3. independently reconstructs the required checks;
4. reruns the mechanical tests;
5. emits raw tool output, not merely a prose summary;
6. identifies blocking defects and unintended changes;
7. does **not** decide KEEP/REVERT/HALT.

### Adjudicator

The Adjudicator:

1. sees the frozen constitution;
2. sees the frozen Builder and Validator evidence packs only after both are hashed/frozen;
3. may not rewrite the ablation, rerun the build, invent new criteria, or alter the constitution;
4. applies the constitution;
5. returns exactly one terminal state: **KEEP**, **REVERT**, or **HALT**.

## Independence rule

No model may hold two roles on the same ablation.

Builder and Validator first-pass outputs must be frozen before either can see the other's work.

The Adjudicator may see both frozen packs but cannot modify them.

Different model families are required. Three instances of one model family do not satisfy this protocol.

## Pre-run freeze

Before execution, freeze:

- baseline framework version;
- ablation ID;
- exact change being tested;
- target stage(s): Stage 3, Stage 4, or both;
- named fixture suite;
- critical reconciliation fields;
- allowed source/data scope;
- expected unchanged surfaces;
- operational benefit predicate;
- regression rules;
- constitution version;
- role assignment.

The ablation may not redefine its own success criterion after seeing results.

## Operational benefit predicate

Every ablation must define a third-party-checkable benefit predicate before execution.

Examples:

- a seeded failure missed by baseline is caught by the ablated framework;
- a redundant rule is removed while every locked fixture and critical output remains unchanged;
- a boundary-condition fixture converts an ambiguous implementation into deterministic agreement;
- a Stage 4 control detects an intentionally seeded source-delivery or judged-path defect;
- a simplification reduces steps or duplicated controls without reducing detection coverage.

"Seems better" is not a valid benefit predicate.

## Evidence packs

### Builder pack

Recommended contents:

```text
Axx-builder/
├── ablation_spec.md
├── changed_files/
├── fixture_results.tsv
├── reconciliation.tsv
├── execution_stdout.txt
├── execution_stderr.txt
├── semantic_diff.txt
├── raw_tool_outputs/
└── manifest.sha256
```

### Validator pack

Recommended contents:

```text
Axx-validator/
├── independent_test_plan.md
├── fixture_results.tsv
├── reconciliation.tsv
├── execution_stdout.txt
├── execution_stderr.txt
├── semantic_diff.txt
├── blocking_objections.md
├── raw_tool_outputs/
└── manifest.sha256
```

## Deterministic freeze

A deterministic hashing step freezes both evidence packs before adjudication.

The freeze must record at minimum:

- file path;
- byte size;
- SHA-256 hash;
- execution timestamp or run identity;
- baseline version;
- constitution version;
- role assignment.

If required artifacts cannot be frozen, adjudication cannot proceed.

## Terminal-state logic

### HALT

Return **HALT** when the harness or evidence is not trustworthy enough to judge the ablation, including:

- Builder and Validator disagree on a hard mechanical fact;
- reconciliation counts conflict;
- required fixture results are missing;
- hashes or frozen versions mismatch;
- raw execution output is missing;
- a role violated information barriers;
- a model occupied more than one role;
- the baseline or constitution changed during the run.

HALT means **diagnose the harness**. It is not equivalent to REVERT.

### KEEP

Return **KEEP** only when all constitution requirements pass, including:

- Builder and Validator independently reproduce the required mechanical result;
- exact reconciliation passes on the predefined critical-field list;
- every mandatory fixture returns its predefined expected result;
- no undeclared semantic change is detected;
- no locked regression is introduced;
- the predeclared benefit predicate is satisfied;
- no blocking objection survives the frozen evidence.

### REVERT

Return **REVERT** when the evidence is mechanically coherent but the proposed change should not become canonical, including:

- benefit predicate not met;
- added complexity is not justified under the frozen rule;
- a non-harness regression appears;
- evidence remains insufficient for KEEP despite internally consistent mechanics;
- a blocking objection remains unresolved.

Conservative default: if KEEP is not established and HALT is not required, return REVERT.

## Rotation

Use the canonical rotation in [role-rotation.md](role-rotation.md).

## Batch audit

Because this protocol is fully AI-operated, completed batches are audited by the three models rather than by a human.

After a batch:

1. roles are reassigned so no model audits the same function it performed on the selected item;
2. one model checks adjudication-rule compliance;
3. one checks evidence-pack/hash integrity;
4. one checks role separation and information-barrier compliance;
5. any hard disagreement returns the batch to **HALT**.

The batch audit may not convert a HALT into KEEP.

## Promotion to canonical framework

Only a **KEEP** result may authorize a reusable framework change.

The retained change must then be:

1. applied to the relevant Stage 3 and/or Stage 4 canonical document;
2. linked to its ablation ID;
3. recorded in a refinement changelog or experiment index;
4. versioned so future projects can identify the controlling framework state.

Ablation evidence is retained even when the result is REVERT or HALT.

## Governing principle

> **AI proposes, independent AI reproduces, deterministic tooling freezes the evidence, and a third AI applies a frozen constitution. Disagreement on mechanics diagnoses the harness; coherent evidence without demonstrated benefit reverts; only reproduced, regression-free benefit is kept.**