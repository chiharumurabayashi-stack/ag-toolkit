param(
    [switch]$DryRun,
    [switch]$Global,
    [switch]$ForceContinue
)

$DiagScript = "C:\Users\chiha\.gemini\antigravity\skills\ag_env_diagnostic\scripts\check_env.ps1"
$SetupScript = "C:\Users\chiha\.gemini\antigravity\scratch\ag_toolkit\setup_env.ps1"
$HealthScript = "C:\Users\chiha\.gemini\antigravity\scratch\ag_toolkit\ag_health.ps1"
$ReportScript = "C:\Users\chiha\.gemini\antigravity\scratch\ag_toolkit\ag_report.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Antigravity Quickstart Orchestrator" -ForegroundColor Cyan
Write-Host "========================================`n"

# 1. Diagnostics
Write-Host ">> Phase 1/3: Environment Diagnosis" -ForegroundColor Cyan
& $DiagScript
if ($LASTEXITCODE -ne 0 -and -not $ForceContinue) {
    Write-Host "`n[FATAL] Diagnosis failed. Stopping setup to prevent damage." -ForegroundColor Red
    Write-Host "Fix the critical issues above or use -ForceContinue to bypass." -ForegroundColor Yellow
    exit 1
}

# 2. Setup
Write-Host "`n>> Phase 2/3: System Setup" -ForegroundColor Cyan
$SetupParams = @()
if ($DryRun) { $SetupParams += "-DryRun" }
if ($Global) { $SetupParams += "-Global" }
& $SetupScript @SetupParams
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
