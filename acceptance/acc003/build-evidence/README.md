# Local build evidence

Actual execution: Linux R 4.3.3, jsonlite 1.8.8, digest 0.6.34, DBI 1.2.2, RSQLite 2.3.4. This is compatibility/offline evidence, not Windows R 4.6.1 or live-AI acceptance. Unzip local-test-evidence.zip to inspect logs, reports, commands and generated tables; paths in archived reports identify the original build host.

The final authoritative local test set is release-tests: all five suites pass, including real native Workflow Gate/finalize calls and a restored passing offline state. Approval/reviewer records in rehearsals are explicitly simulated and cannot certify a live run.

Retained earlier failures: rehearsal-attempt1 exposed empty JSON-array comparison; full-tests-attempt2 exposed an overstrict trailing-newline check on a derived specification (removed); final-tests exposed a test assertion rejecting trailing space in valid CLI PASS output (trimmed in the test). Earlier passing attempts precede final refinements. Never reuse these offline certificates, reference builders or simulated approvals as live evidence.

Additional smoke check: prepare.R live followed by reuse_pretest.R succeeded on a fresh project with unchanged checker/config/environment. No live approvals or certification were fabricated.
