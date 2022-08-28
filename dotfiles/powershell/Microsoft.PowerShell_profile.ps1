#: Get-Package
#:
#: Name                           Version          Source                           ProviderName
#: ----                           -------          ------                           ------------
#: z                              1.1.13           https://www.powershellgallery.c… PowerShellGet
#: Terminal-Icons                 0.7.1            https://www.powershellgallery.c… PowerShellGet
#: posh-git                       1.0.0            https://www.powershellgallery.c… PowerShellGet
#: oh-my-posh                     6.33.0           https://www.powershellgallery.c… PowerShellGet
#: PSFzf                          2.2.9            https://www.powershellgallery.c… PowerShellGet

#: Print the message when starting PowerShell
"Welcome back!"

#region Oh My Posh

#: Use this only if installing using `Install-Module oh-my-posh`
# Import-Module oh-my-posh

#: Use a theme
oh-my-posh --init --shell pwsh --config ~/.poshthemes/multiplex.omp.toml | Invoke-Expression

#: Enable-PoshTransientPrompt
Enable-PoshTooltips

#endregion

#region Terminal-Icons

#: This will slow down the startup time, about 400ms
# Import-Module Terminal-Icons

#endregion

#region PSFzf

#: Looking for filepaths
Set-PsFzfOption -PSReadlineChordProvider "Ctrl+p"
#: Looking for history commands
Set-PsFzfOption -PSReadlineChordReverseHistory "Ctrl+r"

#endregion

#region PSReadLine

#: Change prompt in multiple line mode
Set-PSReadLineOption -ContinuationPrompt "..."

#: Set this after 2.2.0 for prediction feature
# Set-PSReadLineOption -PredictionViewStyle ListView
# Set-PSReadLineOption -PredictionSource History

#region Change keymaps in PSReadLine

#: Tab behavior, choose one of these
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# Set-PSReadlineKeyHandler -Key Tab -Function Complete
# Set-PSReadLineKeyHandler -Key Tab -Function TabCompleteNext
#: Also the `Shift+Tab` key
Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious

#: Up/down arrow to select history items
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
#: Put the cursor at the end of the line when getting the history
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Set-PSReadlineKeyHandler -Key Ctrl+z -Function Undo
# Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord

#: Insert paired quotes if not already on a quote
Set-PSReadLineKeyHandler -Chord 'Oem7', 'Shift+Oem7' `
    -BriefDescription SmartInsertQuote `
    -LongDescription "Insert paired quotes if not already on a quote" `
    -ScriptBlock {
    param($key, $arg)
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line[$cursor] -eq $key.KeyChar) {
        # Just move the cursor
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    } else {
        # Insert matching quotes, move cursor to be in between the quotes
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)" * 2)
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
    }
}

#endregion

#endregion

#region Old Windows profile

<#
# Print the message when starting PowerShell
"Welcome back!"


# Set prompt theme
Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Multiplex2


# Run '.environ' file which executes commands and assigns some variables that depend on specific computer
$USER_PATHS = @()
$USER_MODULES = @()
$USER_REMOVED_ALIASES = @()
$USER_NEW_ALIASES = @{}
$USER_ENVIRONMENT_VARIABLES = @{}
if (Test-Path $HOME/.environ) { Invoke-Expression (Get-Content -Raw $HOME/.environ) }


# Add paths
$Env:Path += ";" + ((@(
            (Get-ChildItem (Join-Path $Env:OneDriveConsumer Cloud\Binaries) -Recurse -Directory "bin").FullName
            $USER_PATHS
        ) | Select-Object -Unique) -join ";")


# Import modules
Import-Module -DisableNameChecking (@(
    "C:\Users\thanh\Desktop\Local\Repos\dotfiles-manager\DotfilesManager.psm1"
    (Get-Module (Join-Path $PSScriptRoot Modules\UserModules\*) -ListAvailable).RootModule
    $USER_MODULES
) | Select-Object -Unique)


# Remove aliases
@(
    # Remove cd alias to use custom cd alias in Goto-Shortcut.ps1
    "cd"
    $USER_REMOVED_ALIASES
) | ForEach-Object { Remove-Item Alias:$_ -Force }


# Create aliases
(@{
    "whereis" = "where.exe"
} + $USER_NEW_ALIASES).GetEnumerator() | ForEach-Object { Set-Alias -Name $_.Key -Value $_.Value }


# Set environment variables
(@{
    USER_CLOUD_ASSET = "$Env:OneDriveConsumer\Cloud\Assets\"
} + $USER_ENVIRONMENT_VARIABLES).GetEnumerator() | ForEach-Object { Set-Item -Path Env:$($_.Key) -Value $_.Value }


# Default parameter values
# $PSDefaultParameterValues = @{
#     "Out-File:Encoding" = "utf8"
# }


# Change keymaps in PSReadLine
Set-PSReadLineKeyHandler -Key "Ctrl+m" -Function MenuComplete
Set-PSReadLineKeyHandler -Key "shift+tab" -Function ForwardWord
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
#>

#endregion

#region Local config example

<#
# User paths
$USER_PATHS = @(
    "C:\Program Files\gnuwin32\bin"
)

# User modules
$USER_MODULES = @(
    "C:\Users\thanh\Desktop\Local\Repos\set-atom-profile\Set-AtomProfile.psm1"
)

# User removed aliases
$USER_REMOVED_ALIASES = @(
    "si"
)

# User new aliases
$USER_NEW_ALIASES = @{
    "ghelp" = "Get-Help"
}

# User environment variables
$USER_ENVIRONMENT_VARIABLES = @{
    DOTNET_CLI_TELEMETRY_OPTOUT = 1
}

# Set encoding
$PSDefaultParameterValues["*:Encoding"] = "Default"
$OutputEncoding = [System.Text.Utf8Encoding]::new($false)

# GitHub CLI completion
Invoke-Expression -Command $(gh completion -s powershell | Out-String)
#>

#endregion
