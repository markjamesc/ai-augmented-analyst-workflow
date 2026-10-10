# Changes from ablations: the 14 KEEP verdicts

This file maps each adopted ablation (KEEP) to the files and lines it changed, with its verdict source, and lists every tested control by stage with its verdict. It follows the repository's portability rule: control IDs and verdicts only, no project case detail. Case-specific run trees stay in the project evidence repo.

**Convention.** KEEP = the change under test is adopted. REVERT = the existing rule stays. HALT = the test could not decide, so the rule stays. NOT_TRIGGERED = the test condition never arose, so there is no verdict.

**Direction matters.** For a cut or relax candidate, KEEP means the control is *relaxed or removed* (C01, C16, C30, C37, C38, C44, C45, C48, C50). For an addition or hardening candidate, KEEP means the new control is *added* (C41, C47, C49R, C51, C53). Each section below says which.

**Scope of this change.** Documents only. The executable gates (`workflow-gate/`, `procedure-gate/`), receipt templates (`templates/`), and R code are unchanged. See "Open items".

Line numbers refer to the branch tip when this file was written.

## Per-KEEP changes

| Control | Direction | Rule adopted | Files and lines | Commit | Verdict source (evidence repo; SHA-256 prefix of terminal state / frozen spec) |
|---|---|---|---|---|---|
| C01 | relax | Stage 3 first-pass blindness is no longer required; a designer may see a peer design or the dossier first, must critique rather than adopt, and must report rejected peer rules. Coordinator-draft ban and cross-review stay. | `docs/three-ai-measurement-design-framework.md` L1084 (section 22); `docs/MASTER_PROMPT.md` L67 (standing rule 3) | 80281bc | `runs/N16/C01/TERMINAL_STATE.txt` c7cde802…; `ABLATION_SPEC.md` 65f8c81d… |
| C16 | relax | No separate Spec-to-Builder packet-completeness review or blocking item. Completeness stays as content of the Stage 3 contracts; omissions are caught by the Fixture Gate and exact reconciliation. Bounded by seed coverage. | Stage 3 doc L833, L845-L847, L1367; Stage 4 doc L459 and L570 (checklist row 1) | ff86ee7 | `runs/N15/C16/TERMINAL_STATE.txt` c7cde802…; spec e5413ac8… |
| C30 | relax | Structural cross-review is no longer a mandatory tier after exact reconciliation; matching totals, exit 0 and passing fixtures on both paths are sufficient. Optional when run. | Stage 4 doc L7, L800 (section 9 note), L953 gate bullet, L1449 (step 19), L1513 (ladder row 4); `docs/MASTER_PROMPT.md` L50, hard stop 4; `docs/PACKET.md` L20 | 5141ffb | `runs/N15/C30/TERMINAL_STATE.txt` c7cde802…; spec 181ea3af… |
| C37 | relax | Recommendation proportionality is checked by an evidence-tag table (Descriptive → monitor/collect; Associational → pilot; Causal-supported → act) in place of the AI audit on that one point. | Stage 5 doc L540 (section 20), L758 (AI 2 audit list), L867 (Gate 9) | 58fc119 | `runs/N16/C37/TERMINAL_STATE.txt` c7cde802…; spec 58c19a5d… |
| C38 | relax | Follow-up (monitoring plan and next question, first-pass items 8-9) is no longer required; a mechanical finality check applies when limitations are non-empty. | Stage 5 doc L622-L626 (section 24), L877 (Gate 10) | 63f6951 | `runs/N16/C38/TERMINAL_STATE.txt` c7cde802…; spec a08c3ba8… |
| C41 | add | Fixture Gate adds a depth gate: fixtures read through the production read path, plus a stub probe with a poison judge. | Stage 4 doc L501 (Fixture Gate item 6), L572 (checklist row 3), L1441 (step 12) | 0639aec | `runs/N13/C41/TERMINAL_STATE.txt` e9de6d76…; spec 03786558… |
| C44 | relax | Re-review rounds receive only changed artifacts, a diff, hashes of unchanged inputs, and the affected-dependencies list. First review per stage stays full scope. | Stage 4 doc L939 (section 9 step 4), L1283 (section 14) | 87ec297 | `runs/N13/C44/TERMINAL_STATE.txt` e9de6d76…; spec a4811cdf… |
| C45 | relax | R-A and R-B runs may be concurrent after a declared memory check (free memory ≥ 2 × serial peak + 2,048 MB); independence unchanged. | Stage 4 doc L187 (section 3) | ca31fad | `runs/N15/REAJ/C45/TERMINAL_STATE.txt` e9de6d76… (supersedes N15 `C45` REVERT); spec 42368e01… |
| C47 | add | Small-denominator and single-unit dominance check at Stage 4 with predeclared thresholds; a flag routes to the owner and never drops rows. | Stage 4 doc L958 (new section 9A); Stage 3 doc L1026 | b3a05fd | `runs/N13/C47/TERMINAL_STATE.txt` e9de6d76…; spec d1582be6… |
| C48 | relax | No second final audit when a mechanical revision checklist (quote match + number diff) passes. | Stage 5 doc L789 (section 28), L1041 (step 14) | 3f6ee79 | `runs/N13/C48/TERMINAL_STATE.txt` c7cde802…; spec 5f0cd243… |
| C49R | add | Evidence delivered as individual files plus `SHA256SUMS.txt`; mandatory first-section file inventory with hashes. | Stage 5 doc L146 (section 3), L647 (AI 3 output) | 1a70b5a | `runs/N17/C49R/TERMINAL_STATE.txt` c7cde802… (supersedes N13 `C49` HALT, kept on record); `ABLATION_SPEC_C49R.md` 753d512e… |
| C50 | relax | One consolidated revision pass replaces the revise / re-audit loop; audit rounds fall from three (one projected) to one audit plus one checked revision. | Stage 5 doc L799 (section 28) and the flow diagram revision edge (L47-L48) | ec2ed7d | `runs/N16/C50/TERMINAL_STATE.txt` c7cde802…; spec 112977b0… |
| C51 | add | Reduced-scale smoke run (k = 16, then k = 4) before the full run; non-reporting; never reconciled or receipted. | Stage 4 doc L509 (section 6A), L1443 (step 13a) | 70d5a7e | `runs/N13/C51/TERMINAL_STATE.txt` e9de6d76…; spec dc918171… |
| C53 | add | Output-field × outcome table is a Design Gate requirement; table violations are builder defects, not owner rulings. | Stage 3 doc L1023, L1030 onward (section 20.4A.1), L1371 (Gate 10 checklist) | afdcde3 | `runs/N13/C53/TERMINAL_STATE.txt` e9de6d76…; spec ad4a9046… |

