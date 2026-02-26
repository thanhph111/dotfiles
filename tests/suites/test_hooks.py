from pathlib import Path
import json
import shlex
import subprocess
import tempfile

import pytest

from helpers.artifacts import write_artifact
from helpers.chezmoi import profile_to_data, render_template, write_data_file
from helpers.docker_cli import DockerRunner, LINUX_IMAGE, PWSH_IMAGE
from helpers.matrix import Profile
from helpers.os_native import powershell_parse_file
from helpers.scripts import load_script


def _container_path(repo_root: Path, path: Path) -> str:
    return f"/repo/{path.relative_to(repo_root).as_posix()}"


def _render_template_native(
    repo_root: Path, template_rel: str, data_file: Path
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "chezmoi",
            "execute-template",
            "--config",
            str(repo_root / "tests" / "fixtures" / "config" / "chezmoi.test.toml"),
            "-S",
            str(repo_root),
            "--init",
            "--stdinisatty=false",
            "--override-data-file",
            str(data_file),
            "--file",
            str(repo_root / template_rel),
        ],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=False,
    )


@pytest.mark.tier_smoke
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_linux_hooks_render_and_parse(
    docker_runner: DockerRunner,
    repo_root: Path,
    artifact_dir: Path,
    selected_profiles: list[Profile],
) -> None:
    docker_runner.ensure_image(LINUX_IMAGE, repo_root / "tests" / "docker" / "linux.Dockerfile")

    templates = sorted((repo_root / "home" / ".chezmoiscripts" / "linux").glob("*.tmpl"))
    assert templates, "No Linux hook templates found"

    rendered = 0
    for profile in selected_profiles:
        for template in templates:
            source_rel = template.relative_to(repo_root).as_posix()
            _, data_file = write_data_file(
                repo_root=repo_root,
                artifact_dir=artifact_dir,
                profile=profile,
                platform="linux",
                secrets_enabled=False,
                label=f"linux-hook-data-{template.stem}",
            )
            output = render_template(
                runner=docker_runner,
                image=LINUX_IMAGE,
                template_rel=source_rel,
                data_file_in_container=data_file,
            )

            rendered_path = write_artifact(
                artifact_dir, f"linux-hook-{profile.id}-{template.stem}.sh", output
            )

            if output.strip() and output.startswith("#!/usr/bin/env bash"):
                parse = docker_runner.run_bash(
                    image=LINUX_IMAGE, script=f"bash -n {_container_path(repo_root, rendered_path)}"
                )
                assert parse.returncode == 0, parse.stdout + parse.stderr

            rendered += 1

    assert rendered > 0


@pytest.mark.tier_smoke
@pytest.mark.platform_darwin
@pytest.mark.requires_docker
def test_darwin_hooks_render_and_parse(
    docker_runner: DockerRunner,
    repo_root: Path,
    artifact_dir: Path,
    selected_profiles: list[Profile],
) -> None:
    docker_runner.ensure_image(LINUX_IMAGE, repo_root / "tests" / "docker" / "linux.Dockerfile")

    templates = sorted((repo_root / "home" / ".chezmoiscripts" / "darwin").glob("*.tmpl"))
    assert templates, "No Darwin hook templates found"

    rendered = 0
    for profile in selected_profiles:
        for template in templates:
            source_rel = template.relative_to(repo_root).as_posix()
            _, data_file = write_data_file(
                repo_root=repo_root,
                artifact_dir=artifact_dir,
                profile=profile,
                platform="darwin",
                secrets_enabled=False,
                label=f"darwin-hook-data-{template.stem}",
            )
            output = render_template(
                runner=docker_runner,
                image=LINUX_IMAGE,
                template_rel=source_rel,
                data_file_in_container=data_file,
            )

            rendered_path = write_artifact(
                artifact_dir, f"darwin-hook-{profile.id}-{template.stem}.sh", output
            )

            if output.strip() and output.startswith("#!/usr/bin/env bash"):
                parse = docker_runner.run_bash(
                    image=LINUX_IMAGE, script=f"bash -n {_container_path(repo_root, rendered_path)}"
                )
                assert parse.returncode == 0, parse.stdout + parse.stderr

            rendered += 1

    assert rendered > 0


