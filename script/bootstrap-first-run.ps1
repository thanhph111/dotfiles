[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $ApplyArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $CommandOrPath
    )

    if (Test-Path -LiteralPath $CommandOrPath) {
        return [System.IO.Path]::GetFullPath($CommandOrPath)
    }

    $commandInfo = Get-Command $CommandOrPath -ErrorAction Stop
    return [System.IO.Path]::GetFullPath($commandInfo.Source)
}

function Get-ChezmoiPath {
    if (-not [string]::IsNullOrWhiteSpace($env:CHEZMOI_CMD)) {
        return Resolve-CommandPath -CommandOrPath $env:CHEZMOI_CMD
    }

    $localChezmoiExe = Join-Path $PWD.Path 'bin\chezmoi.exe'
    if (Test-Path -LiteralPath $localChezmoiExe) {
        return Resolve-CommandPath -CommandOrPath $localChezmoiExe
    }

    return Resolve-CommandPath -CommandOrPath 'chezmoi'
}

function Refresh-ProcessPathFromSystem {
    $currentPath = $env:Path
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    $segments = @()
    if (-not [string]::IsNullOrWhiteSpace($currentPath)) {
        $segments += $currentPath
    }
    if (-not [string]::IsNullOrWhiteSpace($machinePath)) {
        $segments += $machinePath
    }
    if (-not [string]::IsNullOrWhiteSpace($userPath)) {
        $segments += $userPath
    }

    if ($segments.Count -gt 0) {
        $env:Path = ($segments -join ';')
    }
}

$chezmoiPath = Get-ChezmoiPath

Write-Host '[bootstrap] Running first apply...'
& $chezmoiPath apply --init @ApplyArgs

Refresh-ProcessPathFromSystem

$secretsReady = $false
$readinessReason = ''

if (-not [string]::IsNullOrWhiteSpace($env:OP_SERVICE_ACCOUNT_TOKEN)) {
    $secretsReady = $true
    $readinessReason = 'OP_SERVICE_ACCOUNT_TOKEN is set'
} else {
    $opCommand = Get-Command op -ErrorAction SilentlyContinue
    if ($null -ne $opCommand) {
        & $opCommand.Source vault list *> $null
        if ($LASTEXITCODE -eq 0) {
            $secretsReady = $true
            $readinessReason = 'op session is authenticated'
        }
    }
}

if ($secretsReady) {
    Write-Host "[bootstrap] Secrets are ready ($readinessReason). Running second apply..."

    $hadSecretsEnv = Test-Path Env:CHEZMOI_ENABLE_SECRETS
    $previousSecretsEnv = $env:CHEZMOI_ENABLE_SECRETS

    $env:CHEZMOI_ENABLE_SECRETS = '1'
    & $chezmoiPath apply --init @ApplyArgs

    if ($hadSecretsEnv) {
        $env:CHEZMOI_ENABLE_SECRETS = $previousSecretsEnv
    } else {
        Remove-Item Env:CHEZMOI_ENABLE_SECRETS -ErrorAction SilentlyContinue
    }

    Write-Host '[bootstrap] Completed with secrets enabled.'
} else {
    Write-Host '[bootstrap] Secrets are not ready. First pass completed successfully.'
    Write-Host ''
    Write-Host 'Next steps:'
    Write-Host '  1) Client machines: op signin'
    Write-Host '  2) Agent machines: $env:OP_SERVICE_ACCOUNT_TOKEN = "<token>"'
    Write-Host '  3) Re-run: .\script\bootstrap-first-run.ps1'
}
