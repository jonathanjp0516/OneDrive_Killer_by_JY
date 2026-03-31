# OneDrive Killer

A robust PowerShell script designed to completely eradicate Microsoft OneDrive from Windows 10/11, prevent it from reinstalling, and restore your hijacked user folders (Desktop, Documents, Pictures) back to your local profile.

## CRITICAL WARNING: Read Before Executing
This script modifies your system's registry to point your user folders back to your local profile. **It DOES NOT automatically move your physical files.** After running this script and restarting File Explorer, your Desktop might appear empty. **Do not panic!** Your files are safe. 
You must manually navigate to `C:\Users\<YourUsername>\OneDrive\`, cut your files, and paste them into your local folders (e.g., `C:\Users\<YourUsername>\Desktop`).

## What This Script Does
When you execute `OneDriveKiller.ps1`, it performs the following 5 steps:
1. **Force Closes OneDrive:** Terminates all background processes related to OneDrive.
2. **Uninstalls OneDrive:** Locates the system's setup executable and uninstalls the application completely.
3. **Cleans the Registry:** Removes the persistent OneDrive icon from the File Explorer's left navigation pane.
4. **Blocks Reinstallation:** Modifies Group Policy/Registry (`DisableFileSyncNGSC`) to prevent Windows Update from automatically reinstalling or syncing OneDrive in the future.
5. **Restores User Shell Folders:** Scans the registry for hijacked paths (Desktop, Documents, Pictures, etc.) and removes the `\OneDrive` string, pointing them back to your local `%USERPROFILE%`.

## How to Use

Windows blocks unsigned PowerShell scripts by default. You can bypass this securely to run the script:

**Method 1: Run via Command Prompt (Recommended & Easiest)**
1. Click the Windows Start button, type `cmd`.
2. Right-click **Command Prompt** and select **Run as Administrator**.
3. Paste the following command (replace the path with your actual file path) and press Enter:

    ```cmd
    powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\Your\OneDriveKiller.ps1"

**Method 2: Change Execution Policy in PowerShell**

1. Open Windows PowerShell as Administrator.

2. Run the following command to allow local scripts:

    ```PowerShell
    Set-ExecutionPolicy RemoteSigned

(Type Y if prompted for confirmation)

3. Right-click OneDriveKiller.ps1 and select Run with PowerShell.


**Important Note on File Migration:**
    This script updates the Windows Registry to point your user folders (Desktop, Documents, Pictures) back to your local profile. However, it does not move your physical files. After running this script and restarting Explorer, your Desktop might appear empty. Don't panic! Simply navigate to C:\Users\<YourUsername>\OneDrive\, cut your files, and paste them into your local folders.

**Disclaimer: Use this script at your own risk. Always ensure you have backed up important files before modifying system registries.**