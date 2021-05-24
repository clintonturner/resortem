[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    $Path
)

# The temporary folder into which we'll move the files before moving them back in order. GUID to avoid naming collisions.
[string]$TemporaryName = "0c7da1681a3241b081a3e6134e5199ff"
# The name of this script when executed from the command line, so we can filter it out of the list of files to be moved.
[string]$ScriptName = $PSCommandPath

# Recurse down the folder hierarhcy, re-sorting the files one-by-one so they are in order in the file allocation table.
function ProcessFolder($Folder) {
    Write-Host $Folder

    # Get a list of all files in the current folder, sorted alphbetically by name.
    $Files = Get-ChildItem -Path $Folder -File | Sort-Object -Property Name 

    # Remove this script's name from $Files
    $Files = $Files | Where-Object -Property FullName -NE $ScriptName

    # Skip the move operations if we didn't find any files
    if ($null -ne $Files) {
        # Create the temporary directory
        $TemporaryFolder = New-Item -Path $TemporaryName -ItemType Directory
        # Move all files into the temp directory
        $MovedFiles = Move-Item -LiteralPath $Files -Destination $TemporaryFolder -PassThru
        # Move the files back, one by one
        foreach ($MovedFile in $MovedFiles) {
            $MovedBack = Move-Item -LiteralPath $MovedFile -Destination $Folder -PassThru
            Write-Host $MovedBack
        }
        # Clean up the temporary directory but only if it's empty
        if (Test-Path -Path $TemporaryName) {
            $SubItems = Get-ChildItem -Force:$true -LiteralPath $TemporaryName
            If ($null -eq $SubItems) 
            {
                Remove-Item -LiteralPath $TemporaryName
            }
        }
    }

    # Recurse into subdirectories
    $Folders = Get-ChildItem -Path $Folder -Directory | Sort-Object -Property Name
    foreach ($Directory in $Folders) {
        ProcessFolder $Directory
    }
}

$StartPath = Resolve-Path $Path

ProcessFolder $StartPath
