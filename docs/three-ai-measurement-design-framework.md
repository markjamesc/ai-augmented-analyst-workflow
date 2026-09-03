# Three-AI Measurement Design Framework

This framework governs Stage 3, **Design**, of the five-stage AI-Augmented Analyst process.

Its purpose is to convert an approved business decision and analytical question into a complete measurement contract before any production SQL or R code is written.

Stage 3 defines:

- the hypothesis;
- population and exclusions;
- analytical grain;
- primary KPI and supporting metrics;
- segments;
- confounders and competing explanations;
- data-quality and sample-size rules;
- decision rules;
- measurement risks;
- and the output contract required by Stage 4.

The three AIs perform different functions:

- **AI 1 constructs the primary measurement design.**
- **AI 2 independently constructs a counter-design and reviews methodological validity.**
- **AI 3 audits data feasibility, join structure, and implementation risk.**

The governing principle is:

> Decide what would count as evidence before writing the code that produces it.

```mermaid
flowchart TD
    H["Locked Start + Framing<br/>handoff"] --> P["Shared design packet"]

    P --> A1["AI 1<br/>Primary design"]
    P --> A2["AI 2<br/>Independent counter-design"]
    P --> A3["AI 3<br/>Data and risk audit"]

    A1 --> X["Controlled cross-review"]
    A2 --> X
    A3 --> X

    X --> I["Consolidated issue<br/>and decision ledger"]
    I --> G{"Design gate"}

    G -->|"Business ambiguity"| SF["Return to Start<br/>or Framing"]
    SF --> P

    G -->|"Data gap"| DP["Resolve or bound<br/>profiling gap"]
    DP --> P

    G -->|"Revision required"| R["Revise affected<br/>design components"]
    R --> X

    G -->|"Pass"| L["Locked measurement<br/>design"]
    L --> E["Stage 4<br/>Independent execution"]

    classDef input fill:#fff4e5,stroke:#b65c00,color:#3d2200,stroke-width:1.5px
    classDef ai fill:#e8f1ff,stroke:#1f5fa8,color:#102a43,stroke-width:1.5px
    classDef record fill:#f4f6f8,stroke:#657786,color:#1f2933,stroke-width:1.5px
    classDef gate fill:#f2eafe,stroke:#6f42c1,color:#2d1657,stroke-width:2px
    classDef output fill:#e7f7ed,stroke:#238636,color:#123b1d,stroke-width:2px

    class H,P input
    class A1,A2,A3,R ai
    class X,I record
    class G gate
    class L,E output
    class SF,DP input
```

The AIs do not vote on a design. Each disagreement is resolved through the approved business question, explicit definitions, source-data evidence, methodological principles, or a disclosed human decision.

## 1. Position within the five-stage process

| Stage | Function | Controlling output |
|---|---|---|
| 1. Start | Identify the business decision | Approved decision statement |
| 2. Framing | Convert that decision into one analytical question | Locked analytical question |
| 3. Design | Define what must be measured and how evidence will be interpreted | Locked measurement design |
| 4. Execution | Construct, reconcile, review, and analyze the evidence | Validated analytical outputs |
| 5. Finish | Interpret the evidence and recommend a proportionate action | Evidence-traceable recommendation |

Stage 3 is the contract between the business question and the code.

It must be precise enough that independent builders can implement it without silently making different analytical decisions. It must not be so implementation-specific that it becomes disguised SQL.

## 2. What the design must establish

A complete measurement design answers nine distinct questions.

| Design layer | Controlling question |
|---|---|
| Decision alignment | What decision will this evidence support? |
| Hypothesis | What claim, mechanism, or expectation is being tested? |
| Population | Which observations are eligible, and which are excluded? |
| Grain | What does one analytical row represent at each stage? |
| Measurement | How are the primary KPI, guardrails, and diagnostics defined? |
| Comparison | Relative to what baseline, peer group, period, or counterfactual is the result judged? |
| Heterogeneity | Which segments or subgroups may differ meaningfully? |
| Alternative explanation | Which confounders, biases, and rival explanations could change interpretation? |
| Decision rule | How will possible results map to actions, uncertainty, or escalation? |

No single KPI answers all nine questions.

## 3. Required input package

All three AIs receive the same versioned Design Input Package.

### Required business inputs

- original stakeholder request;
- complete Start and Framing decision trail;
- approved decision statement;
- locked analytical question;
- decision owner;
- available actions;
- intended business outcome;
- time horizon;
- capacity, resource, policy, and risk constraints;
- required exceptions;
- and stakeholder approval record.

### Required data inputs