Status and index references (not a KEEP): `docs/MASTER_PROMPT.md` L72 (standing rule 8) and `README.md` (implementation status) now cite the 14 KEEP verdicts.

In the table, "Stage 3 doc" is `docs/three-ai-measurement-design-framework.md`, "Stage 4 doc" is `docs/three-ai-validation-and-analysis-framework.md`, and "Stage 5 doc" is `docs/three-ai-interpretation-and-recommendation-framework.md`.

## Not changed on purpose

- No REVERT, HALT, or NOT_TRIGGERED rule was edited. In particular the coordinator-draft ban (C02), Design Gate after cross-review (C03), the claim-ceiling judgment (C05), the three Stage 5 roles (C04), the numerical-determinism proposal (C46), narrow freeze scope (C43), and the full-scope Source Gate and recon rules stay as they were.
- No removed control was re-added under a new name. The finality check (C38) and the revision checklist (C48) are mechanical checks that replace a removed requirement. They are not new review rounds.
- The post-ablation hardening changes (estimand contract, premise register, specification-uncertainty plan, change classification, intermediate reconciliation, metamorphic tests, reproducibility and AI-provenance records, claim-to-evidence ledger) are a separate step and are not part of this change.

## Per-stage rule and verdict table (all tested controls)

### Stages 1-2, Framing
| Control | Rule | Verdict |
|---|---|---|
| C06 | Start Gate action-vocabulary lock | REVERT |
| C07 | Framing gate: exactly one question | REVERT |
| C09 | Ambiguity attack before lock | REVERT |
| C15 | Ranking / capacity Framing-only | REVERT |

### Stage 3, Design
| Control | Rule | Verdict |
|---|---|---|
| C01 | Stage 3 blindness relaxed | **KEEP** |
| C02 | Coordinator draft given to designer | REVERT |
| C03 | Design Gate after the cross-review | REVERT |

### Stage 3 to 4
| Control | Rule | Verdict |
|---|---|---|
| C11 | Method constants vs knobs | REVERT |
| C14 | Explicit semantics (open / eligible) | REVERT |
| C16 | Spec-to-Builder packet completeness review | **KEEP** |
| C46 | Design-time numerical determinism (proposed addition) | REVERT |
| C53 | Design-time output-field completeness (proposed addition) | **KEEP** |

