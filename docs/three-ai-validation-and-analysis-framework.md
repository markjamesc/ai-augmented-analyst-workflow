# Stage 4 — Execution

Purpose: confirm that SQL/source delivery is correct and R wrangling implements the locked rule correctly. Required checks are executed by the pretested harness, not hand-written coordinator PASS reports.

## Source

For SQL, review the query against locked population/grain, joins and projection; compare extracted rows and critical values by unique keys to an independently obtained raw-side reference from the same snapshot. Counts/sums alone cannot establish equality. Preserve query text, snapshot identification, reference and export hashes. SQL may deliver mechanical raw fields but cannot precompute the judged R decision. Live access uses the approved read-only source client; no database writes.

File sources declare SQL NOT_APPLICABLE and still verify file identity and schema/content behavior. ACC003 uses a file source. Its separate synthetic SQLite test creates ONLY a disposable practice database and subsequently queries it read-only; this is not evidence of MySQL/live-system acceptance.

## Independent builders and checks

R-A (ChatGPT) and R-B (DeepSeek) independently implement the same contract from the same frozen input. Separate fresh chats; no peer code, intermediate solution or shared judged implementation. Preserve exact sent inputs and model/chat identification in one manifest. These are procedural independence attestations, not cryptographic proof; hashes establish identity only. Parallel execution is allowed when resources permit.

Use the actual production reader/entry point for frozen known-answer fixtures. Compare keyed populations, exclusion states, counts/components, ranks and final outputs, not just totals. Applicable row-order and unused-column tests run on each new builder. Combine the tiny-fixture smoke run with production execution. Keep missing/nonfinite semantics explicit. Fixture expected answers never change merely because a builder fails.

Ordinary parsing similarity is not a gate failure. Review only credible prohibited sharing or a specific uncovered correctness concern. A real hardcoded-header defect still needs repair. Give a builder its own failing case/output; withhold the peer solution. Lineage reports its own hash integrity result, not another check's failure.

## Checker and result handling

Pretest the frozen checker with good controls, wrong sum/ID/rank/missingness, a constant-PASS implementation, SQL wrong extraction and intended invariance cases. Reuse that pretest for unchanged checker/configuration/dependencies/interfaces; repeat affected cases when those change. Runtime performs the real project checks, not a ceremonial repetition of all checker tests.

Each executed check yields PASS, ANALYSIS_DEFECT or TOOL_ERROR. A runtime crash is TOOL_ERROR: diagnose/repair and rerun. Missing evidence or an unexecuted check is never PASS. Do not call a checker problem proof of wrong analysis. Nothing advances to Finish until required checks pass on current hashes. Preserve failed attempts and escalate after three unsuccessful repairs of the same defect; no check is waived.

The manifest binds the one design, source/SQL, both builder code/input declarations, checker/configuration/pretest, environment and actual outputs/reports. No chained stage receipts, watchdog, nonce/end-marker ceremony or mandatory three-AI similarity review. Hash changes invalidate affected prior verification. Exact comparisons and known answers remain strict.
