# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Initialize Folder Browser Dialog
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select a Folder"

# Show Folder Browser Dialog and get the folder path
if ($folderBrowser.ShowDialog() -eq "OK") {
    $folderPath = $folderBrowser.SelectedPath
} else {
    Write-Host "No folder selected. Exiting."
    exit
}

# Change directory to selected folder
Set-Location -Path $folderPath

# Get the name of the current directory (your folder name)
$foldername = Split-Path -Leaf (Get-Location)

# Initialize a counter for numbering
$counter = 0

# Loop through all JPEG files in the current directory
Get-ChildItem *.jpg | ForEach-Object {

    # Create an output filename based on the folder name and counter
    $outputFilename = "$foldername" + "_$(("{0:D4}" -f $counter)).jpg"

    # Run ImageMagick command to adjust image
    & 'magick' $_.Name -gamma 2 -modulate 120 -auto-level $outputFilename

    # Increment the counter
    $counter++
}

Write-Host "Image processing complete."
