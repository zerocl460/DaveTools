# Load Windows Forms assembly for folder picker
Add-Type -AssemblyName System.Windows.Forms

Function ConvertTo-PascalCase ($folderName) {
    # Remove leading/trailing whitespaces and split by '-' or '_'
    $parts = ($folderName.Trim() -split '[-_]')

    # Use the last part if it exists, otherwise the whole string
    $namePart = if ($parts.Count -gt 1) { $parts[1] } else { $parts[0] }

    # Remove any numbers from the beginning (e.g., V01 or V100)
    $namePart = $namePart -replace '^\d+', ''

    # Convert to PascalCase (aka UpperCamelCase)
    $pascalCaseName = ($namePart -split ' ' | ForEach-Object { 
        if ($_.Length -gt 1) {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
        }
        elseif ($_.Length -eq 1) {
            $_.ToUpper()
        }
    }) -join ''

    return $pascalCaseName
}

# Set $folderPath to the directory where the .ps1 script is located
$folderPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Get the name of the folder the script is in
$folderName = Split-Path $folderPath -Leaf

# Convert folder name to PascalCase
$pascalCaseName = ConvertTo-PascalCase $folderName

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

# Function to color-correct files located in a given input folder and save them to an output folder
Function Color-Correct-Files ($inputFolder, $outputFolder) {

    # Check if the input or output folder path is null or empty. If so, exit the function.
    if ([string]::IsNullOrEmpty($inputFolder) -or [string]::IsNullOrEmpty($outputFolder)) {
        Write-Host "Input or Output folder is null or empty. Exiting."
        return
    }

    # Check if the input folder actually exists. If not, exit the function.
    if (-Not (Test-Path $inputFolder)) {
        Write-Host "Input folder does not exist. Exiting."
        return
    }

    # Create the output folder, or overwrite if it exists
    New-Item -ItemType Directory -Path $outputFolder -Force

    # Iterate through all files in the input folder, filtering to only process .png and .jpg files
    Get-ChildItem "$inputFolder\*.*" | Where-Object { $_.Extension -eq '.png' -or $_.Extension -eq '.jpg' } | ForEach-Object {
        
        # Determine the output filename based on the original file's name but save as JPG
        $outputFilename = Join-Path $outputFolder ($_.BaseName + ".jpg")
        
        # Run ImageMagick command to apply various color-correction operations and save as JPG with 100% quality
        & 'magick' $_.FullName -depth 16 -modulate 100,140,100 -auto-level -brightness-contrast 5x5 -colorspace sRGB -enhance -contrast-stretch 0 -quality 100 $outputFilename

        # Output a message to indicate progress
        Write-Host "Processed and saved $outputFilename"
    }
}

# Function to create Gigapixeled-Original folder
Function Create-Gigapixeled-Original ($folderPath) {
    $gigaOrigFolder = Join-Path $folderPath "Gigapixeled-Original"
    New-Item -ItemType Directory -Path $gigaOrigFolder -Force
    # Add code to populate this folder if needed
}

# Function to create Gigapixeled-CC folder
Function Create-Gigapixeled-CC ($folderPath) {
    $gigaCCFolder = Join-Path $folderPath "Gigapixeled-CC"
    New-Item -ItemType Directory -Path $gigaCCFolder -Force
    # Add code to populate this folder if needed
}

# Function to create an output folder
Function Create-Output-Folder ($inputFolder, $outputBaseName) {
    # Check if the input folder path is null or empty. If so, exit the function.
    if ([string]::IsNullOrEmpty($inputFolder)) {
        Write-Host "Input folder is null or empty. Exiting."
        return $null
    }

    # Get the last part of the input folder's path (folder name)
    $folderName = [System.IO.Path]::GetFileName($inputFolder)

    # Remove leading/trailing whitespaces and split by '-' or '_'
    $parts = ($folderName.Trim() -split '[-_]')
    
    # Use the last part if it exists, otherwise the whole string
    $namePart = if ($parts.Count -gt 1) { $parts[1] } else { $parts[0] }

    # Remove any numbers from the beginning (e.g., V01 or V100)
    $namePart = $namePart -replace '^\d+', ''

    # Convert to PascalCase (aka UpperCamelCase)
    $pascalCaseName = ($namePart -split ' ' | ForEach-Object { 
        if ($_.Length -gt 1) {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
        }
        elseif ($_.Length -eq 1) {
            $_.ToUpper()
        }
    }) -join ''

    # Construct the output folder path
    $outputFolder = Join-Path $inputFolder $outputBaseName

    return $outputFolder
}

