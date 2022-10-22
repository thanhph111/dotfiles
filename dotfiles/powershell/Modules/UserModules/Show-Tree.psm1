<#
.Synopsis
   Show an ASCII text representation of a namespace tree

.DESCRIPTION
 Script to show the layout of PowerShell namespaces (Trees) using ASCII

.EXAMPLE
PS> Show-Tree C:\ -MaxDepth 2

.EXAMPLE
PS> Show-Tree C:\ -MaxDepth 2 -NotLike Wind*,P* -Verbose

.EXAMPLE
PS> New-PSDrive -PSProvider Registry -Root HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ -Name WINDOWS
PS> Show-Tree Windows: -MaxDepth 1 -ShowDirectory

.NOTE
-Like and -NotLike feature only affect with files.
Otherwise, I don't know how to deal with this situation: parent folders are not allowed to listed but their children are.
#>


function Format-Type {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $Object
    )
    foreach ($filesGroup in $ExtensionColors.values) {
        if ($filesGroup[1].contains([IO.Path]::GetExtension($Object.Extension))) {
            return $filesGroup[0]
        }
    }
    return $null
}


function Show-Tree {
    [CmdletBinding()]
    [Alias('st')]
    [OutputType([string[]])]
    param(
        [Parameter(Position = 0)]
        $Path = (Get-Location),

        [Parameter()]
        [int]$MaxDepth = [int]::MaxValue,

        #List of wildcard matches. If a directory name matches one of these, it will be skipped.
        [Parameter()]
        [String[]]$NotLike = $null,

        #List of wildcard matches. If a directory name matches one of these, it will be shown.
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

            #List of wildcard matches. If a directory name matches one of these, it will be skipped.
            [Parameter()]
            [String[]]$NotLike = $null,

            #List of wildcard matches. If a directory name matches one of these, it will be shown.
            [Parameter()]
            [String[]]$Like = $null,

            [Parameter()]
            [String[]]$_Start = $null,

            #Internal parameter used in recursion for formatting purposes
            [Parameter()]
            [int]$_Depth = 0

        )

        if ($_Depth -ge $MaxDepth) {
            return
        }

        $Children = Get-ChildItem $path -ErrorAction Ignore | Sort-Object
        # $Children = Get-ChildItem $path -ErrorAction Ignore | Where-Object PSIsContainer -eq $true | sort

        $filteredChildren = @()
        foreach ($child in $Children) {
            foreach ($pattern in $NotLike) {
                if ($child.Name -like $pattern) {
                    Write-Verbose "Pattern: $pattern. Skipping: $($child.Name)"
                    continue
                }
            }
            $ShowThisDirectory = $false

            if (!$like) {
                $ShowThisDirectory = $true
            } else {
                foreach ($pattern in $Like) {
                    if ($child.Name -like $pattern) {
                        Write-Verbose "Pattern: $pattern. Including: $($child.Name)"
                        $ShowThisDirectory = $true
                        break;
                    }
                }
            }
            if (($ShowThisDirectory) -or ($child.PSIsContainer)) {
                $filteredChildren += $child
            }
        }

        foreach ($child in $filteredChildren) {
            if ($child -eq $filteredChildren[-1]) {
                $symbol = $EndSymbol
                $increment = $BlankSymbol
            } else {
                $symbol = $BranchSymbol
                $increment = $GuideSymbol
            }
            Write-Host ("{0}{1}$NameSymbol" -f $($_Start), $symbol) -NoNewline

            if ($child.PSIsContainer) {
                Write-Host ($child.Name) -BackgroundColor $FolderColor
                Get-Tree -path:($child.FullName) -_Depth:($_Depth + 1) -MaxDepth:$MaxDepth -NotLike:$NotLike -Like:$Like -_Start:(($_Start + $increment | Out-String) -replace "`r|`n", '')
            } else {
                $color = Format-Type $child
                if ($color) {
                    Write-Host ($child.Name) -ForegroundColor $color
                } else {
                    Write-Host ($child.Name)
                }
            }
        }
    }
    "$((Get-Item $Path).Name)"
    Get-Tree @PSBoundParameters
}

$Indent = 3
$BranchSymbol = [char]::ConvertFromUtf32(0x251C)
$EndSymbol = [char]::ConvertFromUtf32(0x2514)
$NameSymbol = ([char]::ConvertFromUtf32(0x2500)) * $Indent
$GuideSymbol = "$([char]::ConvertFromUtf32(0x2502))$(' ' * $Indent)"
$BlankSymbol = ' ' * ($Indent + 1)

# $Indent = 5
# $BranchSymbol = [char]::ConvertFromUtf32(0x255F )
# $EndSymbol = [char]::ConvertFromUtf32(0x2559)
# $NameSymbol = ([char]::ConvertFromUtf32(0x2500)) * ($Indent - 2) + [char]::ConvertFromUtf32(0x25CF) + " "
# $GuideSymbol = "$([char]::ConvertFromUtf32(0x2551))$(" " * $Indent)"
# $BlankSymbol = " " * ($Indent + 1)


$FolderColor = [ConsoleColor]::DarkGray
$ExtensionColors = @{
    picture    = @(
        [ConsoleColor]::Green, @(
            '.png'
            '.gif'
            '.jpg'
            '.jpeg'
        )
    )
    doc        = @(
        [ConsoleColor]::red, @(
            '.docx'
            '.pdf'
        )
    )
    media      = @(
        [ConsoleColor]::Magenta, @(
            '.mp3'
            '.mp4'
        )
    )
    Archive    = @(
        [ConsoleColor]::Yellow, @(
            '.7z'
            '.gz'
            '.rar'
            '.tar'
            '.zip'
        )
    )
    dll        = @(
        [ConsoleColor]::Green, @(
            '.dll'
            '.pdb'
        )
    )
    text       = @(
        [ConsoleColor]::DarkYellow, @(
            '.csv'
            '.lg'
            'markdown'
            '.rst'
            '.txt'
            '.md'
        )
    )
    config     = @(
        [ConsoleColor]::Yellow, @(
            '.cfg'
            '.config'
            '.conf'
            '.ini'
            '.gitignore'
            '.yml'
        )
    )
    executable = @(
        [ConsoleColor]::Blue, @(
            '.bat'
            '.cmd'
            '.exe'
            '.exe*'
            '.fsx'
            '.js'
            '.pl'
            '.ps1'
            '.psm1'
            '.py'
            '.rb'
            '.reg'
            '.vbs'
        )
    )
}


Export-ModuleMember -Function Show-Tree -Alias st
