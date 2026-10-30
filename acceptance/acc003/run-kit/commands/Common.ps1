$ErrorActionPreference = 'Stop'
$Root = 'C:\ai_workflow_acceptance\ACC003'
$Repo = Join-Path $Root 'workflow'
$Kit = Join-Path $Root 'run-kit'
$Project = Join-Path $Root 'runs\ACC003'
$R = 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe'
if (-not (Test-Path $R)) { throw 'R 4.6.1 executable not found. Correct only this invocation path to the installed R 4.6.1; do not change analytical files.' }
New-Item -ItemType Directory -Force (Join-Path $Root 'logs') | Out-Null
function Run-R {
    param([string[]]$Arguments, [int]$ExpectedExit = 0)
    $Log = Join-Path $Root ('logs\R-' + [guid]::NewGuid().ToString() + '.txt')
    $PreviousErrorActionPreference = $ErrorActionPreference
    $Code = $null
    try {
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = $null
        & $R --vanilla @Arguments 2>&1 | Tee-Object -FilePath $Log
        $Code = $global:LASTEXITCODE
    } finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }
    if ($null -eq $Code) { throw "R did not return an exit code. Preserve $Log; do not certify." }
    if ($Code -ne $ExpectedExit) { throw "R exit $Code (expected $ExpectedExit). Preserve $Log; use DECISIONS.md. Do not certify." }
}
function Assert-WorkflowFiles {
    foreach ($Line in Get-Content (Join-Path $Repo 'WORKFLOW_FILES.sha256')) {
        if ($Line -match '^([a-f0-9]{64})  (.+)$') {
            $Expected = $Matches[1]; $Relative = $Matches[2]
            $Actual = (Get-FileHash -Algorithm SHA256 (Join-Path $Repo $Relative)).Hash.ToLower()
            if ($Actual -ne $Expected) { throw "Workflow byte mismatch: $Relative. Restore from verified archive." }
        } else { throw 'Malformed workflow file manifest' }
    }
}
