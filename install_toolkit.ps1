param(
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
)

Write-Host "--- Antigravity Toolkit Installer ---" -ForegroundColor Cyan

$SourcePath = "C:\Users\chiha\.gemini\antigravity\scratch\ag_toolkit"
$SkillSource = "C:\Users\chiha\.gemini\antigravity\skills\ag_env_diagnostic"

# 1. Create Destination
if (-not (Test-Path $DestinationPath)) {
    Write-Host "Creating destination directory: $DestinationPath"
    New-Item -ItemType Directory $DestinationPath | Out-Null
}

# 2. Copy Core Scripts
Write-Host "Deploying management scripts..."
$FilesToCopy = @(
    "ag_quickstart.ps1",
    "setup_env.ps1",
    "ag_health.ps1",
    "ag_report.ps1",
    "ag_snapshot.ps1",
    ".env.template",
    "setup.md"
)

foreach ($f in $FilesToCopy) {
    Copy-Item (Join-Path $SourcePath $f) (Join-Path $DestinationPath $f) -Force
}

# 3. Create placeholder folders
Write-Host "Creating project structure..."
$Folders = @("workflows", "scripts", "logs", "state/history", "backups")
foreach ($f in $Folders) {
    New-Item -ItemType Directory (Join-Path $DestinationPath $f) -Force | Out-Null
}

Write-Host "`nInstallation Complete!" -ForegroundColor Green
Write-Host "To get started, run: cd $DestinationPath; ./ag_quickstart.ps1" -ForegroundColor Cyan
