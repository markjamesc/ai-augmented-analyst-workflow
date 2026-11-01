# CROSS_REVIEW — REVISE_THEN_LOCK (generalize / no case branding)

> **ACC003 lean workflow (certified 2026-10-30):** Where this text describes CLI commands, receipts, status JSONs or review tiers that the certified code does not run, those are not enforced in the certified ACC003 lean code (2026-10-30). See docs/r-procedure-gate-enforcement.md for the certified interface. The mandatory similarity review is not enforced in the certified ACC003 lean code (2026-10-30).

> **Gate merge 2026-10-31 (branch merge-gates-2026-10-31):** The code in this tree is the fixed gate code from 48b4af8, not the ACC003 lean code of 9bc13eb. The ACC003 lean note above records what was certified for ACC003 on the lean code; it does not describe the current gates. Where it says a command, receipt, review tier, role, nonce or END_REPLY line is not enforced or was cut, the current gates enforce the rules in this text plus the CHANGES 2026-10-31 sections of [r-procedure-gate-enforcement.md](r-procedure-gate-enforcement.md) and [r-workflow-gate-enforcement.md](r-workflow-gate-enforcement.md): F1 Start/Framing roles, F5b reviewed subjects, R1 review coverage, and the Round 2 cuts. No restored text was removed.


**Date:** 2026-09-19 (US Central)  
**Repo:** `markjamesc/ai-augmented-analyst-workflow`  
**Disposition:** Owner approved **revise → lock → push**, plus hard constraint: general workflow must stay portable for **any** future project — **zero case branding**.

## Three-AI verify outcome

| Model | Role | Verdict |
|---|---|---|
| ChatGPT | Builder / consolidator | REVISE_THEN_LOCK |
| Grok | Independent critic | REVISE_THEN_LOCK |
| DeepSeek | Claim-to-text auditor | REVISE_THEN_LOCK |

Edits applied from the critic/auditor minimum set: fail-closed `capacity_stance` / `ml_mode` (required enums; blank = Fail), deferred-N still freezes ranking key/tie-break/no-pad, inverse census-ranking check, Mode use-test + Expand ban as Mode A input, shared judged helpers as a class, dumb comparator, repair-cites-Stage-3+fixtures, Mode B ≠ dual judged-path, failability ladder with no verbal waiver / owner change-control + new freeze + rerun, Workflow Gate consumes lower receipts, evidence schema with contents/hashes for new/forward publishable packs only.

## Generalize-no-case-branding constraint (applied)

In frameworks FORWARD sections, Master Prompt, VERIFY packet, PACKET, r-workflow-gate FORWARD text, templates, and ablation-program-catalog / batch summary docs:

- **Do not** name cities, municipal service programs, project-repo brands, or project-specific construct IDs used on a past project.
- **Do** use portable language: prior locked project packs; historical Mode None/rules posture on a past project; prospective new projects; project evidence repos hold case trees.
- Case-specific ablation trees stay in the project evidence repo; this repo keeps control IDs + terminals only.

Local three-AI verify reply dumps under `docs/forward-verify/` (if present on a worktree) are **not** pushed to `main` — they may retain case names as a private audit trail and must not brand the portable method docs. Listed in `.gitignore`.

## Illustrative fragments (generalized)

Older framework illustrative fragments that once named demo projects were rewritten as generic marketplace-ops / prior-locked-pack language (or removed). Method docs must not brand the portable workflow with real project proper nouns.

## Pre-push check

Run a case-brand audit over `docs/` and `templates/` (local `docs/forward-verify/` dumps stay gitignored and should be absent from a clean worktree). Expected: **no matches** for city names, municipal-program brands, or past-project construct IDs.

## Lock confirmation

Five FORWARD upgrades + Master Prompt standing process rules are locked on `main` for prospective projects. Prior locked packs are not retrofitted.


## Prospective acceptance remediation

New runs must follow [SEND_QUEUE_PROTOCOL.md](SEND_QUEUE_PROTOCOL.md). This adds recorded authorization/send ordering, scoped approval applications, exact test-version binding, capture checks and limited certificate assurance. It does not change original candidate results or certify the historical acceptance run.
