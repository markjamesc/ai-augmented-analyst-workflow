# Methodology hardening — prospective v3

> **ACC003 lean workflow (certified 2026-10-30):** Where this text describes CLI commands, receipts, status JSONs or review tiers that the certified code does not run, those are not enforced in the certified ACC003 lean code (2026-10-30). See docs/r-procedure-gate-enforcement.md for the certified interface. 

> **Gate merge 2026-10-31 (branch merge-gates-2026-10-31):** The code in this tree is the fixed gate code from 48b4af8, not the ACC003 lean code of 9bc13eb. The ACC003 lean note above records what was certified for ACC003 on the lean code; it does not describe the current gates. Where it says a command, receipt, review tier, role, nonce or END_REPLY line is not enforced or was cut, the current gates enforce the rules in this text plus the CHANGES 2026-10-31 sections of [r-procedure-gate-enforcement.md](r-procedure-gate-enforcement.md) and [r-workflow-gate-enforcement.md](r-workflow-gate-enforcement.md): F1 Start/Framing roles, F5b reviewed subjects, R1 review coverage, and the Round 2 cuts. No restored text was removed.


Implementation release candidate, authorized by the owner on 2026-10-10 (“start step 2”).
Base: `e4af085e144884fa8563bb48d9c199aeb5f52f3d` on the ablation KEEP branch.
Ablation evidence closeout: Chicago 311 commit `8db71b7498aa07adcad4ebb6e1f5181f9fa8e91e`.
The final recorded tally is 14 KEEP, 35 REVERT, one inconclusive HALT (C40R).
C40R has a missing round-3 timing record and BOTH_CENSORED outcome; neither strategy demonstrated superiority. Unlimited repair remains the existing default, not an evidence-proven optimum.

This prospective release adds the owner-authorized research hardening route alongside ablation-based refinement. It does not invent KEEP verdicts for research recommendations, rewrite frozen projects, or resolve scientific disagreement by AI vote. The original ablation verdict records are historical. The implementation decisions below are proposals embodied in this review branch, not retroactive owner rulings. The owner reviews the concrete branch before adoption.

## Authority and burden

The five stages remain Start → Framing → Design → Execution → Finish. The Procedure Gate controls order; the Workflow Gate controls release into Finish. GrokBot drives, R authorizes. SQL remains controlled mechanical delivery through the client; R reads frozen extracts. Existing project SQL Query Gates control pre-execution query safety/contract; the SQL Source Gate verifies delivered data against the source. These are different checks; this repository does not manufacture a universal executable Query Gate.

The existing stage contracts remain the authority. `stage3_locked_design.json.methodology` consolidates target and risk fields and references existing clauses; it is not permission to define a second population, grain or decision rule. It must use the same observed population and decision grain. Human-readable ledgers are views of these records. This document resolves prospective-v3 differences from older text; the stage documents point here at their entry points.

Requirement levels are independent of research strength. M = mandatory; C = mandatory when the declared trigger applies; O = optional. B = broad methodological support; S = substantial but conditional evidence; J = specific engineering judgment. None is an empirical accuracy claim about the whole workflow.

| Requirement | Level / support | Failure mode | Enforcement and evidence |
|---|---|---|---|
| Analytical target, estimator and decision rule distinguished | M / B | Correct computation of the wrong quantity | Design target fields, Framing links, population/grain consistency, result and claim target IDs |
| Material premise register, exposure history | M / B; exact taxonomy J | Assumptions promoted to facts; hindsight hidden by a new lock | Separate kind/support/testability, basis, consequence and response; named prior exposure |
| Sensitivity screen | M / B | Undisclosed choice dependence | Required/rationale/instability policy at lock |
| Admissible material sensitivity branches | C / S | Favorable specification selected after results | IDs, justifications, same-target vs supplementary targets; all branch outcomes including failures |
| Classified changes, invalidation and attempts | M / B/J | Stale PASS; lost failures; post-result amendment disguised as correction | Exposure, affected artifacts, rerun steps; design hash bound into receipts; immutable attempt files |
| Semantic checkpoints | M within retained dual path / S/J | Equal totals conceal membership or component differences | Keyed CSV comparisons recomputed by R, exact identities/decisions, locked numeric tolerances |
| Metamorphic applicability screen | M / J | Both paths share an untested defect | Preconditions and rationale for each proposed relation |
| Valid high-value metamorphic relations | C / S | Input-order/irrelevant-field dependencies | Both builders run applicable relations; retain report references |
| Replay and environment provenance | M / B | Results cannot be regenerated; dependencies changed | Clean R process, canonical deterministic outputs, package lock + session inventory + retention |
| AI construction provenance | M / S/J | Claimed independence without observable record | Inputs/outputs, model/provider, contexts, timing and contamination disclosures |
| Claim warrants and audit coverage | M / B; schema J | Correct number used for unsupported conclusion | Extend existing ledger; result/premise links, contrary evidence, uncertainty, separate audits |
| Conditional decision-outcome contract | C / B/J | Compliance confused with decision effectiveness | Precommit action/alternative/window/metric/comparison; linked follow-up in Finish |
| Containers, alternate languages, exhaustive multiverse, formal proofs | O / context-dependent | Unnecessary complexity | Use only for a defined remaining risk |

