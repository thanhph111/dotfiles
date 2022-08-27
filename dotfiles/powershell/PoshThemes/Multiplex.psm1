#Requires -Version 2 -Modules posh-git
# For dark screen only


function Compress-String {
    param(
        [Parameter(Mandatory = $true)]
        [string]$String
    )
    if ($String.length -gt $MaxCharacters) {
        $Real = [int](($MaxCharacters - $TruncatedStringSymbol.length) / 2)
        return -join $String[0..$Real] + $TruncatedStringSymbol + -join $String[(-$Real)..-1]
    }
    return $String
}


function Get-Path {
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PathInfo]
        $Dir
    )

    $OSPathSeparator = [System.IO.Path]::DirectorySeparatorChar
    $Provider = $Dir.Provider.Name
    $HomeDir = $HOME.TrimEnd('/', '\')

    if ($Dir.Path.StartsWith($HomeDir)) {
        $Path = $Dir.Path.Replace($HomeDir, $SL.PromptSymbols.HomeSymbol)
    }
    elseif ($Dir.Path.StartsWith($Env:SystemRoot, "CurrentCultureIgnoreCase")) {
        $Path = $Dir.Path -iReplace ([Regex]::Escape($Env:SystemRoot)), $SL.PromptSymbols.RootSymbol
    }
    else {
        $Path = $Dir.Path.Replace($Dir.Drive.Name + ":", $Dir.Drive.Name)
    }

    $ShortPath = $Path.TrimEnd($OSPathSeparator).Split($OSPathSeparator)
    $ShortPath = $ShortPath | ForEach-Object { Compress-String $_ }

    if ($ShortPath.length -gt $MaxDirectory) {
        return (($ShortPath[0], $ShortPath[1]) -join $SL.PromptSymbols.PathSeparator) + $SL.PromptSymbols.TruncatedFolderSymbol + (($ShortPath[-2], $ShortPath[-1]) -join $SL.PromptSymbols.PathSeparator)
    }

    return $ShortPath -join $SL.PromptSymbols.PathSeparator
}


