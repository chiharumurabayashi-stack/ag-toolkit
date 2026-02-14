param(
    [string]$PhysicalPath = $PSScriptRoot,
    [string]$TargetDrive = $null,  # If provided, uses subst
    [string]$WorkDir = "C:\.ag_work",
    [switch]$Persist = $true,
    [switch]$Force = $false
)

# 1. Strategy Determination
$IsJunctionMode = [string]::IsNullOrEmpty($TargetDrive)

# 2. Path Manifest Logic
$ManifestDir = Join-Path $PhysicalPath "state"
if (-not (Test-Path $ManifestDir)) { New-Item -Path $ManifestDir -ItemType Directory }
$ManifestPath = Join-Path $ManifestDir "path_map.json"

function Write-PathManifest {
    param($Phys, $Virt, $Venv)
    $Manifest = @{
        physical = $Phys
        virtual  = $Virt
        venv     = $Venv
        updated  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $Manifest | ConvertTo-Json | Out-File $ManifestPath -Encoding UTF8
}

# 3. Execution
Write-Host "--- Antigravity Path Layer Stabilizer ---" -ForegroundColor Cyan

if ($IsJunctionMode) {
    # JUNCTION MODE: C:\.ag_work\project-name
    $ProjectName = (Get-Item $PhysicalPath).Name
    if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null }
    
    $TargetLink = Join-Path $WorkDir $ProjectName
    Write-Host ">> Creating Junction: $TargetLink -> $PhysicalPath" -ForegroundColor Cyan
    
    if (Test-Path $TargetLink) {
        # Check if it's already a junction to the same target
        $Existing = (Get-Item $TargetLink).Target
        if ($Existing -eq $PhysicalPath -and -not $Force) {
            Write-Host "[INFO] Junction already exists and points to correct target." -ForegroundColor Green
            $VirtualPath = $TargetLink
        }
        else {
            Write-Host "[WARN] Existing junction/folder found at $TargetLink. Re-creating..." -ForegroundColor Yellow
            cmd /c "rd /s /q `"$TargetLink`""
            cmd /c "mklink /J `"$TargetLink`" `"$PhysicalPath`""
            $VirtualPath = $TargetLink
        }
    }
    else {
        cmd /c "mklink /J `"$TargetLink`" `"$PhysicalPath`""
        $VirtualPath = $TargetLink
    }
}
else {
    # SUBST MODE (Legacy Drive Letter)
    Write-Host ">> Mapping $PhysicalPath to $TargetDrive" -ForegroundColor Cyan
    subst $TargetDrive "$PhysicalPath"
    $VirtualPath = $TargetDrive
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Path mapping failed." -ForegroundColor Red
    exit 1
}

# 4. Persistence (Registry)
if ($Persist -and -not $IsJunctionMode) {
    # Registry persistence is only needed for subst (drive letters don't persist)
    # Junctions are persistent filesystem entries, so no registry needed!
    Write-Host "[INFO] Junctions are persistent by nature. No registry entry needed." -ForegroundColor Gray
}

# 5. Manifest Generation
$VenvBase = "C:\.ag_venv"
$ProjectHash = [BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PhysicalPath))).Replace("-", "").Substring(0, 8)
$VenvPath = Join-Path $VenvBase $ProjectHash

Write-PathManifest -Phys $PhysicalPath -Virt $VirtualPath -Venv $VenvPath
Write-Host "[SUCCESS] Path Layer Stabilized: $VirtualPath" -ForegroundColor Green
Write-Host "[INFO] Project Hash: $ProjectHash" -ForegroundColor Gray
Write-Host "[INFO] Manifest saved to $ManifestPath" -ForegroundColor Gray