## Start and Framing

Start assigns `decision_id`, records the decision owner, feasible options including hold, objectives, constraints, losses and preferences. Begin capturing available source and AI provenance; secrets are never copied to a public manifest. Framing assigns `question_id` and `question_type` (descriptive, associational, predictive, causal, decision), keeps one question and the existing capacity stance. The objective is not silently changed from revenue to profit: profit needs costs and a definition of profit.

A business decision can motivate descriptive analysis. Do not force a causal estimand into a label census. Conversely, forecasting a response at an unobserved price does not identify the effect of changing price. Framing states the distinction before the design.

## Design and Stage-3 lock

Use `templates/methodology/design.example.json` as a **shape example**, not a ready-made scientific design. Replace its illustrative population, dates, applicability assessments, thresholds and text. `methodology/schema.json` checks structure; `contracts.R` implements semantic and dependency checks. Schema validation alone is insufficient.

1. **Analytical target.** Record target/observed populations, analysis/decision units, construct/outcome, time origin/horizon, contrast, aggregation/weights, quantity, estimator, decision-rule reference, validation/identification argument, and permitted claim types. Causal targets additionally name treatment, comparator and identification argument. Explain intercurrent events, censoring and exclusions in the target/conditional method plan as applicable. Finite-population descriptive results do not automatically need a confidence interval.
2. **Premises.** Each material entry has kind (definition/source assertion/assumption/method choice/preference/limitation), support status, testability, basis, affected interpretation and response. “Verified” means checked against a named snapshot/check, not established real-world truth. Diagnostic non-rejection does not verify an identifying assumption.
3. **Exposure.** Record data seen, results seen and test-set access before locking. A post-result lock is not preregistration. For prediction, persist split IDs; fit preprocessing/tuning only on permitted training data. Repeated test feedback requires a new holdout, nested evaluation, or explicit limitation.
4. **Conditional modules.** Screen measurement (always), causal identification, prediction, missingness/selection, dependence, multiplicity, transportability and decision uncertainty (always). Required modules name actual plans, assumptions and validation criteria. There is no automatic “always impute”, “always fit a second model”, universal p-value requirement, or assumption that raw rows are independent samples. Causal plans address consistency, confounding, overlap, interference, selection and time zero; appropriate negative controls are optional falsification checks, not proof of no bias.
5. **Specification uncertainty.** Enumerate a bounded set of justified nonredundant alternatives before results. Label different-target branches supplementary. Predeclare how material instability changes claims/actions. Report failed branches. A majority of significant specifications is not a probability of truth. If no material uncertainty remains, state why; do not run an empty ritual multiverse.
6. **Checkpoint contract.** Lock checkpoint IDs, stable keys, exact and numeric fields, tolerances and rationale. Cover the candidate population, included/excluded memberships and reasons, counts, relevant numerators/denominators, and final critical results. These can share one canonical table where appropriate. Keep intermediate algorithms independent; compare semantic tables, not identical data structures. Key membership and labels remain exact. Numeric comparison uses `abs(a-b) <= abs_tol + rel_tol * max(abs(a),abs(b))`. Meaningful missing statuses are exact fields; NaN/infinite numeric checkpoint values fail. Near-boundary action rules remain locked, never softened to greenwash reconciliation. This elaborates C39; it does not adopt C46's rejected proposal.
7. **Metamorphic relations.** Assess row permutation, irrelevant-field addition and relevant boundary/partition/unit-conversion tests. Preconditions matter: row order can be semantic, ratios are not additive, duplicate rows can legitimately alter uncertainty, and excluded rows may legitimately affect a reference population. A failed relation may expose a specification error as well as a code error. Supplemental counterexamples get new versions without rewriting failed historical fixtures.
8. **Fixture/dependency/output coverage.** C53 requires every output's outcome/null/empty semantics. Record judged rule IDs and fixture coverage. C16 removes a separate packet-completeness review, not the requirement to supply complete authoritative contracts. Lock receipt dependency paths per role: source, code, configuration and outputs actually used. Include runtime helpers/adapters and comparator/test scripts where applicable. Avoid a single generic PASS report claiming everything.
9. **Dominance.** Choose thresholds and consequences for this target before execution. The ablation's 1000/30/one-third settings are example tested settings, not universal statistical defaults. Include denominator and influence checks for ratios/mean errors even where category share is not meaningful. Flags are retained/disclosed, never used to delete inconvenient rows.
10. **Decision-outcome contract, when applicable.** For a testable action recommendation, precommit action, alternative (often hold), outcome metric, window, worthwhile gain, guardrails, comparison design, owner and follow-up ID. Prefer reversible or randomized holdout deployment where feasible and justified. Observational policy evaluation needs defensible identification/overlap; historical hold outcomes alone do not reveal unobserved treatment outcomes. Outcomes may stay unknown. Do not label unknown regret zero. No mandatory outcome trial for purely descriptive work.

