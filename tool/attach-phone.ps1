[CmdletBinding()]
param(
  [string]$DeviceId = '78KVB19C06011325',
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $ProjectRoot
$flutter = 'C:\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { $flutter = 'flutter' }

Write-Host "Attaching Flutter debugger to $DeviceId..." -ForegroundColor Cyan
& $flutter attach -d $DeviceId
exit $LASTEXITCODE
