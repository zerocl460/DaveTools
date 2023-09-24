# Source and destination paths
$sourcePath = "C:\Users\Editor\OneDrive\Old Files\Documents\GitHub\DaveTools\image_processing.ps1"
$destinationPath = "Q:\Halloween & Horror\Canvas Spooky Bundle\image_processing.ps1"

# Copy file (overwrite if it exists)
Copy-Item -Path $sourcePath -Destination $destinationPath -Force
