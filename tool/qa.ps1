[CmdletBinding()]
param(
  [switch]$BuildDebug,
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $ProjectRoot

$flutter = 'C:\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { $flutter = 'flutter' }

function Invoke-Step([string]$Name, [scriptblock]$Command) {
  Write-Host "`n== $Name ==" -ForegroundColor Cyan
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE."
  }
  Write-Host "PASSED: $Name" -ForegroundColor Green
}

Invoke-Step 'Flutter analyze' { & $flutter --no-version-check analyze }
Invoke-Step 'Flutter tests' { & $flutter --no-version-check test }

if (Get-Command npm -ErrorAction SilentlyContinue) {
  Push-Location (Join-Path $ProjectRoot 'functions')
  try {
    Invoke-Step 'Cloud Functions TypeScript check' { npm run lint }
  } finally {
    Pop-Location
  }
} else {
  Write-Warning 'npm is not available; skipped Cloud Functions TypeScript check.'
}

if ($BuildDebug) {
  Invoke-Step 'Arm64 debug APK build' {
    & $flutter --no-version-check build apk --debug --target-platform android-arm64 --build-number=2003
  }
}

Write-Host "`nQA passed." -ForegroundColor Green
