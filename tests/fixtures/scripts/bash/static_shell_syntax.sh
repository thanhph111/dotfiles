set -euo pipefail

checked=0
while IFS= read -r -d '' file_path; do
    [[ -f "$file_path" ]] || continue

    first_line="$(head -n 1 "$file_path" || true)"
    if [[ "$first_line" == '#!/usr/bin/env bash'* || "$first_line" == '#!/bin/bash'* || "$first_line" == '#!/bin/sh'* || "$first_line" == '#!/usr/bin/env sh'* ]]; then
        bash -n "$file_path"
        checked=$((checked + 1))
    fi
done < <(find /repo/script /repo/tests /repo/home/dot_local/bin -type f -print0 | sort -z)

echo "CHECKED=$checked"
if [[ "$checked" -eq 0 ]]; then
    echo "No shell scripts were discovered for syntax checks" >&2
    exit 1
fi
