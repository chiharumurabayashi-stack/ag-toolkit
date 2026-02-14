# Antigravity Migration & Cloud Export
# This script helps you backup the toolkit to GitHub/Cloud for PC migration.

Write-Host "--- Antigravity Migration Assistant ---" -ForegroundColor Cyan

$CurrentPath = [System.IO.Directory]::GetCurrentDirectory()

Write-Host "`n[Pahse 1: Local Cleanup]"
# Remove local history/state to keep cloud clean (optional preference)
# Remove-Item -Path "state/history/*" -Force -ErrorAction SilentlyContinue

Write-Host "`n[Phase 2: GitHub / Cloud Instructions]"
Write-Host "1. Create a NEW PRIVATE REPOSITORY on GitHub (e.g., 'ag-management-toolkit')." -ForegroundColor Yellow
Write-Host "2. Run the following commands in this terminal:`n" -ForegroundColor Gray

Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"
Write-Host "   git branch -M main"
Write-Host "   git push -u origin main"

Write-Host "`n[Phase 3: New PC Recovery Command]"
Write-Host "To restore this onto a NEW PC, simply run:" -ForegroundColor Green
Write-Host "   git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git ag_toolkit"
Write-Host "   cd ag_toolkit"
Write-Host "   ./ag_quickstart.ps1"

Write-Host "`nMigration guidance displayed above." -ForegroundColor Cyan
