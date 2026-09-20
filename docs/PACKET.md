# Workflow packet index

Portfolio method packet for [ai-augmented-analyst-workflow](https://github.com/markjamesc/ai-augmented-analyst-workflow). Five stage frameworks plus the Stage 4 R execution engine and a cross-stage deterministic R workflow gate.

| # | Stage / control | File |
|---|---|---|
| — | Master Prompt template | [MASTER_PROMPT.md](MASTER_PROMPT.md) — standing orchestration rules before Start |
| 1–2 | Start and Framing | [three-ai-start-and-framing-dialogue-framework.md](three-ai-start-and-framing-dialogue-framework.md) |
| 3 | Measurement Design | [three-ai-measurement-design-framework.md](three-ai-measurement-design-framework.md) |
| 4 | Execution, Validation, and Deeper Analysis | [three-ai-validation-and-analysis-framework.md](three-ai-validation-and-analysis-framework.md) |
| 4 | R Workflow Engine (optional paste prompt) | [ENGINE.md](ENGINE.md) |
| Cross-stage | R Workflow Gate — procedural enforcement | [r-workflow-gate-enforcement.md](r-workflow-gate-enforcement.md) |
| 5 | Interpretation and Recommendation | [three-ai-interpretation-and-recommendation-framework.md](three-ai-interpretation-and-recommendation-framework.md) |

**ENGINE.md** is the one-file tidyverse R prompt (thin CONFIG + nine functions + Prep / Analyze / Expand / Assure / Publish). Use it when Stage 4 needs a modular R report script; it does not replace the Stage 4 validation gate or Stages 1–3 / 5 frameworks.

**ML / predictive analytics modes (None / A / B)** live in the Stage 3 measurement-design and Stage 4 validation frameworks; ENGINE Expand is a Mode B helper only.

**The R Workflow Gate is separate from Stage 4 analytical validation.** Stage 4 performs SQL source validation, independent R-A / R-B judged construction, exact reconciliation, structural review, and deeper analysis. The cross-stage gate verifies that the prescribed stage locks and validation controls were actually completed using the correct Stage 3 design version before Stage 5 may begin.

Executable gate: [`../workflow-gate/workflow_gate.R`](../workflow-gate/workflow_gate.R). Example machine-readable stage artifacts are in [`../templates/workflow-gate/`](../templates/workflow-gate/).

Historical case studies do not need to be retrofitted merely for conformity. The deterministic gate is intended as a prospective control for new projects.

## FORWARD method locks (verified)

| Doc | File |
|---|---|
| Three-AI verify / lock packet | [VERIFY_PACKET.md](VERIFY_PACKET.md) |
| Master Prompt (standing rules) | [MASTER_PROMPT.md](MASTER_PROMPT.md) |
| Cross-review (revise→lock) | [CROSS_REVIEW.md](CROSS_REVIEW.md) |

Additive FORWARD sections land in Stages 1–2 Framing, Stage 3 measurement design, and Stage 4 validation frameworks. They do **not** rewrite prior locked / frozen historical Stage 3/4 packs. Case-specific evidence lives in project repos only.