Stage 3 preserves C01's relaxed peer blindness and C02's coordinator-draft ban. The receipt uses `design_exposure_disclosed` instead of a misleading blanket blindness PASS. Record actual peer exposure and rejected/adapted peer rules. The C01 attribution caveat remains. This relaxation does not apply to R-A/R-B construction barriers or abolish the three Stage-5 roles.

## Execution and release gates

Keep SQL Source Gate, frozen fixtures on both independent paths, exact critical reconciliation and all existing failure behavior. C41 requires production-reader fixture roundtrip plus a poison-judge probe; C51 smoke runs precede the full run and never supply analytical results. The smoke **execution report** can document completion; smoke **outputs** must not enter reporting receipts. C45 allows concurrent independent runs subject to the existing resource check. Execution timing does not establish independent error distributions.

`methodology/tools.R` provides test/replay helpers; each path supplies its own judged adapter. The same dumb keyed comparator may be shared. `m_compare` reads IDs as strings, rejects duplicate keys and detects equal-count/different-membership cases. Persist exclusions and empty groups explicitly; a valid empty table with its declared schema can pass. Identical code or the twin path's answers must not become a repair oracle.

**C30 proposed implementation:** accept `PASS` only for an executed structural review. Accept `NOT_REQUIRED` only with a locked conditional policy, complete rule-to-fixture coverage and an explicit skip reason. The structural receipt records `NOT_REQUIRED` honestly with dependencies and scope. Uncovered rules require fixtures or review. A performed review's unresolved findings still block; optional never means “ignore a known defect”. This preserves the ablation's seed-coverage caveat without reinstating a universal review round.

All lower receipts carry the current full Stage-3 receipt SHA-256 and exactly the dependency paths declared for their role, each with a current SHA-256. The Workflow Gate checks bytes and recomputes semantic checkpoint comparisons. It additionally consumes one `methodology` receipt with fixture-depth, smoke, dominance, module, sensitivity, metamorphic, replay and result-inventory evidence. Both direct Workflow Gate use and Procedure Gate execution completion enforce v3. Stale source/code/config/output dependencies cannot be released solely because an unchanged wrapper says PASS.

Record source snapshot/extraction boundary and retention/access instructions; workflow/project commits and dirty status; R/package versions and a restorable lock; OS/locale/timezone/encoding; relevant SQL client/mode and thread/solver settings; RNG/seeds/splits, commands, exit status and timestamps. `m_environment` captures inventory; it does not falsely label an inventory a restorable package lock. Supply `renv.lock`, a conda explicit environment specification or an equivalent retrievable package specification.

