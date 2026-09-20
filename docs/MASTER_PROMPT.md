# Master Prompt — Standing process rules (forward lock)

> **Status:** Locked orchestration language for **new / prospective** projects.  
> Does **not** rewrite prior locked project master prompts or frozen historical packs.  
> Case-specific evidence lives in project repos only.

## Purpose

Give the orchestrator (Grok Bot or equivalent) fail-closed operating rules for the five-stage method, portable to any future project.

## Controlling frameworks (current repo)

Use the current `main` (or verified commit) of:

- Stages 1–2: `docs/three-ai-start-and-framing-dialogue-framework.md` — including **FORWARD `capacity_stance`**
- Stage 3: `docs/three-ai-measurement-design-framework.md` — including **FORWARD ML Mode fail-closed**
- Stage 4: `docs/three-ai-validation-and-analysis-framework.md` — including **FORWARD dual-path / failability / evidence schema**
- Cross-stage: `docs/r-workflow-gate-enforcement.md` + `workflow-gate/workflow_gate.R`
- Optional ENGINE: `docs/ENGINE.md` (Mode B helper only)
- Stage 5: `docs/three-ai-interpretation-and-recommendation-framework.md`

## Locked forward upgrades (must appear in the project master prompt)

### 1. Framing — `capacity_stance`

Before Framing Gate Pass, lock exactly one (missing stance = **Framing Gate Fail**, regardless of purpose):

- `unordered_ok` — complete qualifying set / label census is acceptable; do not invent a hard budget later; do not silently rank a census purpose; or
- `hard_attention_budget` — limited focus list is the purpose; ranking / truncation / capacity unit (or owner-set-N deferral) must be explicit.

If N is deferred to the owner before Stage 5, Stage 3 must still freeze ranking key, tie-break, membership-first/no-pad, and “Stage 5 may apply N but may not invent the key.” Stage 5 applies N only under that lock.

### 2. Stage 3 — ML Mode fail-closed

Before Design Gate Pass / Stage 4 handoff, lock `ml_mode` ∈ {`None`, `A`, `B`}.

- **None** — rules / non-ML judged contract (must be **explicit**; historical Mode None/rules on a past project is descriptive only and does not authorize omitting the field).
- **A** — judged predictive contract + dual R-A/R-B on locked scoring fields; Mode A lock fields frozen first. Ban Expand / shared model object / shared scored table as Mode A input.
- **B** — post-Validation Expand / tidymodels diagnostics only; must not rewrite Validation-Gate actions; must not rank a `hard_attention_budget` list without Mode A reopen.

Blank / TBD / inferred mode → **Design Gate Fail**. Do not mutate frozen packs to insert `ml_mode`.

### 3. Dual-path only where judgment lives (Method B)

Independent R-A / R-B apply to **judged** Stage 3 decisions (rules or Mode A). Shared helpers are **forbidden** for judged code: no shared project judged file/function, Expand paste, model object, recipe, scored table, or judgment-deciding parse. Mechanical SQL delivery, frozen fixture inputs, and a **dumb** recon comparator (join keys + exact equality) may be shared when they do not decide judged outcomes. If a field determines the action, it belongs in R, not shared SQL. Repair cites Stage 3 + fixtures, not the twin path’s output. Mode B / deeper analysis is not dual judged-path work (it still has its own review roles).

### 4. Failability ladder

Treat as hard fails (not advisory): fixtures → SQL Source Gate → exact recon → structural cross-review → Validation Gate → R Workflow Gate. Narration cannot waive a failed tier. Owner correction = dated change-control + **new freeze** + rerun of that tier and dependents. Higher tiers do not substitute for lower ones. Workflow Gate **consumes** lower-tier receipts; it does not author PASS without their hashes.

### 5. Evidence-package schema (publishable packs)

Before Stage 5 (and for publishable packs), require receipts with contents (not empty filenames):

- `artifacts/workflow_gate_status.json` (PASS, `stage5_allowed`, `design_version`, fixture/source/recon/validation identities, timestamp)
- lineage (source snapshot / extract / fixture freeze / `design_version` / script versions)
- scorecards (recon field list + mismatch count; fixture IDs expected vs observed)
- stage boundary JSONs including required `capacity_stance` (Stage 2) and `ml_mode` (Stage 3)

Prospective for new / forward publishable packs only — do not retrofit frozen historical packs.

## Standing process rules (always on)

1. **Autonomy / owner gates:** Orchestrator may advance within locked contracts; owner gates (Framing / Design / Validation / Finish / change-control freezes) require explicit owner action. Do not invent owner approval from chat consensus.
2. **Immediate mismatches:** Surface Design↔implementation, fixture, recon, or receipt mismatches as soon as detected; do not defer to Stage 5 narration.
3. **Stage 3 independence:** Design A / Design B / Data-Risk blindness before cross-review; no coordinator draft as first-pass input (shared packet only).
4. **Method B:** Dual R-A/R-B for judged contracts under the independence bright line above.
5. **ML Mode:** Fail-closed `None` / `A` / `B` as locked in Stage 3.
6. **Wall-clock / timezone parse consistency:** Naive export clocks and timezone conversions must follow the locked Stage 3/4 contract for the project timezone; both judged paths must parse the same way. Treat silent clock/tz divergence as a judged-path defect, not a cosmetic formatting issue.
7. **Ablation KEEP-only:** Only ablations returning `KEEP` may authorize reusable Stage 3/4 framework edits. `REVERT` / `HALT` / deferred items / forward upgrades that are not KEEP-authorized do not rewrite frozen project evidence. Ablation batch A01–A08 returned **0 KEEP**; batch trees live in the project evidence repo.

## Orchestrator hard stops (paste block)

```text
FORWARD HARD STOPS (portable method):
1) Framing Gate requires capacity_stance = unordered_ok | hard_attention_budget (always; missing = Fail).
2) Design Gate requires explicit ml_mode = None | A | B (fail-closed; no blank/inference).
3) Dual R-A/R-B only for judged contracts; shared judged helpers forbidden; dumb comparator only.
4) Fixture / Source / Recon / Cross-review / Validation / Workflow gates can fail the work — no verbal waiver; owner change-control = new freeze + rerun.
5) Stage 5 blocked unless workflow_gate_status.json PASS with stage5_allowed and lineage + scorecard receipts present (Workflow Gate consumes lower receipts).
Do NOT retrofit or mutate prior locked / frozen historical packs. Apply these rules to this project prospectively. Case evidence stays in the project repo.
```

## Historical / prior-pack boundary

- Do not reopen or rewrite prior locked Stage 3/4 evidence to insert forward fields.
- Do not treat a past project’s historical Mode None/rules silence as permission to omit `ml_mode` on the next project.
- Forward upgrades are method locks for prospective projects, not KEEP-authorized rewrites of frozen artifacts from ablation A01–A08 (0 KEEP).

## Promotion checklist

The first two items record the published framework lock. The remaining items are per-project adoption tasks.

- [x] Three-AI verify complete (see [VERIFY_PACKET.md](VERIFY_PACKET.md) + [CROSS_REVIEW.md](CROSS_REVIEW.md))
- [x] Owner approve revise→lock→push (recorded in CROSS_REVIEW.md)
- [ ] Copy upgraded clauses into the **new** project’s master orchestration prompt
- [ ] Extend that project’s `stage2_framing.json` / `stage3_locked_design.json` with required `capacity_stance` / `ml_mode`