<# # Function to create movies from images
Function Create-Movies ($inputFolder, $outputFolder, $framerate) {
    # Check if the input folder path is null or empty. If so, exit the function.
    if ([string]::IsNullOrEmpty($inputFolder)) {
        Write-Host "Input folder is null or empty. Exiting."
        return
    }

    # Check if the output folder path is null or empty. If so, exit the function.
    if ([string]::IsNullOrEmpty($outputFolder)) {
        Write-Host "Output folder is null or empty. Exiting."
        return
    }

    # Check if the input folder actually exists. If not, exit the function.
    if (-Not (Test-Path $inputFolder)) {
        Write-Host "Input folder does not exist. Exiting."
        return
    }

    # Create the output folder if it doesn't exist
    if (-Not (Test-Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder -Force
    }

    # Get a list of all image files in the input folder (jpg or png)
    $imageFiles = Get-ChildItem $inputFolder -File | Where-Object { $_.Extension -eq '.jpg' -or $_.Extension -eq '.png' }

    # Generate a movie file name based on the input folder name
    $movieName = [System.IO.Path]::GetFileName($inputFolder) -replace '_\d{3}', '' -replace '_', ' ' -replace '.png', '.mov'

    # Construct the full path for the movie file
    $moviePath = Join-Path $outputFolder $movieName

    # Use ffmpeg to create a movie from the image sequence
    & 'ffmpeg' -framerate $framerate -i "$inputFolder\%03d.jpg" -c:v prores_ks -profile:v 3 -y $moviePath

    Write-Host "Created ProRes movie: $moviePath"

    # Use ffmpeg to create an mp4 movie from the image sequence
    $mp4Path = $moviePath -replace '.mov', '.mp4'
    & 'ffmpeg' -framerate $framerate -pattern_type glob -i "$inputFolder\*.jpg" -c:v libx264 -pix_fmt yuv420p -y $mp4Path
    Write-Host "Created MP4 movie: $mp4Path" #>
}

# Input folder for the color-corrected images (jpg or png)
$originalCCFolder = Join-Path $folderPath "Original-CC"

<# # Create an output folder for the movies with a simplified name
$outputFolder = Create-Output-Folder -inputFolder $originalCCFolder -outputBaseName "Scrubs"

# Set the frame rate to 30 fps
$frameRate = 30

# After color correction completes:
Create-Movies -inputFolder $originalCCFolder -outputFolder $outputFolder -framerate $frameRate #>




# Step 1: Select the working folder
$folderPath = Select-Folder
$folderName = (Get-Item -Path $folderPath).Name

# Step 2: Copy original files to 'Original' folder
Copy-Original-Files -folderPath $folderPath

# Step 3: Copy and renumber files to 'Original-Renum' folder
Copy-Renum-Files -folderPath $folderPath -folderName $folderName


# Step 4: Perform color correction on 'Original-Renum' and save to 'Original-CC' folderaa
$originalRenumFolder = Join-Path $folderPath "Original-Renum"
$originalCCFolder = Join-Path $folderPath "Original-CC"
Color-Correct-Files -inputFolder $originalRenumFolder -outputFolder $originalCCFolder

# Signal that color correction is complete
Write-Host "Color Correction Complete."

# Step 5: Make Gigapixel Folders
Create-Gigapixeled-Original $folderPath
Create-Gigapixeled-CC $folderPath

<# # Step 6: Wait for Color Correction to complete before creating movies
# Check if the 'Original-CC' folder contains files before proceeding
$originalCCFolder = Join-Path $folderPath "Original-CC"
while ((Get-ChildItem $originalCCFolder -File | Measure-Object).Count -eq 0) {
    Write-Host "Waiting for Color Correction to complete..."
    Start-Sleep -Seconds 5  # Adjust the delay time as needed
}

# Step 7: Now that Color Correction is complete, create movies
# Set the output folder for movies
$outputFolder = Join-Path $folderPath "Movies"
Create-Movies -inputFolder $originalCCFolder -outputFolder $outputFolder -framerate $frameRate #>

Write-Host "All operations complete."