# ACC003 mechanical acceptance

Reference builders are for OFFLINE tests only; never send them or the oracle to the live builders. The 16 original fixture byte files and oracle are unchanged. Reference R-A fixes the F09-specific header; both reference readers reject a duplicate required column name masquerading as an unused field.

Run from repository root:

```
Rscript --vanilla methodology/tests/test_schema.R .
Rscript --vanilla methodology/tests/test_methodology.R .
Rscript --vanilla workflow-gate/tests/test_workflow_gate.R .
Rscript --vanilla procedure-gate/tests/test_procedure_gate.R .
Rscript --vanilla acceptance/acc003/rehearse.R . /ABSOLUTE/NEW/OFFLINE/PROJECT
```

The last command runs actual R builders, all 16 fixtures, new-builder invariance, synthetic SQL positive/negative tests, an injected checker crash, repair/rerun and offline certification. It simulates human/AI approval records openly and cannot establish live role behavior. Use the separate run kit for live ACC003. `prepare.R REPO NEW_PROJECT live` never copies reference builders.

Harness fingerprint includes its R code/schema, runtime/package versions, comparison configuration and fixture/oracle hashes. Retain pretest reports. Exact runtime testing on Windows R4.6.1 is required before live work even if Linux compatibility tests pass.

The live single Design review also reviews the coordinator-authored harness and its offline good/negative evidence (L3); no second reviewer round is added. This independent review is still pending at build delivery.
