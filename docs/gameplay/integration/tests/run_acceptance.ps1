param([string]$Godot = '',[switch]$Render,[ValidateSet('All','Shape','Gameplay')][string]$Suite = 'All')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (!$Godot) {
    foreach ($candidate in @($env:GODOT_BIN,'godot','godot4','D:/workspace/app/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')) {
        if (!$candidate) { continue }
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { $Godot = $command.Source; break }
    }
}
if (!$Godot -or !(Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Set GODOT_BIN or pass -Godot with the Godot console executable path.' }
$evidence = Join-Path $PSScriptRoot 'evidence'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
$results = [Collections.Generic.List[object]]::new()
$runShape = $Suite -in @('All','Shape')
$runGameplay = $Suite -in @('All','Gameplay')
$reportName = if ($Suite -eq 'All') { 'acceptance-run.json' } else { $Suite.ToLowerInvariant() + '-acceptance-run.json' }
$logPrefix = if ($Suite -eq 'All') { '' } else { $Suite.ToLowerInvariant() + '-' }
Write-Host ('Acceptance suite: ' + $Suite)
function Invoke-GodotCheck([string]$Name,[string[]]$Arguments) {
    $log = Join-Path $evidence ($logPrefix + $Name + '.log')
    $launchArgs = @('--path',$projectRoot,'--log-file',$log) + $Arguments
    $output = & $Godot @launchArgs 2>&1
    $exitCode = $LASTEXITCODE
    $errors = @(Select-String -LiteralPath $log -Pattern '^ERROR:|^SCRIPT ERROR:|^SHADER ERROR:' | ForEach-Object { $_.Line })
    $passed = $exitCode -eq 0 -and $errors.Count -eq 0
    $results.Add([pscustomobject]@{step=$Name;passed=$passed;exit_code=$exitCode;errors=$errors})
    if (!$passed) { $output | Write-Output; throw ('Acceptance failed: ' + $Name) }
    $output | Where-Object { $_ -match 'FUNCTIONAL:|WINDOW GIZMO:|AXIS GIZMO:|NATIVE GEOMETRY:|GAMEPLAY GEOMETRY:|DOCK SMOKE:|MATERIAL INSPECTOR:|GPU RENDER:|GPU GRID:|PLAYER RUNTIME:|PLAYER EDITOR:|PLAYER VIEW RENDER:|SPAWN RUNTIME:|SPAWN EDITOR:' } | ForEach-Object { Write-Host $_ }
    Write-Host ($Name + ': PASS')
}
function Invoke-ScriptCheck([string]$Name,[scriptblock]$Action) {
    try {
        & $Action
        $results.Add([pscustomobject]@{step=$Name;passed=$true;exit_code=0;errors=@()})
    } catch {
        $results.Add([pscustomobject]@{step=$Name;passed=$false;exit_code=1;errors=@($_.Exception.Message)})
        throw
    }
}
$failure = $null
try {
    Invoke-GodotCheck 'godot-import' @('--headless','--editor','--import','--quit')
    Invoke-ScriptCheck 'source-audit' { & (Join-Path $PSScriptRoot 'audit_sources.ps1') }
    if ($runShape) {
        Invoke-GodotCheck 'godot-native-geometry' @('--headless','--script','tests/native_geometry.gd')
        Invoke-GodotCheck 'godot-functional' @('--headless','--script','tests/functional.gd')
        Invoke-GodotCheck 'godot-window-gizmo' @('--headless','--editor','tests/window_gizmo.tscn','--','--run-window-gizmo-tests')
        Invoke-GodotCheck 'godot-axis-gizmo' @('--headless','--editor','tests/axis_gizmo.tscn','--','--run-axis-gizmo-tests')
        Invoke-GodotCheck 'godot-material-inspector' @('--headless','--script','tests/material_inspector.gd')
    }
    Invoke-GodotCheck 'godot-dock' @('--headless','--script','tests/dock_smoke.gd','--',('--suite=' + $Suite.ToLowerInvariant()))
    if ($runGameplay) {
        Invoke-GodotCheck 'godot-gameplay-geometry' @('--headless','--script','tests/gameplay_geometry.gd')
        # Mouse capture requires a real window; the headless display driver ignores it.
        Invoke-GodotCheck 'godot-player-runtime' @('--rendering-method','gl_compatibility','--script','tests/player_runtime.gd')
        Invoke-GodotCheck 'godot-player-editor' @('--headless','--editor','tests/player_editor.tscn','--','--run-player-editor-tests')
        Invoke-GodotCheck 'godot-spawn-runtime' @('--rendering-method','gl_compatibility','--script','tests/spawn_runtime.gd')
        Invoke-GodotCheck 'godot-spawn-editor' @('--headless','--editor','tests/spawn_editor.tscn','--','--run-spawn-editor-tests')
    }
    Invoke-ScriptCheck 'cold-install' { & (Join-Path $PSScriptRoot 'cold_install.ps1') -Godot $Godot -Suite $Suite }
    if ($Render -and $runShape) {
        Invoke-GodotCheck 'godot-render' @('--rendering-method','gl_compatibility','--script','tests/render_smoke.gd')
        Invoke-GodotCheck 'godot-grid-render' @('--rendering-method','gl_compatibility','--script','tests/grid_render.gd')
    }
    if ($Render -and $runGameplay) {
        Invoke-GodotCheck 'godot-spawn-render' @('--rendering-method','gl_compatibility','--editor','tests/spawn_editor.tscn','--','--run-spawn-editor-tests','--render-spawn')
        Invoke-GodotCheck 'godot-player-views' @('--rendering-method','gl_compatibility','--script','tests/player_views_render.gd')
    }
} catch { $failure = $_.Exception.Message }
$expectedSteps = if ($Suite -eq 'All') { 14 } else { 9 }
if ($Render) { $expectedSteps += $(if ($Suite -eq 'All') { 4 } else { 2 }) }
$passed = !$failure -and $results.Count -eq $expectedSteps -and @($results | Where-Object { !$_.passed }).Count -eq 0
$report = [pscustomobject]@{suite=$Suite;time=(Get-Date).ToString('o');godot=$Godot;passed=$passed;render_requested=[bool]$Render;steps=@($results);failure=$failure}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidence $reportName) -Encoding utf8
if (!$passed) { throw ('Acceptance failed. ' + $failure + ' See tests/evidence/' + $reportName + '.') }
Write-Host 'All requested acceptance checks passed.'
