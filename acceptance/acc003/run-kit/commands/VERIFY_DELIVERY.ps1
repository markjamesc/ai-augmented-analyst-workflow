# Run in the folder holding the six downloaded files, before extraction.
$ErrorActionPreference = 'Stop'
foreach ($Line in Get-Content '.\SHA256SUMS.txt') {
    if ($Line -match '^([a-f0-9]{64})  (.+)$') {
        $Expected = $Matches[1]; $Name = $Matches[2]
        $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Name).Hash.ToLower()
        if ($Actual -ne $Expected) { throw "Delivery hash mismatch: $Name" }
        Write-Output "OK $Name"
    } else { throw 'Malformed SHA256SUMS entry' }
}
$Root = 'C:\ai_workflow_acceptance\ACC003'
if ((Test-Path "$Root\workflow") -or (Test-Path "$Root\run-kit")) { throw 'Existing installation: verify it; do not overwrite. New paths or byte-identical restoration only.' }
New-Item -ItemType Directory -Force $Root | Out-Null
Expand-Archive -LiteralPath '.\ACC003_workflow.zip' -DestinationPath "$Root\workflow"
Expand-Archive -LiteralPath '.\ACC003_RUN_KIT.zip' -DestinationPath "$Root\run-kit"
Write-Output 'DELIVERY_VERIFIED_AND_EXTRACTED'
