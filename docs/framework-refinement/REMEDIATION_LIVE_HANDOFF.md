# Targeted live acceptance handoff

Base: `8b1a0fd1f581ffb8c0499fa13660fb70fe3c0312`, independently compared with `51b6b0f4741cf97720349c180313353300f5078b`: ahead 2, behind 0. Use the exact implementation SHA supplied in the handoff, on `acceptance-remediation-2026-10-17`. No merge or PR. New evidence only. R 4.6.1 is the supported live target; rebuilt local tests used R 4.4.3. Historical results are not candidate evidence.

Run commands from the checkout root. `ROOT` below is a new, absolute, disposable **clean live fixture** project directory. `PROBES` is a new sibling directory, outside ROOT. Replace these literal arguments with actual quoted paths; do not reuse production projects. Keep each output filename unique. Save every console, exit status and hash. No database access is required. The actual ChatGPT/Grok/DeepSeek roles follow the existing stage contracts and information barriers; synthetic test fixtures are forbidden as live AI evidence.

## Fixture and clean run (f)

Freeze the following UTF-8 CSV at Design, with LF newlines:

```csv
id,amount,eligible
A,9,true
B,10,true
C,11,true
D,20,false
E,10,true
F,0,true
G,,true
H,30,false
```

Question: which eligible records meet a finite amount >=10, ordered amount descending then id ascending, capacity 2? Blank amount is excluded, not zero. Qualified B,C,E; shortlist C,B; qualified count 3; selected count 2; selected sum 21. At capacity 1 select C; moving A from 9 to 10 changes qualification. Expected answers must be independently checked and frozen before builds. Test row shuffle, irrelevant column addition, missingness, exact threshold, ties, exclusion and capacity. Include a planted row-position or threshold defect and require detection. This is a nonconstant mechanical acceptance fixture, not profit evidence. Any SQL Source/Query Gate N/A must be explicitly justified as supplied synthetic CSV, not silently skipped.

Start and proceed stage-by-stage:

```text
Rscript procedure-gate/procedure_gate.R start ROOT ACC-SMALL-REMEDIATION-001
Rscript procedure-gate/procedure_gate.R begin ROOT start
Rscript procedure-gate/procedure_gate.R complete ROOT start
Rscript procedure-gate/procedure_gate.R begin ROOT framing
Rscript procedure-gate/procedure_gate.R complete ROOT framing
Rscript procedure-gate/procedure_gate.R begin ROOT design
Rscript procedure-gate/procedure_gate.R complete ROOT design
Rscript procedure-gate/procedure_gate.R begin ROOT execution
Rscript procedure-gate/procedure_gate.R complete ROOT execution
Rscript procedure-gate/procedure_gate.R begin ROOT finish
Rscript procedure-gate/procedure_gate.R complete ROOT finish
Rscript procedure-gate/procedure_gate.R finalize ROOT
```

**Do not run these as an uninterrupted batch.** Between each begin and complete, perform the real stage work and produce receipts, approvals and operations ledger. Before each actual dispatch:

```text
python tools/acceptance.py packet ROOT PACKET.json --out UNIQUE_PACKET_CHECK.json
```

After inspecting and saving the actual response:

```text
python tools/acceptance.py capture ROOT CAPTURE_REQUEST.json --out UNIQUE_CAPTURE.json
```

Require packet/capture PASS exit 0, begin AUTHORIZED, complete PASS, final certified=true/result=PASS with limited assurance and valid inventory. A packet PASS does not authorize a send. Get the actual owner application evidence permitted by the existing authorization; do not invent owner sign-offs. Failures remain evidence. Conditional approval failures must escalate, never be filled with synthetic PASS.

## Chaining and watchdog (c)

Within the appropriate real stage, execute one genuine dependency chain across the three AIs, preserving independent first passes where required. Show the dependencies, actual packets/replies and capture checks. Demonstrate executor polling (one minute or less); record actual delays. Separately use the labeled synthetic >900-second queue below to test timeout detection economically, without deliberately delaying authorized real work for 15 minutes. If live scheduling behavior itself fails, retain it and do not call the synthetic check a substitute.

