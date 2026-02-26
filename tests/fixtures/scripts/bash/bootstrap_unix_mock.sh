# shellcheck shell=bash
set -euo pipefail

mock_root="$(mktemp -d)"
mock_bin="$mock_root/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/chezmoi" <<'EOF_CHEZ'
#!/usr/bin/env bash
set -euo pipefail
echo "MOCK chezmoi $*"
EOF_CHEZ

cat >"$mock_bin/brew" <<'EOF_BREW'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "shellenv" ]]; then
    echo 'export PATH="$PATH"'
fi
EOF_BREW

cat >"$mock_bin/op" <<'EOF_OP'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "vault" && "${2:-}" == "list" ]]; then
    case "${PROFILE_OP_MODE}" in
    ok)
        echo "[]"
        exit 0
        ;;
    *)
        exit 1
        ;;
    esac
fi
if [[ "${1:-}" == "read" ]]; then
    echo "mock-secret"
    exit 0
fi
echo "{}"
EOF_OP

chmod +x "$mock_bin/chezmoi" "$mock_bin/brew" "$mock_bin/op"

if [[ "${PROFILE_OP_MODE}" == "missing" ]]; then
    rm -f "$mock_bin/op"
fi

if [[ "${PROFILE_WITH_TOKEN}" == "1" ]]; then
    export OP_SERVICE_ACCOUNT_TOKEN="dummy"
else
    unset OP_SERVICE_ACCOUNT_TOKEN || true
fi

output="$({
    PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin" \
        CHEZMOI_CMD="$mock_bin/chezmoi" \
        /repo/script/bootstrap-first-run --dry-run --exclude scripts
} 2>&1)"

printf '%s\n' "$output"
