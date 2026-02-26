from datetime import datetime, timezone
from pathlib import Path
import os
import uuid


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
    return path
