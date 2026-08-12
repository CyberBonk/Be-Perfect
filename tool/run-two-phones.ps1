[CmdletBinding()]
param(
  [string]$ControllerDeviceId = '78KVB19C06011325',
  [string]$ParticipantDeviceId = 'DUM7N19329006023',
  [switch]$UseFirebaseEmulators,
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $ProjectRoot
$flutter = 'C:\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { $flutter = 'flutter' }

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
  throw 'adb is not available on PATH.'
}

foreach ($deviceId in @($ControllerDeviceId, $ParticipantDeviceId)) {
  if (-not (adb devices | Select-String -Pattern "^$([regex]::Escape($deviceId))\s+device$")) {
    throw "Android device '$deviceId' is not connected or authorized."
  }
}

$flutterArgs = @('--no-version-check', 'run', '--no-pub')
if ($UseFirebaseEmulators) {
  foreach ($port in @(9099, 8080, 9000, 5001)) {
    adb -s $ControllerDeviceId reverse "tcp:$port" "tcp:$port" | Out-Null
    adb -s $ParticipantDeviceId reverse "tcp:$port" "tcp:$port" | Out-Null
  }
  $flutterArgs += '--dart-define=USE_FIREBASE_EMULATORS=true'
  $flutterArgs += '--dart-define=PHYSICAL_PHONE_EMULATOR=true'
}

Write-Host "Starting Controller on $ControllerDeviceId and Participant on $ParticipantDeviceId." -ForegroundColor Cyan
Write-Host 'Use the two Flutter windows for logs, hot reload, and clean shutdown.'

$controllerArgs = @('--device-id', $ControllerDeviceId) + $flutterArgs
$participantArgs = @('--device-id', $ParticipantDeviceId) + $flutterArgs

Start-Process -FilePath $flutter -ArgumentList $controllerArgs
Start-Process -FilePath $flutter -ArgumentList $participantArgs
