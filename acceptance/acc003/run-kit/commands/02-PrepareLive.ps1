. "$PSScriptRoot\Common.ps1"
Assert-WorkflowFiles
if (Test-Path $Project) { throw 'Existing live project: resume its recorded state; do not overwrite or prepare again.' }
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\prepare.R'), $Repo, $Project, 'live')
Write-Output 'LIVE_PROJECT_PREPARED: send S1-S3 prompts before owner lock.'
