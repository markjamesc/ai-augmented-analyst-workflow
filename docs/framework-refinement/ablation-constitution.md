# Ablation Constitution

**Version:** 1.0

This constitution controls automated three-model framework ablations. It must be frozen before an ablation begins and may not be changed in response to that ablation's results.

## 1. Separation of duties

For each ablation:

- exactly one model is Builder;
- exactly one different model is Validator;
- exactly one third model is Adjudicator;
- no model may hold more than one role;
- Builder and Validator first-pass outputs are blind to one another;
- the Adjudicator receives only frozen evidence after Builder and Validator packs are complete.

## 2. Frozen inputs

The following must be frozen before execution:

- baseline framework version;
- ablation specification;
- fixture suite;
- critical reconciliation field list;
- allowed source/data scope;
- expected unchanged surfaces;
- operational benefit predicate;
- regression rule;
- model-role assignment;
- constitution version.

Missing frozen inputs require **HALT**.

## 3. Evidence requirement

A claim that a test passed is not evidence by itself.

Required mechanical claims must be backed by raw execution evidence where applicable:

- stdout/stderr;
- SQL/R/tool output;
- fixture actuals and expecteds;
- reconciliation output;
- diff output;
- file manifests;
- SHA-256 hashes.

If a required raw artifact is unavailable, return **HALT**.

## 4. Hard mechanical agreement

Builder and Validator must agree on all predeclared hard mechanical facts.

Examples include:

- `mismatch_count == 0` on the frozen critical-field list;
- fixture IDs executed;
- expected versus actual fixture results;
- baseline and candidate version hashes;
- declared changed-file set;
- source row counts where specified;
- required output existence.

If Builder and Validator disagree on a hard mechanical fact, return **HALT**.

Do not silently REVERT. Mechanical disagreement means the harness or implementation requires diagnosis.

## 5. Semantic protection

Schema equality alone does not prove semantic equality.

The ablation must therefore use both:

- deterministic file/schema/configuration diffing; and
- locked behavioral fixtures covering the decision-changing semantics relevant to the change.

Any undeclared semantic change returns **REVERT** unless the disagreement itself makes the harness suspect, in which case return **HALT**.

## 6. Benefit predicate

Every ablation must state an operational benefit predicate before execution.

The predicate must be checkable from frozen artifacts without asking the Builder what it meant.

Valid forms include:

- detection of a seeded failure missed by baseline;
- removal of redundant complexity with unchanged detection coverage and outputs;
- elimination of a documented ambiguity demonstrated by independent implementation;
- detection of a seeded Stage 4 delivery/implementation defect;
- measurable reduction in unnecessary steps while all required safeguards remain green.

A subjective statement such as "the change is better" is invalid and requires **HALT** before execution.

## 7. KEEP rule

Return **KEEP** only when all are true:

1. evidence packs are complete and frozen;
2. role separation is valid;
3. Builder and Validator agree on hard mechanical facts;
4. exact reconciliation passes where required;
5. every mandatory fixture passes;
6. no undeclared semantic change is detected;
7. no locked regression is introduced;
8. the predeclared benefit predicate is satisfied;
9. no blocking objection remains supported by the frozen evidence.

All nine conditions are conjunctive.

## 8. REVERT rule

Return **REVERT** when:

- the mechanics are internally coherent;
- HALT conditions are absent;
- but one or more KEEP conditions are not established.

REVERT is the conservative default for unresolved soft judgment.

## 9. HALT rule

Return **HALT** when:

- hard mechanical results conflict;
- required raw evidence is missing;
- hashes or frozen versions mismatch;
- the baseline or constitution changed mid-run;
- role separation was violated;
- information barriers were breached before first-pass freeze;
- the benefit predicate was not operationally defined before execution;
- the adjudicator cannot determine which frozen evidence pack is authoritative.

HALT means the experiment is not valid enough to adjudicate.

## 10. Adjudicator limits

The Adjudicator may not:

- create a new success criterion;
- relax a failed hard gate;
- choose one mechanical result over another when Builder and Validator conflict;
- modify Builder or Validator artifacts;
- repair code;
- rerun the ablation and substitute its own result;
- use majority vote to override the constitution.

It must cite the frozen evidence supporting each constitutional condition.

## 11. Constitution changes

This constitution may not self-modify during an ablation.

A proposed change to the constitution must be treated as a separate meta-ablation with:

- a frozen prior constitution;
- a declared proposed revision;
- independent Builder/Validator analysis;
- third-model adjudication;
- deterministic evidence freezing.

## 12. Final rule

> **Hard disagreement halts. Coherent evidence without proven benefit reverts. Only independently reproduced, regression-free, predeclared benefit is kept.**