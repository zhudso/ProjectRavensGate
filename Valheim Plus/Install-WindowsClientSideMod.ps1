$storageDrives = Get-PSDrive -PSProvider FileSystem # Get all drives on the system to search for Valheim install directory
$installedDrive = "C:\" # Default drive to search for Valheim install directory
$valheimInstallDir = "Program Files (x86)\Steam\steamapps\common\Valheim" # Default Valheim install directory
$valheimPlusWindowsClientUri = "https://github.com/Grantapher/ValheimPlus/releases/download/0.9.16.2/WindowsClient.zip" # Valheim Plus mod download link (made by Grant Toepfer)
$valheimPlusWindowsClientFolder = "$env:USERPROFILE\Downloads\ValheimPlusMod_v0.9.16.2_WindowsClient.zip" # Folder to download the Valheim Plus mod to
$moddedServer = "modded.valheim.ravensgate.net" # Modded server to connect to

# Find where Valheim is installed
foreach ($drive in $storageDrives) {
    $valheimInstallDir = "$($drive.Root)$valheimInstallDir"
    if (Test-Path -Path "$valheimInstallDir" -ErrorAction SilentlyContinue) {
        $installedDrive = $drive.Root
        break
    }
    else {
        Write-Warning "Unable to find expected Valheim install directory ($valheimInstallDir)."
        $valheimInstallDir = Read-Host "Please provide where full path where Valheim is installed"
    }
}

# Download the ValheimPlus mod
$ProgressPreferenceBackup = $progressPreference
$progressPreference = 'SilentlyContinue'
Invoke-WebRequest $valheimPlusWindowsClientUri -OutFile $valheimPlusWindowsClientFolder
Write-Output "Downloading Valheim Plus mod to $valheimPlusWindowsClientFolder..."

$backupValheimFolder = Read-Host "Would you like to backup your Valheim folder? (Y/N)"
if ($backupValheimFolder -eq "Y") {
    $valheimBackupFolder = "$($installedDrive)Program Files (x86)\Steam\steamapps\common\Valheim Backup $(Get-Date -Format 'dd-MM-yyyy')" # Set Valheim folder backup directory
    try {
        Copy-Item -Path $valheimInstallDir -Destination "$valheimBackupFolder" -Recurse -Force
        Write-Host -ForegroundColor Green "Valheim folder backed up to $valheimBackupFolder."
    }
    catch {
        Write-Warning "Failed to backup Valheim folder to $valheimBackupFolder."
        Write-Error $($_.Exception.Message)
        return
    }
}

# Extract ValheimPlus to the main Valheim directory
Expand-Archive -Path $valheimPlusWindowsClientFolder -DestinationPath $valheimInstallDir -Force
$progressPreference = $ProgressPreferenceBackup

# Check if the mod was successfully installed
$extractedFiles = Get-ChildItem -Path (Join-Path -Path $valheimInstallDir -ChildPath "*") -Recurse
$allFilesInstalled = $true

foreach ($file in $extractedFiles) {
    $relativePath = $file.FullName.Substring($valheimInstallDir.Length + 1)
    if (-not (Test-Path -Path (Join-Path -Path $valheimInstallDir -ChildPath $relativePath) -ErrorAction SilentlyContinue)) {
        Write-Warning "File $relativePath failed to install to $valheimInstallDir."
        $allFilesInstalled = $false
    }
}

if ($allFilesInstalled) {
    Write-Host -ForegroundColor Green "Valheim Plus mod installed successfully to $valheimInstallDir."
    $ConfettiBombEmoji = [System.Convert]::toInt32("1F38A",16)
    Write-Host -ForegroundColor Green $([System.Char]::ConvertFromUtf32($ConfettiBombEmoji)) "You can now connect to the modded server at ($moddedServer)" $([System.Char]::ConvertFromUtf32($ConfettiBombEmoji))
} else {
    Write-Warning "Valheim Plus mod failed to completely install to $valheimInstallDir."
}