Run `m_replay` with a reviewed script in a fresh `Rscript --vanilla` process into an empty separate output root. It takes frozen-root and output-root arguments and compares declared outputs. Canonicalize deterministic serialization. Persist original/replayed artifact references and report. Stochastic models use the locked fit/split/randomness contract for deterministic result replay; robustness across seeds is a separate sensitivity question. If exact canonical output replay is inappropriate, amend the comparison contract and implementation before release; do not assert PASS from an unrun tolerant replay.

AI provenance records provider, exact reported model, session/context ID, observable prompt/tool-input and response artifacts, exposed settings/seeds, first-pass freeze time, peer-access and contamination disclosure. “Unavailable: provider does not expose it” is valid metadata; invented model revisions are not. Do not request hidden chain-of-thought. Different providers are not a statistical independence guarantee. Archive visible construction evidence; analysis replay does not require regenerating hosted AI text.

## Finish and certification

Extend the existing Claim-to-Evidence Ledger, not a parallel review process. Every substantive claim has an ID, target ID, exact wording, authoritative result IDs and premise IDs, warrant, contrary evidence/defeater, uncertainty, scope, sensitivity disposition, reviewer/evidence references, and separate numerical and inference verdicts. Link the final deliverable's bytes. AI reviewers attest complete claim coverage; a gate cannot discover every unregistered sentence or establish scientific truth from a PASS string.

**C37 proposed implementation:** the coordinator assigns a recommendation tag from the reviewed claim evidence and records who assigned it. The existing evidence-tag table is a ceiling/routing aid, not sufficient authorization to act: owner constraints, costs, reversibility, uncertainty and causal identification still matter. Lock project action vocabulary/interpretation in Design. C05 substantive claim-ceiling review remains; this does not restore a separate proportionality audit round.

**C48/C50 proposed implementation:** one consolidated revision followed by the mechanical revision checklist. `FLAG` or unresolved flags block Finish; correct and recheck affected text and dependencies. Material new claims or design changes enter the existing change route; the checklist cannot certify a new inference merely because quoted numbers match. C44 re-review uses changed artifacts, diff, unchanged hashes **and affected dependencies**. No automatic second final audit. C38's removal of the first-pass next-question tag does not abolish the existing conditional monitoring contract or the new conditional outcome handoff.

Certification separates: procedure complied; computation verified; inference adequate/scope-restricted/insufficient; decision act/pilot/hold/insufficient evidence/no action required; outcome evaluation not applicable/pending/evaluated. Honest insufficient evidence can pass a correctly executed workflow. Broken computation cannot pass by recommending hold. An outcome marked evaluated still needs a linked follow-up report; it does not automatically establish optimality.

When decision-outcome evaluation was required at lock, Finish must record `pending` or `evaluated`. The handoff's owner and run ID must match the lock. Its referenced JSON file must contain exactly the locked `outcome_contract` object (object key order is immaterial). Rehashing a changed alternative does not authorize it; use the amendment route. Optional sensitivity branches must still have valid IDs, targets, relations and justifications.

## Changes, late defects and preserved attempts

Classify changes as implementation correction, design amendment, exploratory analysis or presentation. Record data/results already seen, reason, target effect, affected artifacts and rerun steps. A correction cites the unchanged locked clause; a changed threshold/target is an amendment. Exploration remains labeled and separate. Presentation-only changes cannot silently alter claims. The existing owner approval route for completed locks remains.

In-progress downstream work can follow a permitted `amend`; new receipt hashes invalidate previous Stage-4 receipts. Once a dependent stage is complete, use a **successor**, never state-file editing:

```sh
Rscript procedure-gate/procedure_gate.R successor NEW_ROOT OLD_ROOT NEW_RUN_ID change-control/change.json
```

The new root must exist, have no run, and contain the approved classified change record. The command archives a predecessor state snapshot (and certificate if present), links its identity, and starts all five stages afresh. No old PASS is inherited. The predecessor's evidence remains untouched. Publish a linked correction notice in the project when a released claim is affected; do not silently rewrite the old certificate. Owner approval remains a recorded attestation, not cryptographic authentication.