- database context;
- schema or data dictionary;
- table and column descriptions;
- primary and foreign-key expectations;
- source-system limitations;
- current data profile;
- known missingness, duplication, range, and anomaly findings;
- available time coverage;
- and database dialect for the eventual Stage 4 implementation.

### Missing-input rule

If a required business input is missing, return to Start or Framing.

If a required data fact is missing, record a targeted profiling question. Do not invent a field, cardinality, coverage period, or data-quality condition.

Targeted profiling may inform Stage 3. Production KPI SQL and deeper analysis remain prohibited until the design passes.

## 4. Human authority and AI boundaries

### Stakeholder or decision owner

The stakeholder controls:

- the practical decision;
- available actions;
- business priority;
- operational capacity;
- material exceptions;
- and acceptable business risk.

The stakeholder may propose metrics, but a proposed metric is not automatically a valid measurement definition.

### Human analyst

The human analyst owns:

- the final synthesis;
- analytical judgment where several defensible designs remain;
- escalation to the stakeholder;
- approval of disclosed working assumptions;
- and the lock authorizing Stage 4.

### AI boundaries

No AI may:

- rewrite the approved decision for convenience;
- invent unavailable fields;
- treat an operational concept as a database column without verification;
- select a desired conclusion in advance;
- silently change the population or grain;
- or begin production SQL or R.

## 5. The three AI roles

### AI 1 — Primary Measurement Architect

AI 1 produces Design A from the locked input package.

Its responsibilities include:

- translating the approved question into testable hypotheses;
- defining population and exclusions;
- declaring every required grain;
- specifying KPI contracts;
- defining comparisons and baselines;
- selecting justified segments;
- identifying confounders and measurement risks;
- defining data-quality, sample-size, and sensitivity rules;
- constructing decision rules;
- and producing the Stage 4 output contract.

AI 1 must distinguish business requirements from its own proposed analytical choices.

### AI 2 — Independent Counter-Designer and Methodological Critic

AI 2 independently produces Design B before seeing Design A.

AI 2 tests whether a materially different but defensible design follows from the same business question. It focuses on:

- construct validity;
- hypothesis falsifiability;
- denominator choice;
- baseline and comparison logic;
- selection bias;
- survivor bias;
- confounding;
- segment multiplicity;
- minimum sample rules;
- uncertainty;
- decision-threshold justification;
- and whether the proposed evidence could actually support the intended conclusion.

AI 2 must not disagree merely to create variety. Every alternative must identify the risk it solves and the tradeoff it introduces.

### AI 3 — Data Feasibility and Measurement-Risk Auditor

AI 3 first builds an independent Data and Risk Dossier without seeing Design A or Design B.

It examines:

- whether required concepts have source fields;
- table coverage;
- key uniqueness;
- join cardinality;
- duplicate risk;
- missingness;
- time coverage;
- date and timezone semantics;
- category consistency;
- leakage risk;
- post-outcome fields;
- partial-period effects;
- unsupported operational fields;
- and whether the eventual outputs can be independently reconstructed in Stage 4.

During cross-review, AI 3 checks both designs against the verified data context and profile.

AI 3 may reject an implementable design if the measurement is conceptually invalid, and it may reject a conceptually attractive design if the required evidence does not exist.

## 6. Independence before cross-review

The initial outputs must be developed independently.

| AI | Initial output | Must not see initially |
|---|---|---|
| AI 1 | Complete Design A | Design B and AI 3 risk dossier |
| AI 2 | Complete Design B | Design A and AI 3 risk dossier |
| AI 3 | Data and Risk Dossier | Design A and Design B |

Independence reduces anchoring.

If AI 2 merely edits Design A, agreement between the designs has little value. If AI 3 sees a proposed grain before checking source relationships, it may rationalize the proposed joins instead of independently identifying cardinality risk.

After all three initial outputs are complete, the information barriers are removed for controlled cross-review.

## 7. Design status vocabulary

Every material design element receives one status:

- **Locked:** Approved and controlling for Stage 4.
- **Proposed:** Defensible but not yet approved.
- **Verified:** Supported by the data context or profile.
- **Provisional:** Required temporarily and subject to validation or sensitivity testing.
- **Disputed:** More than one defensible interpretation remains.
- **Open:** Information is insufficient.
- **Infeasible:** Required evidence is unavailable or unreliable.
- **Deferred:** Properly belongs to Stage 4 or Stage 5.
- **Rejected:** Fails business, methodological, or data review.

Stage 4 may implement only **Locked** elements. A provisional design choice may enter Stage 4 only when the design specifies how it will be tested and who accepted the risk.

## 8. Hypothesis contract

The design begins with the approved decision, not with a preferred technique.

