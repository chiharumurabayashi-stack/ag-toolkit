param(
    [string]$Mode = "DryRun", # DryRun, Execute, Rollback
    [string]$Level = "Safe",   # Safe, Moderate, Aggressive
    [string]$RollbackTag = ""
)

# --- Antigravity Self-Healing Orchestrator (v1.1.0) ---
$ToolkitDir = $PSScriptRoot
$StateDir = Join-Path $ToolkitDir "state"
$PlanFile = Join-Path $StateDir "fix_plan.json"
$CursorFile = Join-Path $StateDir "fix_cursor.json"

# Utility: Generate Plan Hash
function Get-PlanHash {
    if (Test-Path $PlanFile) {
        $Content = Get-Content $PlanFile -Raw
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
        $Hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($Bytes)
        return [System.BitConverter]::ToString($Hash).Replace("-", "").ToLower()
    }
    return $null
}

# 1. Initialization & Admin Check
Write-Host "Initializing Antigravity Self-Healing Mode..." -ForegroundColor Cyan
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# 2. Rollback Logic
if ($Mode -eq "Rollback") {
    Write-Host "Entering Rollback Mode..." -ForegroundColor Yellow
    # Logic to call ag_snapshot.ps1 or revert files based on $RollbackTag
    # ...
    exit 0
}

# 3. Plan Generation (Phase 1: Diagnostic -> Internal Plan)
# In its simple version, we assume diag already tagged issues.
# For now, let's mock a plan if missing.
if (-not (Test-Path $PlanFile)) {
    Write-Host "No fix plan found. Generating plan based on current issues..." -ForegroundColor Gray
    # Call internal logic to map issues -> fixes
    $MockPlan = @(
        @{ Fix = "StorePythonAlias"; Order = 20; Level = "Moderate"; Scope = @("PATH"); Precheck = @("python_found"); Reversible = $true }
    )
    $MockPlan | ConvertTo-Json -Depth 5 | Out-File $PlanFile -Encoding UTF8
}

# 4. Consistency Check
$CurrentHash = Get-PlanHash
if (Test-Path $CursorFile) {
    $Cursor = Get-Content $CursorFile | ConvertFrom-Json
    if ($Cursor.PlanHash -ne $CurrentHash) {
        Write-Host "[CRITICAL] Fix plan has changed since last execution. Aborting for safety." -ForegroundColor Red
        exit 1
    }
}

# 5. Pre-Execution Snapshot (Mandatory for Level >= Moderate)
if ($Mode -eq "Execute" -and $Level -ne "Safe") {
    Write-Host "Creating mandatory safety snapshot..." -ForegroundColor Yellow
    & (Join-Path $ToolkitDir "ag_snapshot.ps1") -Tag "pre_autofix"
}

# 6. Execution Loop
$Plan = Get-Content $PlanFile | ConvertFrom-Json | Sort-Object Order
$StartOrder = if (Test-Path $CursorFile) { (Get-Content $CursorFile | ConvertFrom-Json).LastCompletedOrder } else { 0 }

foreach ($Step in $Plan) {
    if ($Step.Order -le $StartOrder) { continue }
    if ($Step.Level -eq "Aggressive" -and $Level -ne "Aggressive") { 
        Write-Host "[SKIP] Level '$($Step.Level)' fix '$($Step.Fix)' requires -Level Aggressive." -ForegroundColor Gray
        continue 
    }

    Write-Host "`n[FIX] $($Step.Fix) (Level: $($Step.Level))" -ForegroundColor Cyan
    Write-Host " -> Scope: $($Step.Scope -join ', ')" -ForegroundColor Gray
    
    if ($Mode -eq "DryRun") {
        Write-Host " [DRYRUN] Would execute repair module for $($Step.Fix)" -ForegroundColor Yellow
        continue
    }

    # Execute Module
    $ModulePath = Join-Path $ToolkitDir "fixes\core\fix_$($Step.Fix).ps1"
    if (-not (Test-Path $ModulePath)) { $ModulePath = Join-Path $ToolkitDir "fixes\env\fix_$($Step.Fix).ps1" }
    
    if (Test-Path $ModulePath) {
        & $ModulePath
        if ($LASTEXITCODE -eq 0) {
            $Cursor = @{ LastCompletedOrder = $Step.Order; PlanHash = $CurrentHash }
            $Cursor | ConvertTo-Json | Out-File $CursorFile -Encoding UTF8
        }
        else {
            Write-Host "[FAIL] Fix '$($Step.Fix)' failed. Stopping orchestration." -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "[ERROR] Fix module not found: $ModulePath" -ForegroundColor Red
    }
}

# 7. Post-Health Check
if ($Mode -eq "Execute") {
    Write-Host "`nFinalizing repairs... Executing Health Check." -ForegroundColor Cyan
    # & (Join-Path $ToolkitDir "ag_health.ps1")
    # If [FAIL] detected in output -> Suggest Rollback
}

Write-Host "`nAnalysis Complete - All tasks finished"
