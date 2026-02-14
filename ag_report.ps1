# Antigravity Report Generator
# Summarizes system and environment state by reading ag_state.json

$StateFile = "state/latest.json"
$ReportPath = "logs/env_report.txt" # Simplified path for consistent access

if (Test-Path $StateFile) {
    $State = Get-Content $StateFile | ConvertFrom-Json
}
else {
    Write-Host "[WARN] No state file found. Running on live data only." -ForegroundColor Yellow
}

$Report = @"
========================================
   Antigravity System Summary Report
========================================
Generated: $(Get-Date)

[System Core]
OS       : $((Get-WmiObject Win32_OperatingSystem).Caption)
RAM      : $([math]::Round((Get-WmiObject Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB, 1)) GB
Computer : $($env:COMPUTERNAME)

[Runtimes]
Python   : $(if ($State.PythonVersion) { $State.PythonVersion } else { & python --version 2>&1 })
Node     : $(if ($State.NodeVersion) { $State.NodeVersion } else { & node -v 2>&1 })

[GPU Info]
Model    : $(if ($State.GpuName) { $State.GpuName } else { "None detected" })
VRAM     : $(if ($State.GpuVram) { $State.GpuVram } else { 0 }) MB

[Environment Info]
Root Path  : $(if ($State.Path) { $State.Path } else { Get-Location })
OneDrive   : $(if ($null -ne $State.OneDrive) { $State.OneDrive } else { "Unknown" })
Status     : $(if ($State.Ready) { "READY" } else { "FAIL/INCOMPLETE" })
Setup Mode : $(if ($null -ne $State.SetupMode) { $State.SetupMode } else { "Unknown" })
Baseline   : $($State.IsBaseline)

[Persistence & drift]
Last Snapshot: $(if ($State.LastSnapshot) { $State.LastSnapshot } else { "None" })
Drift Status : $(
    $addedCount = @($State.Drift.Added).Count
    $removedCount = @($State.Drift.Removed).Count
    $changedCount = @($State.Drift.Changed).Count
    
    if ($addedCount -eq 0 -and $removedCount -eq 0 -and $changedCount -eq 0) { 
        "No drift detected" 
    } else { 
        "DRIFT DETECTED (+$addedCount / -$removedCount / ~$changedCount)" 
    }
)

----------------------------------------
Next Recommended Actions:
1. Finish setup by filling .env if missing.
2. Run ag_snapshot.ps1 before major changes.
3. Run ag_health.ps1 regularly.
========================================
"@

$Report | Out-File $ReportPath -Encoding UTF8
Write-Host "God-level report saved to: $ReportPath" -ForegroundColor Green
Write-Host $Report -ForegroundColor Gray
