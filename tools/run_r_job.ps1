param([Parameter(Mandatory=$true)][string]$Rscript,
      [Parameter(Mandatory=$true)][string]$Script,
      [Parameter(Mandatory=$true)][string]$AttemptDirectory)
$ErrorActionPreference = 'Stop'
if (Test-Path $AttemptDirectory) { throw 'Use a new attempt directory; retain all attempts.' }
New-Item -ItemType Directory -Path $AttemptDirectory | Out-Null
$record = @{ script = (Resolve-Path $Script).Path; sha256 = (Get-FileHash $Script -Algorithm SHA256).Hash.ToLower(); started_at_utc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'); coordinator_pid = $PID }
$record | ConvertTo-Json | Set-Content (Join-Path $AttemptDirectory 'start.json')
& $Rscript $Script *> (Join-Path $AttemptDirectory 'console.txt')
$code = $LASTEXITCODE
$record.exit_status = $code
$record.finished_at_utc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$record | ConvertTo-Json | Set-Content (Join-Path $AttemptDirectory 'exit.json')
exit $code
