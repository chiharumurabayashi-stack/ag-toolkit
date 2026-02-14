param(
    [switch]$DryRun,
    [switch]$Global,
    [string]$EnvName = ".venv"
)

Write-Host "--- Antigravity Local Setup ---" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY RUN MODE] No changes will be applied." -ForegroundColor Yellow }
if ($Global) { Write-Host "[GLOBAL MODE] Dependencies will be installed to system Python." -ForegroundColor Yellow }

$CurrentPath = [System.IO.Directory]::GetCurrentDirectory()

# 1. Environment Choice
$IsWindows = $PSVersionTable.Platform -match "Win" -or $env:OS -like "*Windows*"

if ($Global) {
    Write-Host "Step 1: Skipping Virtual Environment (Global mode enabled)." -ForegroundColor Cyan
    $PipCommand = "pip"
}
else {
    Write-Host "Step 1: Managing Virtual Environment ($EnvName)..."
    if (Test-Path "$CurrentPath\$EnvName") {
        Write-Host "Virtual environment already exists." -ForegroundColor Cyan
    }
    else {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would run: python -m venv $EnvName"
        }
        else {
            try {
                python -m venv $EnvName
                Write-Host "Done." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to create venv."
                exit 1
            }
        }
    }
    $PipCommand = if ($IsWindows) { Join-Path $CurrentPath "$EnvName\Scripts\pip.exe" } else { Join-Path $CurrentPath "$EnvName/bin/pip" }
}

# 2. Dependency Check
$ReqFile = "$CurrentPath\requirements.txt"
if (Test-Path $ReqFile) {
    Write-Host "Step 2: Installing dependencies from requirements.txt..."
    
    $InstallArgs = if ($Global) { @("install", "--user", "-r", $ReqFile) } else { @("install", "-r", $ReqFile) }
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run: $PipCommand $($InstallArgs -join ' ')"
    }
    else {
        & $PipCommand @InstallArgs
    }
}
else {
    Write-Host "Step 2: No requirements.txt found. Skipping." -ForegroundColor Yellow
}

# 3. Environment Template
$EnvTemplate = "$CurrentPath\.env.template"
if (-not (Test-Path "$CurrentPath\.env")) {
    Write-Host "Step 3: Creating .env from template..."
    if (Test-Path $EnvTemplate) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would copy .env.template to .env"
        }
        else {
            Copy-Item $EnvTemplate ".env"
            Write-Host ".env created. Please fill in your API keys." -ForegroundColor Green
        }
    }
    else {
        Write-Host "No .env.template found. Skipping." -ForegroundColor Yellow
    }
}

# 4. Update State Status
if (-not $DryRun) {
    $LatestFile = Join-Path $CurrentPath "state\latest.json"
    if (Test-Path $LatestFile) {
        try {
            $State = Get-Content $LatestFile | ConvertFrom-Json
            $State.SetupMode = if ($Global) { "Global" } else { "Venv" }
            $State | ConvertTo-Json -Depth 5 | Out-File $LatestFile -Encoding UTF8
        }
        catch {
            Write-Host "Warning: Could not update state with SetupMode." -ForegroundColor Yellow
        }
    }
}

Write-Host "`nSetup process completed." -ForegroundColor Green
exit 0
