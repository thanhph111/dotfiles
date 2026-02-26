from pathlib import Path

import pytest

from helpers.artifacts import write_artifact
from helpers.chezmoi import (
    platform_matches,
    render_template,
    resolve_render_platforms,
    write_data_file,
)
from helpers.docker_cli import DockerRunner, LINUX_IMAGE
from helpers.matrix import Matrix, Profile


def _create_mock_op_bin(repo_root: Path, artifact_dir: Path) -> str:
    mock_dir = artifact_dir / "mock-op-bin"
    mock_dir.mkdir(parents=True, exist_ok=True)
    op_path = mock_dir / "op"
    op_path.write_text(
        "\n".join(
            [
                "#!/usr/bin/env bash",
                "set -euo pipefail",
                'if [[ "${1:-}" == "read" ]]; then',
                '    echo "mock-secret"',
                "    exit 0",
                "fi",
                'if [[ "${1:-}" == "vault" && "${2:-}" == "list" ]]; then',
                '    echo "[]"',
                "    exit 0",
                "fi",
                'echo "{}"',
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    op_path.chmod(0o755)
    rel = mock_dir.relative_to(repo_root).as_posix()
    return f"/repo/{rel}"


def _linux_env_with_mock_op(
    repo_root: Path, artifact_dir: Path, extra: dict[str, str] | None = None
) -> dict[str, str]:
    path_head = _create_mock_op_bin(repo_root, artifact_dir)
    env = {"PATH": f"{path_head}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"}
    if extra:
        env.update(extra)
    return env


@pytest.mark.tier_local
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_render_matrix(
    docker_runner: DockerRunner,
    artifact_dir: Path,
    repo_root: Path,
    platform: str,
    selected_profiles: list[Profile],
    matrix: Matrix,
) -> None:
    docker_runner.ensure_image(LINUX_IMAGE, repo_root / "tests" / "docker" / "linux.Dockerfile")
    scenario_cases = matrix.template_cases()
    selected_platforms = resolve_render_platforms(platform)

    renders = 0
    for platform_name in selected_platforms:
        for case in scenario_cases:
            case_id = str(case["id"])
            case_platform = str(case.get("platform", "all"))
            case_profile = str(case.get("profile", "all"))
            template_rel = str(case["template"])
            must_contain = str(case.get("must_contain", ""))

            if not platform_matches(platform_name, case_platform):
                continue

            for profile in selected_profiles:
                if case_profile != "all" and case_profile != profile.id:
                    continue

                _, data_file = write_data_file(
                    repo_root=repo_root,
                    artifact_dir=artifact_dir,
                    profile=profile,
                    platform=platform_name,
                    secrets_enabled=False,
                    label=f"render-data-{case_id}",
                )
                output = render_template(
                    runner=docker_runner,
                    image=LINUX_IMAGE,
                    template_rel=template_rel,
                    data_file_in_container=data_file,
                )
                write_artifact(
                    artifact_dir, f"render-{case_id}.{profile.id}.{platform_name}.out", output
                )

                if must_contain:
                    assert must_contain in output

                renders += 1

    assert renders > 0


@pytest.mark.tier_smoke
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_secrets_gating(
    docker_runner: DockerRunner,
    artifact_dir: Path,
    repo_root: Path,
    profiles_map: dict[str, Profile],
) -> None:
    docker_runner.ensure_image(LINUX_IMAGE, repo_root / "tests" / "docker" / "linux.Dockerfile")

    client = profiles_map["client"]
    agent = profiles_map["agent"]

    client_disabled_data = write_data_file(
        repo_root=repo_root,
        artifact_dir=artifact_dir,
        profile=client,
        platform="linux",
        secrets_enabled=False,
        label="client-disabled",
    )[1]
    client_enabled_data = write_data_file(
        repo_root=repo_root,
        artifact_dir=artifact_dir,
        profile=client,
        platform="linux",
        secrets_enabled=True,
        label="client-enabled",
    )[1]

    ssh_template = "home/dot_ssh/config.tmpl"
    client_disabled_output = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=ssh_template,
        data_file_in_container=client_disabled_data,
        env=_linux_env_with_mock_op(repo_root, artifact_dir),
    )
    client_enabled_output = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=ssh_template,
        data_file_in_container=client_enabled_data,
        env=_linux_env_with_mock_op(repo_root, artifact_dir, {"CHEZMOI_ENABLE_SECRETS": "1"}),
    )
    write_artifact(artifact_dir, "secrets-client-disabled.out", client_disabled_output)
    write_artifact(artifact_dir, "secrets-client-enabled.out", client_enabled_output)

    assert "mock-secret" not in client_disabled_output
    assert "mock-secret" in client_enabled_output

    agent_disabled_data = write_data_file(
        repo_root=repo_root,
        artifact_dir=artifact_dir,
        profile=agent,
        platform="linux",
        secrets_enabled=False,
        label="agent-disabled",
    )[1]
    agent_enabled_data = write_data_file(
        repo_root=repo_root,
        artifact_dir=artifact_dir,
        profile=agent,
        platform="linux",
        secrets_enabled=True,
        label="agent-enabled",
    )[1]

    openclaw_template = "home/dot_openclaw/openclaw.json.tmpl"
    agent_disabled_output = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=openclaw_template,
        data_file_in_container=agent_disabled_data,
        env=_linux_env_with_mock_op(repo_root, artifact_dir),
    )
    agent_enabled_output = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=openclaw_template,
        data_file_in_container=agent_enabled_data,
        env=_linux_env_with_mock_op(repo_root, artifact_dir, {"CHEZMOI_ENABLE_SECRETS": "1"}),
    )
    write_artifact(artifact_dir, "secrets-agent-disabled.out", agent_disabled_output)
    write_artifact(artifact_dir, "secrets-agent-enabled.out", agent_enabled_output)

    assert "MISSING_OP_CLI_RUN_SECOND_APPLY" in agent_disabled_output
    assert "mock-secret" in agent_enabled_output