## Negative probes (a), (b), (d), (e)

After the clean live fixture is preserved, make isolated, clearly labeled negative copies. These mutate copies only; they do not constitute real revocations or authorize premature dispatch:

```text
python tools/prepare_live_probes.py ROOT PROBES
Rscript tools/check_remediation.R validation PROBES/changed-rb
python tools/acceptance.py watchdog ROOT PROBES/watchdog.json --out PROBES/watchdog-result.json
Rscript tools/check_remediation.R operations PROBES/dropped-review finish
Rscript tools/check_remediation.R operations PROBES/stale-reply finish
python tools/acceptance.py capture PROBES/stale-capture PROBES/stale-capture/probe-capture.json --out PROBES/stale-capture/rejected-capture.json
```

Expected outcomes, prespecified:

- **(a)** Retired 2026-10-31 (send chronology cut, owner t1652u). The executor still refuses stage work without AUTHORIZED.
- **(b)** One-line R-B comment after validation: exit 1, stale version/component failure. `Rscript procedure-gate/procedure_gate.R finalize PROBES/changed-rb` must refuse (nonzero; no PASS certification). Preserve that failure. **Correction:** MR alone is insufficient. Rebuild/rerun the version-bound bundle (fixtures both paths, applicable MR both paths, replay, reconciliation and affected downstream receipts). Do this through the existing amendment/successor mechanism or a fresh run; never reopen/overwrite the completed source run. Rehashing only the receipt must still fail. Exact analytical runner commands are project-specific and must be frozen in the fixture's Design, not guessed here. The final new bundle must pass `Rscript tools/check_remediation.R validation REPAIRED_ROOT` and affected gates; retain each attempt.
- **(c)** Watchdog: FLAG, exit 1, overdue includes SYNTHETIC-overdue. The boundary is strictly >900 seconds, not >=900.
- **(d)** Replaced 2026-10-31 (approvals and revocation ledger cut): **dropped-review** (numerical_auditor send removed) exit 1 with `review coverage finish role numerical_auditor` FAIL; **stale-reply** (inference_reviewer reply replaced by the interpreter's bytes, hashes consistent) exit 1 with `review coverage finish distinct replies` FAIL. The probe changes need ChatGPT's agreement before the live probe run.
- **(e)** Stale prior reply with a fresh packet nonce: capture FAIL exit 2. A newly obtained matching live reply must pass exit 0; do not synthesize it.

Before invoking the probe commands, agree with ChatGPT that these are the targeted scenarios; no broader live run is required absent a concrete defect. A full production-data rerun is not necessary.

## Local/PC suite commands

```text
Rscript --version
Rscript workflow-gate/tests/test_workflow_gate.R .
Rscript procedure-gate/tests/test_procedure_gate.R .
Rscript methodology/tests/test_methodology.R .
Rscript methodology/tests/test_acceptance.R .
python methodology/tests/test_schema.py .
Rscript methodology/tests/test_remediation.R .
python -m unittest discover -s tools -p test_acceptance.py
```

Schema suite requires jsonschema 4.23.0. All expected exit 0. Unit fixtures prove code behavior, not live AI behavior. Avoid duplicating a confirmed exact-SHA R 4.6.1 CI run unless needed for Windows-specific risk. `tools/run_r_job.ps1` is untested locally on Windows; exercise it on a harmless fixture if using it for live orchestration.

## Return evidence in one message

Exact checkout SHA and clean/dirty status; R/session/package versions; scenario-by-scenario expected/actual outcome, command, exit status, failures and repairs; actual three-AI identities and visible provenance; queue and approvals/revocations; unchanged original evidence statement; final certificate, run state, Workflow Gate report, Finish receipt, certification check, complete referenced-file inventory, SHA256SUMS and individually accessible critical files. Include original failed attempts and timing limitations. Distinguish synthetic negative probes from actual dispatch/capture evidence. ChatGPT then assesses Step 3; do not infer acceptance from unit tests alone.
