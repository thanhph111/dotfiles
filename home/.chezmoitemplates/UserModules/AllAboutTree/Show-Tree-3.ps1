<#
.Synopsis
   Show an ASCII text representation of a namespace tree

.DESCRIPTION
 Script to show the layout of PowerShell namespaces (Trees) using ASCII

.EXAMPLE
PS> show-tree C:\ -MaxDepth 2

.EXAMPLE
PS> show-tree C:\ -MaxDepth 2 -NotLike Wind*,P* -Verbose

.EXAMPLE
PS> New-PSDrive -PSProvider Registry -Root HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ -Name WINDOWS
PS> Show-Tree Windows: -maxdepth 1 -ShowDirectory

.NOTE
-Like and -NotLike feature only affect with files.
Otherwise, I don't know how to deal with this situation: parent folders are not allowed to listed but their children are.
#>


function format-type {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $object
    )
    foreach ($filesGroup in $extensionTypes.values) {
        if ($filesGroup[1].contains([IO.Path]::GetExtension($object.Extension))) {
            return $color = $filesGroup[0]
        }
    }
    return $color = $null
}


function Show-Tree {
    [CmdletBinding()]
    [Alias("st")]
    [OutputType([string[]])]
    param(
        [Parameter(Position = 0)]
        $Path = (Get-Location),

        [Parameter()]
        [int]$MaxDepth = [int]::MaxValue,

        #List of wildcard matches. If a directoryname matches one of these, it will be skipped.
        [Parameter()]
        [String[]]$NotLike = $null,

        #List of wildcard matches. If a directoryname matches one of these, it will be shown.
        [Parameter()]
        [String[]]$Like = $null
    )

    function Get-Tree {
        [CmdletBinding()]
        [OutputType([string[]])]
        param(
            [Parameter(Position = 0)]
            $Path = (Get-Location),

            [Parameter()]
            [int]$MaxDepth = [int]::MaxValue,

            #List of wildcard matches. If a directoryname matches one of these, it will be skipped.
            [Parameter()]
            [String[]]$NotLike = $null,

            #List of wildcard matches. If a directoryname matches one of these, it will be shown.
            [Parameter()]
            [String[]]$Like = $null,

            [Parameter()]
            [String[]]$_Start = $null,

            #Internal parameter used in recursion for formating purposes
            [Parameter()]
            [int]$_Depth = 0

        )

        if ($_Depth -ge $MaxDepth) {
            return
        }

        $Children = Get-ChildItem $path -ErrorAction Ignore | sort
        # $Children = Get-ChildItem $path -ErrorAction Ignore | Where-Object PSIsContainer -eq $true | sort

        $FilteredChildren = @()
        foreach ($d in $Children) {
            foreach ($pattern in $NotLike) {
                if ($d.Name -like $pattern) {
                    Write-Verbose "Pattern: $Pattern. Skipping: $($d.Name)"
                    continue
                }
            }
            $ShowThisDirectory = $false

            if (!$like) {
                $ShowThisDirectory = $true
            }
            else {
                foreach ($pattern in $Like) {
                    if ($d.Name -like $pattern) {
                        Write-Verbose "Pattern: $Pattern. Including: $($d.Name)"
                        $ShowThisDirectory = $true
                        break;
                    }
                }
            }
            if (($ShowThisDirectory) -or ($d.PSIsContainer)) {
                $FilteredChildren += $d
            }
        }

        foreach ($d in $FilteredChildren) {
            if ($d -eq $FilteredChildren[-1]) {
                $Symbol = $EndSymbol
                $Increment = $BlankSymbol
            }
            else {
                $Symbol = $BranchSymbol
                $Increment = $GuideSymbol
            }
            Write-Host ("{0}{1}$NameSymbol" -f $($_Start),$Symbol) -NoNewline

            if ($d.PSIsContainer) {
                Write-Host ($d.Name) -BackgroundColor $FolderColor
                Get-Tree -path:($d.FullName) -_Depth:($_Depth + 1) -MaxDepth:$MaxDepth -NotLike:$NotLike -Like:$Like -_Start:(($_Start + $Increment | Out-String) -replace "`r|`n","")
            }
            else {
                $Color = format-type $d
                if ($Color) {
                    Write-Host ($d.Name) -ForegroundColor $Color
                }
                else {
                    Write-Host ($d.Name)
                }
            }
        }
    }
    "$((gi $Path).Name)"
    Get-Tree @PSBOundParameters
}

$Indent = 3
$BranchSymbol = [char]::ConvertFromUtf32(0x251C)
$EndSymbol = [char]::ConvertFromUtf32(0x2514)
$NameSymbol = ([char]::ConvertFromUtf32(0x2500)) * $Indent
$GuideSymbol = "$([char]::ConvertFromUtf32(0x2502))$(" " * $Indent)"
$BlankSymbol = " " * ($Indent + 1)

# $Indent = 5
# $BranchSymbol = [char]::ConvertFromUtf32(0x255F )
# $EndSymbol = [char]::ConvertFromUtf32(0x2559)
# $NameSymbol = ([char]::ConvertFromUtf32(0x2500)) * ($Indent - 2) + [char]::ConvertFromUtf32(0x25CF) + " "
# $GuideSymbol = "$([char]::ConvertFromUtf32(0x2551))$(" " * $Indent)"
# $BlankSymbol = " " * ($Indent + 1)


$extensionTypes = @{
    picture = @([ConsoleColor]::Green,@(".png",".gif",".jpg",".jpeg"))
    doc = @([ConsoleColor]::red,@(".docx",".pdf"))
    media = @([ConsoleColor]::Magenta,@(".mp3",".mp4"))
    Archive = @([ConsoleColor]::Yellow,@(".7z",".gz",".rar",".tar",".zip"))
    dll = @([ConsoleColor]::Green,@(".dll",".pdb"))
    text = @([ConsoleColor]::darkyellow,@(".csv",".lg","markdown",".rst",".txt",".md"))
    config = @([ConsoleColor]::Yellow,@(".cfg",".config",".conf",".ini",".gitignore",".yml"))
    executable = @([ConsoleColor]::Blue,@(".exe",".exe*",".bat",".cmd",".py",".pl",".ps1",".psm1",".vbs",".rb",".reg",".fsx",".js"))
}

$FolderColor = [ConsoleColor]::DarkGray
