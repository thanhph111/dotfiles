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

function Get-Tree {
    [CmdletBinding()]
    # [Alias("tree")]
    [OutputType([string[]])]
    param (
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
        [String[]]$Like = $null
    )

    function show-Tree {
        [CmdletBinding()]
        [Alias("tree")]
        [OutputType([string[]])]
        param (
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

            #Internal parameter used in recursion for formating purposes
            [Parameter()]
            [int]$_Depth = 0

        )

        if ($_Depth -ge $MaxDepth) {
            return
        }
        $FirstDirectoryShown = $False
        $start = $GuideSymbol * $_Depth
        $Children = Get-ChildItem $path -ErrorAction Ignore | sort
        :NextDirectory foreach ($d in $Children) {
            foreach ($pattern in $NotLike) {
                if ($d.PSChildName -like $pattern) {
                    Write-Verbose "Skipping $($d.PSChildName). Not like $Pattern"
                    continue NextDirectory;
                }
            }
            $ShowThisDirectory = $false
            if (!$like) {
                $ShowThisDirectory = $true
            }
            else {
                foreach ($pattern in $Like) {
                    if ($d.PSChildName -like $pattern) {
                        Write-Verbose "Including $($d.PSChildName). Like $Pattern"
                        $ShowThisDirectory = $true
                        break;
                    }
                }
            }
            # When we dir a Get-ChildItem, we get the OS view of the object so here we need to transform
            # it into the PowerShell view of the path (e.g. to deal with PSDrives with deep ROOT directories)
            # $ProviderPath = $ExecutionContext.SessionState.Path.GetResolvedProviderPathFromPSPath($d.PSPath,[ref]$d.PSProvider)
            # $RootRelativePath = $ProviderPath.SubString($d.PSDrive.Root.Length)
            # $PSDriveFullPath = Join-Path ($d.PSDrive.Name + ":") $RootRelativePath
            $PSDriveFullPath = $d.FullName
            if ($ShowThisDirectory) {
                # if (($FirstDirectoryShown -eq $FALSE) -and $ShowDirectory) {
                #     $FirstDirectoryShown = $True
                #     Write-Output ("{0}{1}" -f $start,$Path)
                # }
                if ($d -eq $Children[-1]) {
                    Write-Output ("{0}$EndSymbol$NameSymbol{1}" -f $start,(Split-Path $PSDriveFullPath -Leaf))
                    return
                }
                else {
                    Write-Output ("{0}$BranchSymbol$NameSymbol{1}" -f $start,(Split-Path $PSDriveFullPath -Leaf))
                }
            }
            if ((($d.Attributes) -band [IO.FileAttributes]::Directory) -ne 0) {
                show-Tree -path:$PSDriveFullPath -_Depth:($_Depth + 1) -ShowDirectory:$ShowDirectory -MaxDepth:$MaxDepth -NotLike:$NotLike -Like:$Like
            }
        }
    }
    "$((gi $Path).BaseName)"
    show-Tree @PSBOundParameters
}

$BranchSymbol = [char]::ConvertFromUtf32(0x251C)
$EndSymbol = [char]::ConvertFromUtf32(0x2514)
$NameSymbol = ([char]::ConvertFromUtf32(0x2500)) * 3
$GuideSymbol = "$([char]::ConvertFromUtf32(0x2502))$(" " * 3)"