### 8.1 Business hypothesis

State the decision-relevant expectation in plain language.

Example:

> A meaningful subset of eligible sellers has persistently elevated late-fulfillment rates and can be prioritized for intervention within the available program capacity.

### 8.2 Mechanism or rationale

State why the pattern might exist and why the proposed action could matter.

Do not convert a plausible story into an established causal mechanism.

### 8.3 Observable implication

State what pattern should appear if the hypothesis is useful.

Examples include:

- stable elevation relative to a justified baseline;
- concentration of risk in particular units or segments;
- persistence under reasonable measurement alternatives;
- or a meaningful difference large enough to change action.

### 8.4 Counterevidence

State what result would weaken or defeat the hypothesis.

A hypothesis that cannot lose is not controlling analytical guidance.

### 8.5 Statistical hypotheses where relevant

Use null and alternative hypotheses only when a statistical test genuinely contributes to the decision.

Do not add significance testing merely to make a descriptive decision process appear scientific.

### 8.6 Hypothesis hierarchy

Separate:

- primary business hypothesis;
- primary analytical hypothesis;
- secondary hypotheses;
- exploratory questions;
- and mechanism claims requiring stronger evidence.

Exploratory findings must not be presented later as if they were prespecified confirmatory tests.

## 9. Population and eligibility contract

The population contract must specify:

- target population;
- observable population;
- inclusion rules;
- exclusion rules;
- time window;
- lower-bound inclusivity;
- upper-bound exclusivity;
- status requirements;
- required non-null fields;
- unit eligibility;
- entity eligibility;
- and how excluded records will be counted and reported.

### Target versus observable population

The target population is the population about which the decision is intended.

The observable population is the subset represented in the available data.

The design must disclose any gap between them. A query cannot repair a coverage limitation by filtering it away.

### Exclusion discipline

Every exclusion must have:

- a reason;
- a stage at which it is applied;
- an expected effect;
- and an audit count.

A missing outcome should not be silently treated as a negative outcome. An inner join should not become an undocumented eligibility rule.

## 10. Analytical grain contract

Grain is the meaning of one row.

The design must declare grain at every material level:

| Layer | Grain question |
|---|---|
| Source | What does one source row represent? |
| Eligibility | At what unit is inclusion determined? |
| Event or observation | What counts once in the numerator or denominator? |
| Entity-period | At what level is the KPI calculated? |
| Segment | At what level are comparisons made? |
| Decision | At what level is action assigned? |

### Grain transition map

For each transition, record:

- input grain;
- output grain;
- grouping keys;
- deduplication rule;
- aggregation rule;
- expected row-count direction;
- and uniqueness assertion.

### Join cardinality contract

Before SQL, declare the expected relationship for every required join:

- one-to-one;
- one-to-many;
- many-to-one;
- or many-to-many.

If a many-to-many relationship is legitimate, specify how it will be controlled. `DISTINCT` is not an acceptable substitute for understanding the duplication.

### Example

In a seller-fulfillment analysis, raw order items may contain several rows for the same seller within one order. If the measurement unit is seller-order, the design must require a seller-order grain before calculating lateness. Counting order-item rows would overweight multi-item orders.

## 11. KPI and metric contract

Every KPI must be defined before implementation.

### Required KPI fields

| Field | Required definition |
|---|---|
| Metric name | Stable business-readable name |
| Purpose | Decision the metric supports |
| Grain | Level at which it is computed |
| Population | Eligible observations |
| Numerator | Exact event or quantity counted |
| Denominator | Exact opportunity set |
| Formula | Unambiguous mathematical definition |
| Time basis | Event date, calendar date, timestamp, cohort, or window |
| Direction | Whether higher or lower is better |
| Missingness | Treatment of absent components |
| Weighting | Entity-weighted, event-weighted, revenue-weighted, or other |
| Aggregation | How lower-grain values roll up |
| Precision | Internal calculation and display rules |
| Audit components | Counts required to reproduce the metric |
| Limitations | Known interpretive boundaries |

### Metric hierarchy

Separate:

- **Primary KPI:** The main decision metric.
- **Guardrail metrics:** Outcomes that must not deteriorate while optimizing the primary KPI.
- **Diagnostic metrics:** Measures that help explain the KPI.
- **Audit metrics:** Counts used to validate construction.
- **Sensitivity twins:** Alternative definitions used to test robustness.

Do not allow a diagnostic metric to replace the primary KPI during execution without reopening the design.

### Rate contract

For every rate, preserve numerator and denominator.

$$
\text{Rate} = \frac{\text{Qualified events}}{\text{Eligible opportunities}}
$$

