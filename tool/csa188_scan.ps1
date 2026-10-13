param(
    [Parameter(Mandatory=$true)][string]$GitleaksPath,
    [Parameter(Mandatory=$true)][ValidateSet('history','assets')][string]$Mode,
    [string]$AssetPath = 'build/web',
    [string]$RepositoryPath = ''
)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryPath) { $RepositoryPath = Split-Path -Parent $PSScriptRoot }
$taskScanner = (Resolve-Path -LiteralPath $GitleaksPath).Path
$taskRoot = (Resolve-Path -LiteralPath $RepositoryPath).Path
$taskReport = Join-Path ([System.IO.Path]::GetTempPath()) ('csa188-' + [guid]::NewGuid().ToString() + '.json')
try {
    if ($Mode -eq 'assets') {
        $taskAssets = (Resolve-Path -LiteralPath (Join-Path $taskRoot $AssetPath)).Path
        if (-not (Test-Path -LiteralPath (Join-Path $taskAssets 'main.dart.js'))) { throw 'Release JavaScript asset is missing; build not verified.' }
        & $taskScanner dir $taskAssets --redact=100 --no-banner --report-format json --report-path $taskReport --exit-code 1
    } else {
        & $taskScanner git $taskRoot --redact=100 --no-banner '--log-opts=--all' --report-format json --report-path $taskReport --exit-code 1
    }
    $taskResult = $LASTEXITCODE
    # Report only metadata. Never print Match/Secret or complete JSON findings.
    $taskFindings = @(Get-Content -LiteralPath $taskReport -Raw | ConvertFrom-Json)
    foreach ($taskFinding in $taskFindings) {
        if ($null -eq $taskFinding -or -not $taskFinding.RuleID) { continue }
        [pscustomobject]@{ Rule=$taskFinding.RuleID; File=$taskFinding.File; Line=$taskFinding.StartLine; Commit=$taskFinding.Commit } | ConvertTo-Json -Compress | Write-Output
    }
    if ($taskResult -ne 0) { throw "Gitleaks $Mode scan needs review (exit $taskResult)." }
    Write-Output "PASS: Gitleaks $Mode scan, no credential findings. This is pattern coverage, not a proof of absence."
} finally {
    if (Test-Path -LiteralPath $taskReport) { Remove-Item -LiteralPath $taskReport }
}