### Stage 4, Execution
| Control | Rule | Verdict |
|---|---|---|
| C18 | No fixture rewrite on fail | REVERT |
| C24 | Mechanical vs judged population | HALT |
| C26 | Frozen source package | REVERT |
| C27 | Fixtures on both paths | REVERT |
| C29 | Recon investigation | REVERT |
| C30 | Structural cross-review | **KEEP** |
| C31 | Lineage attestation | REVERT |
| C33 | Naive clock contract | REVERT |
| C39 | Recon scope and tolerance | REVERT |
| C40 | Repair-round cap | NOT_TRIGGERED |
| C41 | Fixture depth over count | **KEEP** |
| C42 | Batched owner rulings | REVERT |
| C45 | Parallel R-A / R-B runs | **KEEP** |
| C47 | Small-denominator / dominance check | **KEEP** |
| C51 | Reduced-scale smoke run | **KEEP** |
| C52 | Parallel extract and Source Gate queries | REVERT |

### Stage 4 to 5
| Control | Rule | Verdict |
|---|---|---|
| C32 | Freeze before Stage 5 | REVERT |
| C34 | Deterministic workflow gate | REVERT |

### Stage 5, Interpretation
| Control | Rule | Verdict |
|---|---|---|
| C04 | Single interpreter replaces the three roles | REVERT |
| C05 | Word-list lint replaces claim-ceiling judgment | REVERT |
| C35 | Freeze validated pack | REVERT |
| C36 | No re-judging validation labels | REVERT |
| C37 | Evidence-tag table checks proportionality | **KEEP** |
| C38 | Follow-up tag dropped | **KEEP** |
| C44 | Changed-files-only re-review | **KEEP** |
| C48 | No second final audit after verified revisions | **KEEP** |
| C49R | Individual-file evidence delivery with checksums | **KEEP** |
| C50 | Consolidated revision pass replaces the loop | **KEEP** |

### All stages
| Control | Rule | Verdict |
|---|---|---|
| C43 | Narrow freeze scope | REVERT |
| C54 | Builder file-download capture channel | REVERT |

### Earlier A-batch (no rule changed)
A01 Dual-path independence REVERT · A02 Known-case Fixture Gate HALT · A03 SQL nonjudgment bright line REVERT · A04 SQL Source Gate vs raw REVERT · A05 Single owner knob only REVERT · A06 Integrity-gate INCONCLUSIVE REVERT · A07 Primary construct REVERT · A08 Exact recon critical-field set REVERT. A09 and A10 were deferred.

Tally: 14 KEEP, 26 REVERT, 1 HALT, 1 NOT_TRIGGERED across the numbered program; with A01-A08, 14 KEEP, 33 REVERT, 2 HALT, 1 NOT_TRIGGERED over 50 controls. Locked-forward, untested by design: capacity stance at Framing, ML Mode declaration, dual-path only where judgment lives (scoped), the failability ladder, and the evidence-package schema.

## Caveats carried by the verdicts

- Several verdicts rest on one frozen pack or one seeded-defect set (C30 seeds were fixture-covered; C37 and C38 results are partly specific to one text; C44 did not measure an unchanged-file defect).
- The C16 result is bounded by the seeded omissions a frozen pack could exercise.
- C49R was scored with a Python port of the original R scorers (parity shown on earlier data).
- Time savings are not part of any verdict predicate. Accuracy-adding KEEPs (C41, C47, C49R, C51, C53) were judged on detection and no regression.

## Open items needing an owner ruling

1. **Gate and receipt consistency (C30).** `workflow-gate/workflow_gate.R` still requires `structural_cross_review == "PASS"`, and the Stage 4 receipt template carries that field. The documents now treat the review as optional. Decide whether the gate should accept a `NOT_REQUIRED` value (a code and test change) or whether the review stays recorded as a receipt field.
2. **Exact meaning of C16.** The tested change omitted a locked rule from one builder's packet and found the remaining mechanical checks caught it. This change reads KEEP as "no separate completeness review; completeness is content of the contracts". Confirm that reading.
3. **Finish monitoring contract (C38).** Only the first-pass follow-up tag and Gate 10's next-question line were relaxed. The §21-§22 monitoring contract for a recommended action was not tested and is unchanged.
4. **Recommendation tag (C37).** The test assigned one evidence tag to the whole recommendation, by the coordinator. Decide who assigns the tag and whether the action lexicon is project-declared.
5. **Revision FLAG handling (C48/C50).** The tests did not define what happens after a FLAG beyond "correct and recheck". This change says flagged text does not pass the Finish Gates until corrected and the checklist passes.
6. **C01 attribution.** The tested unblinded chat also saw a coordinator draft (shared with C02). C02 returned REVERT, so the coordinator-draft ban stays; the C01 result is not cleanly separated from that effect.
7. **Dominance thresholds (C47).** The tested values (≥ 1,000 total, ≥ 30 per unit, share > 1/3) are written as the default; confirm or replace them in Stage 3 per project.
