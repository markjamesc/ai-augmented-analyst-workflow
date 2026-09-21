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
- Whole-run procedure referee: `docs/r-procedure-gate-enforcement.md` + `procedure-gate/procedure_gate.R`
- Stage 4→5 release: `docs/r-workflow-gate-enforcement.md` + `workflow-gate/workflow_gate.R`
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

## R Procedure Referee (always on for prospective runs)

The five-stage method and the controlling framework documents remain authoritative. The R Procedure Gate verifies the observable procedural record; it does not replace or redesign any stage.

### GrokBot execution instructions

You are GrokBot, the orchestrator. Read this entire template, including the standing rules and hard stops, before starting. Coordinate the three AI roles according to the linked stage frameworks and the project's supplied role assignments.

This is a Markdown instruction document with R checkpoints. Execute the R blocks through your local execution tools, one checkpoint at a time. Do not paste the entire document into the R console or render all blocks as an unattended `.Rmd` pipeline. Perform the framework work and obtain required human approvals between checkpoints. Never simulate console output or infer that an unexecuted command passed.

Make a project-specific copy of this template in the project repository. Fill the configuration from supplied project information before initializing the run. Preserve the canonical workflow checkout for the duration of the run; its controlling files are hashed at initialization. Do not invent a decision, constraint, model assignment, or approval to fill a gap.

### Configure the project and R command helper

Supply the initial project request and available evidence separately from these technical settings. Use absolute paths; on Windows, forward slashes work in R strings. R must have `jsonlite`, `digest`, `purrr`, and `magrittr` installed. If R, a dependency, a path, or required project information is unavailable, stop and report the specific problem.

```r
project_name <- "{{PROJECT_NAME}}"
run_id <- "{{RUN_ID}}"
workflow_repo <- "{{WORKFLOW_REPOSITORY_PATH}}"
project_root <- "{{PROJECT_ROOT_PATH}}"

settings <- c(project_name, run_id, workflow_repo, project_root)
stopifnot(all(nzchar(trimws(settings))), !any(grepl("{{", settings, fixed = TRUE)))

workflow_repo <- normalizePath(workflow_repo, mustWork = TRUE)
project_root <- normalizePath(project_root, mustWork = TRUE)
stopifnot(dir.exists(workflow_repo), dir.exists(project_root))

gate_script <- normalizePath(
  file.path(workflow_repo, "procedure-gate", "procedure_gate.R"),
  mustWork = TRUE
)

# This helper executes the existing gate CLI; the gate files own all checks.
run_procedure_gate <- function(action, step = NULL) {
  arguments <- c(gate_script, action, project_root, step)
  error_log <- tempfile("procedure-gate-stderr-")
  on.exit(unlink(error_log), add = TRUE)

  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    args = vapply(arguments, shQuote, character(1)),
    stdout = TRUE,
    stderr = error_log
  )
  exit_status <- attr(output, "status")
  if (is.null(exit_status)) exit_status <- 0L

  cat(output, sep = "\n")
  if (file.exists(error_log)) cat(readLines(error_log, warn = FALSE), sep = "\n")
  if (exit_status != 0L) stop("Procedure Gate failed; stop progression and inspect the output.")

  response <- jsonlite::fromJSON(paste(output, collapse = "\n"), simplifyVector = FALSE)
  expected <- switch(action,
    start = "STARTED", begin = "AUTHORIZED", complete = "PASS",
    finalize = "PASS", status = NULL,
    stop("Unknown gate action")
  )
  actual <- if (action == "finalize") response$result else response$status
  if (!is.null(expected) && !identical(actual, expected)) {
    stop("Unexpected gate result; stop progression.")
  }
  if (action == "finalize" && !isTRUE(response$certified)) {
    stop("Final certification was not granted.")
  }
  invisible(response)
}
```

Keep the configuration and helper available for subsequent R blocks. If your execution tool opens a fresh R session, rerun this setup with the same settings before the requested checkpoint. State persists in the project files; do not initialize a new run merely because the R session restarted.

### Initialize once, or inspect an existing run

For a new run, execute once and require `STARTED`:

```r
run_procedure_gate("start", run_id)
```

When resuming, execute the following instead of `start`. Confirm the recorded run ID matches the intended run, then continue from the recorded current stage or next incomplete stage. A status response is informational; it does not authorize work by itself.

```r
run_status <- run_procedure_gate("status")
stopifnot(identical(run_status$run_id, run_id))
```

### Stage 1 — Start

Execute and require `AUTHORIZED` before beginning Start:

