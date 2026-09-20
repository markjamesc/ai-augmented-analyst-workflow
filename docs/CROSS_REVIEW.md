# CROSS_REVIEW — REVISE_THEN_LOCK (generalize / no case branding)

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

## Residual older examples (not expanded)

Pre-existing illustrative sections that mention other demo brands (e.g. FulfillIQ / Olist) in older framework prose were **left unchanged** for this lock. They are residual older examples, not part of the FORWARD upgrade set. Do not expand them in this commit.

## Pre-push check

Run a case-brand audit over `docs/` and `templates/` (excluding any local `docs/forward-verify/` dumps). Expected: **no matches** for city names, municipal-program brands, or past-project construct IDs in general method docs.

## Lock confirmation

Five FORWARD upgrades + Master Prompt standing process rules are locked on `main` for prospective projects. Prior locked packs are not retrofitted.
