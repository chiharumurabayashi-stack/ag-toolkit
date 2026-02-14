param(
    [switch]$DryRun,
    [string]$EnvName = ".venv"
)

Write-Host "--- Antigravity Local Setup ---" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY RUN MODE] No changes will be applied." -ForegroundColor Yellow }

$CurrentPath = [System.IO.Directory]::GetCurrentDirectory()

# 1. venv Creation
Write-Host "Step 1: Creating Virtual Environment ($EnvName)..."
if (Test-Path "$CurrentPath\$EnvName") {
    Write-Host "Virtual environment already exists." -ForegroundColor Cyan
} else {
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run: python -m venv $EnvName"
    } else {
        try {
            python -m venv $EnvName
            Write-Host "Done." -ForegroundColor Green
        } catch {
            Write-Error "Failed to create venv."
            exit 1
        }
    }
}

# 2. Dependency Check
$ReqFile = "$CurrentPath\requirements.txt"
if (Test-Path $ReqFile) {
    Write-Host "Step 2: Installing dependencies from requirements.txt..."
    $PipPath = if ($IsWindows) { "$EnvName\Scripts\pip.exe" } else { "$EnvName/bin/pip" }
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run: $PipPath install -r requirements.txt"
    } else {
        & $PipPath install -r requirements.txt
    }
} else {
    Write-Host "Step 2: No requirements.txt found. Skipping." -ForegroundColor Yellow
}

# 3. Environment Template
$EnvTemplate = "$CurrentPath\.env.template"
if (-not (Test-Path "$CurrentPath\.env")) {
    Write-Host "Step 3: Creating .env from template..."
    if (Test-Path $EnvTemplate) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would copy .env.template to .env"
        } else {
            Copy-Item $EnvTemplate ".env"
            Write-Host ".env created. Please fill in your API keys." -ForegroundColor Green
        }
    } else {
        Write-Host "No .env.template found. Skipping." -ForegroundColor Yellow
    }
}

Write-Host "`nSetup process completed." -ForegroundColor Green
exit 0
