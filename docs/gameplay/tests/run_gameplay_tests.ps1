param([string]$Godot = '',[switch]$Render)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'run_acceptance.ps1') -Godot $Godot -Render:$Render -Suite gameplay