A percentage without its components is insufficient for validation, sample-size assessment, or decision review.

### Date and timestamp rules

Define explicitly:

- date versus timestamp comparison;
- timezone;
- same-day treatment;
- missing timestamp treatment;
- late-arriving data;
- partial days or months;
- and half-open window boundaries.

## 12. Comparison and baseline contract

A value becomes decision-relevant only relative to an appropriate reference.

Possible references include:

- marketplace or portfolio baseline;
- peer group;
- prior period;
- target or SLA;
- matched comparison group;
- expected value from a model;
- or a no-action baseline.

The design must state:

- why the reference is appropriate;
- whether it is weighted;
- whether the focal unit contributes to its own baseline;
- how small peers are handled;
- whether seasonality matters;
- and what interpretation the comparison does and does not permit.

A percentile, average, target, and causal counterfactual are not interchangeable.

## 13. Segment contract

Segments are included because the decision may differ across groups, not because every available category should be explored.

For each segment, specify:

- business rationale;
- source field;
- transformation or grouping rule;
- expected category values;
- missing-category treatment;
- minimum group size;
- whether it is prespecified or exploratory;
- interaction or overlap with other segments;
- and the action that a segment difference could change.

### Segment priority

Classify segments as:

- required for the primary decision;
- required as a fairness or risk guardrail;
- diagnostic;
- exploratory;
- or excluded.

### Multiplicity risk

Testing many segments increases the chance of finding unstable extremes. The design must state whether segment findings are descriptive, confirmatory, adjusted for multiple testing, or subject to later validation.

## 14. Confounder and competing-explanation ledger

A confounder is not merely another available variable.

For each proposed confounder or competing explanation, record:

| Field | Required content |
|---|---|
| Risk ID | Stable identifier |
| Variable or mechanism | Exact factor |
| Why it matters | Path by which it could distort interpretation |
| Relation to exposure or segment | Why imbalance is plausible |
| Relation to outcome | Why the KPI could change |
| Available measure | Verified field or acknowledged absence |
| Planned treatment | Stratify, adjust, restrict, match, describe, sensitivity test, or disclose |
| Residual limitation | What remains unresolved |

Examples may include:

- volume;
- product mix;
- geography;
- seasonality;
- customer composition;
- tenure;
- order value;
- operational complexity;
- and exposure opportunity.

### Causal ceiling

Adjustment does not automatically establish causality.

The design must classify the intended conclusion as:

- descriptive;
- comparative;
- associational;
- predictive;
- or causal.

Every later claim must remain under that ceiling unless a stronger design is separately justified.

## 15. Data-quality and anomaly contract

Before execution, specify rules for:

- duplicate keys;
- impossible dates;
- negative or impossible values;
- category inconsistencies;
- outliers;
- partial periods;
- missing required fields;
- records outside the expected time range;
- conflicting source values;
- late-arriving records;
- and join failures.

For each issue, choose one action:

- exclude;
- correct from an authoritative source;
- retain and flag;
- winsorize or transform;
- analyze separately;
- perform sensitivity analysis;
- or pause for investigation.

No anomaly policy may be invented after results are seen merely because it improves the conclusion.

## 16. Sample-size and uncertainty contract

The design must specify where sample size affects:

- eligibility;
- ranking stability;
- segment reporting;
- confidence intervals;
- statistical testing;
- model validation;
- and decision thresholds.

### Minimum denominator

A minimum denominator may protect against unstable rates, but it requires a rationale.

Label the rule as:

- policy-based;
- statistically justified;
- empirically validated;
- or provisional.

A provisional threshold must not be presented later as an SLA or scientific constant.

### Uncertainty representation

Specify whether the output requires:

- raw numerator and denominator;
- interval estimates;
- shrinkage or partial pooling;
- suppression of tiny cells;
- sensitivity bands;
- or a stability flag.

## 17. Decision-rule contract

The decision rule connects evidence to action.

For every action category, specify:

- eligibility requirement;
- evidence threshold;
- comparison rule;
- capacity constraint;
- tie-breaking rule;
- guardrail;
- exception path;
- uncertainty treatment;
- and what happens when evidence is insufficient.

### Decision categories

Examples include:

- intervene;
- monitor;
- no action;
- escalate for review;
- or collect more evidence.

### Capacity-aware rules

If only a limited number of entities can receive intervention, the design must say whether priority is based on:

- rate severity;
- total events at risk;
- expected benefit;
- confidence-adjusted risk;
- policy priority;
- or a defined combination.

The selection logic must be fixed before the ranked results are viewed.

### What the rule does not establish

A decision threshold is a policy choice informed by evidence. It is not automatically:

