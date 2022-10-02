#Requires -Version 4.0 -RunAsAdministrator

Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('windows')]
    [string]$Profile,
    [Parameter(Mandatory = $false)]
    [string[]]$Configs
)


# Exit immediately if an error occurs
$ErrorActionPreference = 'Stop'

# This script is only for Windows
if ($env:OS -ne 'Windows_NT') {
    Write-Error 'This script is only for Windows.'
    exit 1
}

# Go to the project directory
Set-Location -Path $PSScriptRoot

# Profiles and configs paths
$MetaDirectoryPath = "$PWD\meta"
$ConfigDirectoryPath = "$MetaDirectoryPath\configs"
$ProfileDirectory = "$MetaDirectoryPath\profiles"
$BaseConfigFilePath = "$MetaDirectoryPath\base.yaml"
$PreConfigFilePath = "$MetaDirectoryPath\pre.yaml"
$PostConfigFilePath = "$MetaDirectoryPath\post.yaml"

# Dotbot paths
$DotbotDirectoryPath = "$PWD\dotbot"
$DotbotBinaryFilePath = "$DotbotDirectoryPath\bin\dotbot"
$DotbotPluginDirectoryPath = "$PWD\plugins"
$DotbotExcludedPlugin = @('ifplatform')
$DotbotPluginArguments = Get-ChildItem -Directory -Path $DotbotPluginDirectoryPath | ForEach-Object {
    if ($DotbotExcludedPlugin -notcontains $_.Name) {
        "-p $DotbotPluginDirectoryPath\$_"
    }
}

# Update Dotbot submodule
git -C "$DotbotDirectoryPath" submodule sync --quiet --recursive
git submodule update --init --recursive

function Test-PythonInstalled {
    # Check if Python is installed
    # Python redirects to Microsoft Store in Windows 10 when not installed
    foreach ($PythonCommand in ('python', 'python3')) {
        if (
            & {
                $ErrorActionPreference = 'SilentlyContinue'
                ![string]::IsNullOrEmpty((&$PythonCommand -V))
                $ErrorActionPreference = 'Stop'
            }
        ) {
            return $PythonCommand
        }
    }
    Write-Error 'Python is not installed.'
    exit 1
}

function Invoke-Config {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigFilePath
    )

    $TemporaryFilePath = New-TemporaryFile

    # Merge configs using Set-Content
    $content = @(
        $BaseConfigFilePath,
        $ConfigFilePath
    ) | ForEach-Object { Get-Content -Path $_ }
    Set-Content -Path $TemporaryFilePath -Value $content

    & $PythonCommand $DotbotBinaryFilePath -d $PWD -c $TemporaryFilePath $DotbotPluginArguments $Args

    Remove-Item -Path $TemporaryFilePath
}

$PythonCommand = Test-PythonInstalled

# Invoke pre-config
Write-Output 'Running pre-config...'
Invoke-Config -ConfigFilePath $PreConfigFilePath

# Invoke config
Write-Output 'Running configs...'
@(
    & {
        if (!$Profile) {
            return
        }
        $profileFilePath = "$ProfileDirectory\" + $Profile
        if (Test-Path $profileFilePath) {
            Get-Content -Path $profileFilePath | ForEach-Object {
                # Ignore comments and empty lines
                if (!($_ -match '^\s*#' -or [string]::IsNullOrEmpty($_))) {
                    $_
                }
            }
        }
    }
    $Configs
) | Where-Object { $_ } | Get-Unique | ForEach-Object {
    $configFilePath = "$ConfigDirectoryPath\" + "$_.yaml"
    if (!(Test-Path $configFilePath)) {
        Write-Warning "Ignoring unknown config: $configFilePath"
        continue
    }
    Invoke-Config -ConfigFilePath $configFilePath
}

# Invoke pre-config
Write-Output 'Running post-config...'
Invoke-Config -ConfigFilePath $PostConfigFilePath

exit 0
