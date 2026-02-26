from dataclasses import dataclass
from pathlib import Path
from typing import Any
import tomllib


@dataclass(frozen=True)
class Profile:
    id: str
    hostname: str
    codename: str
    vault: str
    client: bool
    agent: bool
    personal: bool
    with_token: bool
    op_mode: str


@dataclass(frozen=True)
class BootstrapCase:
    id: str
    profile: str
    expect_ready: bool
    expect_applies: int


@dataclass(frozen=True)
class Matrix:
    profiles: dict[str, Profile]
    bootstrap: list[BootstrapCase]
    templates: list[dict[str, Any]]

    def profile_ids(self) -> tuple[str, ...]:
        return tuple(self.profiles.keys())

    def bootstrap_cases(self) -> list[BootstrapCase]:
        return list(self.bootstrap)

    def template_cases(self) -> list[dict[str, Any]]:
        return list(self.templates)


def resolve_profile_ids(requested: str, available_ids: tuple[str, ...]) -> list[str]:
    if requested == "all":
        return list(available_ids)
    if requested not in available_ids:
        raise ValueError(f"Unknown profile '{requested}' (available: {', '.join(available_ids)})")
    return [requested]


def _load_profiles(profiles_path: Path) -> dict[str, Profile]:
    root = tomllib.loads(profiles_path.read_text(encoding="utf-8"))
    profiles_raw = root.get("profiles", {})
    if not profiles_raw:
        raise ValueError("profiles must not be empty")

    profiles: dict[str, Profile] = {}
    for key, raw in profiles_raw.items():
        if str(raw.get("id")) != key:
            raise ValueError(
                f"profiles.{key}.id must match profile key ('{key}'), got '{raw.get('id')}'"
            )
        profiles[key] = Profile(**raw)

    return profiles


def load_matrix(profiles_path: Path, scenarios_dir: Path) -> Matrix:
    profiles = _load_profiles(profiles_path)

    bootstrap_cases_raw = tomllib.loads(
        (scenarios_dir / "bootstrap.toml").read_text(encoding="utf-8")
    )["cases"]
    template_cases = tomllib.loads((scenarios_dir / "templates.toml").read_text(encoding="utf-8"))[
        "cases"
    ]

    bootstrap_cases: list[BootstrapCase] = []
    for index, case in enumerate(bootstrap_cases_raw):
        try:
            bootstrap_case = BootstrapCase(**case)
        except TypeError as exc:
            raise TypeError(f"bootstrap.cases[{index}] invalid schema: {exc}") from exc

        profile_name = bootstrap_case.profile
        if profile_name not in profiles:
            raise ValueError(
                f"bootstrap.cases[{index}] references unknown profile '{profile_name}'"
            )
        bootstrap_cases.append(bootstrap_case)

    for index, case in enumerate(template_cases):
        profile_name = str(case["profile"])
        if profile_name != "all" and profile_name not in profiles:
            raise ValueError(
                f"templates.cases[{index}] references unknown profile '{profile_name}'"
            )

    return Matrix(profiles=profiles, bootstrap=bootstrap_cases, templates=template_cases)
