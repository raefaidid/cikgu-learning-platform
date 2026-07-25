#Requires -Version 5.1
<#
    One-command setup for the Cikgu database on Windows.

    Usage (from the repository root, in PowerShell):
        powershell -ExecutionPolicy Bypass -File scripts\setup.ps1

    Starts the Oracle 23ai Free container, waits for it to become healthy,
    and installs the CIKGU schema with seed data.
#>
[CmdletBinding()]
param(
    [switch]$SkipSchema
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Fail($msg)       { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# --- 1. Docker present and running ---------------------------------------
Write-Step 'Checking Docker'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fail "Docker is not installed. Install Docker Desktop from https://www.docker.com/products/docker-desktop/ and run this script again."
}
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Fail "Docker is installed but not running. Start Docker Desktop, wait for it to say 'Engine running', then re-run this script."
}
Write-Ok 'Docker is running.'

# --- 2. .env --------------------------------------------------------------
Write-Step 'Checking .env'
if (-not (Test-Path '.env')) {
    Copy-Item '.env.example' '.env'
    Write-Ok 'Created .env from .env.example.'
} else {
    Write-Ok '.env already exists.'
}

$envVars = @{}
Get-Content '.env' | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') { $envVars[$Matches[1]] = $Matches[2] }
}
$OraclePwd     = $envVars['ORACLE_PWD']
$ContainerName = if ($envVars['ORACLE_CONTAINER_NAME']) { $envVars['ORACLE_CONTAINER_NAME'] } else { 'cikgu-oracle' }
$HostPort      = if ($envVars['ORACLE_HOST_PORT']) { $envVars['ORACLE_HOST_PORT'] } else { '1521' }
if (-not $OraclePwd) { Fail 'ORACLE_PWD is not set in .env' }

# --- 3. Port availability -------------------------------------------------
$inUse = Get-NetTCPConnection -LocalPort $HostPort -State Listen -ErrorAction SilentlyContinue
if ($inUse) {
    $owner = docker ps --filter "publish=$HostPort" --format '{{.Names}}' 2>$null
    if ($owner -and $owner -ne $ContainerName) {
        Fail "Port $HostPort is already used by container '$owner'. Stop it (docker stop $owner) or set ORACLE_HOST_PORT to a free port in .env."
    }
}

# --- 4. Start the database -----------------------------------------------
Write-Step 'Starting Oracle 23ai Free (first run downloads ~2 GB, be patient)'
docker compose up -d
if ($LASTEXITCODE -ne 0) { Fail 'docker compose up failed. See the output above.' }

# --- 5. Wait for healthy --------------------------------------------------
Write-Step 'Waiting for the database to become healthy (first start takes 3-10 minutes)'
$deadline = (Get-Date).AddMinutes(15)
$status = ''
while ((Get-Date) -lt $deadline) {
    $status = (docker inspect --format '{{.State.Health.Status}}' $ContainerName 2>$null)
    if ($status -eq 'healthy') { break }
    if ($status -eq 'unhealthy') {
        Fail "Container reported unhealthy. Check logs with: docker logs $ContainerName"
    }
    Write-Host '    still starting...' -ForegroundColor DarkGray
    Start-Sleep -Seconds 15
}
if ($status -ne 'healthy') {
    Fail "Timed out waiting for the database. Check logs with: docker logs $ContainerName"
}
Write-Ok 'Database is healthy.'

# --- 6. Install the schema ------------------------------------------------
if ($SkipSchema) {
    Write-Ok 'Skipping schema install (-SkipSchema).'
} else {
    Write-Step 'Installing the CIKGU schema'
    # -L matters: without it sqlplus exits 0 even when the logon is refused,
    # which would let a failed install report success.
    $connect = "system/$OraclePwd@//localhost:1521/FREEPDB1"
    docker compose exec -T oracle sqlplus -S -L $connect '@cikgu_install.sql'
    if ($LASTEXITCODE -ne 0) {
        Fail "Schema install failed. If the error above is ORA-01017, the ORACLE_PWD in .env does not match the password the container was created with. Run 'docker compose down -v' to wipe it and start over."
    }

    Write-Step 'Verifying the install'
    $verify = 'SET HEADING OFF FEEDBACK OFF PAGESIZE 0', 'SELECT count(*) FROM app_user;', 'EXIT'
    $rows = ($verify | docker compose exec -T oracle sqlplus -S -L 'cikgu/Cikgu_123@//localhost:1521/FREEPDB1') -join ''
    $rows = $rows.Trim()
    if ($LASTEXITCODE -ne 0 -or $rows -notmatch '^\d+$' -or [int]$rows -eq 0) {
        Fail "Schema verification failed (app_user returned '$rows'). Re-run this script."
    }
    Write-Ok "CIKGU schema installed and populated ($rows users seeded)."
}

Write-Host ''
Write-Host 'Database is ready.' -ForegroundColor Green
Write-Host 'Next, run the web app:' -ForegroundColor Green
Write-Host ''
Write-Host '    cd src\cikgu-app-django'
Write-Host '    python -m venv .venv'
Write-Host '    .venv\Scripts\Activate.ps1'
Write-Host '    pip install -r requirements.txt'
Write-Host '    python manage.py runserver'
Write-Host ''
if ($HostPort -ne '1521') {
    Write-Host "NOTE: you changed the port, so set it for the app first:" -ForegroundColor Yellow
    Write-Host "    `$env:CIKGU_DB_PORT = '$HostPort'"
    Write-Host ''
}
Write-Host 'Then open http://localhost:8000 and log in as halim.abdullah@cikgu.my / password123'
