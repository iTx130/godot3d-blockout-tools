param([Parameter(Mandatory=$true)][string]$Godot,[ValidateSet('All','Shape','Gameplay')][string]$Suite = 'All')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$isolatedRoot = Join-Path ([IO.Path]::GetTempPath()) ('godot3d-blockout-cold-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $isolatedRoot | Out-Null
New-Item -ItemType Directory -Path (Join-Path $isolatedRoot 'addons') | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'addons/blockout_tools') -Destination (Join-Path $isolatedRoot 'addons/blockout_tools') -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'demo') -Destination (Join-Path $isolatedRoot 'demo') -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'project.godot') -Destination (Join-Path $isolatedRoot 'project.godot')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'cold_probe.gd') -Destination (Join-Path $isolatedRoot 'cold_probe.gd')
if (Test-Path -LiteralPath (Join-Path $isolatedRoot '.godot')) { throw 'Cold project unexpectedly contains an import cache' }
$evidence = Join-Path $PSScriptRoot 'evidence'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
$logPrefix = if ($Suite -eq 'All') { '' } else { $Suite.ToLowerInvariant() + '-' }
foreach ($stage in @(@{Name='cold-import';Arguments=@('--headless','--editor','--import','--quit')},@{Name='cold-probe';Arguments=@('--headless','--script','cold_probe.gd','--',('--suite=' + $Suite.ToLowerInvariant()))})) {
    $log = Join-Path $evidence ($logPrefix + $stage.Name + '.log')
    $launchArgs = @('--path',$isolatedRoot,'--log-file',$log) + $stage.Arguments
    $output = & $Godot @launchArgs 2>&1
    $exitCode = $LASTEXITCODE
    $errors = @(Select-String -LiteralPath $log -Pattern '^ERROR:|^SCRIPT ERROR:|^SHADER ERROR:')
    if ($exitCode -ne 0 -or $errors.Count -gt 0) { $output | Write-Output; throw ('Cold installation failed: ' + $stage.Name) }
}
$reportPath = Join-Path $isolatedRoot 'cold-result.json'
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if ($report.passed -ne $report.tested -or @($report.failures).Count -gt 0) { throw 'Cold probe contains failed checks' }
Copy-Item -LiteralPath $reportPath -Destination (Join-Path $evidence ($logPrefix + 'cold-install.json'))
Write-Host ('COLD INSTALL ({0}): {1}/{2}' -f $Suite,$report.passed,$report.tested)