@pytest.mark.tier_full
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_darwin_openclaw_hook_guard_docker(
    docker_runner: DockerRunner,
    repo_root: Path,
    artifact_dir: Path,
    profiles_map: dict[str, Profile],
) -> None:
    docker_runner.ensure_image(LINUX_IMAGE, repo_root / "tests" / "docker" / "linux.Dockerfile")

    profile = profiles_map["agent"]
    template_rel = "home/.chezmoiscripts/darwin/run_onchange_after_1-openclaw-onboard.tmpl"
    _, data_file = write_data_file(
        repo_root=repo_root,
        artifact_dir=artifact_dir,
        profile=profile,
        platform="darwin",
        secrets_enabled=False,
        label="darwin-hook-agent",
    )

    rendered = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=template_rel,
        data_file_in_container=data_file,
    )
    rendered_script = artifact_dir / "darwin-openclaw-onboard.sh"
    rendered_script.write_text(rendered, encoding="utf-8")
    rendered_script.chmod(0o755)

    log_file = artifact_dir / "darwin-hook-openclaw.log"
    script = load_script(
        repo_root,
        "bash",
        "hooks_darwin_guard.sh",
        substitutions={
            "SCRIPT_PATH": shlex.quote(_container_path(repo_root, rendered_script)),
            "LOG_PATH": shlex.quote(_container_path(repo_root, log_file)),
        },
    )

    result = docker_runner.run_bash(image=LINUX_IMAGE, script=script)
    output = result.stdout + result.stderr
    write_artifact(artifact_dir, "darwin-hooks-docker.log", output)
    assert result.returncode == 0, output


@pytest.mark.tier_full
@pytest.mark.platform_windows
@pytest.mark.requires_docker
def test_windows_hooks_render_and_parse_docker(
    docker_runner: DockerRunner,
    repo_root: Path,
    artifact_dir: Path,
    selected_profiles: list[Profile],
) -> None:
    docker_runner.ensure_image(PWSH_IMAGE, repo_root / "tests" / "docker" / "powershell.Dockerfile")

    templates = sorted((repo_root / "home" / ".chezmoiscripts" / "windows").glob("*.ps1.tmpl"))
    assert templates, "No Windows hook templates found"

    rendered = 0
    parse_errors: list[str] = []
    for profile in selected_profiles:
        for template in templates:
            source_rel = template.relative_to(repo_root).as_posix()
            _, data_file = write_data_file(
                repo_root=repo_root,
                artifact_dir=artifact_dir,
                profile=profile,
                platform="windows",
                secrets_enabled=False,
                label=f"windows-hook-data-{template.stem}",
            )
            output = render_template(
                runner=docker_runner,
                image=PWSH_IMAGE,
                template_rel=source_rel,
                data_file_in_container=data_file,
            )
            rendered_path = write_artifact(
                artifact_dir, f"windows-hook-{profile.id}-{template.stem}.ps1", output
            )
            container_rendered_path = _container_path(repo_root, rendered_path)
            parse_script = "\n".join(
                [
                    "$tokens = $null",
                    "$errors = $null",
                    f"[void][System.Management.Automation.Language.Parser]::ParseFile('{container_rendered_path}', [ref]$tokens, [ref]$errors)",
                    "if ($errors.Count -gt 0) {",
                    "  $errors | ForEach-Object { Write-Error $_.Message }",
                    "  exit 1",
                    "}",
                ]
            )
            parse = docker_runner.run_pwsh(image=PWSH_IMAGE, script=parse_script)
            if parse.returncode != 0:
                parse_errors.append(
                    f"{rendered_path}\nSTDOUT:\n{parse.stdout}\nSTDERR:\n{parse.stderr}"
                )
            rendered += 1

    write_artifact(artifact_dir, "windows-hooks-docker.log", f"RENDERED={rendered}\n")
    assert rendered > 0
    assert not parse_errors, "\n\n".join(parse_errors)


