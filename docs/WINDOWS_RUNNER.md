# Windows run helper

`tools/run_r_job.ps1 -Rscript C:\path\Rscript.exe -Script C:\run\reviewed.R -AttemptDirectory C:\run\attempt-NEW` runs a reviewed script synchronously, preserving script hash, start/finish UTC, coordinator PID, console and exit status. Use R 4.6.1 for live acceptance. Never reuse an attempt directory. No DB writes or system changes are authorized by this helper. The helper has not been tested on Windows in the local Linux environment.

The coordinator monitors process, memory and output progress; preserves every failed attempt; avoids launching duplicate work after disconnect; checks state before any retry (five-minute spacing, maximum three within authority). Detached scheduling, keep-awake and memory guards are not implemented here. Do not claim unattended execution guarantees. The script must read the locked source identity and use a clean project working directory; never rely on a partial mirror.

## D-27: environment inheritance and restoration

From the repository root:

```text
Rscript tools/run_restore.R ROOT REVIEWED_PROJECT_RESTORE_SCRIPT NEW_LIBRARY NEW_ATTEMPT
```

The reviewed project script must accept ROOT and NEW_LIBRARY as arguments and implement the frozen restoration specification. Adapt the actual project script explicitly; it was not available when this repository helper was written. The helper never invents package sources or installs arbitrary packages itself. It sets R_LIBS_USER/R_LIBS/R_LIBS_SITE in the parent before spawning, records actual child paths/packages and restores the parent's environment afterwards. It never relies on system2(env=). Each attempt/library must be new; retain failed attempts.

CHILD_CHECKS_PASS only establishes execution and library-isolation checks. Compare actual versions with the frozen environment specification and rerun output identity checks before issuing the methodology restore report. Linux local tests do not establish Windows behavior; CI now exercises R 4.6.1 on Ubuntu and Windows, and the owner's PC must verify the actual restore script.
