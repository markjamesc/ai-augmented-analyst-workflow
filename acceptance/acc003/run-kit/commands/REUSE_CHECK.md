# What can be reused from early-week rehearsal

The exact candidate and unchanged pretest may be reused. `03-Lock.ps1` calls reuse_pretest.R, which compares checker/code/schema hashes, R/package/environment identity, locked comparison configuration and fixture/oracle hashes. It also checks the pretest's evidence files. A mismatch requires affected pretests, not a manual PASS override.

The live run must create its own owner approval, AI replies, independent builders, execution outputs, Finish reviews and certificate. Do not reuse offline simulated approval files or reference builders. Runtime variables merely changing installation paths are not analytical changes; verify artifact bytes. Keep all test results honest about the version/platform actually run.

If the approved Design review changes a substantive comparator/interface rule, first settle the owner decision and ask ChatGPT for the affected pretest adjustment. Do not reinterpret the fixture or invent a new schema while running.
