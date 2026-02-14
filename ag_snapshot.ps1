param(
    [string]$Tag = "stable"
)

Write-Host "--- Antigravity Snapshot Utility ---" -ForegroundColor Cyan

$CurrentPath = [System.IO.Directory]::GetCurrentDirectory()
$Timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$FolderName = "${Timestamp}_$Tag"
$BackupRoot = Join-Path $CurrentPath "backups"
$TargetDir = Join-Path $BackupRoot $FolderName

# Create directories
if (-not (Test-Path $BackupRoot)) { New-Item -ItemType Directory $BackupRoot | Out-Null }
New-Item -ItemType Directory $TargetDir | Out-Null

$FilesToBackup = @(".env", "requirements.txt", "config.json", "state/latest.json")
$FoundFiles = @()

Write-Host "Archiving critical configurations..."
foreach ($f in $FilesToBackup) {
    $Src = Join-Path $CurrentPath $f
    if (Test-Path $Src) {
        $Dest = Join-Path $TargetDir (Split-Path $f -Leaf)
        Copy-Item $Src $Dest -Force
        $FoundFiles += $f
    }
}

# Metadata Generation
Write-Host "Generating snapshot metadata..."
$LatestJson = Join-Path $CurrentPath "state/latest.json"
$Latest = if (Test-Path $LatestJson) { Get-Content $LatestJson | ConvertFrom-Json } else { $null }

$Meta = @{
    Timestamp       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tag             = $Tag
    ToolkitVersion  = "1.0.0"
    ProjectRoot     = $CurrentPath
    PythonVer       = if ($Latest) { $Latest.PythonVersion } else { "Unknown" }
    VenvName        = ".venv"
    FilesIncluded   = $FoundFiles
    ChecksumSummary = if ($Latest) { $Latest.Hashes } else { @{} }
}

$Meta | ConvertTo-Json -Depth 5 | Out-File (Join-Path $TargetDir "snapshot_meta.json") -Encoding UTF8

# Update LastSnapshot in latest.json
if ($Latest) {
    $Latest.LastSnapshot = "backups/$FolderName"
    $Latest | ConvertTo-Json -Depth 5 | Out-File $LatestJson -Encoding UTF8
}

Write-Host "`nSnapshot completed: backups/$FolderName" -ForegroundColor Green
Write-Host "Metadata saved to snapshot_meta.json" -ForegroundColor Cyan
