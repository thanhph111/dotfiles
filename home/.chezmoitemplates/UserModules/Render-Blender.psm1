function Render-Blender {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputFile,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile = "//Render_",

        [Parameter(Mandatory = $false)]
        [ValidateSet("BLENDER_EEVEE", "CYCLES")]
        [string]$Engine = "BLENDER_EEVEE",

        [Parameter(Mandatory = $false)]
        [int]$Threads = 0
    )

    $InputFile = (Get-Item $InputFile).FullName
    $CurrentLine = $Host.UI.RawUI.CursorPosition.Y
    $ConsoleWidth = $Host.UI.RawUI.BufferSize.Width
    $Before = $false

    $Parameters = @(
        "--background", $InputFile
        "--render-output", $OutputFile
        "--engine", $Engine
        "--threads", $Threads
        "--render-format", "PNG"
        "--use-extension", 1
        "--render-frame", 1
    )
    blender @Parameters | ForEach-Object {
        if ($Before) {
            $CurrentLine = $Host.UI.RawUI.CursorPosition.Y
            $Count = [math]::Ceiling($Length / $ConsoleWidth)
            for ($i = 1; $i -le $Count; $i++) {
                [Console]::SetCursorPosition(0, ($CurrentLine - $i))
                [Console]::Write("{0,-$ConsoleWidth}" -f " ")
            }
            [Console]::SetCursorPosition(0, ($CurrentLine - $Count))
        }
        if ($_.StartsWith("Fra") -and
            !($_.EndsWith("Finished")) -and
            !($_.EndsWith("Ve:0 Fa:0 La:0"))) {
            $Before = $true
            $Length = $_.Length
        } else {
            $Before = $false
        }
        Write-Output $_
    }
}
