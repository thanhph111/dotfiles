if (-not (Get-PackageProvider NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force
}

@(
    'posh-git',
    'PsFzf',
    'PSReadline',
    'Terminal-Icons',
    'z'
) | ForEach-Object {
    if (-not (Get-InstalledModule $_ -ErrorAction SilentlyContinue)) {
        Install-Module $_ -Repository PSGallery -Scope CurrentUser -Force -AllowClobber
    }
}
