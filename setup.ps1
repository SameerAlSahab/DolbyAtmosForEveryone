
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Please run this PowerShell script as Administrator!" -ForegroundColor Red
    Pause
    Exit
}

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "            DOLBY ATMOS SETUP SCRIPT                " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan


Write-Host "`nSelect which Dolby Atmos version you want to install:" -ForegroundColor Yellow
Write-Host " [1] Dolby Atmos - Home"
Write-Host " [2] Dolby Atmos - Gaming"
$choice = Read-Host "`nEnter your choice (1 or 2)"

switch ($choice) {
    "1" { $versionName = "Home";   $sub = "home" }
    "2" { $versionName = "Gaming"; $sub = "gaming" }
    default { Write-Host "[!] Invalid selection! Exiting..." -ForegroundColor Red; Pause; Exit }
}
$driverInfPath = Join-Path $PSScriptRoot "drivers\$sub\hdaudio.inf"
$appxPath      = Join-Path $PSScriptRoot "control_app\${sub}_control.Appx"

foreach ($p in @($driverInfPath, $appxPath)) {
    if (-not (Test-Path $p)) {
        Write-Host "[!] Missing file: $p" -ForegroundColor Red
        Pause
        Exit
    }
}
Write-Host "[+] Selected Version: Dolby Atmos ($versionName)" -ForegroundColor Green


Write-Host "`n[1/6] Pre checks..." -ForegroundColor Yellow

$secureBoot = $false
try { $secureBoot = [bool](Confirm-SecureBootUEFI) } catch { $secureBoot = $false }   # throws on legacy BIOS
$testSigningOn = [bool](bcdedit /enum '{current}' | Select-String 'testsigning\s+Yes')

if ($testSigningOn) {
    Write-Host "[+] Test signing is already enabled." -ForegroundColor Green
} else {
    if ($secureBoot) {
        Write-Host "[!] Secure Boot is ON. Test signing cannot be enabled." -ForegroundColor Red
        Write-Host "[!] Disable Secure Boot in BIOS, then run this script again. Nothing was changed." -ForegroundColor Red
        Pause
        Exit
    }
    bcdedit /set testsigning on | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] bcdedit failed (code $LASTEXITCODE). Nothing else was changed." -ForegroundColor Red
        Pause
        Exit
    }
    Write-Host "[+] Test signing enabled (active after reboot)." -ForegroundColor Green
}


Write-Host "`n[2/6] Creating restore point and backup folder..." -ForegroundColor Yellow
$backupDir = Join-Path $PSScriptRoot ("driver_backup_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
try {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
    Checkpoint-Computer -Description "Before Dolby Atmos setup" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Write-Host "[+] Restore point created." -ForegroundColor Green
} catch {
    Write-Host "[!] Could not create restore point: $($_.Exception.Message)" -ForegroundColor Yellow
}


Write-Host "`n[3/6] Audio devices currently installed:" -ForegroundColor Yellow
$audioDevs = @(Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq 'MEDIA' })
$audioDevs | Select-Object DeviceName, DriverProviderName, DriverVersion, InfName | Format-Table -AutoSize | Out-Host


$infText = Get-Content $driverInfPath -Raw -ErrorAction SilentlyContinue
$codecIds = @()
foreach ($d in $audioDevs) {
    if ($d.HardWareID -match 'VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}') { $codecIds += $Matches[0] }
}
foreach ($id in ($codecIds | Sort-Object -Unique)) {
    if ($infText -match [regex]::Escape($id)) {
        Write-Host "[+] INF contains $id" -ForegroundColor Green
    } else {
        Write-Host "[-] INF does NOT contain $id (expected for GPU HDMI audio; a problem if it is your main codec)" -ForegroundColor Yellow
    }
}


Write-Host "`n[4/6] Old audio drivers..." -ForegroundColor Yellow

$audioClasses = 'MEDIA', 'Extension', 'SoftwareComponent', 'AudioProcessingObject'
$knownVendor  = 'Realtek|Conexant|Synaptics|Waves|Nahimic|A-Volute|Dolby|DTS|IDT|Cirrus|Creative|Sonic|Maxx|Harman|Bang'


$candidates = @(Get-WindowsDriver -Online | Where-Object {
    ($_.ClassName -in $audioClasses) -and
    ($_.ClassName -eq 'MEDIA' -or $_.ProviderName -match $knownVendor)
})

$i = 0
$list = @(foreach ($d in $candidates) {
    $i++
    [pscustomobject]@{
        No       = $i
        Rec      = $(if ($d.ProviderName -match $knownVendor) { '*' } else { '' })
        Provider = $d.ProviderName
        Class    = $d.ClassName
        Inf      = $d.Driver
        Original = Split-Path $d.OriginalFileName -Leaf
        Version  = $d.Version
    }
})

