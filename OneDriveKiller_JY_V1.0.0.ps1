# Check if the script is running with Administrator privileges
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Insufficient privileges! Please right-click this script and select 'Run as Administrator'."
    Pause
    Exit
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       OneDrive Killer is Running...        " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Array to store the results of each step for the final summary
$results = @()

# Helper function to add results
function Add-Result ($Step, $Status, $Details) {
    $results += [PSCustomObject]@{
        Step    = $Step
        Status  = $Status
        Details = $Details
    }
}

#Force close OneDrive
Write-Host "[1/5] Checking OneDrive process..." -ForegroundColor Yellow
try {
    $odProcess = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
    if ($odProcess) {
        Stop-Process -Name "OneDrive" -Force -ErrorAction Stop
        Add-Result "Kill Process" "Success" "OneDrive process terminated."
        Write-Host "  -> Process terminated." -ForegroundColor DarkGray
    } else {
        Add-Result "Kill Process" "Skipped" "OneDrive is not running."
        Write-Host "  -> OneDrive is not running." -ForegroundColor DarkGray
    }
} catch {
    Add-Result "Kill Process" "Failed" $_.Exception.Message
    Write-Host "  -> Failed to terminate process." -ForegroundColor Red
}
Start-Sleep -Seconds 2

#Uninstall OneDrive
Write-Host "`n[2/5] Uninstalling OneDrive..." -ForegroundColor Yellow
try {
    $onedriveSetupPaths = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe"
    )

    $setupFound = $false
    foreach ($path in $onedriveSetupPaths) {
        if (Test-Path $path) {
            Write-Host "  -> Found installer, starting uninstallation..." -ForegroundColor DarkGray
            Start-Process -FilePath $path -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction Stop
            $setupFound = $true
            Add-Result "Uninstall" "Success" "Uninstallation command executed."
            break
        }
    }

    if (-not $setupFound) {
        Add-Result "Uninstall" "Skipped" "Installer not found (already removed?)."
        Write-Host "  -> Installer not found." -ForegroundColor DarkGray
    }
} catch {
    Add-Result "Uninstall" "Failed" $_.Exception.Message
    Write-Host "  -> Uninstallation failed." -ForegroundColor Red
}
Start-Sleep -Seconds 3

#Remove OneDrive icon from File Explorer
Write-Host "`n[3/5] Cleaning Registry (Explorer Icon)..." -ForegroundColor Yellow
try {
    $clsidPaths = @(
        "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
        "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    )
    $iconRemoved = $false
    foreach ($path in $clsidPaths) {
        if (Test-Path $path) {
            Set-ItemProperty -Path $path -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction Stop
            $iconRemoved = $true
        }
    }
    if ($iconRemoved) {
        Add-Result "Remove Icon" "Success" "Registry keys updated."
        Write-Host "  -> Icon removed from Explorer." -ForegroundColor DarkGray
    } else {
        Add-Result "Remove Icon" "Skipped" "Registry keys not found."
        Write-Host "  -> Icon registry keys not found." -ForegroundColor DarkGray
    }
} catch {
    Add-Result "Remove Icon" "Failed" $_.Exception.Message
    Write-Host "  -> Failed to modify registry." -ForegroundColor Red
}

#Block future automatic reinstallation
Write-Host "`n[4/5] Setting Group Policies (Blocking OneDrive)..." -ForegroundColor Yellow
try {
    $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
    if (-not (Test-Path $policyPath)) {
        New-Item -Path $policyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $policyPath -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force -ErrorAction Stop
    Add-Result "Block Reinstall" "Success" "Policy DisableFileSyncNGSC set to 1."
    Write-Host "  -> Group policy applied." -ForegroundColor DarkGray
} catch {
    Add-Result "Block Reinstall" "Failed" $_.Exception.Message
    Write-Host "  -> Failed to set group policy." -ForegroundColor Red
}

#Fix hijacked User Shell Folders
Write-Host "`n[5/5] Fixing User Shell Folders paths..." -ForegroundColor Yellow
try {
    $shellFoldersPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $shellFolders = Get-Item -Path $shellFoldersPath
        
    $modifiedCount = 0
    foreach ($property in $shellFolders.Property) {
        $value = (Get-ItemProperty -Path $shellFoldersPath -Name $property -ErrorAction SilentlyContinue).$property
        if ($value -is [string] -and $value -match "OneDrive") {
            $newValue = $value -replace "\\OneDrive", ""
            Set-ItemProperty -Path $shellFoldersPath -Name $property -Value $newValue -ErrorAction Stop
            Write-Host "  -> Reverted [$property] to: $newValue" -ForegroundColor DarkGray
            $modifiedCount++
        }
    }

    if ($modifiedCount -gt 0) {
        Add-Result "Fix Paths" "Success" "Fixed $modifiedCount folder paths."
    } else {
        Add-Result "Fix Paths" "Skipped" "No hijacked paths found."
        Write-Host "  -> No paths needed fixing." -ForegroundColor DarkGray
    }
} catch {
    Add-Result "Fix Paths" "Failed" $_.Exception.Message
    Write-Host "  -> Failed to modify folder paths." -ForegroundColor Red
}

# Execution Summary
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "           EXECUTION SUMMARY              " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

foreach ($res in $results) {
    $color = switch ($res.Status) {
        "Success" { "Green" }
        "Skipped" { "DarkYellow" }
        "Failed"  { "Red" }
        default   { "White" }
    }
    
    # Format output for alignment
    $stepPadded = $res.Step.PadRight(16)
    $statusPadded = "[ $($res.Status) ]".PadRight(12)
    Write-Host "$stepPadded $statusPadded - $($res.Details)" -ForegroundColor $color
}
Write-Host "==========================================" -ForegroundColor Cyan

# Final Warning
Write-Host "`n ATTENTION:" -ForegroundColor Red
Write-Host "If 'Fix Paths' was successful, your physical files are still in C:\Users\<YourUsername>\OneDrive\" -ForegroundColor Yellow
Write-Host "You MUST manually cut and paste them into your local Desktop/Documents folders." -ForegroundColor Yellow

# Restart Explorer
Write-Host ""
$restartExplorer = Read-Host "Restart File Explorer now to apply changes? (Y/N)"
if ($restartExplorer -match "^[Yy]$") {
    Stop-Process -Name explorer -Force
}