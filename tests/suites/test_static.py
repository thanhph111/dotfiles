from pathlib import Path
import tomllib

import pytest

from helpers.artifacts import write_artifact
from helpers.chezmoi import render_template, resolve_render_platforms, write_data_file
from helpers.docker_cli import DockerRunner, LINUX_IMAGE, PWSH_IMAGE
from helpers.matrix import Profile, load_matrix
from helpers.os_native import powershell_parse_file
from helpers.scripts import apply_substitutions, load_script


@pytest.mark.tier_local
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_shell_syntax_docker(
    docker_runner: DockerRunner, artifact_dir: Path, repo_root: Path
) -> None:
    script = load_script(repo_root, "bash", "static_shell_syntax.sh")

    result = docker_runner.run_bash(image="bash:5.2", script=script)
    output = result.stdout + result.stderr
    write_artifact(artifact_dir, "static-shell-syntax.log", output)

    assert result.returncode == 0, output
    assert "CHECKED=" in output


@pytest.mark.tier_local
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_chezmoi_config_compiles(
    docker_runner: DockerRunner,
    artifact_dir: Path,
    repo_root: Path,
    platform: str,
    selected_profiles: list[Profile],
) -> None:
    docker_runner.ensure_image(LINUX_IMAGE, repo_root / "tests" / "docker" / "linux.Dockerfile")

    compiled = 0
    for platform_name in resolve_render_platforms(platform):
        if platform_name == "darwin":
            continue
        for profile in selected_profiles:
            _, data_file = write_data_file(
                repo_root=repo_root,
                artifact_dir=artifact_dir,
                profile=profile,
                platform=platform_name,
                secrets_enabled=False,
                label="compile-core",
            )
            output = render_template(
                runner=docker_runner,
                image=LINUX_IMAGE,
                template_rel="home/.chezmoi.toml.tmpl",
                data_file_in_container=data_file,
            )
            write_artifact(
                artifact_dir, f"compile-.chezmoi.{profile.id}.{platform_name}.out", output
            )
            tomllib.loads(output)
            compiled += 1

    assert compiled > 0


@pytest.mark.tier_smoke
@pytest.mark.platform_windows
@pytest.mark.requires_docker
def test_powershell_parser_docker(
    docker_runner: DockerRunner, artifact_dir: Path, repo_root: Path
) -> None:
    docker_runner.ensure_image(PWSH_IMAGE, repo_root / "tests" / "docker" / "powershell.Dockerfile")

    script = load_script(repo_root, "pwsh", "static_powershell_parse.ps1")

    result = docker_runner.run_pwsh(image=PWSH_IMAGE, script=script)
    output = result.stdout + result.stderr
    write_artifact(artifact_dir, "static-powershell-parse-docker.log", output)

    assert result.returncode == 0, output
    assert "CHECKED=" in output


@pytest.mark.tier_smoke
@pytest.mark.platform_windows
@pytest.mark.native_ci_only
def test_powershell_parser_native_ci(repo_root: Path, artifact_dir: Path) -> None:
    files = sorted((repo_root / "script").rglob("*.ps1")) + sorted(
        (repo_root / "tests").rglob("*.ps1")
    )
    assert files, "No PowerShell scripts found for parser checks"

    checked = 0
    errors: list[str] = []
    for file_path in files:
        result = powershell_parse_file(file_path)
        if result.returncode != 0:
            errors.append(f"{file_path}:\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}")
        checked += 1

    write_artifact(artifact_dir, "static-powershell-parse-native.log", f"CHECKED={checked}\n")
    assert not errors, "\n\n".join(errors)


@pytest.mark.tier_local
def test_script_loader_missing_file_fails_fast(repo_root: Path) -> None:
    with pytest.raises(FileNotFoundError):
        load_script(repo_root, "bash", "does-not-exist.sh")


@pytest.mark.tier_local
def test_script_loader_unresolved_placeholder_fails_fast() -> None:
    with pytest.raises(ValueError, match="Unresolved script placeholders"):
        apply_substitutions("echo {{MISSING_TOKEN}}", substitutions={})


@pytest.mark.tier_local
def test_matrix_loader_validates_required_keys(tmp_path: Path) -> None:
    bad_profiles = tmp_path / "profiles.toml"
    bad_profiles.write_text(
        """
[profiles.personal]
id = "personal"
hostname = "T-X"
codename = "T-X"
vault = "Personal"
client = false
agent = false
personal = true
with_token = false
op_mode = "missing"
""".strip()
        + "\n",
        encoding="utf-8",
    )

    scenarios_dir = tmp_path / "scenarios"
    scenarios_dir.mkdir(parents=True, exist_ok=True)
    (scenarios_dir / "bootstrap.toml").write_text(
        """
[[cases]]
id = "case"
profile = "personal"
expect_ready = false
# expect_applies intentionally missing
""".strip()
        + "\n",
        encoding="utf-8",
    )
    (scenarios_dir / "templates.toml").write_text(
        """
[[cases]]
id = "tpl"
template = "home/dot_ssh/config.tmpl"
platform = "all"
profile = "all"
must_contain = "Host *"
""".strip()
        + "\n",
        encoding="utf-8",
    )

    with pytest.raises(TypeError, match="bootstrap.cases\\[0\\] invalid schema"):
        load_matrix(bad_profiles, scenarios_dir)
