import json
from pathlib import Path
import re
import shlex
from typing import Any
import uuid

from helpers.docker_cli import DockerRunner
from helpers.matrix import Profile

CHEZMOI_CONFIG = "/repo/tests/fixtures/config/chezmoi.test.toml"
PATH_FALLBACK = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
_TEMPLATE_INCLUDE_RE = re.compile(r'\{\{-?\s*template\s+"')


def platform_home_dir(platform: str) -> str:
    if platform in {"windows", "powershell"}:
        return r"C:\Users\tester"
    if platform == "darwin":
        return "/Users/tester"
    return "/home/tester"


def platform_os_key(platform: str) -> str:
    return "windows" if platform == "powershell" else platform


def platform_os_release_id(platform: str) -> str:
    return "debian" if platform == "linux" else ""


def profile_to_data(profile: Profile, platform: str, secrets_enabled: bool) -> dict[str, Any]:
    return {
        "codename": profile.codename,
        "personal": profile.personal,
        "vault": profile.vault,
        "headless": True,
        "client": profile.client,
        "agent": profile.agent,
        "secretsEnabled": secrets_enabled,
        "gitName": "Thanh Phan",
        "gitEmail": "thanhph111@gmail.com",
        "gitSigningKey": "DC49B16FF2563A32",
        "chezmoi": {
            "username": "tester",
            "hostname": profile.hostname,
            "os": platform_os_key(platform),
            "homeDir": platform_home_dir(platform),
            "sourceDir": "/repo/home",
            "osRelease": {"id": platform_os_release_id(platform)},
        },
    }


def write_data_file(
    repo_root: Path,
    artifact_dir: Path,
    profile: Profile,
    platform: str,
    secrets_enabled: bool,
    label: str,
) -> tuple[Path, str]:
    payload = profile_to_data(profile, platform, secrets_enabled)
    file_path = artifact_dir / f"{label}-{profile.id}-{platform}-{uuid.uuid4().hex[:8]}.json"
    file_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    relative = file_path.relative_to(repo_root).as_posix()
    return file_path, f"/repo/{relative}"


def requires_managed_render(repo_root: Path, template_rel: str) -> bool:
    """Check if a template uses {{ template "..." }} includes that need the full chezmoi pipeline."""
    content = (repo_root / template_rel).read_text(encoding="utf-8")
    return bool(_TEMPLATE_INCLUDE_RE.search(content))


def render_template_execute(
    runner: DockerRunner,
    image: str,
    template_rel: str,
    data_file_in_container: str,
    env: dict[str, str] | None = None,
) -> str:
    cmd = [
        "chezmoi",
        "execute-template",
        "--config",
        CHEZMOI_CONFIG,
        "-S",
        "/repo",
        "--init",
        "--stdinisatty=false",
        "--override-data-file",
        data_file_in_container,
        "--file",
        f"/repo/{template_rel}",
    ]
    proc = runner.run_container(image=image, container_cmd=cmd, env=env)
    if proc.returncode != 0:
        raise AssertionError(
            f"Template render failed: {template_rel}\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
        )
    return proc.stdout


def render_template_managed(
    runner: DockerRunner,
    image: str,
    template_rel: str,
    data_file_in_container: str,
    env: dict[str, str] | None = None,
) -> str:
    tmp_dest = f"/tmp/chezmoi-cat-{uuid.uuid4().hex}"

    script = "\n".join(
        [
            "set -euo pipefail",
            f"target=$(chezmoi target-path --config {shlex.quote(CHEZMOI_CONFIG)} -S /repo -D {shlex.quote(tmp_dest)} --source-path {shlex.quote(template_rel)})",
            f'chezmoi cat --config {shlex.quote(CHEZMOI_CONFIG)} -S /repo -D {shlex.quote(tmp_dest)} --override-data-file {shlex.quote(data_file_in_container)} "$target"',
        ]
    )

    proc = runner.run_bash(image=image, script=script, env=env)
    if proc.returncode != 0:
        raise AssertionError(
            f"Managed template render failed: {template_rel}\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
        )
    return proc.stdout


def render_template(
    runner: DockerRunner,
    image: str,
    template_rel: str,
    data_file_in_container: str,
    env: dict[str, str] | None = None,
) -> str:
    if requires_managed_render(runner.repo_root, template_rel):
        return render_template_managed(runner, image, template_rel, data_file_in_container, env=env)
    return render_template_execute(runner, image, template_rel, data_file_in_container, env=env)


def resolve_render_platforms(selected_platform: str) -> list[str]:
    if selected_platform == "all":
        return ["linux", "darwin", "windows"]
    if selected_platform == "powershell":
        return ["windows"]
    return [selected_platform]


def platform_matches(requested: str, scenario_platform: str) -> bool:
    if requested == "all" or scenario_platform == "all":
        return True

    aliases = {"powershell": "windows", "windows": "powershell"}

    if requested == scenario_platform:
        return True

    return aliases.get(requested) == scenario_platform
