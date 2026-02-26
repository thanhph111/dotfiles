#!/usr/bin/env -S mise x uv -- uv run --script --no-sync

# MISE description="Build markdown summary from pytest JUnit XML"

import argparse
import json
from pathlib import Path
from typing import Iterable
import xml.etree.ElementTree as ET


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build markdown summary from pytest JUnit XML")
    parser.add_argument("--junit", required=True, help="Path to junit.xml")
    parser.add_argument(
        "--artifact-index",
        required=False,
        default="",
        help="Path to artifact-index.json (optional)",
    )
    parser.add_argument("--output", required=True, help="Path to output markdown file")
    parser.add_argument(
        "--snippet-lines",
        required=False,
        type=int,
        default=20,
        help="Number of lines to include per failure artifact snippet",
    )
    parser.add_argument(
        "--meta",
        action="append",
        default=[],
        metavar="KEY=VALUE",
        help="Environment metadata entry",
    )
    return parser.parse_args()


def _to_int(value: str | None) -> int:
    if value is None:
        return 0
    try:
        return int(value)
    except ValueError:
        return 0


def _to_float(value: str | None) -> float:
    if value is None:
        return 0.0
    try:
        return float(value)
    except ValueError:
        return 0.0


def _collect_suites(root: ET.Element) -> list[ET.Element]:
    if root.tag == "testsuite":
        return [root]
    if root.tag == "testsuites":
        return [suite for suite in root if suite.tag == "testsuite"]
    return []


def _nodeid(testcase: ET.Element) -> str:
    classname = (testcase.get("classname") or "").strip()
    name = (testcase.get("name") or "").strip()
    if classname and name:
        return f"{classname}::{name}"
    return classname or name or "<unknown>"


def _nodeid_candidates(testcase: ET.Element) -> list[str]:
    classname = (testcase.get("classname") or "").strip()
    name = (testcase.get("name") or "").strip()
    candidates = []

    if classname and name:
        candidates.append(f"{classname}::{name}")
        candidates.append(f"{classname.replace('.', '/')}.py::{name}")
        if classname.startswith("tests."):
            candidates.append(f"{classname.replace('.', '/')[6:]}.py::{name}")
    elif classname:
        candidates.append(classname)
    elif name:
        candidates.append(name)
    else:
        candidates.append("<unknown>")

    deduped: list[str] = []
    for candidate in candidates:
        if candidate not in deduped:
            deduped.append(candidate)
    return deduped


def _first_line(text: str) -> str:
    return (text.strip().splitlines() or [""])[0].strip()


def _short_failure_message(entry: ET.Element) -> str:
    message = (entry.get("message") or "").strip()
    if message:
        return _first_line(message)

    text = (entry.text or "").strip()
    if text:
        return _first_line(text)

    return "No message"


def _parse_meta(items: Iterable[str]) -> dict[str, str]:
    meta: dict[str, str] = {}
    for item in items:
        if "=" not in item:
            continue
        key, value = item.split("=", 1)
        key = key.strip()
        if not key:
            continue
        meta[key] = value.strip()
    return meta


def _load_artifact_index(path: Path | None) -> dict[str, list[str]]:
    if path is None or not path.exists():
        return {}

    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, dict) and isinstance(raw.get("tests"), dict):
        payload = raw["tests"]
    elif isinstance(raw, dict):
        payload = raw
    else:
        return {}

    result: dict[str, list[str]] = {}
    for key, value in payload.items():
        if isinstance(key, str) and isinstance(value, list):
            paths = [item for item in value if isinstance(item, str)]
            result[key] = paths
    return result