- a natural boundary;
- an SLA;
- a causal effect threshold;
- or proof that entities immediately below it are meaningfully different.

## 18. Measurement-risk register

Every material risk receives:

| Field | Required content |
|---|---|
| Risk ID | Stable identifier |
| Design component | Population, grain, KPI, segment, confounder, threshold, source, or output |
| Failure mode | What could go wrong |
| Likelihood | Low, medium, high, or unknown |
| Decision impact | How the error could alter action |
| Detection control | Check that would reveal it |
| Prevention control | Design rule that reduces it |
| Sensitivity test | Alternative definition or scenario |
| Residual risk | What remains after controls |
| Status | Resolved, accepted, open, blocking, or deferred |

High-impact risks cannot be buried in prose. They must appear in the register and at the Design Gate.

## 19. Non-executable implementation blueprint

Stage 3 must describe the required transformation logic without writing production SQL or R.

The blueprint should identify:

1. source tables;
2. required fields;
3. expected keys;
4. join relationships;
5. population filters;
6. eligibility logic;
7. grain transitions;
8. metric components;
9. aggregations;
10. segment assignments;
11. decision classifications;
12. audit counts;
13. and required outputs.

Acceptable blueprint language:

> Join orders to order items on the verified order key, establish one row per seller-order before lateness classification, then aggregate eligible seller-orders to the seller-window level.

Not acceptable during Stage 3: executable query syntax, CTE construction, database-specific implementation, or code written to produce the result.

The design defines what the code must do. Stage 4 independently determines how to implement it.

## 20. Stage 4 output contract

The locked design must support the three-AI execution architecture.

### SQL A contract

Define the required final KPI table:

- exact grain;
- required keys;
- numerator and denominator columns;
- unrounded metric columns;
- eligibility flags;
- decision-rule fields;
- audit fields;
- and expected uniqueness.

### SQL B contract

Define the lower-grain analytical extract required for independent reconstruction:

- exact grain;
- raw or minimally transformed fields;
- source keys;
- timestamps;
- inclusion and exclusion evidence;
- fields required to rebuild the KPI;
- and fields SQL B must not precompute.

### R(B) reconstruction contract

Define what R must independently reconstruct from SQL B:

- population rules not irrevocably applied upstream;
- eligibility;
- event classification;
- numerator;
- denominator;
- rate;
- volume floor;
- segments;
- decision classification;
- and audit totals.

### Reconciliation contract

Define exact comparison requirements:

- key coverage;
- row counts;
- uniqueness;
- numerator equality;
- denominator equality;
- flag equality;
- decision equality;
- global control totals;
- and numerical tolerance for unrounded rates.

This output contract allows Stage 4 to build independent implementations without forcing the builders to copy one another.

## 21. Phase 1 — Lock and inspect the input package

Before independent design begins, all three AIs confirm:

- the same approved decision;
- the same analytical question;
- the same source versions;
- the same database context;
- the same data profile;
- and the same stated constraints.

Any contradiction is recorded before design work begins.

Examples:

- the question requires customer behavior, but only seller and order data are available;
- the stakeholder requests a causal recommendation, but the planned evidence is observational;
- the decision horizon lies outside data coverage;
- or an operational concept such as “featured placement” is not a database field.

## 22. Phase 2 — Independent first-pass designs

AI 1, AI 2, and AI 3 work independently from the shared packet.

### AI 1 output: Design A

AI 1 returns a complete proposed measurement design using the required structure in Section 31.

### AI 2 output: Design B

AI 2 returns an independent design covering the same required structure, plus:

- the strongest alternative KPI;
- the strongest alternative grain;
- the strongest alternative comparison;
- the most important confounder;
- and the design choice most likely to change the decision.

### AI 3 output: Data and Risk Dossier

AI 3 returns:

- source-to-concept map;
- key and cardinality map;
- missingness and anomaly summary;
- unavailable-field list;
- leakage and temporal-risk list;
- measurement-risk register;
- targeted profiling gaps;
- and implementability verdict for each required design component.

## 23. Phase 3 — Controlled cross-review

After the independent pass, combine all three outputs into one review packet.

### AI 1 reviews Design B and the Data and Risk Dossier

AI 1 identifies:

- improvements that should replace Design A;
- alternatives that answer a different question;
- data risks that require design changes;
- and any business requirement lost in Design B.

### AI 2 reviews Design A and the Data and Risk Dossier

AI 2 identifies:

- invalid or weak hypotheses;
- construct-validity problems;
- denominator and baseline risks;
- unhandled confounding;
- unjustified sample or decision thresholds;
- and claims stronger than the design can support.

