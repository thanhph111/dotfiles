$ErrorActionPreference = 'Stop'
$mockRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("bootstrap-pwsh-" + [guid]::NewGuid().ToString("N"))
$mockBin = Join-Path $mockRoot 'bin'
New-Item -ItemType Directory -Force -Path $mockBin | Out-Null

$chezmoiMock = Join-Path $mockBin 'chezmoi'
Set-Content -Encoding Ascii -Path $chezmoiMock -Value @'
#!/bin/sh
set -eu
echo "MOCK chezmoi $*"
'@
& /bin/chmod +x $chezmoiMock

$brewMock = Join-Path $mockBin 'brew'
Set-Content -Encoding Ascii -Path $brewMock -Value @'
#!/bin/sh
set -eu
[ "${1:-}" = "shellenv" ] && echo 'export PATH="$PATH"'
'@
& /bin/chmod +x $brewMock

$opMock = Join-Path $mockBin 'op'
Set-Content -Encoding Ascii -Path $opMock -Value @'
#!/bin/sh
set -eu
if [ "${1:-}" = "vault" ] && [ "${2:-}" = "list" ]; then
    case "${PROFILE_OP_MODE:-missing}" in
    ok)
        echo "[]"
        exit 0
        ;;
    *)
        exit 1
        ;;
    esac
fi
if [ "${1:-}" = "read" ]; then
    echo "mock-secret"
    exit 0
fi
echo "{}"
'@
& /bin/chmod +x $opMock

if ($env:PROFILE_OP_MODE -eq 'missing') {
    Remove-Item -LiteralPath $opMock -Force -ErrorAction SilentlyContinue
}

if ($env:PROFILE_WITH_TOKEN -eq '1') {
    $env:OP_SERVICE_ACCOUNT_TOKEN = 'dummy'
} else {
    Remove-Item Env:OP_SERVICE_ACCOUNT_TOKEN -ErrorAction SilentlyContinue
}

$env:CHEZMOI_CMD = $chezmoiMock
$env:PATH = "${mockBin}:$env:PATH"

$output = & /repo/script/bootstrap-first-run.ps1 --dry-run --exclude scripts 2>&1 | Out-String
$applyCount = ([regex]::Matches($output, 'MOCK chezmoi apply')).Count

Write-Output $output
if ($applyCount -ne [int]$env:PROFILE_EXPECT_APPLIES) {
    throw "unexpected apply count $applyCount"
}
