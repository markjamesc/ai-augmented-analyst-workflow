. "$PSScriptRoot\Common.ps1"
Assert-WorkflowFiles
Run-R -Arguments @((Join-Path $Repo 'tools\preflight.R'), '--install')
Write-Output 'PREFLIGHT_COMPLETE'
