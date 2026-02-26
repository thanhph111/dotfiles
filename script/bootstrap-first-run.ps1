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
$deferReason = ''
$tokenPresent = -not [string]::IsNullOrWhiteSpace($env:OP_SERVICE_ACCOUNT_TOKEN)

$opCommand = Get-Command op -ErrorAction SilentlyContinue
if ($null -eq $opCommand) {
    if ($tokenPresent) {
        $deferReason = 'OP_SERVICE_ACCOUNT_TOKEN is set but op CLI is not available on PATH.'
    } else {
        $deferReason = 'op CLI is not available on PATH.'
    }
} else {
    & $opCommand.Source vault list *> $null
    if ($LASTEXITCODE -eq 0) {
        $secretsReady = $true
        if ($tokenPresent) {
            $readinessReason = 'op CLI is available and service token is usable'
        } else {
            $readinessReason = 'op CLI is available and session is authenticated'
        }
    } elseif ($tokenPresent) {
        $deferReason = 'OP_SERVICE_ACCOUNT_TOKEN is set but op vault access failed (invalid token or missing permissions).'
    } else {
        $deferReason = 'op CLI is available but not authenticated.'
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
    Write-Host "[bootstrap] $deferReason"
    Write-Host '[bootstrap] Secrets are not ready. First pass completed successfully.'
    Write-Host ''
    Write-Host 'Next steps:'
    Write-Host '  1) Ensure op CLI is installed and on PATH.'
    Write-Host '  2) Client machines: op signin'
    Write-Host '  3) Agent machines: $env:OP_SERVICE_ACCOUNT_TOKEN = "<token>"'
    Write-Host '  4) Verify readiness: op vault list'
    Write-Host '  5) Re-run: .\script\bootstrap-first-run.ps1'
}