### AI 3 reviews Design A and Design B

AI 3 identifies:

- unavailable fields;
- unsafe joins;
- incompatible grains;
- hidden filters;
- impossible audit requirements;
- untestable decision rules;
- and designs that cannot feed independent SQL A versus R(B) reconciliation.

Every criticism must target an exact design field, proposition, or ledger entry.

## 24. Phase 4 — Design reconciliation

Create a Design Reconciliation Matrix.

| Component | Design A | Design B | Data evidence | Controlling rule | Resolution |
|---|---|---|---|---|---|
| Hypothesis | Exact wording | Exact wording | Relevant support | Approved question and falsifiability | Lock, revise, branch, or open |
| Population | Inclusion/exclusion | Inclusion/exclusion | Coverage profile | Target population | Lock, revise, or escalate |
| Grain | Proposed levels | Proposed levels | Key/cardinality evidence | Unit counted once | Lock or revise |
| KPI | Formula A | Formula B | Available fields | Construct validity | Lock, sensitivity twin, or reject |
| Segments | Proposed groups | Proposed groups | Category profile | Decision relevance | Lock, exploratory, or reject |
| Confounders | Proposed controls | Proposed controls | Available measures | Interpretive risk | Address or disclose |
| Decision rule | Rule A | Rule B | Capacity evidence | Stakeholder constraint | Lock or return to stakeholder |

Agreement is not automatically correct. Disagreement is not automatically a problem.

The resolution must state why one design choice better follows from the approved question, available evidence, and methodological standard.

## 25. Phase 5 — Research, profiling, or stakeholder return

Unresolved issues follow one of three routes.

### Business ambiguity

Return to Start or Framing when the issue changes:

- decision owner;
- action;
- outcome;
- material constraint;
- time horizon;
- or the meaning of the analytical question.

### Data uncertainty

Request targeted profiling when the issue concerns:

- key uniqueness;
- missingness;
- field coverage;
- category values;
- time range;
- duplication;
- or join cardinality.

The profiling task must answer the exact gap and must not become production analysis.

### Methodological choice

Resolve through:

- statistical principle;
- construct validity;
- sensitivity design;
- decision relevance;
- or an explicit human choice between defensible alternatives.

If no resolution is justified, mark the item **Disputed** and specify how Stage 4 will branch or test it.

## 26. Phase 6 — Candidate measurement design

AI 1 produces the consolidated candidate after accepted resolutions.

Every field must identify its status and origin:

- stakeholder requirement;
- locked Start/Framing statement;
- verified data fact;
- accepted methodological choice;
- provisional assumption;
- or unresolved limitation.

No new material design choice may appear at synthesis without returning to review.

## 27. Phase 7 — Final three-AI audit

The candidate design receives three different audits.

### AI 1 — Decision trace audit

Check that every major design choice traces to:

- the approved decision;
- the locked analytical question;
- a verified data requirement;
- or a disclosed methodological judgment.

### AI 2 — Methodological audit

Check:

- hypothesis clarity and falsifiability;
- construct validity;
- population alignment;
- denominator validity;
- comparison logic;
- confounding;
- segment multiplicity;
- sample-size treatment;
- uncertainty;
- causal ceiling;
- and proportionality of decision rules.

### AI 3 — Implementation-contract audit

Check:

- source availability;
- field definitions;
- keys and cardinalities;
- grain transitions;
- date logic;
- missingness rules;
- anomaly rules;
- audit counts;
- SQL A contract;
- SQL B lower-grain contract;
- R(B) reconstruction contract;
- and reconciliation requirements.

Each audit returns:

- **Pass**;
- **Pass with required revisions**;
- or **Fail**.

A required revision must name the affected design field and provide an exact correction or decision request.

## 28. Mandatory Design Gate

The design passes only when all of the following are satisfied.

### Gate 1 — Decision alignment

- Approved decision and question preserved.
- Possible actions remain visible.
- Capacity and timing constraints represented.
- No metric-first substitution.

### Gate 2 — Hypothesis

- Primary hypothesis explicit.
- Observable implications stated.
- Counterevidence stated.
- Confirmatory and exploratory work separated.

### Gate 3 — Population

- Target and observable populations distinguished.
- Inclusion and exclusion rules exact.
- Date window and boundary logic explicit.
- Exclusion audit counts required.

### Gate 4 — Grain and joins

- Every grain declared.
- Grain transitions mapped.
- Join cardinalities stated.
- Uniqueness assertions specified.
- Duplication cannot be hidden by deduplication.

### Gate 5 — Metrics

