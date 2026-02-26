# Tests

The test platform is Python-first (`uv` + `pytest`) with profile-driven fixtures.

## Usage

```bash
mise run test                                        # local tier, linux, docker
mise run test --tier smoke                           # smoke tier
mise run test --tier full --platform all             # full matrix
mise run test --platform darwin --profile agent      # specific combo
mise run test --suite hooks --tier smoke             # single suite
mise run test --report pretty                        # html + junit + summary (default)
mise run test --report off                           # no extra report files
mise run test --help                                 # show all flags
```

Local policy is strict: all local runtime tests must run through Docker.
Native execution is CI-only and guarded in `tests/conftest.py`.

## Reports

`--report pretty` writes per-run artifacts under `tests/artifacts/<run-id>/`:

- `junit.xml`
- `report.html` (self-contained)
- `summary.md`
- `artifact-index.json`
- suite logs and rendered outputs from tests

`summary.md` stays concise and includes artifact references/snippets for failed tests only.
CI appends `summary.md` to GitHub Step Summary and uploads artifacts on every run.

## Structure

- `tests/pytest.ini`: pytest configuration and markers
- `tests/conftest.py`: CLI options, tier/platform/profile filtering, local Docker guard
- `tests/helpers/`: shared Docker/chezmoi/profile/artifact helpers
- `tests/fixtures/profiles.toml`: consolidated profiles
- `tests/fixtures/scenarios/*.toml`: split scenario sets
- `tests/fixtures/scripts/{bash,pwsh}`: reusable script fixtures for runtime checks
- `.mise/tasks/test-build-summary.py`: JUnit -> Markdown summary generator
- `tests/suites/test_*.py`: pytest suites
- `tests/artifacts/`: per-run logs and rendered files

## Suites

- `test_static.py`: shell/PowerShell parse checks and template compile smoke
- `test_bootstrap.py`: first-run bootstrap matrix and integration flows
- `test_templates.py`: render matrix, secrets gating, onepassword mode
- `test_hooks.py`: Linux/Darwin/Windows hook render and guard behavior
