. "$PSScriptRoot\Common.ps1"
Run-R -Arguments @((Join-Path $Repo 'procedure-gate\procedure_gate.R'), 'finish', $Project)
Write-Output 'FINISH_RECORDED'
