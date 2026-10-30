# Stage 3 — Measurement Design

One authoritative design.json, validated by methodology/schema.json and the R semantic validator. The human-readable summary is a view of this contract, never a competing authority.

1. ChatGPT drafts the target question, population/grain, definitions, metrics including denominator/aggregation, filters, missingness, threshold/tie/ranking/capacity rules, source and output contracts.
2. Grok, in a separate reviewer chat, performs ONE independent review for wrong definitions, infeasible source mappings, ambiguous rules, invalid inference and inadequate known-answer coverage. The fixture oracle is independently derived/reviewed once against the written rule, not against builder output.
3. ChatGPT makes one consolidated revision if needed. Verify resolution of affected substantive issues with the same reviewer; no full repeated audit or extra reviewer. Unresolved substantive disagreement goes to the owner.
4. Show the concise design and its hash to the owner. An unambiguous Approved/Yes in direct response to approval of that contract is sufficient. Save verbatim evidence and the approved hash. `lock` validates the record and freezes its referenced files in the manifest; the machine does not authenticate the human or prove conversational intent.

## Required substance, minimal paperwork

Lock one question, observed/target population where different, row grain and join cardinality, eligibility/exclusion precedence, time/clock rules if relevant, metric definitions, decision rule, source fidelity method and known-answer fixtures before results. Checkpoint schemas name keys, exact fields, numeric fields and explicit missing-state tokens/flags. NA is not zero. ACC003 uses exact binary64 quantities and exact decision fields; no post-hoc tolerances.

For confounding, uncertainty, multiplicity, segments, small denominators, sensitivity, research return, monitoring and leakage, record applies/does-not-apply and why. When applicable, add its actual rule/plan in this SAME contract and assess implications in Finish. No separate module branches or Stage-4 methodological gate. Prespecify material defensible alternatives where relevant; do not vote over arbitrary specifications. Record material assumptions/limitations together, not in duplicate warrant ledgers. Prior results exposure cannot be erased by relocking.

## One model rule

Record whether a model exists and whether its predictions determine the answer. Fit on the R-A/R-B-confirmed data. If predictions decide the answer, independently fit the second path from the same locked specification and compare predictions and decision outputs exactly. Lock target, allowed features, leakage rule, train/test split, algorithm/selection, solver/seed, evaluation and action mapping; resolve nondeterminism before lock. Both paths can agree and still share leakage, so Design/Finish must assess validity.

Insight-only modeling uses one build; label it exploratory/unvalidated and exclude it from the decision and headline. Promoting it into a decision needs an approved new contract. No Mode A/B labels or extra branch machinery.

No per-field AI authorship, duplicated output/nullability tables, separate spec-to-builder review tier or repeated three-AI final Design audits.
