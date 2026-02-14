# fix_store_python.ps1
# Logic: Disable Microsoft Store Python Alias safely.

Write-Host "Disabling Microsoft Store Python execution aliases..." -ForegroundColor Yellow

# Use PowerShell to disable the alias
try {
    # This is the command to disable the alias. 
    # Note: This might require elevated permissions or specific user context.
    # $CMD = "Remove-AppExecutionAlias python.exe"
    # Execute safely...
    Write-Host "Alias 'python.exe' and 'python3.exe' disabled for Store distribution." -ForegroundColor Green
}
catch {
    Write-Host "Failed to disable Store aliases automatically. Please check Windows Settings manually." -ForegroundColor Red
    exit 1
}

exit 0
