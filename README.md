# 🎧 DolbyAtmosForEveryone

**Dolby Atmos driver + Control App for PCs and laptops that don't officially ship with it.**

This repository provides modified `.inf` audio drivers and the companion Control App (Home / Gaming) so Dolby Atmos can be installed on supported-but-unlicensed hardware. Read **Before you start** first: this changes low-level Windows security settings. Note: This is not a fake repository with virus inside files. You can verify the files by virus scanners. Read Disclaimer and Notice at the end before any DMCA takedown notice.

---

## ⚠️ Before you start

- **Use at your own risk.** Modified, non-Microsoft-signed drivers are installed, and Windows Test Mode is enabled. Nothing here is guaranteed to work on your hardware.
- **BitLocker / Device Encryption:** disabling Secure Boot or enabling Test Mode can trigger a BitLocker recovery prompt. **Back up your recovery key first** (`manage-bde -protectors -get C:`) or suspend BitLocker before continuing.
- **Test Mode side effects:** a "Test Mode" watermark appears on the desktop, and some anti-cheat / DRM systems (e.g. Vanguard, FACEIT, and some EA/Activision titles) refuse to run with Secure Boot off or Test Mode on. If you play such games, think twice, especially for the **Gaming** version.
- **The script removes existing audio drivers.** It creates a restore point and backs up the drivers you choose to remove into a `driver_backup_*` folder, but make your own backup of anything important.
- Only download from this repository's Releases page and verify the checksums listed there.

---

## ✅ Compatibility

The drivers only install on audio codecs whose hardware ID is listed in the modified `.inf`. It will **not** work on every machine (USB audio, some Intel Smart Sound / DMIC-only setups, etc.).

Check your codec (PowerShell):

```powershell
Get-CimInstance Win32_PnPSignedDriver | Where-Object DeviceClass -eq 'MEDIA' |
    Select-Object DeviceName, DriverProviderName, HardWareID
```

Look for `VEN_xxxx&DEV_xxxx` (e.g. `VEN_10EC&DEV_0256`) and check it appears in `drivers\home\hdaudio.inf` / `drivers\gaming\hdaudio.inf`.

| Codec | Laptop / PC | Home | Gaming | Notes |
|-------|-------------|------|--------|-------|
| *(fill in)* | *(fill in)* | ✅/❌ | ✅/❌ | |

Requirements: Windows 10/11 **x64**, Administrator rights.

---

## 🔐 Prerequisites (driver signature)

Because the `.inf` files are modified, Windows blocks them by default.

**Option A: Disable Secure Boot + Test Mode (recommended, persistent)**
1. Enter BIOS/UEFI and turn **OFF** Secure Boot (see the BitLocker note above).
2. Boot into Windows. The script enables Test Mode automatically (`bcdedit /set testsigning on`).

**Option B: One-time F7 (temporary, manual install only)**
1. Hold `Shift` + click **Restart** → **Troubleshoot** → **Advanced options** → **Startup Settings** → **Restart**.
2. Press `7` / `F7` to **Disable driver signature enforcement**.
3. This only lasts until the next reboot, so the Dolby APO may stop loading afterwards. Use it for testing only. It does **not** work with the script (the script needs Test Mode).

---

## 🚀 Installation

Extract the ZIP first. `setup.ps1` must sit next to the `drivers` and `control_app` folders.

### Method 1: Script (recommended)
1. Meet the prerequisites above.
2. Open **PowerShell as Administrator** in the extracted folder and run:
   ```powershell
   Get-ChildItem -Recurse | Unblock-File
   powershell -ExecutionPolicy Bypass -File .\setup.ps1
   ```
   > Don't use right-click → *Run with PowerShell*. It doesn't elevate.
3. Choose **Home** or **Gaming**.
4. The script will: check Secure Boot / Test Mode, create a restore point, list your current audio drivers and **let you choose which to remove**, install the Dolby driver, then the Control App.
5. **Restart your PC.**

### Method 2: Manual
1. Open **Device Manager** → **Sound, video and game controllers**.
2. Right-click your audio device (Realtek / Conexant / Synaptics / etc.) → **Uninstall device**. Tick **Attempt to remove the driver for this device** if shown.
3. Right-click the device again (or the basic *High Definition Audio Device*) → **Update driver**.
4. **Browse my computer** → **Let me pick from a list** → **Have Disk...** → select the `.inf` from `drivers\home` or `drivers\gaming`.
5. Accept the security warning and install.
6. Double-click the matching `.Appx` in `control_app` to install the Control App.
7. **Restart your PC.**

---

## 🛠️ Troubleshooting

| Problem | Fix |
|---------|-----|
| Device Manager shows **Code 52** (can't verify signature) | Test Mode isn't active. Check that Secure Boot is off and `bcdedit /enum` shows `testsigning Yes`, then reboot. |
| **No sound** after install | Device Manager → audio device → Update driver → Let me pick → **High Definition Audio Device**. |
| Windows put the old driver back | Windows Update replaced it. Reinstall, and consider blocking driver updates for that device. |
| **Appx install fails** | Install missing dependencies (VCLibs / .NET Native), enable Developer Mode / sideloading, and check the error text from `Add-AppxPackage`. |
| Script won't run | Run from an Administrator PowerShell with `-ExecutionPolicy Bypass` and `Unblock-File` (see above). |
| BitLocker asks for a recovery key | Enter your recovery key. This is caused by the Secure Boot / boot config change. |

---

## ↩️ Uninstall

1. Device Manager → audio device → **Update driver** → Let me pick → **High Definition Audio Device**.
2. Remove the Dolby driver package: `pnputil /enum-drivers`, find the entry, then `pnputil /delete-driver oemXX.inf /uninstall`.
3. Remove the app: `Get-AppxPackage *Dolby* | Remove-AppxPackage`.
4. Turn Test Mode off: `bcdedit /set testsigning off`, then re-enable Secure Boot in BIOS.
5. If you blocked Windows driver updates, undo it:
   ```powershell
   Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name ExcludeWUDriversInQualityUpdate
   Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' -Name SearchOrderConfig -Value 1
   ```
6. To restore your old audio driver, use the `driver_backup_*` folder: `pnputil /add-driver "<backup folder>\*.inf" /subdirs /install`, or use the System Restore point created by the script.

---

## ⚖️ Disclaimer & Notice

This software is provided **"as is"**, without warranty of any kind. You are responsible for what you install on your system.

**Trademark Notice:** "Dolby", "Dolby Atmos", and the double-D symbol are registered trademarks of Dolby Laboratories. This project is **not** endorsed by, affiliated with, maintained, authorized, or sponsored by Dolby Laboratories. All product and company names are the registered trademarks of their original owners.

**Takedown Requests:** If you represent Dolby or any related entity and wish for this repository to be removed, please email **sameeralsahab@proton.me** and it will be taken down immediately.
