# R 4.6.1 environment-documentation change

Date: 2026-10-10 America/Chicago. Base: `51b6b0f4741cf97720349c180313353300f5078b`. Branch: `regression-acceptance-r461-env-2026-10-10`.

The supported R version and CI test target are **R 4.6.1**. The owner reports that GrokBot's live acceptance run uses R 4.6.1 on the owner's PC and tests the original base commit unchanged. Completion or PASS of that live run has not been established by this change.

This is a separate environment-documentation change, not a methodology change or a revision of the original candidate's results. No R gate code, schema, contract, test script, or test expectation is changed. The only executable configuration change is the CI R-version pin. The existing branch trigger already covers this new branch.

## Tested-version status

Local execution is unavailable in this session. An R 4.6.1 GitHub CI run will be attempted on this branch. Until that run succeeds, all five suites on R 4.6.1 are **NOT VERIFIED**, not PASS. The original candidate's historical passes remain valid only for their recorded environment. The Python schema suite is not itself an R-version test.

## References found before edits

The scan covered all 71 text files at the base commit, including docs, READMEs, templates, schemas, both gates, CI and test scripts. The PDF and PowerPoint binary exports were not text-scanned or modified. Each matched line follows; the GNU Make match is unrelated to R.

- `docs/framework-refinement/HARDENING_IMPLEMENTATION.md:54`: `All three commands above passed in Linux with R 4.4.3 and the recorded package inventory. Workflow tests accepted known valid cases and rejected 17 deliberate defects. Procedure tests completed the synthetic five-stage certification and rejected 23 invalid amendments without changing state. Methodology tests rejected 28 contract defects, checked keyed reconciliation and numerical boundaries, detected a seeded metamorphic fault, and exercised a fresh-process replay. Successor/retry tests preserved the predecessor and failed attempts without inheriting completed stages.`
- `docs/framework-refinement/step3-evidence/R-session.txt:1`: `R version 4.4.3 (2025-02-28)`
- `docs/framework-refinement/STEP3_LOCAL_ACCEPTANCE.md:38`: `Use Linux R 4.4.3 with jsonlite, digest, purrr and magrittr. The evidence includes exact conda package URLs with SHA-256 fragments and a Python package inventory. `r-linux-64-explicit.txt` can be supplied to `micromamba create -p <new-env> -f <file>`. It is platform-specific, not a Windows environment specification. Run from the repository root:`
- `.github/workflows/workflow-gate-test.yml:43`: `          r-version: "4.4.3"`
- `docs/framework-refinement/step3-evidence/r-linux-64-explicit.txt:69`: `https://conda.anaconda.org/conda-forge/linux-64/make-4.4.1-hb03c661_3.conda#4c65d2769847778a6d84db6984ac81bcec6f8958d349f1fe57ae040ccc56a801`
- `docs/framework-refinement/step3-evidence/r-linux-64-explicit.txt:76`: `https://conda.anaconda.org/conda-forge/linux-64/r-base-4.4.3-h502d0c9_11.conda#f2e18482ab87de3d29520e69b20a34f785d738cb0c007b3c4ef8cf8cbce7fb09`
- `methodology/tests/test-environment-session.txt:1`: `R version 4.4.3 (2025-02-28)`
- `methodology/tests/test-environment-packages.csv:2`: `"base","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:3`: `"cli","3.6.6","4.4.3"`
- `methodology/tests/test-environment-packages.csv:4`: `"compiler","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:5`: `"datasets","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:6`: `"digest","0.6.39","4.4.3"`
- `methodology/tests/test-environment-packages.csv:7`: `"glue","1.8.1","4.4.3"`
- `methodology/tests/test-environment-packages.csv:8`: `"graphics","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:9`: `"grDevices","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:10`: `"grid","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:11`: `"jsonlite","2.0.0","4.4.3"`
- `methodology/tests/test-environment-packages.csv:12`: `"lifecycle","1.0.5","4.4.3"`
- `methodology/tests/test-environment-packages.csv:13`: `"magrittr","2.0.5","4.4.3"`
- `methodology/tests/test-environment-packages.csv:14`: `"methods","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:15`: `"parallel","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:16`: `"purrr","1.2.2","4.4.3"`
- `methodology/tests/test-environment-packages.csv:17`: `"rlang","1.3.0","4.4.3"`
- `methodology/tests/test-environment-packages.csv:18`: `"splines","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:19`: `"stats","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:20`: `"stats4","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:21`: `"tcltk","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:22`: `"tools","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:23`: `"utils","4.4.3","4.4.3"`
- `methodology/tests/test-environment-packages.csv:24`: `"vctrs","0.7.3","4.4.3"`

## Exact edits

### .github/workflows/workflow-gate-test.yml

Old:

```text
r-version: "4.4.3"
```

New:

```text
r-version: "4.6.1"
```

### docs/framework-refinement/HARDENING_IMPLEMENTATION.md

Old:

```text
All three commands above passed in Linux with R 4.4.3 and the recorded package inventory.
```

New:

```text
All three commands above passed in the historical Linux environment identified by the retained session and package inventory. The supported R version is now R 4.6.1; this environment-documentation update does not relabel those historical test results. See [R version change and verification status](R_4_6_1_ENVIRONMENT_CHANGE.md).
```

### docs/framework-refinement/STEP3_LOCAL_ACCEPTANCE.md

Old:

```text
Use Linux R 4.4.3 with jsonlite, digest, purrr and magrittr. The evidence includes exact conda package URLs with SHA-256 fragments and a Python package inventory. `r-linux-64-explicit.txt` can be supplied to `micromamba create -p <new-env> -f <file>`. It is platform-specific, not a Windows environment specification. Run from the repository root:
```

New:

```text
The supported R version is R 4.6.1, with jsonlite, digest, purrr and magrittr. See [R version change and verification status](R_4_6_1_ENVIRONMENT_CHANGE.md). The retained conda package URLs, SHA-256 fragments and Python inventory describe the original historical test environment, not the new supported version. `r-linux-64-explicit.txt` can be supplied to `micromamba create -p <new-env> -f <file>` to reproduce that historical environment only; it is neither an R 4.6.1 lockfile nor a Windows environment specification. Run from the repository root:
```

### README.md

Old:

```text
This portfolio artifact presents
```

New:

```text
Supported R version: **R 4.6.1**. See [environment change and tested-version status](docs/framework-refinement/R_4_6_1_ENVIRONMENT_CHANGE.md). This version update is separate from the original candidate's acceptance results.

This portfolio artifact presents
```

## Historical evidence retained

The two captured session files, captured package inventory and explicit historical environment lock are unchanged. Replacing their version strings or package URLs would falsely describe the executed tests and invalidate evidence hashes. Their old-version references are historical exceptions, as are the old-text inventory in this change record. GNU Make 4.4.1 is unrelated and unchanged. The new supported-version declaration does not manufacture R 4.6.1 test evidence.

This record is a new file (no previous text). No existing published branch is updated; no merge or pull request is part of this change.
