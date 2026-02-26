$ErrorActionPreference = 'Stop'
$targetDirs = @('/repo/script', '/repo/tests')

$files = @()
foreach ($dir in $targetDirs) {
    if (Test-Path -LiteralPath $dir) {
        $files += Get-ChildItem -Path $dir -Recurse -File -Filter *.ps1 | Sort-Object FullName
    }
}

if ($files.Count -eq 0) {
    throw 'No PowerShell scripts found for parser checks'
}

$checked = 0
foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        $message = ($errors | ForEach-Object { $_.Message }) -join "`n"
        throw "PowerShell parse errors in $($file.FullName):`n$message"
    }
    $checked++
}

Write-Output "CHECKED=$checked"
