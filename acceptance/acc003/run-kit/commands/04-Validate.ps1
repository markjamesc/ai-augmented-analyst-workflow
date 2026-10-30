. "$PSScriptRoot\Common.ps1"
Assert-WorkflowFiles
Run-R -Arguments @((Join-Path $Repo 'procedure-gate\procedure_gate.R'), 'validate', $Project)
Run-R -Arguments @((Join-Path $Repo 'workflow-gate\workflow_gate.R'), $Project)
Write-Output 'VALIDATION_PASS: may proceed to Finish.'
