[CmdletBinding()]
param(
  [string]$DeviceId = 'DUM7N19329006023',
  [switch]$UseFirebaseEmulators,
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $ProjectRoot
$flutter = 'C:\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { $flutter = 'flutter' }

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
  throw 'adb is not available on PATH. Add the Android SDK platform-tools directory first.'
}

$device = adb devices | Select-String -Pattern "^$([regex]::Escape($DeviceId))\s+device$"
if (-not $device) {
  throw "Android device '$DeviceId' is not connected or not authorized. Run: adb devices"
}

$args = @('-d', $DeviceId)
if ($UseFirebaseEmulators) {
  adb reverse tcp:9099 tcp:9099 | Out-Null
  adb reverse tcp:8080 tcp:8080 | Out-Null
  adb reverse tcp:9000 tcp:9000 | Out-Null
  adb reverse tcp:5001 tcp:5001 | Out-Null
  $args += '--dart-define=USE_FIREBASE_EMULATORS=true'
  $args += '--dart-define=PHYSICAL_PHONE_EMULATOR=true'
}

Write-Host "Starting Timer Be Perfect on $DeviceId..." -ForegroundColor Cyan
& $flutter run @args
exit $LASTEXITCODE
