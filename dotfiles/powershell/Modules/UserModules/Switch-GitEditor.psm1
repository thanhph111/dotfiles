$ValidEditors = @{
    "atom"   = "atom.cmd --wait"
    "vim"    = "vim.bat"
    "vscode" = "code --wait"
}


function Switch-GitEditor {
    param(
        [Parameter()]
        [ValidateSet("atom", "vim", "vscode")]
        [string]
        $Editor
    )
    git config --global core.editor $ValidEditors.$Editor

    $GitConfigFile = $HOME + "\.gitconfig"
    if (Test-Path $GitConfigFile) {
        (Get-Item $GitConfigFile).Attributes = "Hidden"
    }
}


Export-ModuleMember -Function Switch-GitEditor
