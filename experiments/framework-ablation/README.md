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

Protocol scaffold created. No execution evidence is implied by the presence of this directory.