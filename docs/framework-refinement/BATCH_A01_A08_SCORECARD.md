# Ablation Batch Scorecard — A01–A08

**Scope:** Completed ablation batch (prior locked Method B project evidence)  
**Batch:** Post–Finish Gate ablation slate (8 controls)  
**Adjudicated:** 2026-09-19 (US Central / project timezone)  
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

**Zero KEEP** ⇒ no Stage 3/4 rule changes were authorized by this batch. Tested controls remain as locked in the general frameworks pending a later KEEP.

Prior locked Stage 4 labels / packs in the project evidence repo were **not** rewritten.

## Terminal summary

| ID | Control ablated | Terminal | Canonical effect |
|----|-----------------|----------|------------------|
| A01 | Dual-path independence (no shared judged code) | **REVERT** | Dual-path independence remains |
| A02 | Known-case Fixture Gate before builders | **HALT** | Fixture Gate remains (same practical outcome as REVERT; see harness note) |
| A03 | SQL nonjudgment bright line | **REVERT** | SQL nonjudgment remains |
| A04 | SQL Source Gate vs raw | **REVERT** | Source Gate remains |
| A05 | Single owner knob only (κ) | **REVERT** | Single owner knob κ remains; companion constants stay constants |
| A06 | Integrity-gate INCONCLUSIVE (vs soft residual) | **REVERT** | Hard INCONCLUSIVE for integrity failures remains |
| A07 | Primary construct choice | **REVERT** | Locked primary construct remains |
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
| A05 | No authorized multi-knob policy; sensitivity at nearby knob values does not prove benefit of tunable companion constants; P1 failed. |
| A06 | Soft residual / default-by-absence not evidenced as safer than hard INCONCLUSIVE; P1 fail hook met. |
| A07 | Alternate raw-age analogue construct not equivalent to the locked primary construct on fixture cases; P1 failed. |
| A08 | Aggregate-only recon loses row-level detection of disagreement classes; P1 failed. |

## A02 HALT note (harness)

Official terminal: **HALT** (ChatGPT Adjudicator, twice). Substantive finding was still **not KEEP** — Fixture Gate remains mandatory. Diagnosis: adjudicator treated missing original production R stdout as Constitution §3 incompleteness after recon/fixture/portfolio/lineage hashes were present. Forward harness briefs for later ablations: when Builder/Validator agree on hard numbers and `_raw_evidence` MANIFEST is present, do **not** HALT solely for absent historical Rscript stdout; return **REVERT** when P1 fails and other HALT conditions are absent. See project-repo `A02/HARNESS_DIAGNOSIS.md`.

## Evidence locations

- Per-ablation trees: `docs/ablations/A01` … `docs/ablations/A08` in the **project evidence repo** (each includes `ABLATION_SPEC.md`, `ADJUDICATION.md`, `TERMINAL_STATE.txt`, builder/validator reports).
- Framework catalog results: this repo → `docs/framework-refinement/ablation-program-catalog.md` and companion `ablation-batch-A01-A08-results.md`.

## Post-batch sequence

1. ~~Finish A01–A08~~ **Done** — zero KEEP.
2. Apply only KEEP edits to Stage 3/4 canonical docs — **N/A this batch**.
3. Draft forward workflow upgrades (capacity stance, ML Mode fail-closed, dual-path where judgment lives, failability ladder, evidence-package schema, Master Prompt) for three-AI verify — **Done**.
4. Lock approved upgrades for prospective new projects — **this lock commit**.
5. Ablations remain temporary refinement, not a sixth project stage.

## Confirmation

**No KEEP ⇒ no Stage 3/4 framework edits required from batch A01–A08.**
