. "$PSScriptRoot\Common.ps1"
Assert-WorkflowFiles
Run-R -Arguments @((Join-Path $Repo 'procedure-gate\procedure_gate.R'), 'lock', $Project)
$Pretest = (Get-Content (Join-Path $Root 'offline_pretest_location.txt') -Raw).Trim()
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\reuse_pretest.R'), $Repo, $Project, $Pretest)
Write-Output 'LOCK_AND_PRETEST_COMPLETE'
