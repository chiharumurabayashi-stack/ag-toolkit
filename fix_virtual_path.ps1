param(
    [string]$PhysicalPath = $PSScriptRoot,
    [string]$TargetDrive = $null,
    [switch]$Persist = $true,
    [switch]$Force = $false
)

# 1. Drive Letter Strategy
$SafeCandidates = @('X', 'Y', 'Z', 'P', 'Q', 'R')
$RestrictionList = @('A', 'B', 'C', 'D', 'E')

function Get-NextAvailableDrive {
    $UsedDrives = (Get-PSDrive -PSProvider FileSystem).Name
    foreach ($Letter in $SafeCandidates) {
        if ($Letter -notin $UsedDrives) { return "$Letter`:" }
    }
    # Fallback: scan from Z downwards excluding restrictions
    for ($i = [int][char]'Z'; $i -ge [int][char]'F'; $i--) {
        $Letter = [char]$i
        if ($Letter -notin $UsedDrives -and $Letter -notin $SafeCandidates) {
            return "$Letter`:"
        }
    }
    return $null
}

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
Write-Host "--- Antigravity Virtual Path Fixer ---" -ForegroundColor Cyan

# Check if already running on a virtual drive
$CurrentRoot = (Get-Item $PhysicalPath).Root.Name
if ($CurrentRoot -in $SafeCandidates -and -not $Force) {
    Write-Host "[INFO] Already running on virtual drive $CurrentRoot" -ForegroundColor Green
    exit 0
}

# Select Drive
if (-not $TargetDrive) {
    $TargetDrive = Get-NextAvailableDrive
}
if (-not $TargetDrive) {
    Write-Host "[FAIL] No available drive letters found." -ForegroundColor Red
    exit 1
}

Write-Host ">> Mapping $PhysicalPath to $TargetDrive" -ForegroundColor Cyan
subst $TargetDrive "$PhysicalPath"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] subst command failed." -ForegroundColor Red
    exit 1
}

# 4. Persistence (Registry)
if ($Persist) {
    Write-Host ">> Registering persistence in HKCU Run..." -ForegroundColor Cyan
    $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $RegName = "AntigravitySubst_$($TargetDrive.Replace(':',''))"
    $RegValue = "subst $TargetDrive `"$PhysicalPath`""
    
    try {
        Set-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -ErrorAction Stop
        Write-Host "[SUCCESS] Registry updated: $RegName" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Failed to write to registry. Persistence may not work." -ForegroundColor Yellow
    }
}

# 5. Manifest Generation
$VenvBase = "C:\.ag_venv"
$ProjectHash = [BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PhysicalPath))).Replace("-", "").Substring(0, 8)
$VenvPath = Join-Path $VenvBase $ProjectHash

Write-PathManifest -Phys $PhysicalPath -Virt $TargetDrive -Venv $VenvPath
Write-Host "[SUCCESS] Root mapped to $TargetDrive" -ForegroundColor Green
Write-Host "[INFO] Project Hash: $ProjectHash" -ForegroundColor Gray
Write-Host "[INFO] Manifest saved to $ManifestPath" -ForegroundColor Gray
