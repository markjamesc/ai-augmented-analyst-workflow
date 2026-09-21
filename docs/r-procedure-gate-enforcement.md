# R Procedure Gate — Whole-Run Procedural Referee

## Purpose

The five-stage analytical workflow and its framework documents remain unchanged. This control adds a deterministic R referee around the existing procedure.

> **GrokBot coordinates the method. The stage documents define the method. R verifies the observable procedural record.**

The Procedure Gate does not perform analysis, call an AI, or decide whether the final recommendation is wise. It records stage state, checks the required stage receipts, invokes the existing R Workflow Gate at the Execution boundary, and writes a final certificate only after the complete procedure passes.

## Relationship to the existing Workflow Gate

The controls answer different questions:

| Control | Question |
|---|---|
| Stage 4 analytical validation | Are the analytical results mechanically supported under the locked design? |
| R Workflow Gate | Are the Stage 4 requirements satisfied so Stage 5 may begin? |
| R Procedure Gate | Does the whole run show Start → Framing → Design → Execution → Finish in the prescribed order? |

The Procedure Gate wraps the Workflow Gate; it does not replace or duplicate it.

```text
Start → Framing → Design → Execution
                                ↓
                    existing Workflow Gate
                                ↓ PASS
                             Finish
                                ↓
                    final procedure certificate
```

## Executable files

```text
procedure-gate/procedure.json
procedure-gate/procedure_gate.R
procedure-gate/README.md
procedure-gate/tests/test_procedure_gate.R
```

The machine-readable procedure names the five existing stages, their controlling documents, prerequisites, receipts, and the existing gate used to complete Execution.

## Project evidence

During a run, the gate writes:

```text
artifacts/procedure/run_state.json
artifacts/procedure/checks/
artifacts/final_certificate.json
```

The authoritative analytical artifacts and stage receipts remain in the project repository. The outer state records their identities and hashes, and later transitions recheck those hashes so a completed receipt cannot be changed silently; it does not replace them.

## Operating rule

Before a stage begins, the orchestrator calls `begin`. After the required stage receipt is written, it calls `complete`. A failed completion leaves the stage open for repair and rerun.

Execution is not marked complete until the Procedure Gate runs `workflow-gate/workflow_gate.R` and confirms both:

- process exit code `0`; and
- `workflow_gate_status.json` contains `result = PASS` and `stage5_allowed = true`.

After Finish, `finalize` succeeds only when all five stages and the nested Workflow Gate have passed. The run is protocol-compliant only when `artifacts/final_certificate.json` reports `result = PASS` and `certified = true`.

## Scope and limit

This is a procedural certification layer. It verifies observable artifacts, order, versions, AI-role and review attestations, approvals recorded in receipts, and deterministic gate results. An attestation is an auditable claim, not proof of an AI's private context or conceptual independence. The gate also does not prove the correctness of the final business judgment.

The initial enforcement is definitional rather than a security sandbox: work outside the gate may technically occur, but it cannot produce a valid protocol certificate.

See [`../procedure-gate/README.md`](../procedure-gate/README.md) for commands and receipt details.
