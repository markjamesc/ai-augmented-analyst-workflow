# Windows run helper

`tools/run_r_job.ps1 -Rscript C:\path\Rscript.exe -Script C:\run\reviewed.R -AttemptDirectory C:\run\attempt-NEW` runs a reviewed script synchronously, preserving script hash, start/finish UTC, coordinator PID, console and exit status. Use R 4.6.1 for live acceptance. Never reuse an attempt directory. No DB writes or system changes are authorized by this helper. The helper has not been tested on Windows in the local Linux environment.

The coordinator monitors process, memory and output progress; preserves every failed attempt; avoids launching duplicate work after disconnect; checks state before any retry (five-minute spacing, maximum three within authority). Detached scheduling, keep-awake and memory guards are not implemented here. Do not claim unattended execution guarantees. The script must read the locked source identity and use a clean project working directory; never rely on a partial mirror.