```r
run_procedure_gate("begin", "start")
```

Read `docs/three-ai-start-and-framing-dialogue-framework.md` in `workflow_repo` and follow its Start procedure. Save the actual stage evidence and `artifacts/stage1_decision.json` in `project_root`, using the current template in `templates/workflow-gate/` as the schema guide. Template PASS values are examples, not evidence.

Execute after the work and required confirmation are complete; require `PASS`:

```r
run_procedure_gate("complete", "start")
```

### Stage 2 — Framing

Execute and require `AUTHORIZED`:

```r
run_procedure_gate("begin", "framing")
```

Follow the Framing procedure in `docs/three-ai-start-and-framing-dialogue-framework.md`, including its reviews, approvals, and capacity stance lock. Save the evidence and `artifacts/stage2_framing.json` using the current schema template.

Execute and require `PASS`:

```r
run_procedure_gate("complete", "framing")
```

### Stage 3 — Measurement Design

Execute and require `AUTHORIZED`:

```r
run_procedure_gate("begin", "design")
```

Follow `docs/three-ai-measurement-design-framework.md` in full, including the independent first passes, controlled cross-review, Design Gates, and human-approved lock. Save the evidence and `artifacts/stage3_locked_design.json` using the current schema template.

Execute and require `PASS`:

```r
run_procedure_gate("complete", "design")
```

### Stage 4 — Execution, Validation, and Deeper Analysis

Execute and require `AUTHORIZED`:

```r
run_procedure_gate("begin", "execution")
```

Follow `docs/three-ai-validation-and-analysis-framework.md` in full. Use `docs/ENGINE.md` only where permitted by the existing framework. Preserve the lower-tier evidence files, their hashes, and `artifacts/stage4_validation_status.json` using the current schema template.

Execute and require `PASS`:

```r
run_procedure_gate("complete", "execution")
```

This completion command invokes the existing R Workflow Gate. Do not mark Execution complete first or substitute a separate verbal release. On Workflow Gate failure, Execution remains incomplete and Stage 5 remains blocked.

### Stage 5 — Finish: Interpretation and Recommendation

Execute and require `AUTHORIZED`:

```r
run_procedure_gate("begin", "finish")
```

Follow `docs/three-ai-interpretation-and-recommendation-framework.md` in full, including independent first passes, cross-review, Finish Gates, and explicit human analyst approval. Save the deliverables and `artifacts/stage5_interpretation_status.json`, using `templates/procedure-gate/stage5_interpretation_status.example.json` as the schema guide. Record the actual Workflow Gate report hash.

Execute and require `PASS`:

```r
run_procedure_gate("complete", "finish")
```

### Final certification and failure handling

After Finish passes, execute:

```r
run_procedure_gate("finalize")

certificate <- jsonlite::read_json(
  file.path(project_root, "artifacts", "final_certificate.json")
)
stopifnot(
  identical(certificate$run_id, run_id),
  identical(certificate$result, "PASS"),
  isTRUE(certificate$certified)
)
```

Report certification only after successful execution and confirmation of the generated certificate. The certificate covers the gate's observable checks and recorded attestations; it does not prove private AI context or authenticate a self-reported human approval.

On `BLOCKED`, `FAIL`, malformed output, or execution error, stop progression and report the actual failed checks. Repair an incomplete stage under its existing framework and retry its completion check. Do not rerun `begin` for a stage already recorded as active or reopen a completed stage by editing state. Material changes to completed locks require the framework's owner-approved change control; if the existing gate cannot represent the required reopening, pause and report that limitation. Never overwrite prior evidence, change the gate, or manufacture a receipt to force a pass.

## Orchestrator hard stops (paste block)

```text
FORWARD HARD STOPS (portable method):
1) Framing Gate requires capacity_stance = unordered_ok | hard_attention_budget (always; missing = Fail).
2) Design Gate requires explicit ml_mode = None | A | B (fail-closed; no blank/inference).
3) Dual R-A/R-B only for judged contracts; shared judged helpers forbidden; dumb comparator only.
4) Fixture / Source / Recon / Cross-review / Validation / Workflow gates can fail the work — no verbal waiver; owner change-control = new freeze + rerun.
5) Stage 5 blocked unless workflow_gate_status.json PASS with stage5_allowed and lineage + scorecard receipts present (Workflow Gate consumes lower receipts).
6) The complete run is not protocol-compliant unless the R Procedure Gate certifies all five stages and writes final_certificate.json with result = PASS and certified = true.
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
