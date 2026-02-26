from datetime import datetime, timezone
from pathlib import Path
import json
import os
from collections import defaultdict
from contextvars import ContextVar
import uuid

_CURRENT_NODEID: ContextVar[str | None] = ContextVar("artifact_nodeid", default=None)
_ARTIFACT_REGISTRY: dict[str, list[str]] = defaultdict(list)


def create_artifact_dir(repo_root: Path, requested: str | None = None) -> Path:
    artifacts_root = repo_root / "tests" / "artifacts"
    artifacts_root.mkdir(parents=True, exist_ok=True)

    if requested:
        path = Path(requested)
        if not path.is_absolute():
            path = repo_root / path
        path.mkdir(parents=True, exist_ok=True)
        return path

    run_id = f"{datetime.now(tz=timezone.utc):%Y%m%dT%H%M%SZ}-{os.getpid()}-{uuid.uuid4().hex[:6]}"
    path = artifacts_root / run_id
    path.mkdir(parents=True, exist_ok=True)
    return path


def write_artifact(artifact_dir: Path, name: str, content: str) -> Path:
    path = artifact_dir / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    _register_artifact(artifact_dir=artifact_dir, path=path)
    return path


def set_current_test(nodeid: str) -> None:
    _CURRENT_NODEID.set(nodeid)


def clear_current_test() -> None:
    _CURRENT_NODEID.set(None)


def write_artifact_index(artifact_dir: Path) -> Path:
    path = artifact_dir / "artifact-index.json"
    payload = {"tests": _ARTIFACT_REGISTRY}
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    return path


def _register_artifact(artifact_dir: Path, path: Path) -> None:
    nodeid = _CURRENT_NODEID.get()
    if not nodeid:
        return

    try:
        relative_path = path.relative_to(artifact_dir).as_posix()
    except ValueError:
        relative_path = str(path)

    entries = _ARTIFACT_REGISTRY[nodeid]
    if relative_path not in entries:
        entries.append(relative_path)
