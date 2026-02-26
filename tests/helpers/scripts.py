from pathlib import Path
import re


PLACEHOLDER_PATTERN = re.compile(r"{{([A-Z][A-Z0-9_]*)}}")


def apply_substitutions(content: str, substitutions: dict[str, str] | None = None) -> str:
    rendered = content
    for key, value in (substitutions or {}).items():
        rendered = rendered.replace(f"{{{{{key}}}}}", value)

    unresolved = sorted(set(PLACEHOLDER_PATTERN.findall(rendered)))
    if unresolved:
        raise ValueError(f"Unresolved script placeholders: {', '.join(unresolved)}")

    return rendered


def load_script(
    repo_root: Path, kind: str, name: str, substitutions: dict[str, str] | None = None
) -> str:
    if kind not in {"bash", "pwsh"}:
        raise ValueError(f"Unsupported script kind '{kind}'")

    path = repo_root / "tests" / "fixtures" / "scripts" / kind / name
    if not path.exists():
        raise FileNotFoundError(f"Missing script fixture: {path}")

    content = path.read_text(encoding="utf-8")
    return apply_substitutions(content, substitutions=substitutions)