# function Write-Theme {
#     param(
#         [bool]
#         $lastCommandFailed,
#         [string]
#         $with
#     )
#     $lastColor = $SL.Colors.PromptBackgroundColor
#     $Prompt = Write-Prompt -Object $SL.PromptSymbols.StartSymbol -ForegroundColor $SL.Colors.SessionInfoForegroundColor -BackgroundColor $SL.Colors.SessionInfoBackgroundColor
#
#     #check the last command state and indicate if failed
#     If ($lastCommandFailed) {
#         $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $SL.Colors.CommandFailedIconForegroundColor -BackgroundColor $SL.Colors.SessionInfoForegroundColor
#     }
#     else {
#       $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $SL.Colors.GitDefaultColor -BackgroundColor $SL.Colors.SessionInfoForegroundColor
#     }
#
#     #check for elevated prompt
#     If (Test-Administrator) {
#         $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.ElevatedSymbol) " -ForegroundColor $SL.Colors.AdminIconForegroundColor -BackgroundColor $SL.Colors.SessionInfoForegroundColor
#     }
#
#     # Check SystemRoot
#     If ($PWD.Path.StartsWith($Env:SystemRoot, "CurrentCultureIgnoreCase")) {
#         $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.RootSymbol) " -ForegroundColor $SL.Colors.AdminIconForegroundColor -BackgroundColor $SL.Colors.SessionInfoForegroundColor
#     }
#
#     $User = $SL.CurrentUser
#     $Computer = $SL.CurrentHostname
#     if (Test-NotDefaultUser($User)) {
#         $Prompt += Write-Prompt -Object "$User@$Computer" -ForegroundColor $SL.Colors.PromptForegroundColor -BackgroundColor $SL.Colors.SessionInfoForegroundColor
#     }
#
#     if (Test-VirtualEnv) {
#         $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $SL.Colors.SessionInfoForegroundColor -BackgroundColor $SL.Colors.VirtualEnvBackgroundColor
#         $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.VirtualEnvSymbol) $(Get-VirtualEnvName) " -ForegroundColor $SL.Colors.VirtualEnvForegroundColor -BackgroundColor $SL.Colors.VirtualEnvBackgroundColor
#         $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $SL.Colors.VirtualEnvBackgroundColor -BackgroundColor $SL.Colors.PromptBackgroundColor
#     }
#     else {
#         $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $SL.Colors.SessionInfoForegroundColor -BackgroundColor $SL.Colors.PromptBackgroundColor
#     }
#
#     # Writes the drive portion
#     $Path = Get-Path -dir $PWD
#     $Prompt += Write-Prompt -Object "$Path " -ForegroundColor $SL.Colors.SessionInfoBackgroundColor -BackgroundColor $SL.Colors.PromptBackgroundColor
#
#     $status = Get-VCSStatus
#     if ($status) {
#         $ThemeInfo = Get-VcsInfo -status ($status)
#         $lastColor = $ThemeInfo.BackgroundColor
#         $Prompt += Write-Prompt -Object $($SL.PromptSymbols.SegmentForwardSymbol) -ForegroundColor $SL.Colors.PromptBackgroundColor -BackgroundColor $lastColor
#         $Prompt += Write-Prompt -Object " $($ThemeInfo.VcInfo) " -BackgroundColor $lastColor -ForegroundColor $SL.Colors.GitForegroundColor
#     }
#
#     # Write time
#     $TimeStamp = Get-Date -UFormat %R
#     $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $SL.Colors.WithBackgroundColor
#     $Prompt += Write-Prompt -Object " $($TimeStamp)$([char]::ConvertFromUtf32(0xFA19))" -BackgroundColor $SL.Colors.WithBackgroundColor -ForegroundColor $SL.Colors.PromptForegroundColor
#     $lastColor = $SL.Colors.WithBackgroundColor
#     $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor
#
#     if ($with) {
#         $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $SL.Colors.WithBackgroundColor
#         $Prompt += Write-Prompt -Object " $($with.ToUpper()) " -BackgroundColor $SL.Colors.WithBackgroundColor -ForegroundColor $SL.Colors.WithForegroundColor
#         $lastColor = $SL.Colors.WithBackgroundColor
#         $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor
#     }
#
#     # Write the symbol in new line
#     $Prompt += Set-Newline
#     $Prompt += Write-Prompt -Object ($SL.PromptSymbols.PromptIndicator) -ForegroundColor $SL.Colors.PromptBackgroundColor
#     $Prompt += " "
#     $Prompt
# }


