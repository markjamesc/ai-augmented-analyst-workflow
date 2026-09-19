# Ablation Program Catalog

**Status:** Living catalog for temporary framework refinement  
**Repo:** `ai-augmented-analyst-workflow`  
**Protocol:** [three-model-ablation-protocol.md](three-model-ablation-protocol.md) · [ablation-constitution.md](ablation-constitution.md) · [role-rotation.md](role-rotation.md)  
**Scope:** Ablations may update Stage 3 and/or Stage 4 canonical docs. They are **not** a permanent Stage 6 of the five-stage method. Owner may run them for a limited number of projects.

## What an ablation is

Each ablation stresses **one** major control. Three models rotate Builder / Independent Validator / Adjudicator.

| Terminal | Meaning | Framework edit? |
|----------|---------|-----------------|
| **KEEP** | Proposed change becomes canonical | Yes — Stage 3 and/or Stage 4 docs |
| **REVERT** | Valid judgment; proposed change rejected | No — control stays |
| **HALT** | Harness/evidence not trustworthy enough to judge | No — diagnose harness |

There is **no quorum** across the slate: one KEEP authorizes that rule’s change only.

## Current Chicago 311 slate (Dataset 2) — **8 controls**

First-cut batch after Stage 5 Finish Gate. **Limited to 8** (not 10) for this run (data/time limits).

| ID | Control | Typical target |
|----|---------|----------------|
| A01 | Dual-path independence (no shared judged code) | Stage 4 |
| A02 | Known-case Fixture Gate before builders | Stage 3/4 |
| A03 | SQL nonjudgment bright line | Stage 4 (+ Stage 3 contract) |
| A04 | SQL Source Gate vs raw | Stage 4 |
| A05 | Single owner knob only | Stage 3 |
| A06 | Integrity-gate INCONCLUSIVE (vs soft residual) | Stage 3 |
| A07 | Primary construct (e.g. TCD-IG vs raw age) | Stage 3 |
| A08 | Exact recon critical-field set | Stage 3/4 |

**Not in this batch** (deferred): A09 capacity/ranking Framing-only; A10 ML Mode None/A/B declaration — remain on the eventual catalog for a later project if needed.

Chicago frozen Stage 4 packs are **never rewritten** by ablations. KEEP updates the **general** frameworks only.

## Eventual major-control catalog — 38 rules to test

These are the ablation-sized controls for a fuller program (not every checklist sentence in the docs).

Marked **(batch)** = on the current Chicago 8-control slate.

### Cross-cutting / three-AI process
1. Stage 3 independent Design A / Design B / Data-Risk blindness before cross-review  
2. No coordinator draft as first-pass input (shared packet only)  
3. Design Gate only after cross-review  
4. Stage 5 three-AI roles (builder / critic / auditor) with blindness before cross-review  
5. Claim ceiling / no overclaim (descriptive vs causal; simulation vs live ops)

### Start & Framing
6. Start Gate three-way action vocabulary lock before measurement  
7. Framing Gate single analytical question lock (CQ-style)  
8. Capacity stance at Framing (unordered OK vs hard attention budget)  
9. Ambiguity / premature-framing attack before lock

### Stage 3 measurement
10. Single owner knob only **(batch A05)**  
11. Method constants vs knobs (constants not secretly tunable)  
12. Integrity-gate INCONCLUSIVE vs soft residual **(batch A06)**  
13. Primary construct choice **(batch A07)**  
14. Open / eligibility / duplicate-legacy locked semantics  
15. Ranking/capacity Framing-only  
16. Spec→builder packet completeness  
17. Known-case Fixture Gate freeze before builders **(batch A02)**  
18. No rewrite fixtures after Fail (new version only)  
19. ML Mode None/A/B declaration at Design Gate  
20. Mode A dual-path judged scoring lock fields (when Mode A)  
21. Mode B post-validation only (no silent rewrite of Validation Gate actions)

### Stage 4 execution / validation
22. SQL nonjudgment bright line **(batch A03)**  
23. SQL Source Gate vs raw **(batch A04)**  
24. Mechanical envelope vs final judged universe  
25. Dual-path R-A/R-B independence **(batch A01)**  
26. Same frozen source package to both builders  
27. Fixture execution Pass on both paths before trusting production  
28. Exact recon critical-field set **(batch A08)**  
29. Exact recon fail → investigate/correct/rerun (no averaging / ID copying)  
30. Structural cross-review after recon  
31. Lineage / snapshot attestation  
32. Validation Gate owner freeze before Stage 5 use  
33. Naive export clock contract (character → project timezone wall)  
34. Deterministic workflow gate before Stage 5

### Stage 5 interpretation
35. Freeze validated pack before deeper analysis  
36. Deeper analysis does not re-judge Validation Gate labels  
37. Finish Gate / recommendation proportionality  
38. Monitoring / next analytical question with recommendation

**Counts:** 38 eventual major controls · **8 on the current slate** · ~30 remaining for later projects.

## What not to ablate one-by-one

Design Gate bullets #1–11, Finish Gate #1–11, and every “must” sentence in prose should usually stay as **gate checklists**, not 100 separate ablations. Bundle them under the major controls above unless a specific bullet repeatedly fails in the wild.

## Post-batch sequence (planned)

1. Finish current **A01–A08** (stop; do not run A09/A10 this batch).  
2. Apply only **KEEP** edits to Stage 3/4 canonical docs; link ablation IDs.  
3. Draft forward upgrades (Framing `capacity_stance`, ML Mode Design Gate fail-closed, dual-path only where judgment lives, failability ladder, evidence-package schema, Master Prompt).  
4. Three-AI verification panel on those upgrades.  
5. Once approved → canonical for Price Point and later projects.  
6. Ablations remain temporary; may stop after a limited number of projects.

## Related links

- Protocol: `docs/framework-refinement/three-model-ablation-protocol.md`  
- Constitution: `docs/framework-refinement/ablation-constitution.md`  
- Role rotation: `docs/framework-refinement/role-rotation.md`  
- Folder: `docs/framework-refinement/`
