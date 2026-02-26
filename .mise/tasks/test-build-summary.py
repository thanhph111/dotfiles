#!/usr/bin/env -S mise x uv -- uv run --script --no-sync

# MISE description="Build markdown summary from pytest JUnit XML"

import argparse
from pathlib import Path
from typing import Iterable
import xml.etree.ElementTree as ET


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build markdown summary from pytest JUnit XML")
    parser.add_argument("--junit", required=True, help="Path to junit.xml")
    parser.add_argument("--output", required=True, help="Path to output markdown file")
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


def build_summary(junit_path: Path, meta: dict[str, str]) -> str:
    tree = ET.parse(junit_path)
    root = tree.getroot()
    suites = _collect_suites(root)
    if not suites:
        raise ValueError(f"Unsupported JUnit root tag: {root.tag}")

    tests = failures = errors = skipped = 0
    duration = 0.0
    failed_rows: list[tuple[str, str]] = []

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
                    failed_rows.append((test_id, _short_failure_message(item)))

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

    return "\n".join(lines) + "\n"


def build_fallback(junit_path: Path, meta: dict[str, str], error: str) -> str:
    lines = [
        "# Test Summary",
        "",
        "JUnit report could not be parsed. See artifact logs for details.",
        "",
        f"- Input: `{junit_path}`",
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
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    meta = _parse_meta(args.meta)

    try:
        if not junit_path.exists():
            raise FileNotFoundError(str(junit_path))
        summary = build_summary(junit_path=junit_path, meta=meta)
    except Exception as exc:  # noqa: BLE001
        summary = build_fallback(junit_path=junit_path, meta=meta, error=str(exc))

    output_path.write_text(summary, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