@pytest.mark.tier_local
@pytest.mark.platform_linux
@pytest.mark.requires_docker
def test_onepassword_mode(
    docker_runner: DockerRunner,
    artifact_dir: Path,
    repo_root: Path,
    profiles_map: dict[str, Profile],
) -> None:
    docker_runner.ensure_image(LINUX_IMAGE, repo_root / "tests" / "docker" / "linux.Dockerfile")

    profile = profiles_map["personal"]
    template_rel = "home/.chezmoi.toml.tmpl"

    _, base_data = write_data_file(
        repo_root=repo_root,
        artifact_dir=artifact_dir,
        profile=profile,
        platform="linux",
        secrets_enabled=False,
        label="onepassword-base",
    )

    base_output = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=template_rel,
        data_file_in_container=base_data,
    )
    write_artifact(artifact_dir, "onepassword-base.out", base_output)
    assert "prompt = false" in base_output
    assert "secretsEnabled = false" in base_output
    assert 'mode = "service"' not in base_output

    enabled_output = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=template_rel,
        data_file_in_container=base_data,
        env={"CHEZMOI_ENABLE_SECRETS": "1"},
    )
    write_artifact(artifact_dir, "onepassword-enable-secrets.out", enabled_output)
    assert "secretsEnabled = true" in enabled_output
    assert 'mode = "service"' not in enabled_output

    service_output = render_template(
        runner=docker_runner,
        image=LINUX_IMAGE,
        template_rel=template_rel,
        data_file_in_container=base_data,
        env={"OP_SERVICE_ACCOUNT_TOKEN": "dummy"},
    )
    write_artifact(artifact_dir, "onepassword-service.out", service_output)
    assert "secretsEnabled = true" in service_output
    assert 'mode = "service"' in service_output
