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
#>


function format-type {
    param(
        [Parameter(Mandatory = $true)]
        # [System.IO.FileInfo]
        $object
    )
    foreach ($filesGroup in $extensionTypes.values) {
        if ($filesGroup[1].contains([IO.Path]::GetExtension($object.Extension))) {
            return $color = $filesGroup[0]
        }
    }
    return $color = $null
}


function Get-Tree {
    [CmdletBinding()]
    # [Alias("tree")]
    [OutputType([string[]])]
    param(
        [Parameter(Position = 0)]
        $Path = (Get-Location),

        [Parameter()]
        [int]$MaxDepth = [int]::MaxValue,

        #Show the full name of the directory at each sublevel
        [Parameter()]
        [switch]$ShowDirectory,

        #List of wildcard matches. If a directoryname matches one of these, it will be skipped.
        [Parameter()]
        [String[]]$NotLike = $null,

        # [Parameter()]
        # [String[]]$start = $null,

        #List of wildcard matches. If a directoryname matches one of these, it will be shown.
        [Parameter()]
        [String[]]$Like = $null
    )

    function show-Tree {
        [CmdletBinding()]
        [Alias("tree")]
        [OutputType([string[]])]
        param(
            [Parameter(Position = 0)]
            $Path = (Get-Location),

            [Parameter()]
            [int]$MaxDepth = [int]::MaxValue,

            #Show the full name of the directory at each sublevel
            [Parameter()]
            [switch]$ShowDirectory,

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
        $FirstDirectoryShown = $False

        $Children = Get-ChildItem $path -ErrorAction Ignore | sort
        # $Children = Get-ChildItem $path -ErrorAction Ignore | Where-Object PSIsContainer -eq $true | sort

        foreach ($d in $Children) {
            $PSDriveFullPath = $d.FullName
            if ($d -eq $Children[-1]) {
                $Symbol = $EndSymbol
                $Increment = " " * ($Indent + 1)
            }
            else {
                $Symbol = $BranchSymbol
                $Increment = $GuideSymbol
            }
            Write-Host ("{0}{1}$NameSymbol" -f $($_Start),$Symbol) -NoNewline

            $Color = format-type $d
            if ($Color) {
                Write-Host (Split-Path $PSDriveFullPath -Leaf) -ForegroundColor $Color
            }
            elseif ((($d.Attributes) -band [IO.FileAttributes]::Directory) -ne 0) {
                Write-Host (Split-Path $PSDriveFullPath -Leaf) -BackgroundColor ([ConsoleColor]::DarkGray)
            }
            else {
                Write-Host (Split-Path $PSDriveFullPath -Leaf)
            }

            if ((($d.Attributes) -band [IO.FileAttributes]::Directory) -ne 0) {
                show-Tree -path:$PSDriveFullPath -_Depth:($_Depth + 1) -ShowDirectory:$ShowDirectory -MaxDepth:$MaxDepth -NotLike:$NotLike -Like:$Like -_Start:(($_Start + $Increment | Out-String) -replace "`r|`n","")
            }
        }
    }
    "$((gi $Path).BaseName)"
    show-Tree @PSBOundParameters
}

$Indent = 2
$BranchSymbol = [char]::ConvertFromUtf32(0x251C)
$EndSymbol = [char]::ConvertFromUtf32(0x2514)
$NameSymbol = ([char]::ConvertFromUtf32(0x2500)) * $Indent
$GuideSymbol = "$([char]::ConvertFromUtf32(0x2502))$(" " * $Indent)"


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
