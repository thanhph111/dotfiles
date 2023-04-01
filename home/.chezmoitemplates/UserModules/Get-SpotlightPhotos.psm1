function Get-SpotlightPhotos {
    param(
        [int]$ReverseDays = 10
    )

    $PhotoPath = $Env:LOCALAPPDATA + "\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
    $NewFolder = "SpotlightPhotos"
    $NewPath = $HOME + "\" + $NewFolder
    $LibraryPath = "C:\Users\thanh\OneDrive\Sync Drive\Wallpapers\Windows Spotlight"

    if (Test-Path -Path $NewPath) {
        Write-Output "Folder $NewFolder found in $HOME."
        $Message = "Do you want to delete it? [Y to delete]"
        $IsDelete = Read-Host -Prompt $Message
        if ($IsDelete -eq "y") {
            Remove-Item -Path $NewPath -Recurse
        } else {
            "Script end."
            exit
        }
    }

    if (Test-Path -Path $PhotoPath) {
        $Limit = (Get-Date).AddDays(- $ReverseDays)
        New-Item -ItemType Directory -Path $NewPath | Out-Null
        Get-ChildItem -Path $PhotoPath | Where-Object { $_.LastWriteTime -gt $Limit } | Copy-Item -Destination $NewPath
        Get-ChildItem -Path $NewPath | Rename-Item -NewName { $_.Name + ".jpg" }
        if (Test-Path $LibraryPath) { Invoke-Item $LibraryPath }
        Invoke-Item $NewPath
    } else {
        Write-Output "Source Spotlight photos path does not exist."
    }
}


Export-ModuleMember -Function Get-SpotlightPhotos