# Framework Ablation Experiments

This directory stores execution evidence for reusable framework-refinement experiments.

The canonical protocol is:

- [Three-Model Ablation Protocol](../../docs/framework-refinement/three-model-ablation-protocol.md)
- [Ablation Constitution](../../docs/framework-refinement/ablation-constitution.md)
- [Role Rotation](../../docs/framework-refinement/role-rotation.md)

## Run layout

Each ablation should receive its own immutable run directory:

```text
A01/
├── ablation_spec.md
├── builder/
├── validator/
├── freeze/
├── adjudication.md
└── final_state.txt
```

`final_state.txt` must contain exactly one of:

- `KEEP`
- `REVERT`
- `HALT`

Do not delete failed or reverted runs. They are part of the framework's development record.

## Current status

Batch A01–A08 is complete: **0 KEEP, 7 REVERT, 1 HALT**; A09/A10 were deferred. See the [scorecard](../../docs/framework-refinement/BATCH_A01_A08_SCORECARD.md). No canonical Stage 3/4 changes were authorized by this batch.

This directory remains a layout template. The actual batch evidence is held in the project evidence repository, not duplicated here. Completed adjudication does not imply an unattended automated harness or establish the controls' general effectiveness.