$toRemove = @()
if ($list.Count -gt 0) {
    $list | Format-Table -AutoSize | Out-Host
    Write-Host "* = known audio vendor. Keep NVIDIA/AMD/Intel HDMI/DP audio entries." -ForegroundColor Gray
    $sel = Read-Host "Numbers to remove (e.g. 1,3), 'r' = all marked *, Enter = skip"
    if ($sel -eq 'r') {
        $toRemove = @($list | Where-Object { $_.Rec -eq '*' })
    } elseif ($sel) {
        $nums = @($sel -split '[,\s]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })
        $toRemove = @($list | Where-Object { $nums -contains $_.No })
    }
} else {
    Write-Host "[-] No third-party audio drivers found." -ForegroundColor Gray
}

foreach ($drv in $toRemove) {
    Write-Host "    [X] $($drv.Provider) ($($drv.Inf))" -ForegroundColor Magenta
    pnputil /export-driver $drv.Inf $backupDir | Out-Null      # backup first
    pnputil /delete-driver $drv.Inf /uninstall /force | Out-Null
    switch ($LASTEXITCODE) {
        0       { Write-Host "        Removed" -ForegroundColor Gray }
        3010    { Write-Host "        Removed (reboot required)" -ForegroundColor Gray }
        default { Write-Host "        FAILED (pnputil code $LASTEXITCODE)" -ForegroundColor Red }
    }
}


$svcNames = 'CxUtilSvc', 'CxAudioSvc', 'RtkAudioService', 'RtkAudioUniversalService', 'RtkAudUService', 'NahimicService', 'WavesSysSvc'
foreach ($svc in (Get-Service -Name $svcNames -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Disabling service: $($svc.Name)" -ForegroundColor Magenta
    Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
    Set-Service  -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
}

# Conexant leftover EXEs (.exe -> .exe.bak)
$conexantDir = "C:\Program Files\CONEXANT"
if (Test-Path $conexantDir) {
    Get-ChildItem -Path $conexantDir -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Rename-Item -Path $_.FullName -NewName "$($_.Name).bak" -Force -ErrorAction Stop
            Write-Host "    [R] $($_.Name) -> $($_.Name).bak" -ForegroundColor Gray
        } catch {
            Write-Host "    [!] Could not rename $($_.Name) (locked?)" -ForegroundColor Red
        }
    }
}


$blockWU = Read-Host "`nBlock Windows Update driver updates? This affects ALL drivers (y/N)"
if ($blockWU -eq 'y') {
    $regPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $regPath2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
    if (-not (Test-Path $regPath1)) { New-Item -Path $regPath1 -Force | Out-Null }
    if (-not (Test-Path $regPath2)) { New-Item -Path $regPath2 -Force | Out-Null }
    Set-ItemProperty -Path $regPath1 -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $regPath2 -Name "SearchOrderConfig" -Value 0 -Type DWord -Force
    Write-Host "[+] Windows driver auto-update blocked (undo command shown at the end)." -ForegroundColor Green
}


Write-Host "`n[5/6] Installing Dolby Atmos ($versionName) driver..." -ForegroundColor Yellow
pnputil /add-driver "$driverInfPath" /install
if ($LASTEXITCODE -notin 0, 3010) {
    Write-Host "[!] pnputil failed (code $LASTEXITCODE)" -ForegroundColor Red
}


Write-Host "`n[6/6] Installing Dolby Access ($versionName) control app..." -ForegroundColor Yellow
try {
    Add-AppxPackage -Path $appxPath -ErrorAction Stop
    Write-Host "[+] Control app installed." -ForegroundColor Green
} catch {
    Write-Host "[!] AppX installation failed: $_" -ForegroundColor Red
    Write-Host "    (Check that its dependencies like VCLibs / .NET Native are installed and the package cert is trusted.)" -ForegroundColor Gray
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "                INSTALLATION COMPLETE               " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "1. Restart your PC to load the Dolby APO driver in Test Mode."
Write-Host "2. If sound disappears: Device Manager -> change driver to 'High Definition Audio Device'."
Write-Host "3. Removed drivers are backed up in: $backupDir"
Write-Host "4. Undo the Windows Update block (if you enabled it):"
Write-Host "   Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name ExcludeWUDriversInQualityUpdate"
Write-Host "   Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' -Name SearchOrderConfig -Value 1"
Write-Host "5. Undo test mode later: bcdedit /set testsigning off"
Write-Host "====================================================" -ForegroundColor Cyan
Pause
