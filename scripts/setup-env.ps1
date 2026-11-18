# Creates Backend/backend/.env from .env.example with freshly generated secrets.
# Usage (Windows PowerShell, from anywhere):
#   powershell -ExecutionPolicy Bypass -File scripts\setup-env.ps1          # refuses to touch an existing .env
#   powershell -ExecutionPolicy Bypass -File scripts\setup-env.ps1 -Force   # backs up the existing .env, then recreates it
param([switch]$Force)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$example = Join-Path $root 'Backend\backend\.env.example'
$envFile = Join-Path $root 'Backend\backend\.env'

if (-not (Test-Path $example)) {
    Write-Error "Cannot find $example"
    exit 1
}

if (Test-Path $envFile) {
    if (-not $Force) {
        Write-Output 'Backend/backend/.env already exists, left unchanged.'
        Write-Output 'Run with -Force to back it up and create a new one.'
        exit 0
    }
    $backup = "$envFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $envFile $backup
    Write-Output "Backed up the existing .env to $backup"
}

function New-RandomBase64([int]$bytes) {
    $buffer = New-Object byte[] $bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($buffer)
    $rng.Dispose()
    [Convert]::ToBase64String($buffer)
}

$jwtSecret = New-RandomBase64 48
$tokenKey = New-RandomBase64 32

# OAuth placeholders become empty so the sign-in buttons stay hidden until real values are filled in.
$lines = Get-Content $example -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^JWT_SECRET=') { "JWT_SECRET=$jwtSecret" }
    elseif ($_ -match '^GITHUB_TOKEN_KEY=') { "GITHUB_TOKEN_KEY=$tokenKey" }
    elseif ($_ -match '^(GITHUB_CLIENT_ID|GITHUB_CLIENT_SECRET|GOOGLE_CLIENT_ID|GOOGLE_CLIENT_SECRET)=your_') { "$($Matches[1])=" }
    else { $_ }
}

# UTF-8 without BOM and LF endings, so Spring Boot reads the first key correctly.
[System.IO.File]::WriteAllText($envFile, (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding $false))

Write-Output 'Created Backend/backend/.env with a new JWT_SECRET and GITHUB_TOKEN_KEY.'
Write-Output ''
Write-Output 'Optional, for "Continue with GitHub / Google": fill in GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET,'
Write-Output 'GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in that file (see README), then restart the backend.'
Write-Output 'The file is gitignored; never commit it.'
