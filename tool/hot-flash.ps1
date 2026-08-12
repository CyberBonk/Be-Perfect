[CmdletBinding()]
param(
  [ValidateSet('STK', 'VOG')]
  [string]$Phone = 'STK'
)

$deviceIds = @{
  STK = '78KVB19C06011325'
  VOG = 'DUM7N19329006023'
}

$deviceId = $deviceIds[$Phone]
Write-Host "Attaching hot-reload session to $Phone ($deviceId)..." -ForegroundColor Cyan
Write-Host 'After attach: press r for hot reload, R for hot restart, q to end the session.' -ForegroundColor DarkCyan

$scriptPath = Join-Path $PSScriptRoot 'attach-phone.ps1'
& $scriptPath -DeviceId $deviceId
exit $LASTEXITCODE
