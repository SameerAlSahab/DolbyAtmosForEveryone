# 🎧 DolbyAtmosForEveryone

**Real Dolby Atmos for every PC and Laptop (Control App + Driver).**

This repository provides everything you need to install and run the official Dolby Atmos audio drivers and its companion Control App on unsupported PCs and laptops. 

---

## ⚠️ Prerequisites 
Since these are modified `.inf` drivers, Windows will block the installation by default due to strict driver signature checks. **You must do ONE of the following before installing:**

**Option A: Disable Secure Boot (Recommended for Automated Script)**
1. Enter your PC's BIOS/UEFI settings.
2. Turn **OFF** Secure Boot.
3. Boot into Windows. (The automated script will automatically enable Windows Test Mode).

**Option B: Disable Driver Signature Enforcement (No BIOS changes needed)**
1. Hold the `Shift` key and click **Restart** from the Windows start menu.
2. Go to **Troubleshoot** > **Advanced Options** > **Startup Settings** > click **Restart**.
3. Once the PC reboots to the Startup Settings screen, press `7` or `F7` to **Disable driver signature enforcement**.

---

## 🚀 How to Set Up

First, extract the downloaded ZIP file from this repository. Make sure the `setup.ps1` file is placed in the root of the extracted folder (alongside the `drivers` and `control_app` folders).

### Method 1: PS1 Installation (Recommended)
1. Ensure you have met the prerequisites mentioned above.
2. Right-click on the `setup.ps1` file and select **Run with PowerShell**.
    * *Note: You must run it as an Administrator.*
3. Follow the on-screen prompts to choose between the **Home** or **Gaming** version.
4. The script will automatically clean up old stubborn drivers (Realtek/Conexant), install the Dolby driver, and install the Control App.
5. **Restart your PC.**

### Method 2: Manual Installation
If you prefer not to use the script, you can install it manually:
1. Open **Device Manager**.
2. Expand **Sound, video and game controllers**.
3. Right-click your current audio device (e.g., Realtek/Conexant) and select **Uninstall device**.
4. Right-click on the device again (or the basic High Definition Audio Device) and select **Update driver**.
5. Choose **Browse my computer for drivers** -> **Let me pick from a list of available drivers on my computer**.
6. Click **Have Disk...** and navigate to the extracted folder. Select the `.inf` file from either the `drivers\home` or `drivers\gaming` folder.
7. Accept any Windows security warnings and install the driver.
8. Once the driver is installed, go to the `control_app` folder and double-click the corresponding `.Appx` file (Home or Gaming) to install the Dolby Control interface.
9. **Restart your PC.**

---

## ⚖️ Disclaimer & Notice

**Trademark Notice:** "Dolby", "Dolby Atmos", and the double-D symbol are registered trademarks of Dolby Laboratories. This project is **not** endorsed by, directly affiliated with, maintained, authorized, or sponsored by Dolby Laboratories. All product and company names are the registered trademarks of their original owners.

**Takedown Requests:** If you represent Dolby or any related entity and wish for this repository to be removed, please send an email to: **sameeralsahab@proton.me** and it will be taken down immediately.
