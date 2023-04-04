$extensionsFile = "$env:CHEZMOI_SOURCE_DIR\private_dot_config\gh\.extensions"

$extensions = Get-Content -Path $extensionsFile

$extensions | ForEach-Object { gh extension install $_ 2>$null }
