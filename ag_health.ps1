# Antigravity Health Check Script
# Verifies environment state after setup

Write-Host "--- Antigravity Health Check ---" -ForegroundColor Cyan

$Status = @{
    Ready = 0
    Warn  = 0
    Fail  = 0
}

function Report {
    param([string]$Level, [string]$Module, [string]$Message)
    $Color = if ($Level -eq "FAIL") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "Green" }
    Write-Host "[$Level] $Module : $Message" -ForegroundColor $Color
    $script:Status[$Level]++
}

# 1. Directory Structure
Write-Host "Checking Project Structure..."
$Folders = @("workflows", "scripts", "logs")
foreach ($f in $Folders) {
    if (Test-Path $f) {
        Report "READY" "Folder" "$f exists."
    }
    else {
        Report "WARN" "Folder" "$f missing. Some features may not work."
    }
}

# 2. Critical Files
Write-Host "`nChecking Critical Files..."
if (Test-Path ".env") {
    Report "READY" "File" ".env found."
}
else {
    Report "FAIL" "File" ".env missing. Run setup or rename .env.template."
}

if (Test-Path "config.json") {
    Report "READY" "File" "config.json found."
}
else {
    Report "WARN" "File" "config.json missing. Using default settings."
}

# 3. Virtual Environment
Write-Host "`nChecking Virtual Environment..."
if (Test-Path ".venv") {
    Report "READY" "venv" ".venv found."
}
else {
    Report "FAIL" "venv" ".venv missing. Setup is incomplete."
}

# 4. Logs Writable
Write-Host "`nChecking Logs..."
if (Test-Path "logs") {
    try {
        "test" | Out-File "logs/health_test.txt"
        Remove-Item "logs/health_test.txt"
        Report "READY" "Logs" "Directory is writable."
    }
    catch {
        Report "FAIL" "Logs" "Directory is not writable."
    }
}

$SummaryColor = if ($Status.Fail -gt 0) { "Red" } else { "Green" }
Write-Host "`n--- Health Summary ---" -ForegroundColor Cyan
Write-Host "READY: $($Status.Ready) | WARN: $($Status.Warn) | FAIL: $($Status.Fail)" -ForegroundColor $SummaryColor

if ($Status.Fail -gt 0) {
    exit 1
}
else {
    exit 0
}
