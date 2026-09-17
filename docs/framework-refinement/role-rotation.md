# Three-Model Role Rotation

The framework-ablation system uses three model families:

- ChatGPT
- DeepSeek
- Grok

No model may occupy more than one role on the same ablation.

## Canonical rotation

| Ablation | Builder | Validator | Adjudicator |
|---|---|---|---|
| A01 | ChatGPT | DeepSeek | Grok |
| A02 | DeepSeek | Grok | ChatGPT |
| A03 | Grok | ChatGPT | DeepSeek |
| A04 | ChatGPT | DeepSeek | Grok |
| A05 | DeepSeek | Grok | ChatGPT |
| A06 | Grok | ChatGPT | DeepSeek |

Continue the three-row cycle for later ablations.

## Why rotate

Rotation reduces persistent role bias:

- one model does not become the permanent proposer;
- one model does not become the permanent skeptic;
- one model does not become the permanent authority;
- model-family-specific failure modes are exposed in different positions.

Rotation does not make the models perfectly independent. Independence also requires blind first passes, frozen evidence, distinct roles, deterministic hashing, and a precommitted constitution.

## Batch audit rotation

For the fully AI-operated batch audit, do not assign a model to audit the same function it performed on the selected ablation.

The three audit functions are:

1. adjudication-rule compliance;
2. evidence-pack and hash integrity;
3. role-separation and information-barrier compliance.

Any hard disagreement during batch audit returns the affected batch to **HALT**.