Checks and Workflow Gate reports have unique attempt files; the familiar report path is the current pointer. Procedure Gate hashes its own code, the method validators/schema/tools, the workflow code, configuration and controlling documents. Recheck supporting dependencies at release, Finish and certification. File hashes protect consistency against the recorded bytes; a writer able to replace both hashes and records is outside this trust boundary. Protected execution/signing is optional for a stronger adversarial threat model.

## Migration and validation boundary

- Prospective v3 deliberately rejects old receipts missing the new contract. No legacy opt-out flag silently downgrades a new run. Replay historical runs with their pinned historical referee/environment.
- Adopt this branch only for a new run or explicit successor. Do not bulk-edit frozen project packs to satisfy v3.
- Update all project-specific adapters and receipt writers to emit these records, preserving independent construction. The reusable repository cannot supply project-specific scientific judgments, replay scripts, database authentication or real three-AI messages.
- Step 2 delivers code/docs/templates and targeted tests. Step 3 must run the actual GrokBot + three AI system end to end in the deployment environment. Synthetic role receipts test plumbing only. Step 4 tests accuracy and decision effectiveness on held-out tasks/outcomes. Neither has been completed by this implementation.

## Research basis

The earlier review was a targeted critical review, not a registered systematic review or quantitative expert-consensus survey. These sources support principles, not every schema detail or the exact three-AI architecture:

1. National Academies (2019), *Reproducibility and Replicability in Science*, https://doi.org/10.17226/25303 — computational reproducibility versus empirical replication.
2. ICH (2019), E9(R1), https://database.ich.org/sites/default/files/E9-R1_Step4_Guideline_2019_1203.pdf — target/estimand and same-target sensitivity; adapted beyond clinical trials.
3. Hernán & Robins (2020), *Causal Inference: What If*, https://miguelhernan.org/whatifbook — identification and missing counterfactuals.
4. Flake & Fried (2020), https://doi.org/10.1177/2515245920952393 — measurement validity/transparency.
5. Simonsohn et al. (2020), https://doi.org/10.1038/s41562-020-0912-z; Steegen et al. (2016), https://doi.org/10.1177/1745691616658637; Del Giudice & Gangestad (2021), https://doi.org/10.1177/2515245920954925 — justified specification analysis and nonequivalent-target pitfalls.
6. Knight & Leveson (1986), https://doi.org/10.1109/TSE.1986.6312924 — independent implementations can fail together.
7. Liu et al. (2014), https://doi.org/10.1109/TSE.2013.46; Barr et al. (2015), https://doi.org/10.1109/TSE.2014.2372785 — metamorphic testing and limits of test oracles.
8. Sandve et al. (2013), https://doi.org/10.1371/journal.pcbi.1003285; W3C PROV-DM, https://www.w3.org/TR/prov-dm/ — executable provenance and reproducibility.
9. Lakens (2024), https://doi.org/10.1525/collabra.117094; Baldwin et al. (2022), https://doi.org/10.1007/s10654-021-00839-0 — justified deviations and prior exposure.
10. GRADE EtD (2016), https://doi.org/10.1136/bmj.i2016; ASA (2016), https://doi.org/10.1080/00031305.2016.1154108 — evidence-to-decision, values and inferential limits; domain adaptation required.
11. TRIPOD+AI (2024), https://doi.org/10.1136/bmj-2023-078378; Hughes et al. (2019), https://doi.org/10.1093/ije/dyz032 — prediction reporting and context-dependent missingness methods.
12. Morris et al. (2019), https://doi.org/10.1002/sim.8086 — prespecified simulation aims, generators, targets, methods and performance measures; synthetic truth is generator-specific.
13. NIST AI 600-1 (2024), https://doi.org/10.6028/NIST.AI.600-1 — provenance and context-specific evaluation; no guarantee from model agreement.


## Prospective acceptance remediation

New runs must follow [SEND_QUEUE_PROTOCOL.md](SEND_QUEUE_PROTOCOL.md). This adds recorded authorization/send ordering, scoped approval applications, exact test-version binding, capture checks and limited certificate assurance. It does not change original candidate results or certify the historical acceptance run.

Prospective live-finding repairs: follow [LIVE_FAILURE_REPAIRS.md](framework-refinement/LIVE_FAILURE_REPAIRS.md) for immutable candidates, nullable checkpoint schemas, source applicability, Windows references/restoration and capture/timing evidence. Prior run evidence remains unchanged.
