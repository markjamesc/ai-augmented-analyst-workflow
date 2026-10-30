# Pre-set decisions

| Situation | Action |
|---|---|
| Required check PASS | Continue; no owner confirmation needed. |
| ANALYSIS_DEFECT | Do not advance on that result. Identify the failing evidence and repair implementation toward the same locked rule. Preserve attempts. Never rewrite the oracle to fit a builder. |
| TOOL_ERROR | Fix and rerun affected checks; do not call the analysis false. Unexecuted/unresolved check cannot certify. Independent unrelated work may continue. |
| Three unsuccessful repair attempts on SAME defect | Escalate once to owner with actual attempts/reasons/options. Initial construction is not a repair; changing chat/author does not reset count. No fourth repair without owner ruling. No analytical verdict is implied by the budget. |
| Permitted GrokBot tool repairs | Rerun, correct invocation path, or restore exact bytes from verified source. Other code/configuration changes return to ChatGPT in the coordination chat. |
| Checker/config/dependency/interface changed | Repeat affected pretests, then affected project checks; record new hashes. No tolerance relaxation or rule change without owner approval. |
| Design/locked decision change needed | Owner decision; prepare successor run with approved new contract hash and preserved predecessor. Never silently relock old run. |
| Similar parser code | Continue if independently built and substantive checks pass; similarity alone does not fail. Credible prohibited sharing gets focused investigation. |
| R-A/R-B agree but fixture fails | Remediate; shared wrong answer is not valid. Check oracle/adapter if evidence suggests checker fault; preserve distinction. |
| File source | SQL main-source gate NOT_APPLICABLE, file identity still checked. Separate synthetic SQL test is required in offline pretest. |
| Malformed/late reply | Delay alone irrelevant. Extract complete correct artifact without semantic edits. Recapture missing/truncated/wrong content using conditional13; preserve superseded reply. |
| Stale reply / wrong attached file | Do not use it. Resend the correct exact packet, record the one material exception. No nonce ritual. |
| AI usage limit | Save completed artifacts and role/chat state; pause until available. No silent service substitution or purchase. No deadline makes a failing check PASS. |
| PC offline | Retry access after five minutes, up to three retries; then report unavailable and preserve progress. Do not repeat writes whose completion is uncertain: inspect state first. |
| Uncertain command completion | Inspect saved manifest/attempt/log before rerun; use new attempt folder, never overwrite prior evidence. |
| Insight-only model contradicts rule | Exclude from decision/headline; label exploratory/unvalidated. No model exists in ACC003. |
| Decision model leakage | Remediate design/claim; prediction agreement cannot validate leakage. Requires owner if locked decisions change. |
| All checks good but Finish unsupported | Correct claim/interpretation, not data/rules; one consolidated revision, affected verification only. |
| Publication | Separate owner approval, new branch only; no main/merge/PR. |

Unknown substantive risk: preserve evidence, state the actual blocker and use the relevant reserved-owner/ChatGPT repair route. This table is not permission to invent a ruling or certify an unverified result. Operational pause is not an analytical failure.

Repair routing: use conditional14 for builder fixes (own failure only), conditional15 for harness/code/configuration problems to ChatGPT, and conditional12 for Finish artifact serialization errors: correct the artifact with prompt 12 against prompt 09's explicit interface, preserve meaning, and obtain affected-content verification at the new hash. A checker/config/interface implementation defect goes to prompt 15. TOOL_ERROR describes the failed check, not an automatic routing rule to a particular AI. None of these routes waives substantive checks or resets a defect's repair count. Record attempts with record.R repair; no per-glitch owner addendum. A newly found serialization defect is not an additional full substantive-audit round.