def _load_snippet(path: Path, lines_count: int) -> str:
    try:
        text = path.read_text(encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        return f"<unreadable: {exc}>"

    lines = text.splitlines()
    if not lines:
        return "<empty>"
    return "\n".join(lines[:lines_count]).strip()


def _resolve_artifacts(
    index: dict[str, list[str]], testcase: ET.Element, artifact_root: Path
) -> list[tuple[str, Path]]:
    for nodeid in _nodeid_candidates(testcase):
        if nodeid in index:
            paths: list[tuple[str, Path]] = []
            for artifact in index[nodeid]:
                paths.append((artifact, artifact_root / artifact))
            return paths
    return []


def build_summary(
    junit_path: Path, artifact_index_path: Path | None, snippet_lines: int, meta: dict[str, str]
) -> str:
    tree = ET.parse(junit_path)
    root = tree.getroot()
    suites = _collect_suites(root)
    if not suites:
        raise ValueError(f"Unsupported JUnit root tag: {root.tag}")

    tests = failures = errors = skipped = 0
    duration = 0.0
    failed_rows: list[tuple[str, str]] = []
    failure_details: list[tuple[str, str, list[tuple[str, Path]]]] = []
    artifact_root = junit_path.parent
    artifact_index = _load_artifact_index(artifact_index_path)

    for suite in suites:
        tests += _to_int(suite.get("tests"))
        failures += _to_int(suite.get("failures"))
        errors += _to_int(suite.get("errors"))
        skipped += _to_int(suite.get("skipped"))
        duration += _to_float(suite.get("time"))

        for testcase in suite.iter("testcase"):
            test_id = _nodeid(testcase)
            for key in ("failure", "error"):
                for item in testcase.findall(key):
                    message = _short_failure_message(item)
                    failed_rows.append((test_id, message))
                    artifacts = _resolve_artifacts(artifact_index, testcase, artifact_root)
                    failure_details.append((test_id, message, artifacts))

    passed = max(tests - failures - errors - skipped, 0)

    lines = [
        "# Test Summary",
        "",
        "| Metric | Value |",
        "|---|---:|",
        f"| Passed | {passed} |",
        f"| Failed | {failures} |",
        f"| Errors | {errors} |",
        f"| Skipped | {skipped} |",
        f"| Total | {tests} |",
        f"| Duration (s) | {duration:.2f} |",
    ]

    lines.extend(["", "## Environment", "", "| Key | Value |", "|---|---|"])
    if meta:
        for key in sorted(meta):
            value = meta[key] or "-"
            lines.append(f"| `{key}` | `{value}` |")
    else:
        lines.append("| `metadata` | `none` |")

    lines.extend(["", "## Failures", ""])
    if failed_rows:
        for test_id, message in failed_rows:
            lines.append(f"- `{test_id}`: {message}")
    else:
        lines.append("- None")

    if failure_details:
        lines.extend(["", "## Failure Artifacts", ""])
        for test_id, message, artifacts in failure_details:
            lines.append(f"### `{test_id}`")
            lines.append("")
            lines.append(f"- Message: {message}")
            if not artifacts:
                lines.append("- Artifacts: none recorded")
                lines.append("")
                continue

            for artifact_rel, artifact_path in artifacts:
                lines.append(f"- Artifact: `{artifact_rel}`")
                snippet = _load_snippet(artifact_path, snippet_lines)
                lines.append("")
                lines.append("```text")
                lines.append(snippet)
                lines.append("```")
            lines.append("")

    return "\n".join(lines) + "\n"


def build_fallback(
    junit_path: Path, artifact_index_path: Path | None, meta: dict[str, str], error: str
) -> str:
    lines = [
        "# Test Summary",
        "",
        "JUnit report could not be parsed. See artifact logs for details.",
        "",
        f"- Input: `{junit_path}`",
        f"- Artifact index: `{artifact_index_path}`",
        f"- Error: `{error}`",
        "",
        "## Environment",
        "",
        "| Key | Value |",
        "|---|---|",
    ]

    if meta:
        for key in sorted(meta):
            value = meta[key] or "-"
            lines.append(f"| `{key}` | `{value}` |")
    else:
        lines.append("| `metadata` | `none` |")

    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    junit_path = Path(args.junit)
    artifact_index_path = Path(args.artifact_index) if args.artifact_index else None
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    meta = _parse_meta(args.meta)
    snippet_lines = max(args.snippet_lines, 1)

    try:
        if not junit_path.exists():
            raise FileNotFoundError(str(junit_path))
        summary = build_summary(
            junit_path=junit_path,
            artifact_index_path=artifact_index_path,
            snippet_lines=snippet_lines,
            meta=meta,
        )
    except Exception as exc:  # noqa: BLE001
        summary = build_fallback(
            junit_path=junit_path,
            artifact_index_path=artifact_index_path,
            meta=meta,
            error=str(exc),
        )

    output_path.write_text(summary, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