- Primary KPI fully contracted.
- Numerator and denominator exact.
- Guardrails, diagnostics, and audit metrics distinguished.
- Date, missingness, aggregation, weighting, and precision rules defined.

### Gate 6 — Comparisons and segments

- Baseline justified.
- Weighting explicit.
- Segments decision-relevant.
- Minimum group and exploratory-status rules defined.

### Gate 7 — Confounders and interpretation

- Major competing explanations listed.
- Available controls verified.
- Residual limitations disclosed.
- Descriptive, associational, predictive, or causal ceiling stated.

### Gate 8 — Data quality and uncertainty

- Missingness and anomaly rules prespecified.
- Sample-size requirements justified or labeled provisional.
- Sensitivity analyses defined.
- Blocking data gaps resolved or bounded.

### Gate 9 — Decision rules

- Evidence-to-action mapping explicit.
- Capacity and tie-breaking rules explicit.
- Insufficient-evidence path defined.
- Thresholds not misrepresented as natural facts or SLAs.

### Gate 10 — Stage 4 contract

- SQL A final-table contract complete.
- SQL B lower-grain contract complete.
- R(B) independent-reconstruction contract complete.
- Reconciliation requirements complete.
- No production SQL or R has been written in Stage 3.

### Gate 11 — Review and ownership

- Independent first passes completed.
- Cross-review findings resolved or disclosed.
- No decision made by majority vote.
- Human analyst approves the final lock.
- Material business changes returned to the stakeholder.

## 29. What passing the Design Gate proves

| Passing establishes | Passing does not establish |
|---|---|
| The team has one controlling measurement specification | The selected business decision is guaranteed to succeed |
| Independent reviewers tested the design | Every reviewer prefers the same design |
| Population, grain, KPI, and rules are explicit | The eventual code will implement them correctly |
| Known measurement risks are controlled or disclosed | No unknown data problem exists |
| Stage 4 outputs and validation targets are defined | SQL A and R(B) will reconcile on the first attempt |
| The intended conclusion ceiling is defined | The evidence will support the preferred conclusion |

Stage 3 validates the specification. Stage 4 validates its implementation and the evidence produced from it.

## 30. Illustrative FulfillIQ design fragment

The following illustrates the level of precision required. It is not a universal template.

### Approved decision context

Prioritize sellers for an intervention program with capacity for approximately 20 concurrent plans, while preserving a separate view of severe low-volume cases.

### Population

- Delivered orders only.
- Purchase timestamp from `2018-01-01 00:00:00` inclusive to `2018-09-01 00:00:00` exclusive.
- All seller states.
- Required delivery timestamps non-null for the primary lateness denominator.

### Grain

- Operational event grain: seller-order `(seller_id, order_id)`.
- KPI grain: seller-window.
- Decision grain: seller.

### Primary KPI

Seller Late-Fulfillment Rate:

$$
\text{Seller LFR} =
\frac{\text{Late eligible seller-orders}}
{\text{All eligible seller-orders}}
$$

- Working lateness definition: `DATE(actual delivery) > DATE(estimated delivery)`.
- Timestamp-based lateness retained as a sensitivity twin.
- Numerator and denominator retained as audit fields.

### Sample-size rule

A minimum of 30 usable seller-orders is provisional. It is not an SLA and must be reviewed through stability and sensitivity analysis.

### Primary source path

The primary KPI path uses orders, order items, and sellers. Reviews, payments, product categories, and raw geolocation do not enter the primary KPI joins merely because they are available.

### Operational constraints

Program capacity is a business constraint, not a database column. Featured placement, intervention status, or plan capacity must not be invented as source fields.

This fragment is strong enough to control implementation while leaving SQL A, SQL B, and R(B) free to be independently constructed.

## 31. Required structure of `Stage_03_Measurement_Design.md`

The final Stage 3 artifact must contain:

1. Document purpose and version.
2. Approved decision statement.
3. Locked analytical question.
4. Stakeholder constraints and exceptions.
5. Intended conclusion type and ceiling.
6. Hypothesis hierarchy.
7. Population and eligibility contract.
8. Time-window and date contract.
9. Grain and join-cardinality contract.
10. Primary KPI contract.
11. Guardrail, diagnostic, audit, and sensitivity metrics.
12. Comparison and baseline contract.
13. Segment contract.
14. Confounder and competing-explanation ledger.
15. Missingness, anomaly, and data-quality rules.
16. Sample-size and uncertainty rules.
17. Decision rules and capacity constraints.
18. Measurement-risk register.
19. Non-executable implementation blueprint.
20. SQL A output contract.
21. SQL B lower-grain output contract.
22. R(B) reconstruction contract.
23. Exact reconciliation contract.
24. Multi-AI review and resolution record.
25. Assumptions, open questions, and accepted limitations.
26. Stage 4 handoff and lock approval.

