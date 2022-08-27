# This script will direct to source directory when using 'cd' alias with shortcut file '.lnk'
# Need to remove alias 'cd' first


function cd {
    param(
        [string]
        $target
    )
    if ($target.ToString().EndsWith(".lnk")) {
        $sh = New-Object -com wscript.shell
        $fullpath = (Resolve-Path $target).Path
        $targetpath = $sh.CreateShortcut($fullpath).TargetPath
        Set-Location $targetpath
    } else {
        Set-Location $target
    }
}


Export-ModuleMember -Function cd