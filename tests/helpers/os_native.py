from pathlib import Path
import subprocess


def powershell_parse_file(path: Path) -> subprocess.CompletedProcess[str]:
    script = "\n".join(
        [
            "$tokens = $null",
            "$errors = $null",
            f"[void][System.Management.Automation.Language.Parser]::ParseFile('{str(path).replace("'", "''")}', [ref]$tokens, [ref]$errors)",
            "if ($errors.Count -gt 0) {",
            "  $errors | ForEach-Object { Write-Error $_.Message }",
            "  exit 1",
            "}",
        ]
    )
    return subprocess.run(
        ["pwsh", "-NoLogo", "-NoProfile", "-Command", script],
        text=True,
        capture_output=True,
        check=False,
    )


def bash_syntax_file(path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["bash", "-n", str(path)], text=True, capture_output=True, check=False)
