from pathlib import Path
import os
import subprocess

import pytest

from helpers.artifacts import create_artifact_dir
from helpers.chezmoi import platform_matches
from helpers.docker_cli import DockerRunner
from helpers.matrix import Matrix, Profile, load_matrix, resolve_profile_ids

TIER_RANK = {"local": 1, "smoke": 2, "full": 3}

FILE_SUITE_MAP = {
    "test_static.py": "static",
    "test_bootstrap.py": "bootstrap",
    "test_templates.py": "templates",
    "test_hooks.py": "hooks",
}

PROFILES_FILE = Path(__file__).resolve().parent / "fixtures" / "profiles.toml"
SCENARIOS_DIR = Path(__file__).resolve().parent / "fixtures" / "scenarios"


def _load_matrix_file() -> Matrix:
    return load_matrix(PROFILES_FILE, SCENARIOS_DIR)


def _normalize_driver(requested: str) -> str:
    if requested != "auto":
        return requested

    proc = subprocess.run(["docker", "info"], text=True, capture_output=True, check=False)
    if proc.returncode == 0:
        return "docker"
    return "native"


def _is_ci() -> bool:
    return os.getenv("CI", "").strip().lower() == "true"


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption("--tier", action="store", default="local", choices=["local", "smoke", "full"])
    parser.addoption(
        "--suite",
        action="store",
        default="all",
        choices=["static", "bootstrap", "templates", "hooks", "all"],
    )
    parser.addoption(
        "--platform",
        action="store",
        default="linux",
        choices=["linux", "darwin", "windows", "powershell", "all"],
    )
    parser.addoption(
        "--profile",
        action="store",
        default="all",
        choices=["personal", "client", "client-auth", "agent", "all"],
    )
    parser.addoption(
        "--driver", action="store", default="docker", choices=["docker", "native", "auto"]
    )


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line("markers", "tier_local: Included in local tier")
    config.addinivalue_line("markers", "tier_smoke: Included in smoke tier and above")
    config.addinivalue_line("markers", "tier_full: Included in full tier only")
    config.addinivalue_line("markers", "platform_linux: Linux-oriented checks")
    config.addinivalue_line("markers", "platform_darwin: Darwin/macOS-oriented checks")
    config.addinivalue_line("markers", "platform_windows: Windows/PowerShell-oriented checks")
    config.addinivalue_line("markers", "requires_docker: Requires Docker")
    config.addinivalue_line("markers", "native_ci_only: Native checks that only run in CI")


def pytest_sessionstart(session: pytest.Session) -> None:
    config = session.config

    driver = _normalize_driver(config.getoption("--driver"))
    config.option.driver = driver

    if not _is_ci() and driver != "docker":
        raise pytest.UsageError("Native driver is disallowed locally. Use --driver docker.")

    if not _is_ci() and driver == "docker":
        proc = subprocess.run(["docker", "info"], text=True, capture_output=True, check=False)
        if proc.returncode != 0:
            raise pytest.UsageError(
                "Docker daemon is unavailable. Start Docker/OrbStack first.\n"
                f"STDERR:\n{proc.stderr}"
            )


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    selected_tier = config.getoption("--tier")
    selected_suite = config.getoption("--suite")
    selected_platform = config.getoption("--platform")
    selected_driver = config.getoption("--driver")

    deselected: list[pytest.Item] = []
    kept: list[pytest.Item] = []

    for item in items:
        suite = FILE_SUITE_MAP.get(item.path.name)
        if selected_suite != "all" and suite != selected_suite:
            deselected.append(item)
            continue

        required_tier_name = "local"
        if item.get_closest_marker("tier_full"):
            required_tier_name = "full"
        elif item.get_closest_marker("tier_smoke"):
            required_tier_name = "smoke"

        if TIER_RANK[selected_tier] < TIER_RANK[required_tier_name]:
            item.add_marker(pytest.mark.skip(reason=f"Requires --tier {required_tier_name}"))

        platform_marks = []
        if item.get_closest_marker("platform_linux"):
            platform_marks.append("linux")
        if item.get_closest_marker("platform_darwin"):
            platform_marks.append("darwin")
        if item.get_closest_marker("platform_windows"):
            platform_marks.append("windows")

        if platform_marks and selected_platform != "all":
            if not any(
                platform_matches(selected_platform, marked_platform)
                for marked_platform in platform_marks
            ):
                item.add_marker(
                    pytest.mark.skip(reason=f"Excluded by --platform={selected_platform}")
                )

        if item.get_closest_marker("requires_docker") and selected_driver != "docker":
            item.add_marker(pytest.mark.skip(reason="Requires --driver docker"))

        if item.get_closest_marker("native_ci_only"):
            if not _is_ci():
                item.add_marker(pytest.mark.skip(reason="native_ci_only tests run only in CI"))
            if selected_driver == "docker":
                item.add_marker(
                    pytest.mark.skip(reason="native_ci_only tests require --driver native")
                )

        kept.append(item)

    if deselected:
        config.hook.pytest_deselected(items=deselected)
        items[:] = kept


def pytest_generate_tests(metafunc: pytest.Metafunc) -> None:
    if "profile_name" not in metafunc.fixturenames:
        return

    matrix = _load_matrix_file()
    requested = metafunc.config.getoption("--profile")
    selected = resolve_profile_ids(requested, matrix.profile_ids())
    metafunc.parametrize("profile_name", selected, ids=selected)


@pytest.fixture(scope="session")
def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def matrix() -> Matrix:
    return _load_matrix_file()


@pytest.fixture(scope="session")
def artifact_dir(repo_root: Path) -> Path:
    requested = os.getenv("TEST_ARTIFACT_DIR")
    return create_artifact_dir(repo_root=repo_root, requested=requested)


@pytest.fixture(scope="session")
def tier(pytestconfig: pytest.Config) -> str:
    return pytestconfig.getoption("--tier")


@pytest.fixture(scope="session")
def platform(pytestconfig: pytest.Config) -> str:
    return pytestconfig.getoption("--platform")


@pytest.fixture(scope="session")
def driver(pytestconfig: pytest.Config) -> str:
    return pytestconfig.getoption("--driver")


@pytest.fixture(scope="session")
def profiles_map(matrix: Matrix) -> dict[str, Profile]:
    return matrix.profiles


@pytest.fixture
def profile(profile_name: str, profiles_map: dict[str, Profile]) -> Profile:
    return profiles_map[profile_name]


@pytest.fixture(scope="session")
def selected_profiles(pytestconfig: pytest.Config, matrix: Matrix) -> list[Profile]:
    requested = pytestconfig.getoption("--profile")
    return [matrix.profiles[pid] for pid in resolve_profile_ids(requested, matrix.profile_ids())]


@pytest.fixture(scope="session")
def docker_runner(repo_root: Path, artifact_dir: Path, pytestconfig: pytest.Config) -> DockerRunner:
    runner = DockerRunner(
        repo_root=repo_root,
        artifact_dir=artifact_dir,
        verbose=pytestconfig.getoption("verbose") > 0,
    )
    if pytestconfig.getoption("--driver") == "docker":
        runner.require_docker()
    return runner


@pytest.fixture(scope="session")
def all_profile_ids(matrix: Matrix) -> tuple[str, ...]:
    return matrix.profile_ids()
