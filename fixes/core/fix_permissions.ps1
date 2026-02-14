# fix_permissions.ps1
# Logic: Check for admin rights and offer self-elevation if needed.

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $IsAdmin) {
    Write-Host "[REQUIRED] This repair requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "Triggering UAC elevation..." -ForegroundColor Cyan
    
    # We don't want to just start a new shell randomly.
    # The Orchestrator should handle the re-entry logic.
    # This script just signals or performs a small elevated task.
    # To elevate the WHOLE orchestrator:
    # Start-Process powershell -Verb RunAs -ArgumentList "-File", "$($PSScriptRoot)\..\..\auto_fix.ps1", "-Execute"
    
    # For now, just exit with code indicating elevation needed or attempted.
    exit 2 # Custom code for elevation required
}

Write-Host "Administrator permissions verified." -ForegroundColor Green
exit 0