## 32. Failure conditions

The process fails if:

- production SQL or R is written before the design is locked;
- the requested metric substitutes for the approved decision;
- the approved analytical question is silently changed;
- all three AIs edit one initial design instead of producing independent first passes;
- AI 2 manufactures disagreement without a methodological reason;
- AI 3 invents fields or cardinalities;
- population filters are vague;
- missing outcomes are silently treated as negative outcomes;
- the analytical grain is unstated;
- `DISTINCT` is used conceptually to hide an unexplained join duplication;
- numerator or denominator is ambiguous;
- rates are specified without their component counts;
- date versus timestamp behavior is left to the implementer;
- a baseline is chosen merely because it makes the result look extreme;
- segments are added without decision relevance;
- exploratory subgroup findings are mislabeled confirmatory;
- a correlation design is described as causal;
- confounders are listed without explaining how they threaten interpretation;
- unavailable controls are treated as if adjustment occurred;
- sample thresholds are invented after viewing results;
- a provisional threshold is called an SLA;
- data anomalies are removed without a prespecified rule and audit count;
- decision rules are written after seeing which entities rank highest;
- operational concepts are treated as database columns without verification;
- data convenience silently narrows the business question;
- the Stage 4 output contract does not preserve independent reconstruction;
- an AI disagreement is resolved by voting;
- a blocking risk is hidden;
- a material business change is not returned to the stakeholder;
- or Stage 4 cannot implement the design without making new analytical decisions.

## 33. Required deliverables

The process produces:

1. `01_DESIGN_INPUT_PACKAGE.md`
2. `02_AI1_PRIMARY_MEASUREMENT_DESIGN.md`
3. `03_AI2_INDEPENDENT_COUNTER_DESIGN.md`
4. `04_AI3_DATA_AND_RISK_DOSSIER.md`
5. `05_CROSS_REVIEW_FINDINGS.md`
6. `06_DESIGN_RECONCILIATION_MATRIX.md`
7. `07_MEASUREMENT_RISK_REGISTER.md`
8. `08_CANDIDATE_MEASUREMENT_DESIGN.md`
9. `09_FINAL_THREE_AI_AUDITS.md`
10. `10_STAGE_03_MEASUREMENT_DESIGN.md`
11. `11_STAGE_04_EXECUTION_HANDOFF.md`

These may be combined into one controlled document when every component remains identifiable and versioned.

## 34. Complete operating sequence

1. Receive the locked Start and Framing handoff.
2. Verify that all three AIs have the same input versions.
3. Return business ambiguity to Start or Framing.
4. Have AI 1 construct Design A independently.
5. Have AI 2 construct Design B independently.
6. Have AI 3 construct the Data and Risk Dossier independently.
7. Remove the information barriers after the three initial outputs are complete.
8. Cross-review exact design fields and risks.
9. Build the Design Reconciliation Matrix.
10. Resolve disagreements through business requirements, data evidence, and methodological principles.
11. Run targeted profiling only for consequential data gaps.
12. Return material business changes to the stakeholder.
13. Build the consolidated candidate design.
14. Audit decision trace, methodological validity, and implementation feasibility separately.
15. Resolve or disclose every material objection.
16. Complete all eleven Design Gates.
17. Lock `Stage_03_Measurement_Design.md` through human approval.
18. Deliver the output contracts to the three independent Stage 4 builders.

## 35. Final completion standard

Stage 3 is complete only when:

- the approved decision and question remain controlling;
- the hypotheses are explicit and capable of encountering counterevidence;
- population and exclusions are exact;
- every grain and grain transition is declared;
- primary KPI numerator and denominator are unambiguous;
- comparisons and baselines are justified;
- segments are decision-relevant and classified as prespecified or exploratory;
- major confounders and competing explanations are addressed or disclosed;
- missingness and anomaly rules are prespecified;
- sample and uncertainty rules are justified or labeled provisional;
- decision thresholds and capacity rules are fixed before results;
- measurement risks have detection and sensitivity controls;
- AI 1 and AI 2 completed independent designs;
- AI 3 independently audited data feasibility;
- cross-review disagreements were resolved through evidence rather than voting;
- the SQL A, SQL B, R(B), and reconciliation contracts are complete;
- no production SQL or R was written during Stage 3;
- the human analyst approved the lock;
- and Stage 4 can begin without making new measurement decisions.

The final governing rule is:

> If Stage 4 must decide what the population, grain, KPI, threshold, or action rule means, Stage 3 is not finished.

End of framework.
