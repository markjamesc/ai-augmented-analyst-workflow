# Successor compatibility repairs, 2026-10-18

Base: beede13c8cc13bec3a05d6a709dcca54b0b6c70e. Original run evidence and published branches remain unchanged.

Changes: methodology/contracts.R and schema.json support enumerated missing statuses without conflating reasons; singular form remains compatible and ambiguous forms fail. examples/acceptance-successor contains the project mapping, original-byte ledger regression inputs, stricter output parser adaptation and fresh-library restore adapter. CI adds the new suite. tools/test_acceptance.py writes exact UTF-8 bytes so its hash fixture does not depend on Windows newline translation.

Local R 4.4.3 Linux: all nine suites exited zero. Workflow: known PASS/refusal and 17 defects; Procedure: complete synthetic flow and amendment/tamper checks; Methodology: 28 defects plus comparison/replay/successor tests; Acceptance 46/46; Schema 18/18; prior Remediation 21/21; Livefix 31/31; new Successor 21/21; Python 11 unittest methods. Logs in successor-evidence. No simulated test establishes actual three-AI compliance.

Development failures retained: first successor run hit a test expression-selection error (fixed by requiring a symbol assignment); second found R partial-name matching made missing_value resolve to missing_values, rejecting valid enum policies (fixed with exact [[ access). One initial invocation from the wrong working directory failed before loading the suite; then rerun from repository root. A temporary schema-edit generator failed before writing schema; corrected before testing. These are not accepted release runs.

The predecessor's R 4.6.1 CI 39164964769 completed Linux SUCCESS, Windows FAILURE at Helper regression. Detailed annotations were unavailable through the connector. Code inspection found test put() hashed LF strings while write_text translated them to CRLF on Windows; exact byte writes correct that concrete defect. The new Windows CI must establish the outcome; do not claim the historical failure passed.

The restore adapter was syntax-checked, not run against the actual project. Frozen restore-spec.txt and original attempt-2 restore_report.json remain outstanding. CRAN availability of frozen versions is not guaranteed; mismatch fails rather than changing the spec. No project restoration, actual Windows execution or successor live acceptance is claimed. See examples/acceptance-successor/README.md for installation, restart, reuse and review requirements.
