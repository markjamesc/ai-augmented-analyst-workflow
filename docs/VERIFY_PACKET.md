# VERIFY_PACKET — Forward workflow upgrades (three-AI review → lock)

> **ACC003 lean workflow (certified 2026-10-30):** Where this text describes CLI commands, receipts, status JSONs or review tiers that the certified code does not run, those are not enforced in the certified ACC003 lean code (2026-10-30). See docs/r-procedure-gate-enforcement.md for the certified interface. 

> **Gate merge 2026-10-31 (branch merge-gates-2026-10-31):** The code in this tree is the fixed gate code from 48b4af8, not the ACC003 lean code of 9bc13eb. The ACC003 lean note above records what was certified for ACC003 on the lean code; it does not describe the current gates. Where it says a command, receipt, review tier, role, nonce or END_REPLY line is not enforced or was cut, the current gates enforce the rules in this text plus the CHANGES 2026-10-31 sections of [r-procedure-gate-enforcement.md](r-procedure-gate-enforcement.md) and [r-workflow-gate-enforcement.md](r-workflow-gate-enforcement.md): F1 Start/Framing roles, F5b reviewed subjects, R1 review coverage, and the Round 2 cuts. No restored text was removed.


**Repo worktree:** `/workspace/ai-augmented-analyst-workflow-work` (clone of `markjamesc/ai-augmented-analyst-workflow`)  
**Intent:** Three-AI verify completed; owner approved **REVISE_THEN_LOCK** with generalize-no-case-branding constraint.  
**Historical packs rule:** Prior locked Stage 3/4 packs must remain untouched; do not retrofit frozen project evidence.

## What was verified (now locked)

Five locked upgrades, applied as **additive FORWARD** method language:

| # | Upgrade | Where locked | Must stay true |
|---|---|---|---|
| 1 | **Framing `capacity_stance`** (`unordered_ok` vs `hard_attention_budget`) | `docs/three-ai-start-and-framing-dialogue-framework.md` | Stance always required; deferred N still freezes ranking key / tie-break / no-pad; Stage 5 applies N only; no silent ranking of census purposes |
| 2 | **ML Mode fail-closed** (None / A / B) | `docs/three-ai-measurement-design-framework.md` (+ existing §17A / Stage 4 §6B) | Blank mode = Design Gate Fail; Mode A = judged predictive + dual R-A/R-B; Mode B = post-Validation Expand only; ban Expand/shared model/scored table as Mode A input; past-project Mode is descriptive only |
| 3 | **Dual-path only where judgment** | `docs/three-ai-validation-and-analysis-framework.md` | Dual R-A/R-B for judged decisions; shared judged helpers forbidden; dumb comparator; judged fields in R not shared SQL; repair cites Stage 3+fixtures; Mode B ≠ dual judged-path |
| 4 | **Failability ladder** | same Stage 4 FORWARD block | Fixtures → Source Gate → exact recon → cross-review → Validation Gate → Workflow Gate; no verbal waiver; owner change-control + new freeze + rerun; Workflow Gate consumes lower receipts |
| 5 | **Evidence schema receipts** | same Stage 4 FORWARD block | New/forward publishable packs need workflow_gate + lineage + scorecards + stage JSONs with contents/hashes; not forced retrofit of historical packs |

Also locked: `docs/MASTER_PROMPT.md` (portable orchestration language for new projects).

## What must stay true (reviewer checklist)

1. **Additive, not rewrite:** FORWARD sections are marked; pre-existing canonical text is not deleted or contradicted without cause.
2. **Prior packs unaffected:** No instruction to mutate frozen Stage 3/4 packs; FORWARD text exempts historical project evidence; case evidence lives in project repos.
3. **A01–A08 0 KEEP:** These upgrades are **not** claimed as KEEP-authorized Stage 3/4 rewrites from the ablation batch; they are post-batch forward method locks.
4. **Mode A ≠ Mode B:** Judged predictive work cannot be satisfied by pasting ENGINE Expand into both paths.
5. **Independence bright line preserved:** Shared source/fixtures/schema OK; shared judged code not OK.
6. **Workflow gate remains procedural:** Does not replace analytical Validation Gate or R-A/R-B recon.
7. **Portable method:** General docs name no city, case brand, or project-specific construct IDs.

## Files in this lock

| File | Change |
|---|---|
| `docs/three-ai-start-and-framing-dialogue-framework.md` | + FORWARD `capacity_stance` (revised) |
| `docs/three-ai-measurement-design-framework.md` | + FORWARD ML Mode fail-closed (revised) |
| `docs/three-ai-validation-and-analysis-framework.md` | + FORWARD dual-path / failability / evidence schema (revised) |
| `docs/MASTER_PROMPT.md` | **new** — standing process rules + locked upgrades |
| `docs/VERIFY_PACKET.md` | this packet (lock record) |
| `docs/CROSS_REVIEW.md` | revise→lock cross-review + generalize constraint |
| `docs/PACKET.md` | + index links |
| `docs/r-workflow-gate-enforcement.md` | + FORWARD pointer to evidence receipts |
| `templates/workflow-gate/stage2_framing.example.json` | required `capacity_stance` example |
| `templates/workflow-gate/stage3_locked_design.example.json` | required `ml_mode` example |
| `docs/framework-refinement/ablation-program-catalog.md` | five upgrades marked locked forward; batch language neutralized |

## Three-AI roles (completed)

| Model | Role | Outcome |
|---|---|---|
| ChatGPT | Builder / consolidator | REVISE_THEN_LOCK |
| Grok | Independent critic | REVISE_THEN_LOCK (attack-surface edits applied) |
| DeepSeek | Claim-to-text auditor | REVISE_THEN_LOCK (framework fail-closed wording applied) |

## Pass / revise / lock disposition

**Locked** after revise: all five upgrades present with FORWARD markers, prior-pack exemption in general language, Mode A/B bright line intact, Master Prompt matches frameworks, and **generalize-no-case-branding** applied (no city / case / project-construct names in general method docs).


## Prospective acceptance remediation

New runs must follow [SEND_QUEUE_PROTOCOL.md](SEND_QUEUE_PROTOCOL.md). This adds recorded authorization/send ordering, scoped approval applications, exact test-version binding, capture checks and limited certificate assurance. It does not change original candidate results or certify the historical acceptance run.
