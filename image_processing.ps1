# Load Windows Forms assembly for folder picker
Add-Type -AssemblyName System.Windows.Forms

# Function to pick a folder using a dialog
Function Select-Folder {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.ShowDialog() | Out-Null
    return $folderBrowser.SelectedPath
}

# Function to copy original files to 'Original' folder
Function Copy-Original-Files ($folderPath) {
    $originalFolder = Join-Path $folderPath "Original"
    New-Item -ItemType Directory -Path $originalFolder -Force
    Copy-Item "$folderPath\*.png" -Destination $originalFolder
}

# Function to copy and renumber files to 'Original-Renum' folder
Function Copy-Renum-Files ($folderPath, $folderName) {
    $renumFolder = Join-Path $folderPath "Original-Renum"
    New-Item -ItemType Directory -Path $renumFolder -Force

    # Extract the part of the folder name after the '-'
    $relevantName = ($folderName -split ' - ')[1]

    # Convert the extracted name to PascalCase (aka UpperCamelCase)
    $formattedName = ($relevantName -split ' ' | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() }) -join ''

    $counter = 1
    Get-ChildItem "$folderPath\Original\*.png" | Get-Random -Count (Get-ChildItem "$folderPath\Original\*.png").Count | ForEach-Object {
        $newName = "${formattedName}_$(("{0:D3}" -f $counter)).png"
        Copy-Item $_.FullName -Destination (Join-Path $renumFolder $newName)
        $counter++
    }
}


# Function to color-correct files and save to 'Original-CC' folder
Function Color-Correct-Files ($folderPath) {
    $ccFolder = Join-Path $folderPath "Original-CC"
    New-Item -ItemType Directory -Path $ccFolder -Force
    Get-ChildItem "$folderPath\Original-Renum\*.png" | ForEach-Object {
        $outputFilename = Join-Path $ccFolder $_.Name
        & 'magick' $_.FullName -depth 16 -modulate 100,140,100 -auto-level -brightness-contrast 10x10 -colorspace sRGB -enhance -contrast -contrast-stretch 0 $outputFilename
    }
}

# Main Script Execution Starts Here

# Step 1: Select the working folder
$folderPath = Select-Folder
$folderName = (Get-Item -Path $folderPath).Name

# Step 2: Copy original files to 'Original' folder
Copy-Original-Files -folderPath $folderPath

# Step 3: Copy and renumber files to 'Original-Renum' folder
Copy-Renum-Files -folderPath $folderPath -folderName $folderName

# Step 4: Perform color correction and save to 'Original-CC' folder
Color-Correct-Files -folderPath $folderPath

Write-Host "All operations complete."
