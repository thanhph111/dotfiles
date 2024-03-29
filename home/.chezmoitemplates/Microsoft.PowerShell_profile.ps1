#: Install extra modules:
#:   posh-git
#:   PsFzf
#:   Terminal-Icons
#:   z

#: Use this to profile the startup time of your PowerShell session
# Set-PSDebug -Trace 1

#: Print the message when starting PowerShell
'Welcome back!'

#region Functions

function Test-CommandExists {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Command
    )

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $Command) {
            $true
        }
    } catch {
        $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

function Test-ModuleExists {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Module
    )

    if (Get-Module $Module -ListAvailable) {
        $true
    } else {
        $false
    }
}

function Test-CommandParameterExists {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Command,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Parameter
    )

    if (-not (Test-CommandExists $Command)) {
        return $false
    }

    if ((Get-Command $Command).Parameters.Keys -contains $Parameter) {
        $true
    } else {
        $false
    }
}

function Write-AllPoshThemes {
    function Get-PoshThemes {
        if ($env:POSH_THEMES_PATH) {
            return Get-ChildItem $env:POSH_THEMES_PATH
        }
        if ((Test-CommandExists brew) -and (brew --prefix oh-my-posh)) {
            return Get-ChildItem "$(brew --prefix oh-my-posh)/themes/"
        }
        return @()
    }
    foreach ($file in Get-PoshThemes) {
        $env:POSH_THEME = $file.ToString()
        $themeName = $file.Name
        Write-Host ($themeName + ' ' + '-' * ([Console]::WindowWidth - $themeName.Length - 1))
        prompt
    }
}

function Get-ChildItemBySize {
    Get-ChildItem @args |
        Add-Member -Force -PassThru -Type ScriptProperty -Name Length -Value {
            Get-ChildItem $this -Recurse -Force | Measure-Object -Sum Length | Select-Object -Expand Sum
        } |
        Sort-Object Length -Descending |
        Format-Table @{ label = 'TotalSize (KB)'; expression = { [math]::Truncate($_.Length / 1KB) }; width = 14 },
        @{ label = 'Mode'; expression = { $_.Mode }; width = 8 },
        Name
}

function Measure-BootTimeShell {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]
        $Shell = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    )

    $number = 4
    $totalMilliSeconds = 0

    if (!(Test-CommandExists $Shell)) {
        Write-Error "Command '$Shell' not found"
        return
    }

    $scriptBlock = { & $Shell -i -c 'exit' }
    if ((Split-Path $Shell -Leaf -ErrorAction SilentlyContinue) -match 'powershell') {
        $scriptBlock = { & $Shell -Command 'exit' }
    }

    1..$number | ForEach-Object {
        $bootTime = (Measure-Command $scriptBlock).TotalMilliseconds
        Write-Output "Boot time ${_}: $bootTime ms"
        $totalMilliSeconds += $bootTime
    }
    Write-Output "Average boot time: $([math]::Round($totalMilliSeconds / $number)) ms"
}

# Import user modules
@(
    (Get-Module (Join-Path $PSScriptRoot Modules\UserModules\*) -ListAvailable).RootModule
    $USER_MODULES
) | Select-Object -Unique | Import-Module -DisableNameChecking

#endregion

#region PSReadLine

#: Use Emacs mode
Set-PSReadLineOption -EditMode Emacs

#: Change prompt in multiple line mode
Set-PSReadLineOption -ContinuationPrompt '...'

#: Prediction on type
if (Test-CommandParameterExists Set-PSReadLineOption PredictionSource) {
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -PredictionSource History
}