@pytest.mark.tier_full
@pytest.mark.platform_darwin
@pytest.mark.native_ci_only
def test_darwin_openclaw_hook_guard_native_ci(
    repo_root: Path, artifact_dir: Path, profiles_map: dict[str, Profile]
) -> None:
    check = subprocess.run(["chezmoi", "--version"], text=True, capture_output=True, check=False)
    assert check.returncode == 0, f"Missing chezmoi in CI native job\n{check.stderr}"

    profile = profiles_map["agent"]
    data = profile_to_data(profile, "darwin", False)

    with tempfile.TemporaryDirectory(prefix="dotfiles-test-darwin-") as tmp:
        tmp_path = Path(tmp)
        data_file = tmp_path / "data.json"
        data_file.write_text(json.dumps(data, indent=2), encoding="utf-8")

        template_rel = "home/.chezmoiscripts/darwin/run_onchange_after_1-openclaw-onboard.tmpl"
        rendered_proc = _render_template_native(repo_root, template_rel, data_file)
        assert rendered_proc.returncode == 0, (
            f"Failed to render darwin hook\nSTDOUT:\n{rendered_proc.stdout}\nSTDERR:\n{rendered_proc.stderr}"
        )

        rendered_script = artifact_dir / "darwin-openclaw-onboard-native.sh"
        rendered_script.write_text(rendered_proc.stdout, encoding="utf-8")
        rendered_script.chmod(0o755)

        log_file = artifact_dir / "darwin-hook-openclaw-native.log"
        if log_file.exists():
            log_file.unlink()

        script = load_script(
            repo_root,
            "bash",
            "hooks_darwin_guard.sh",
            substitutions={
                "SCRIPT_PATH": shlex.quote(str(rendered_script)),
                "LOG_PATH": shlex.quote(str(log_file)),
            },
        )

        result = subprocess.run(
            ["bash", "-lc", script], text=True, capture_output=True, check=False
        )
        assert result.returncode == 0, f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"


@pytest.mark.tier_full
@pytest.mark.platform_windows
@pytest.mark.native_ci_only
def test_windows_hooks_render_and_parse_native_ci(
    repo_root: Path, artifact_dir: Path, selected_profiles: list[Profile]
) -> None:
    check = subprocess.run(["chezmoi", "--version"], text=True, capture_output=True, check=False)
    assert check.returncode == 0, f"Missing chezmoi in CI native job\n{check.stderr}"

    templates = sorted((repo_root / "home" / ".chezmoiscripts" / "windows").glob("*.ps1.tmpl"))
    assert templates, "No Windows hook templates found"

    rendered = 0
    errors: list[str] = []
    with tempfile.TemporaryDirectory(prefix="dotfiles-test-windows-") as tmp:
        tmp_path = Path(tmp)

        for profile in selected_profiles:
            payload = profile_to_data(profile, "windows", False)
            payload["chezmoi"]["sourceDir"] = str(repo_root / "home")

            for template in templates:
                data_file = tmp_path / f"data-{profile.id}-{template.stem}.json"
                data_file.write_text(json.dumps(payload, indent=2), encoding="utf-8")

                source_rel = template.relative_to(repo_root).as_posix()
                render_proc = _render_template_native(repo_root, source_rel, data_file)
                if render_proc.returncode != 0:
                    errors.append(
                        f"{template} render failed\nSTDOUT:\n{render_proc.stdout}\nSTDERR:\n{render_proc.stderr}"
                    )
                    continue

                rendered_path = (
                    artifact_dir / f"windows-hook-native-{profile.id}-{template.stem}.ps1"
                )
                rendered_path.write_text(render_proc.stdout, encoding="utf-8")

                parse = powershell_parse_file(rendered_path)
                if parse.returncode != 0:
                    errors.append(
                        f"{rendered_path}\nSTDOUT:\n{parse.stdout}\nSTDERR:\n{parse.stderr}"
                    )

                rendered += 1

    write_artifact(artifact_dir, "windows-hooks-native.log", f"RENDERED={rendered}\n")
    assert rendered > 0
    assert not errors, "\n\n".join(errors)
