# Lean R gate interface

From repository root: `Rscript --vanilla procedure-gate/procedure_gate.R COMMAND PROJECT`.
Commands: init PROJECT RUN_ID live|offline; lock; validate; finish; finalize; status.

Only stage restrictions: owner lock before Execution; required checks PASS on current evidence before Finish. Finalize verifies that evidence and reviewed Finish content remain current. `workflow-gate/workflow_gate.R PROJECT` inspects the actual current validation manifest; it does not run new analysis or accept coordinator substitute statuses.

Exit 0: requested operation succeeded. Exit 1 from validate: demonstrated comparison defect. Exit 2: tool/evidence/precondition issue requiring repair/diagnosis, not a claim that the analysis is false. Inspect each check's status and detail. Preserve all attempts. Existing certificates identify their manifest hash; after a change they are historical, not current certification.

Old commands/receipts from procedure 2.x are not silently migrated. Old runs use their pinned repository. See the current README and delivered ACC003 run kit for exact examples.
