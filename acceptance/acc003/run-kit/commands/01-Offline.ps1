. "$PSScriptRoot\Common.ps1"
Assert-WorkflowFiles
$Evidence = Join-Path $Root ('rehearsal\tests-' + [guid]::NewGuid().ToString())
Run-R -Arguments @((Join-Path $Repo 'tools\run_tests.R'), $Repo, $Evidence)
$Pretest = Get-ChildItem -Path $Evidence -Recurse -Filter 'pretest.json' | Select-Object -First 1
if (-not $Pretest) { throw 'Offline pretest evidence missing' }
$Pretest.DirectoryName | Set-Content (Join-Path $Root 'offline_pretest_location.txt')
Write-Output "OFFLINE_COMPLETE: $Evidence"
