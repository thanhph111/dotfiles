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
