param(
    [switch]$DryRun,
    [switch]$Global,
    [switch]$ForceContinue
)

# 0. Path Resolution
$GlobalDiag = Join-Path $env:USERPROFILE ".gemini\antigravity\skills\ag_env_diagnostic\scripts\check_env.ps1"
$LocalDiag = Join-Path $PSScriptRoot ".agent\skills\ag_env_diagnostic\scripts\check_env.ps1"
$LocalDiagAlt = Join-Path (Get-Item $PSScriptRoot).Parent.FullName ".agent\skills\ag_env_diagnostic\scripts\check_env.ps1"

if (Test-Path $LocalDiag) { $DiagScript = $LocalDiag }
elseif (Test-Path $LocalDiagAlt) { $DiagScript = $LocalDiagAlt }
else { $DiagScript = $GlobalDiag }

$SetupScript = Join-Path $PSScriptRoot "setup_env.ps1"
$HealthScript = Join-Path $PSScriptRoot "ag_health.ps1"
$ReportScript = Join-Path $PSScriptRoot "ag_report.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Antigravity Quickstart Orchestrator" -ForegroundColor Cyan
Write-Host "========================================`n"

# 1. Diagnostics
Write-Host ">> Phase 1/3: Environment Diagnosis" -ForegroundColor Cyan
& $DiagScript
if ($LASTEXITCODE -ne 0 -and -not $ForceContinue) {
    Write-Host "`n[FAIL] Diagnosis found critical issues." -ForegroundColor Red
    Write-Host "Antigravity Self-Healing is generating a repair plan..." -ForegroundColor Cyan
    
    $FixScript = Join-Path $PSScriptRoot "auto_fix.ps1"
    if (Test-Path $FixScript) {
        Write-Host "--- Repair Plan Preview (DryRun) ---" -ForegroundColor Yellow
        & $FixScript -Mode DryRun
        Write-Host "`nTo execute the repair, run: ./auto_fix.ps1 -Mode Execute -Level Moderate" -ForegroundColor Green
        Write-Host "(Snapshot and rollback support are enabled by default for safety)" -ForegroundColor Gray
    }
    
    if (-not $ForceContinue) {
        Write-Host "`nStopping setup. Please repair the environment and retry." -ForegroundColor Yellow
        exit 1
    }
}

# 2. Setup
Write-Host "`n>> Phase 2/3: System Setup" -ForegroundColor Cyan
& $SetupScript -Global:$Global -DryRun:$DryRun
if ($LASTEXITCODE -ne 0 -and -not $ForceContinue) {
    Write-Host "`n[FATAL] Setup failed. Stopping." -ForegroundColor Red
    exit 1
}

# 3. Health Check
Write-Host "`n>> Phase 3/3: Health Verification" -ForegroundColor Cyan
& $HealthScript
if ($LASTEXITCODE -ne 0 -and -not $ForceContinue) {
    Write-Host "`n[WARN] Health check found issues. System may be unstable." -ForegroundColor Yellow
}

# 4. Report (Optional)
if (Test-Path $ReportScript) {
    Write-Host "`n>> Generating Summary Report..." -ForegroundColor Cyan
    & $ReportScript
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   Quickstart Completed Successfully" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
