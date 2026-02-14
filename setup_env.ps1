param(
    [switch]$DryRun,
    [switch]$Global,
    [string]$EnvName = ".venv"
)

Write-Host "--- Antigravity Local Setup ---" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY RUN MODE] No changes will be applied." -ForegroundColor Yellow }
if ($Global) { Write-Host "[GLOBAL MODE] Dependencies will be installed to system Python." -ForegroundColor Yellow }

$CurrentPath = [System.IO.Directory]::GetCurrentDirectory()

# 0. Python Root Check & Auto-Install
try {
    $PythonCheck = & python --version 2>&1
    if ($PythonCheck -notlike "*Python 3.*") { throw "Python not found" }
}
catch {
    Write-Host "Python not found. Attempting auto-installation via winget..." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run: winget install Python.Python.3 --silent --show-progress"
    }
    else {
        & winget install Python.Python.3 --silent --show-progress
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Python via winget. Please install it manually from python.org."
            exit 1
        }
        Write-Host "Python installed. Please restart your terminal if it doesn't work in the next step." -ForegroundColor Green
        # Refresh Path for current session if possible
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
}

# 0.5 Node.js Root Check & Auto-Install
try {
    $NodeCheck = & node -v 2>&1
    if ($NodeCheck -notlike "v*") { throw "Node not found" }
}
catch {
    Write-Host "Node.js not found. Attempting auto-installation via winget..." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host "[DRY RUN] Would run: winget install OpenJS.NodeJS.LTS --silent --show-progress"
    }
    else {
        & winget install OpenJS.NodeJS.LTS --silent --show-progress
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Note: Node.js installation via winget might need user interaction or failed. Please check manually if needed." -ForegroundColor Yellow
        }
        else {
            Write-Host "Node.js (LTS) installed." -ForegroundColor Green
            # Refresh Path again
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        }
    }
}

# 1. Environment Choice & Path Resolution
$IsWinSystem = $PSVersionTable.Platform -match "Win" -or $env:OS -like "*Windows*"

# Load Path Manifest if exists
$ManifestPath = Join-Path $CurrentPath "state\path_map.json"
$ExternalVenvPath = $null
if (Test-Path $ManifestPath) {
    try {
        $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
        $ExternalVenvPath = $Manifest.venv
    }
    catch {}
}

if ($Global) {
    Write-Host "Step 1: Skipping Virtual Environment (Global mode enabled)." -ForegroundColor Cyan
    $PipCommand = "pip"
}
else {
    # Determine Venv Path
    if ($null -eq $ExternalVenvPath) {
        $VenvFullPath = Join-Path $CurrentPath $EnvName
        Write-Host "Step 1: Managing Local Virtual Environment ($EnvName)..."
    }
    else {
        $VenvFullPath = $ExternalVenvPath
        Write-Host "Step 1: Managing External Hashed Virtual Environment..."
        Write-Host ">> Target: $VenvFullPath" -ForegroundColor Gray
    }

    if (Test-Path $VenvFullPath) {
        Write-Host "Virtual environment already exists." -ForegroundColor Cyan
    }
    else {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would run: python -m venv $VenvFullPath"
        }
        else {
            try {
                if (-not (Test-Path (Split-Path $VenvFullPath))) { New-Item -ItemType Directory (Split-Path $VenvFullPath) -Force | Out-Null }
                python -m venv $VenvFullPath
                Write-Host "Done." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to create venv at $VenvFullPath."
                exit 1
            }
        }
    }
    $PipCommand = if ($IsWinSystem) { Join-Path $VenvFullPath "Scripts\pip.exe" } else { Join-Path $VenvFullPath "bin/pip" }
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
$ToolkitTemplate = Join-Path $PSScriptRoot ".env.template"

if (-not (Test-Path "$CurrentPath\.env")) {
    Write-Host "Step 3: Creating .env from template..."
    $SourceTemplate = $null
    if (Test-Path $EnvTemplate) { $SourceTemplate = $EnvTemplate }
    elseif (Test-Path $ToolkitTemplate) { $SourceTemplate = $ToolkitTemplate }

    if ($SourceTemplate) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would copy $SourceTemplate to .env"
        }
        else {
            Copy-Item $SourceTemplate ".env"
            Write-Host ".env created from $SourceTemplate. Please fill in your API keys." -ForegroundColor Green
        }
    }
    else {
        Write-Host "No .env.template found in root or toolkit. Skipping." -ForegroundColor Yellow
    }
}

# 4. Browser Automation Setup (Playwright)
Write-Host "Step 4: Setting up Browser Automation (Playwright)..." -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "[DRY RUN] Would install playwright and chromium to C:\.ag_browser"
}
else {
    # Install Playwright python package
    Write-Host "Installing playwright package..." -ForegroundColor Gray
    & $PipCommand install playwright python-dotenv
    
    # Ensure local cache directory exists
    $BrowserPath = "C:\.ag_browser"
    if (-not (Test-Path $BrowserPath)) {
        New-Item -ItemType Directory -Path $BrowserPath -Force | Out-Null
        Write-Host "Created local browser cache at $BrowserPath" -ForegroundColor Gray
    }
    
    # Install Chromium
    Write-Host "Installing Chromium binary..." -ForegroundColor Gray
    $env:PLAYWRIGHT_BROWSERS_PATH = $BrowserPath
    & $PipCommand -m playwright install chromium
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Browser automation setup complete." -ForegroundColor Green
    }
    else {
        Write-Host "Warning: Playwright/Chromium installation failed. Browser tests might not work." -ForegroundColor Yellow
    }
}

# 5. Update State Status
if (-not $DryRun) {
    $LatestFile = Join-Path $CurrentPath "state\latest.json"
    if (Test-Path $LatestFile) {
        try {
            $StateTmp = Get-Content $LatestFile -Raw | ConvertFrom-Json
            $ModeValue = if ($Global) { "Global" } else { "Venv" }
            
            # Robust property addition for PSUcustomObject
            $StateTmp | Add-Member -NotePropertyName "SetupMode" -NotePropertyValue $ModeValue -Force
            
            $StateTmp | ConvertTo-Json -Depth 5 | Out-File $LatestFile -Encoding UTF8 -Force
            Write-Host "State updated with SetupMode: $ModeValue" -ForegroundColor Gray
        }
        catch {
            Write-Host "Warning: Could not update state with SetupMode. Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Note: state/latest.json not found at $LatestFile. Skipping state update." -ForegroundColor Gray
    }
}

Write-Host "`nSetup process completed." -ForegroundColor Green
exit 0