function Write-Theme {
    param(
        [bool]
        $LastCommandFailed,
        [string]
        $with
    )
    $LastForegroundColor = $LayerTextColor1
    $LastBackgroundColor = $LayerBackgroundColor1

    $Prompt = Write-Prompt -Object $SL.PromptSymbols.StartSymbol -ForegroundColor $LayerBackgroundColor1 -BackgroundColor $SL.Colors.SessionInfoBackgroundColor


    # Check the last command state and indicate if failed
    If ($LastCommandFailed) {
        $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $([System.ConsoleColor]::DarkRed) -BackgroundColor $LastBackgroundColor
    }
    else {
      $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $([System.ConsoleColor]::Green) -BackgroundColor $LastBackgroundColor
    }

    #check for elevated prompt
    If (Test-Administrator) {
        $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.ElevatedSymbol) " -ForegroundColor $([System.ConsoleColor]::DarkYellow) -BackgroundColor $LastBackgroundColor
    }

    # Check SystemRoot
    If ($PWD.Path.StartsWith($Env:SystemRoot, "CurrentCultureIgnoreCase")) {
        $Prompt += Write-Prompt -Object "$($SL.PromptSymbols.RootSymbol) " -ForegroundColor $([System.ConsoleColor]::DarkYellow) -BackgroundColor $LastBackgroundColor
    }

    # Write time
    $TimeStamp = Get-Date -UFormat %R
    $Prompt += Write-Prompt -Object "$TimeSymbol $TimeStamp " -ForegroundColor $LastForegroundColor -BackgroundColor $LastBackgroundColor

    $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $LayerBackgroundColor1 -BackgroundColor $LayerBackgroundColor2

    $LastForegroundColor = $LayerTextColor2
    $LastBackgroundColor = $LayerBackgroundColor2

    $User = $SL.CurrentUser
    $Computer = $SL.CurrentHostname
    if (Test-NotDefaultUser($User)) {
        $Prompt += Write-Prompt -Object " $User@$Computer " -ForegroundColor $LastForegroundColor -BackgroundColor $LastBackgroundColor
    }


    if (Test-VirtualEnv) {
        $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $LayerBackgroundColor2 -BackgroundColor $LayerBackgroundColor3

        $LastForegroundColor = $LayerTextColor3
        $LastBackgroundColor = $LayerBackgroundColor3

        $Prompt += Write-Prompt -Object " $($SL.PromptSymbols.VirtualEnvSymbol) $(Get-VirtualEnvName) " -ForegroundColor $LastForegroundColor -BackgroundColor $LastBackgroundColor

        $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $LayerBackgroundColor3 -BackgroundColor $LayerBackgroundColor4
    }
    else {
        $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $LayerBackgroundColor2 -BackgroundColor $LayerBackgroundColor4
    }

    # Writes the drive portion
    $LastForegroundColor = $LayerTextColor4
    $LastBackgroundColor = $LayerBackgroundColor4

    $Path = Get-Path -dir $PWD
    $Prompt += Write-Prompt -Object " $Path " -ForegroundColor $LastForegroundColor -BackgroundColor $LastBackgroundColor

    # Write VCS status
    $Status = Get-VCSStatus
    if ($Status) {
        $ThemeInfo = Get-VcsInfo -Status ($Status)
        $LastBackgroundColor = $ThemeInfo.BackgroundColor
        $Prompt += Write-Prompt -Object $($SL.PromptSymbols.SegmentForwardSymbol) -ForegroundColor $LayerBackgroundColor4 -BackgroundColor $LastBackgroundColor
        $Prompt += Write-Prompt -Object " $($ThemeInfo.VcInfo) " -ForegroundColor $SL.Colors.GitForegroundColor -BackgroundColor $LastBackgroundColor
    }

    $LastForegroundColor, $LastBackgroundColor = $LastBackgroundColor, $LastForegroundColor

    $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $LastForegroundColor

    if ($with) {
        $LastForegroundColor = [System.ConsoleColor]::Black
        $LastBackgroundColor = [System.ConsoleColor]::White
        $Prompt = Write-Prompt -Object " $($SL.PromptSymbols.StartSymbol)" -ForegroundColor $LastBackgroundColor -BackgroundColor $SL.Colors.SessionInfoBackgroundColor
        $Prompt += Write-Prompt -Object " $($with.ToUpper()) " -ForegroundColor $LastForegroundColor -BackgroundColor $LastBackgroundColor
        $Prompt += Write-Prompt -Object $SL.PromptSymbols.SegmentForwardSymbol -ForegroundColor $LastBackgroundColor
    }

    # Write the symbol in new line
    $Prompt += Set-Newline
    $Prompt += Write-Prompt -Object ($SL.PromptSymbols.PromptIndicator) -ForegroundColor $([System.ConsoleColor]::DarkCyan)
    $Prompt += " "
    $Prompt
}


$MaxCharacters = 15
$MaxDirectory = 4
$TruncatedStringSymbol = [char]::ConvertFromUtf32(0x2026)
$TimeSymbol = [char]::ConvertFromUtf32(0xFA19)

$Git = $global:GitPromptSettings

# $Git.FileAddedText = [char]::ConvertFromUtf32(0x25A0)
# $Git.FileModifiedText = [char]::ConvertFromUtf32(0x25EA)
# $Git.FileRemovedText = [char]::ConvertFromUtf32(0x25A1)

$SL = $global:ThemeSettings