#: Adjust some colors for better visibility on white background
#: The issue https://github.com/PowerShell/PSReadLine/issues/464 might be a better solution
Set-PSReadLineOption -Colors @{
    'Command'                = "$([char]27)[94m"
    'Comment'                = "$([char]27)[90m"
    'ContinuationPrompt'     = "$([char]27)[37m"
    'Default'                = "$([char]27)[37m"
    'Emphasis'               = "$([char]27)[36m"
    'Error'                  = "$([char]27)[91m"
    'InlinePrediction'       = "$([char]27)[37;2m"
    'Keyword'                = "$([char]27)[35m"
    'ListPrediction'         = "$([char]27)[33m"
    'ListPredictionSelected' = "$([char]27)[97;47;5m"
    'Member'                 = "$([char]27)[37;2m"
    'Number'                 = "$([char]27)[34m"
    'Operator'               = "$([char]27)[33m"
    'Parameter'              = "$([char]27)[95m"
    'Selection'              = "$([char]27)[30;47m"
    'String'                 = "$([char]27)[36m"
    'Type'                   = "$([char]27)[31m"
    'Variable'               = "$([char]27)[32m"
}

#region Change keymaps in PSReadLine

#: Tab behavior, choose one of these
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
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
    -LongDescription 'Insert paired quotes if not already on a quote' `
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

#: Don't save to history when using VSCode terminal
if ($env:TERM_PROGRAM -eq 'vscode') {
    Set-PSReadLineOption -HistorySaveStyle SaveNothing
}

#: Intercept history saving
Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)

    #: Don't save to history commands which has less than 4 characters or starts with space or end with semicolon
    return $line.Length -gt 3 -and $line[0] -ne ' ' -and $line[0] -ne ';'
}

#endregion

#endregion

#region Tools

#region Oh My Posh

if (Test-CommandExists oh-my-posh) {
    #: Use a theme
    $env:POSH_THEME = '~/.config/oh-my-posh/multiplex.toml'
    oh-my-posh init pwsh | Invoke-Expression

    #: Enable-PoshTransientPrompt
    Enable-PoshTooltips

    #: Enable Git auto-completion
    #: This must be done after Oh My Posh initialization
    $env:POSH_GIT_ENABLED = $true

    #: Send an OSC99 escape sequence to the terminal to let it know of the current directory
    #: Only benefits the Windows Terminal
    #: This set an environment variable and the Oh My Posh theme have to print it out
    if ($env:WT_SESSION) {
        function Set-Osc99 {
            $env:OMP_SUFFIX = (
                "$([char]27)]9;9;`"$($executionContext.SessionState.Path.CurrentLocation)`"$([char]27)\"
            )
        }
        #: This overrides the `Set-PoshContext` and Oh My Posh uses it in the `prompt` function
        New-Alias -Name Set-PoshContext -Value Set-Osc99 -Scope Global -Force
    }

    #: Send an OSC7 escape sequence to the terminal to let it know of the current directory
    #: Only benefits the WezTerm terminal
    #: This set an environment variable and the Oh My Posh theme have to print it out
    if (($env:OS -eq 'Windows_NT') -and ($env:TERM_PROGRAM -eq 'WezTerm')) {
        function Set-Osc7 {
            $currentLocation = $executionContext.SessionState.Path.CurrentLocation
            if ($currentLocation.Provider.Name -eq 'FileSystem') {
                $directoryUri = "file://${env:COMPUTERNAME}/$($currentLocation.ProviderPath -replace '\\', '/')"
                $env:OMP_SUFFIX = "$([char]27)]7;${directoryUri}$([char]27)\"
            }
        }
        #: This overrides the `Set-PoshContext` and Oh My Posh uses it in the `prompt` function
        New-Alias -Name Set-PoshContext -Value Set-Osc7 -Scope Global -Force
    }
}

#endregion

#region Terminal-Icons

if (Test-ModuleExists Terminal-Icons) {
    #: This will slow down the startup time, about 400ms
    Import-Module Terminal-Icons
}

#endregion

#region PSFzf

if (Test-CommandExists Set-PsFzfOption) {
    #: Looking for filepaths
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+p'
    #: Looking for history commands
    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
}

#endregion

#region GitHub CLI

if (Test-CommandExists gh) {
    #: Completion
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
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
