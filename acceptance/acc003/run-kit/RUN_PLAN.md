# Ordered ACC003 plan

This is a mechanical test on a known fixture. Rehearsal certificates do not count as live acceptance. Preserve all failed attempts and original ACC002 evidence.

| Step | Actor | Input | Output / pass condition |
|---|---|---|---|
| 0 Verify delivery | GrokBot/PC | Six files and SHA256SUMS | Hashes agree; extract into fresh workflow/run-kit paths; record archive identity |
| 1 Preflight early | PC | commands/00-Preflight.ps1 | R4.6.1 and packages ready; workflow file hashes match |
| 2 Offline rehearsal early | PC | commands/01-Offline.ps1 | ALL_FIVE_SUITES_PASS; actual builder/SQL tests, deliberate checker crash and recovery; offline certificate; negative cases reject their intended defects |
| 3 Live project | PC | commands/02-PrepareLive.ps1 | Fresh runs/ACC003, mode live; no reference builders copied |
| 4 Start | ChatGPT dialogue chat, prompt01 | Synthetic stakeholder, source/problem | start.md accurate and explicitly synthetic; no separate owner approval |
| 5 Framing | Same dialogue chat, prompt02 | Start and fixed question | framing.md preserves one question and constraints |
| 6 Design draft | Fresh ChatGPT Design chat, prompt03 | design.json, schema, Start/Framing, spec, fixtures/oracle | One complete candidate, no rule drift; inspect.R design validates schema |
| 7 Design review | Fresh Grok Design-review chat, prompt04 | Candidate and oracle/rule materials | One independent review, including oracle derivation and pretested coordinator-harness review (L3); ACCEPT or named corrections; use conditional05/06 only if necessary |
| 8 Owner lock | GrokBot + owner + PC | Concise design summary and exact contract hash; actual accepting review | Explicit owner approval of this contract; record then commands/03-Lock.ps1 gives LOCKED and PRETEST_REUSED |
| 9 Build R-A | Fresh ChatGPT builder chat, prompt07 | builder_contract.json, builder_spec.md, source CSV only | Complete independent R script; actual prompt/reply/model/chat recorded |
| 10 Build R-B | Fresh DeepSeek builder chat, prompt08 | Same permitted specification/source, no peer solution | Separate complete script and declaration; may run sends concurrently |
| 11 Execution | PC/GrokBot | Actual builders and frozen inputs; commands/04-Validate.ps1 | Every required check PASS; fixtures both paths, exact keyed reconciliation, per-builder shuffle/unused column, source/pretest/independence; SQL main gate N/A |
| 12 Finish synthesis | Fresh ChatGPT synthesis chat, prompt09 | Actual validated evidence, contract and scope | finish.json with exact evidence paths and bounded claims |
| 13 Inference review | Fresh Grok Finish chat, prompt10 | Exact Finish content/hash and evidence | One accepted inference review of same content; corrections use conditional12 |
| 14 Numerical review | Fresh DeepSeek Finish chat, prompt11 | Same content and actual tables | One accepted numerical/evidence review; fresh role despite same service as R-B; disclose this service overlap |
| 15 Finish record | PC | Both actual accepted reviews, commands/05-Finish.ps1 | FINISH_RECORDED; reviews bind current substantive content |
| 16 Certify | PC | commands/06-Certify.ps1 | CERTIFIED; current manifest/contract/check outputs/Finish hashes match |
| 17 Report | GrokBot | Actual certificate and manifest evidence | FINAL_REPORT.md completed, evidence delivered; no publication without owner approval |

Nine mandatory sends: 01,02,03,04,07,08,09,10,11 (ChatGPT5, Grok2, DeepSeek2). Conditional sends only for actual findings; no mandatory “AI says checking looks good” send after the executable checker. Budget cannot guarantee one usage window. Safe pauses: after a saved reply, owner lock or completed check; resume without repeating good work. Preflight/offline can be done earlier. Do not copy rehearsal outputs, approvals, builder code or PASS receipts into the live run.

Before Stage-3 lock regenerate builder_contract.json from the final approved design by removing only expected_primary and fixtures. Keep the original full design for validation; generated builder view must preserve every implementation rule. Use the provided refresh_view.R. Re-pretest is needed if comparison configuration changes; analytical decisions need owner approval. The frozen known answers are not reconstructed from builder output.

When a malformed reply is incomplete, request recapture in the SAME role chat. Treat a correct complete artifact with odd formatting normally. Store files UTF-8 without BOM; retain source fixtures byte-identically. Do not silently “repair” data or code while extracting it. Repair rules are in DECISIONS.md.

Publication clarification: before Finish review sends, check the saved JSON against prompt 09's field-by-type interface. This is interface preparation only; 05-Finish remains authoritative. Follow commands/RECORDING.md for ZIP/text-bundle, direct clipboard capture and session-resumption fallbacks. The documented live ACC003 run used the earlier kit; these clarifications are post-run improvements and are not retroactively claimed as live-tested sends.
