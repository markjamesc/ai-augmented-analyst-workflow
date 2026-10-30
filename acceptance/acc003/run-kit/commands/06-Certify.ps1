. "$PSScriptRoot\Common.ps1"
Assert-WorkflowFiles
Run-R -Arguments @((Join-Path $Repo 'procedure-gate\procedure_gate.R'), 'finalize', $Project)
Write-Output 'CERTIFIED: send FINAL_REPORT.md with actual evidence. Publishing is separate.'
