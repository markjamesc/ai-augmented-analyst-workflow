# V3 Stage Mechanics Note

**Date:** 2026-09-09  
**Evidence base:** FulfillIQ 2.0 (Olist freeze) Stages 1–5  
**Scope:** Targeted refinements to Stage 3 and Stage 4 frameworks — not a blank-page rewrite. Stages 1–2 unchanged. Master Prompt unchanged. Stage 5: packaging completeness only.

## What this run confirmed

1. **Translation drift is real.** Independent R(B) under-implemented locked Stage 3 rules (half-rate persistence, real dual-clock N5, full seller universe). That produced action / universe diffs versus SQL A until repaired toward the locked design — not by copying A’s ID list.
2. **Stage 4 dual-builder + exact recon is the right sieve.** Exact recon on decision-grain fields caught the miss. The Stage 4 *direction* stays; V3 hardens **checklist enforcement**.
3. **Agreement ≠ proof.** Matching builders can still share a wrong design. Better Stage 3 cuts translation drift; it does not erase correlated design error or irreducible data-floor limits.

## What V3 changes

| Stage | Change type | Content |
| --- | --- | --- |
| 3 | Heavier translation | Spec→builder attestations + known-case fixtures that fail the build if H2 / N5 / universe (or design equivalents) are missing (§19A; Design Gate 10) |
| 4 | Checklist only | Pre-build attestation, fixtures before recon, hard exact-recon contract, mismatch→repair-toward-design (never copy IDs), snapshot lineage, plumbing disclosure, simulation release block (§6A) |
| 5 | Packaging only | Evidence Package must include judged dual-clock / N-rule fields when INCONCLUSIVE is claimed |
| 1–2 / Master Prompt | None | Already at target standard for V3 |

## Why 0% decision-changing mismatch is unreachable

- **Data floor:** freeze age, missing fields, and policy filters (e.g. featured-out / tiny-volume rules) shape who can appear; residual ambiguity remains.
- **Shared wrong design:** if Stage 3 locks an incorrect rule, A and R(B) can match exactly and still be wrong for the business decision.
- **Plumbing vs translation:** dialect, privilege, and halt quirks create non-zero process friction even when logic is right.
- **Interpretation ceiling:** Stage 5 can still overclaim if packaging is thin; checklists reduce but do not eliminate executive paraphrase risk.

Target for the next project: cut *decision-changing translation* mismatch toward a lower band (roughly mid-single-digits to low tens of percent), then **ablate one change at a time** to confirm which V3 items moved the needle. Do not treat that target as already measured.

## How to verify on the next project

1. Score proposed checklist/fixture items against a known-case / toy that would have caught the FulfillIQ R miss.
2. Ablate one V3 change at a time.
3. Keep dual-builder exact recon as the Pass criterion for Stage 4.
4. Record residual mismatches as translation vs plumbing vs shared-design vs data-floor.
