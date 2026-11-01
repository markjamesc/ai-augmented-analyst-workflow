# Live-finding repair verification

Base: 088fffe14356a2537fb8642b6cb2dbd389675716. New procedure: 2.2-livefix-v1. Local runtime: R 4.4.3 on Linux; jsonschema 4.23.0. Local results do not establish R 4.6.1 or Windows behavior. CI is configured for R 4.6.1 on both Ubuntu and Windows; its exact-commit results must be checked separately.

All eight release suites exited zero:

| Suite | Result |
|---|---|
| Workflow Gate | baseline/refusal checks and 17 forward defects passed |
| Procedure Gate | five-stage synthetic certification, illegal transition/tamper checks, 23 refused amendments; explicit NOT_RUN result tested |
| Methodology | 28 contract defects plus keyed comparison, replay, metamorphic fault and successor/retry checks |
| Local acceptance | 46/46 |
| Schema compatibility | 18/18 |
| Earlier remediation regression | 21/21 |
| Python helper regression | 11/11 methods, including subcases |
| Live-finding regression | 31/31 |

The new 31 cases cover D-22 output/nullable schema compatibility; exact missingness flags, keys and tokens; null-versus-zero, Infinity/NaN rejection; all-missing rows; immutable candidate snapshots and nested stale-reference rejection at completion; retained capture evidence; Windows path canonicalization/traversal; SQL N/A with mandatory source fidelity; actual child environment inheritance and parent restoration on success/failure; and the actual new-library restore wrapper. Existing suite fixtures are explicitly synthetic, not live owner approvals or AI provenance.

Development failures retained under livefix-evidence:

- attempt1-livefix.log: environment helper restoration indexed an unnamed single-variable Sys.getenv result; fixed by explicitly naming saved values.
- final-livefix.log: 30/31, new-library wrapper failed. restore-debug-failure.log records the local child crash inside installed.packages(); the probe now reads installed package DESCRIPTION metadata without loading the tools namespace. Site-library inheritance is explicitly set to the new library. The actual wrapper passes in release-livefix.log. The local crash is not represented as proof of the original Windows D-27 cause.
- attempt1-procedure.log: exited 1 during a development period in which controlling sources were edited. This is not accepted verification evidence. Subsequent fixed-source final-procedure.log and release-procedure.log both passed.
- Expected negative-case exit-1 warnings remain visible in passing suite logs. These demonstrate refusal and are not hidden suite failures.

Release logs are named release-*.log; SOURCE_MANIFEST.json identifies implementation/test files and SHA256SUMS.txt covers the retained evidence directory. Historical remediation-evidence and original run evidence were not changed.

The exact project restore script and actual CP-ledger schema were not supplied with the coordination summary. Repository behavior is tested; project-specific compatibility/adaptation and the successor's actual three-AI acceptance remain outstanding. No certification or merge is implied by these local tests.
