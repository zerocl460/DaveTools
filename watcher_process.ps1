Add-Type -AssemblyName System.Windows.Forms

Function Create-Folder ($folderPath, $folderName) {
    $newFolderPath = Join-Path $folderPath $folderName
    New-Item -ItemType Directory -Path $newFolderPath -Force
    return $newFolderPath
}

Function Color-Correct-Files ($inputFile, $outputFolder) {
    $outputFilename = Join-Path $outputFolder ([System.IO.Path]::GetFileName($inputFile))
    if (Test-Path $outputFilename) { return }
    & 'magick' $inputFile -depth 16 -modulate 100,140,100 -auto-level -brightness-contrast 10x10 -colorspace sRGB -enhance -contrast-stretch 0 $outputFilename
}

# Get script's own location
$folderPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Create required folders
$originalFolder = Create-Folder -folderPath $folderPath -folderName "Original"
$renumFolder = Create-Folder -folderPath $folderPath -folderName "Original-Renum"
$gigaOrigFolder = Create-Folder -folderPath $folderPath -folderName "Gigapixeled-Original"
$gigaCCFolder = Create-Folder -folderPath $folderPath -folderName "Gigapixeled-CC"

# File watcher setup
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $gigaOrigFolder
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# Action for new file creation
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $extension = [System.IO.Path]::GetExtension($path)
    if ($extension -eq '.png' -or $extension -eq '.jpg') {
        Color-Correct-Files $path $gigaCCFolder
    }
}

# Register event
Register-ObjectEvent $watcher "Created" -Action $action

# Keep script running
while ($true) { Start-Sleep 10 }
