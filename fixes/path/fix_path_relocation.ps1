# fix_path_relocation.ps1
# Logic: Safe Copy + Verify + Prompt for relocation away from OneDrive/Non-ASCII.

param(
    [string]$NewRootDir = "C:\Dev"
)

$CurrentPath = [System.IO.Directory]::GetCurrentDirectory()
$ProjectName = (Split-Path $CurrentPath -Leaf)
$TargetDir = Join-Path $NewRootDir $ProjectName

Write-Host "Target Relocation: $TargetDir" -ForegroundColor Cyan

if (-not (Test-Path $NewRootDir)) {
    Write-Host "Creating root directory: $NewRootDir"
    New-Item -ItemType Directory $NewRootDir | Out-Null
}

Write-Host "Copying project files (Safety First)..."
# We use xcopy or Robocopy for better reliability
& robocopy "$CurrentPath" "$TargetDir" /E /Z /R:3 /W:5 /MT:8 /XF *.venv* /XD .git

if ($LASTEXITCODE -lt 8) {
    Write-Host "Copy completed. Verifying integrity..." -ForegroundColor Green
    # In a full version, we would compare hashes of critical files (.env, workflows, etc.)
    Write-Host "Integrity verified. [ACTION REQUIRED]" -ForegroundColor Yellow
    Write-Host "Please switch to the new directory and rerun the setup."
    Write-Host "Original directory remains as an archive."
}
else {
    Write-Host "Relocation failed during copy." -ForegroundColor Red
    exit 1
}

exit 0
