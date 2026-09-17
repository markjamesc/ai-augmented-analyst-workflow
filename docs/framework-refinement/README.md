# Framework Refinement

The five-stage AI-Augmented Analyst workflow remains the production analytical method:

1. Start
2. Framing
3. Measurement Design
4. Execution, Independent Validation, and Analysis
5. Interpretation and Recommendation

Framework refinement is a separate layer used to test proposed reusable changes to Stage 3 and Stage 4 before those changes become canonical.

The refinement layer is intentionally **not a sixth project stage**. Individual projects follow the current canonical workflow. Proposed changes to the reusable workflow are tested here.

## Three-model ablation system

Framework changes are evaluated through a fully automated three-model separation-of-duties process using:

- **ChatGPT**
- **DeepSeek**
- **Grok**

The three models rotate through:

- **Builder** — proposes/implements the ablation and produces raw execution evidence.
- **Validator** — independently reruns the required tests without seeing the Builder's conclusion.
- **Adjudicator** — receives only frozen Builder and Validator evidence and applies the precommitted constitution.

No model may occupy more than one role on the same ablation.

The system has three terminal states:

- **KEEP** — the change satisfies every hard gate and the predeclared benefit criterion.
- **REVERT** — the evidence is mechanically coherent, but the change fails the benefit/regression/judgment rules.
- **HALT** — Builder and Validator disagree on a hard mechanical fact, evidence is incomplete, or the harness itself is suspect.

## Core documents

- [Three-Model Ablation Protocol](three-model-ablation-protocol.md)
- [Ablation Constitution](ablation-constitution.md)
- [Role Rotation](role-rotation.md)

## Evidence repository

Actual ablation runs belong under:

`experiments/framework-ablation/`

Each run should preserve the specification, raw tool output, fixture results, reconciliation output, frozen manifests/hashes, validator output, adjudication record, and final state.

## Scope

The primary refinement target is the **Stage 3 → Stage 4 interface**:

- Stage 3 defines what must be true.
- Stage 4 proves that the locked meaning was implemented correctly.
- Ablation testing asks whether either layer is too weak, ambiguous, redundant, or unnecessarily complex.

A retained ablation changes the reusable framework only after the three-model protocol returns **KEEP**.