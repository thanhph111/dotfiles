from pathlib import Path
import re
import subprocess

import pytest

from helpers.artifacts import write_artifact
from helpers.docker_cli import DockerRunner, LINUX_IMAGE, PWSH_IMAGE
from helpers.matrix import Profile
from helpers.scripts import load_script


@pytest.mark.tier_local
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_unix_bootstrap_mock(
    docker_runner: DockerRunner, artifact_dir: Path, profile: Profile, repo_root: Path
) -> None:
    script = load_script(repo_root, "bash", "bootstrap_unix_mock.sh")

    env = {
        "PROFILE_ID": profile.id,
        "PROFILE_OP_MODE": profile.op_mode,
        "PROFILE_WITH_TOKEN": "1" if profile.with_token else "0",
    }

    result = docker_runner.run_bash(image="bash:5.2", script=script, env=env)
    output = result.stdout + result.stderr
    write_artifact(artifact_dir, f"bootstrap-unix-mock-{profile.id}.log", output)

    assert result.returncode == 0, output

    actual_applies = len(re.findall(r"MOCK chezmoi apply", output))
    assert actual_applies == profile.expect_applies

    if profile.expect_ready:
        assert "Secrets are ready" in output
    else:
        assert "Secrets are not ready" in output


@pytest.mark.tier_full
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_unix_bootstrap_integration(
    docker_runner: DockerRunner, artifact_dir: Path, profile: Profile, repo_root: Path
) -> None:
    docker_runner.ensure_image(
        LINUX_IMAGE, docker_runner.repo_root / "tests" / "docker" / "linux.Dockerfile"
    )
    script = load_script(repo_root, "bash", "bootstrap_unix_integration.sh")

    env = {
        "PROFILE_ID": profile.id,
        "PROFILE_CODENAME": profile.codename,
        "PROFILE_VAULT": profile.vault,
        "PROFILE_CLIENT": "1" if profile.client else "0",
        "PROFILE_AGENT": "1" if profile.agent else "0",
        "PROFILE_PERSONAL": "1" if profile.personal else "0",
        "PROFILE_WITH_TOKEN": "1" if profile.with_token else "0",
        "PROFILE_OP_MODE": profile.op_mode,
    }

    result = docker_runner.run_bash(image=LINUX_IMAGE, script=script, env=env)
    output = result.stdout + result.stderr
    write_artifact(artifact_dir, f"bootstrap-unix-integration-{profile.id}.log", output)

    assert result.returncode == 0, output

    if profile.expect_ready:
        assert "Secrets are ready" in output
        assert "Running second apply" in output
    else:
        assert "Secrets are not ready" in output
        assert "Running second apply" not in output


@pytest.mark.tier_smoke
@pytest.mark.platform_windows
@pytest.mark.requires_docker
def test_powershell_bootstrap_mock(
    docker_runner: DockerRunner, artifact_dir: Path, profile: Profile, repo_root: Path
) -> None:
    docker_runner.ensure_image(
        PWSH_IMAGE, docker_runner.repo_root / "tests" / "docker" / "powershell.Dockerfile"
    )
    script = load_script(repo_root, "pwsh", "bootstrap_powershell_mock.ps1")

    env = {
        "PROFILE_ID": profile.id,
        "PROFILE_WITH_TOKEN": "1" if profile.with_token else "0",
        "PROFILE_OP_MODE": profile.op_mode,
        "PROFILE_EXPECT_APPLIES": str(profile.expect_applies),
    }

    result = docker_runner.run_pwsh(image=PWSH_IMAGE, script=script, env=env)
    output = result.stdout + result.stderr
    write_artifact(artifact_dir, f"bootstrap-powershell-mock-{profile.id}.log", output)

    assert result.returncode == 0, output


@pytest.mark.tier_smoke
@pytest.mark.platform_windows
@pytest.mark.native_ci_only
def test_windows_native_bootstrap_script_parses(repo_root: Path) -> None:
    script = "\n".join(
        [
            "$tokens = $null",
            "$errors = $null",
            "[void][System.Management.Automation.Language.Parser]::ParseFile('script/bootstrap-first-run.ps1', [ref]$tokens, [ref]$errors)",
            "if ($errors.Count -gt 0) { exit 1 }",
        ]
    )

    result = subprocess.run(
        ["pwsh", "-NoLogo", "-NoProfile", "-Command", script],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 0, f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