# Custom symbols
$SL.PromptSymbols.StartSymbol                    = [char]::ConvertFromUtf32(0xE0B6)
$SL.PromptSymbols.TruncatedFolderSymbol          = " " + [char]::ConvertFromUtf32(0x00BB) + " "
$SL.PromptSymbols.PromptIndicator                = [char]::ConvertFromUtf32(0x25B6)
$SL.PromptSymbols.FailedCommandSymbol            = [char]::ConvertFromUtf32(0x25CF)
$SL.PromptSymbols.ElevatedSymbol                 = [char]::ConvertFromUtf32(0xF997)
$SL.PromptSymbols.SegmentForwardSymbol           = [char]::ConvertFromUtf32(0xE0B4)
# $SL.PromptSymbols.SegmentBackwardSymbol          = [char]::ConvertFromUtf32(0x)
# $SL.PromptSymbols.SegmentSeparatorForwardSymbol  = [char]::ConvertFromUtf32(0x)
# $SL.PromptSymbols.SegmentSeparatorBackwardSymbol = [char]::ConvertFromUtf32(0x)
$SL.PromptSymbols.PathSeparator                  = " " + [char]::ConvertFromUtf32(0x2219) + " "
# $SL.PromptSymbols.VirtualEnvSymbol               = [char]::ConvertFromUtf32(0x)
$SL.PromptSymbols.HomeSymbol                     = [char]::ConvertFromUtf32(0xF015)
# $SL.PromptSymbols.HomeSymbol                     = [char]::ConvertFromUtf32(0xE5FE)
$SL.PromptSymbols.RootSymbol                     = [char]::ConvertFromUtf32(0xF992)
# $SL.PromptSymbols.UNCSymbol                      = [char]::ConvertFromUtf32(0x)

# Custom colors
$SL.Colors.GitDefaultColor                         = [System.ConsoleColor]::DarkGreen
# $SL.Colors.GitLocalChangesColor                    = [System.ConsoleColor]::DarkYellow
# $SL.Colors.GitNoLocalChangesAndAheadColor          = [System.ConsoleColor]::DarkMagenta
# $SL.Colors.GitNoLocalChangesAndBehindColor         = [System.ConsoleColor]::DarkRed
# $SL.Colors.GitNoLocalChangesAndAheadAndBehindColor = [System.ConsoleColor]::DarkRed
$SL.Colors.PromptForegroundColor                   = [System.ConsoleColor]::White
# $SL.Colors.PromptHighlightColor                    = [System.ConsoleColor]::DarkBlue
# $SL.Colors.DriveForegroundColor                    = [System.ConsoleColor]::DarkBlue
$SL.Colors.PromptBackgroundColor                   = [System.ConsoleColor]::Blue
# $SL.Colors.PromptSymbolColor                       = [System.ConsoleColor]::White
$SL.Colors.SessionInfoBackgroundColor              = [System.ConsoleColor]::Black
$SL.Colors.SessionInfoForegroundColor              = [System.ConsoleColor]::Magenta
# $SL.Colors.CommandFailedIconForegroundColor        = [System.ConsoleColor]::DarkRed
# $SL.Colors.AdminIconForegroundColor                = [System.ConsoleColor]::DarkYellow
$SL.Colors.WithBackgroundColor                     = [System.ConsoleColor]::Magenta
$SL.Colors.WithForegroundColor                     = [System.ConsoleColor]::DarkRed
$SL.Colors.GitForegroundColor                      = [System.ConsoleColor]::Black
$SL.Colors.VirtualEnvForegroundColor               = [System.ConsoleColor]::White
$SL.Colors.VirtualEnvBackgroundColor               = [System.ConsoleColor]::Red


$LayerTextColor1 = [System.ConsoleColor]::White
$LayerTextColor2 = [System.ConsoleColor]::White
$LayerTextColor3 = [System.ConsoleColor]::Black
$LayerTextColor4 = [System.ConsoleColor]::Black

$LayerBackgroundColor1 = [System.ConsoleColor]::DarkBlue
$LayerBackgroundColor2 = [System.ConsoleColor]::Blue
$LayerBackgroundColor3 = [System.ConsoleColor]::DarkCyan
$LayerBackgroundColor4 = [System.ConsoleColor]::Cyan
