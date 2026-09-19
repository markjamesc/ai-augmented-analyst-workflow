# Chicago 311 Ablation Batch Scorecard — A01–A08

**Project:** Chicago 311 Dispatch Priority (Dataset 2 / Method B)  
**Batch:** Post–Stage 5 ablation slate (8 controls)  
**Adjudicated:** 2026-09-19 (America/Chicago)  
**Constitution:** v1.0  
**Protocol:** three-model Builder / Validator / Adjudicator → KEEP / REVERT / HALT  
**Catalog:** `ai-augmented-analyst-workflow` → `docs/framework-refinement/ablation-program-catalog.md`

## Batch outcome (headline)

| Metric | Value |
|--------|-------|
| Completed | A01–A08 |
| Deferred | A09 (Capacity Framing-only), A10 (ML Mode declaration) |
| **KEEP** | **0** |
| **REVERT** | **7** (A01, A03–A08) |
| **HALT** | **1** (A02) |
| Stage 3/4 canonical framework edits from this batch | **None** |

**Zero KEEP** ⇒ no Stage 3/4 rule changes were authorized by this batch. All tested controls remain as locked for Chicago 311 and for the general frameworks pending a later KEEP.

Frozen Chicago Stage 4 labels / packs were **not** rewritten.

## Terminal summary

| ID | Control ablated | Terminal | Canonical effect |
|----|-----------------|----------|------------------|
| A01 | Dual-path independence (no shared judged code) | **REVERT** | Dual-path independence remains |
| A02 | Known-case Fixture Gate before builders | **HALT** | Fixture Gate remains (same practical outcome as REVERT; see harness note) |
| A03 | SQL nonjudgment bright line | **REVERT** | SQL nonjudgment remains |
| A04 | SQL Source Gate vs raw | **REVERT** | Source Gate remains |
| A05 | Single owner knob only (κ) | **REVERT** | Single owner knob κ remains; W / n_min stay constants |
| A06 | Integrity-gate INCONCLUSIVE (vs soft residual) | **REVERT** | Hard INCONCLUSIVE for integrity failures remains |
| A07 | TCD-IG vs raw open age construct | **REVERT** | Locked TCD-IG dormancy construct remains |
| A08 | Exact recon critical-field set | **REVERT** | Full exact recon critical-field set remains |
| A09 | Capacity / ranking Framing-only | **DEFERRED** | Not run this batch |
| A10 | ML Mode None/A/B declaration | **DEFERRED** | Not run this batch |

## Role rotation (this batch)

| ID | Builder | Validator | Adjudicator |
|----|---------|-----------|-------------|
| A01 | ChatGPT | DeepSeek | Grok |
| A02 | DeepSeek | Grok | ChatGPT |
| A03 | Grok | ChatGPT | DeepSeek |
| A04 | ChatGPT | DeepSeek | Grok |
| A05 | DeepSeek | Grok | ChatGPT |
| A06 | Grok | ChatGPT | DeepSeek |
| A07 | ChatGPT | DeepSeek | Grok |
| A08 | DeepSeek | Grok | ChatGPT |

## One-line adjudication rationale

| ID | Why not KEEP |
|----|--------------|
| A01 | Benefit of collapsing dual paths unproven; independence remains load-bearing for silent coupling detection. |
| A02 | P1 failed (Fixture Gate ≠ exact recon defect classes); official terminal **HALT** on evidence-completeness reading — harness note clarifies future REVERT default when P1 fails and mechanics agree. |
| A03 | SQL nonjudgment necessary for Source Gate meaning and mechanical-vs-judged envelope separation; P1 failed. |
| A04 | Source Gate covers extract-vs-raw defects that dual-R recon alone can miss (shared-input blind spot); P1 failed. |
| A05 | No authorized multi-knob policy; sensitivity at κ=2 vs κ=3 does not prove benefit of tunable W/n_min; P1 failed. |
| A06 | All 6,377 INCONCLUSIVE attributed to `thin_type_or_missing_peer`; soft residual / STANDARD-by-default not evidenced as safer; P1 fail hook met. |
| A07 | Raw calendar age would change F03 (STANDARD under TCD-IG → escalate under raw); construct not equivalent; P1 failed. |
| A08 | Aggregate-only recon loses SR_NUMBER/row-level detection (historical ~104-row clock-skew STANDARD vs ESCALATE); P1 failed. |

## A02 HALT note (harness)

Official terminal: **HALT** (ChatGPT Adjudicator, twice). Substantive finding was still **not KEEP** — Fixture Gate remains mandatory. Diagnosis: adjudicator treated missing original production R stdout as Constitution §3 incompleteness after recon/fixture/portfolio/lineage hashes were present. Forward harness briefs for later ablations: when Builder/Validator agree on hard numbers and `_raw_evidence` MANIFEST is present, do **not** HALT solely for absent historical Rscript stdout; return **REVERT** when P1 fails and other HALT conditions are absent. See `A02/HARNESS_DIAGNOSIS.md`.

## Evidence locations

- Per-ablation trees: `docs/ablations/A01` … `docs/ablations/A08` in `chicago-311-dispatch-priority` (each includes `ABLATION_SPEC.md`, `ADJUDICATION.md`, `TERMINAL_STATE.txt`, builder/validator reports).
- Slate: `POST_STAGE5_ABLATION_SLATE.md`
- Framework catalog results: `ai-augmented-analyst-workflow` → `docs/framework-refinement/ablation-program-catalog.md` (Batch A01–A08 results section) and companion `ablation-batch-A01-A08-results.md`.

## Post-batch sequence (unchanged plan)

1. ~~Finish A01–A08~~ **Done** — zero KEEP.
2. Apply only KEEP edits to Stage 3/4 canonical docs — **N/A this batch**.
3. Draft forward workflow upgrades (capacity stance, ML Mode fail-closed, dual-path where judgment lives, failability ladder, evidence-package schema, Master Prompt) for three-AI verify.
4. Lock approved upgrades for Price Point and later projects.
5. Ablations remain temporary refinement, not a sixth project stage.

## Confirmation

**No KEEP ⇒ no Stage 3/4 framework edits required from batch A01–A08.**
