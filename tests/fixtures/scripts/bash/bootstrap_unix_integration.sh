set -euo pipefail

tmpdir="$(mktemp -d)"
mock_bin="$tmpdir/bin"
mkdir -p "$mock_bin" "$tmpdir/home" "$tmpdir/cache"

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
chmod +x "$mock_bin/brew" "$mock_bin/op"

if [[ "${PROFILE_OP_MODE}" == "missing" ]]; then
    rm -f "$mock_bin/op"
fi

client_bool=false
agent_bool=false
personal_bool=false
if [[ "${PROFILE_CLIENT}" == "1" ]]; then client_bool=true; fi
if [[ "${PROFILE_AGENT}" == "1" ]]; then agent_bool=true; fi
if [[ "${PROFILE_PERSONAL}" == "1" ]]; then personal_bool=true; fi

cat >"$tmpdir/chezmoi.test.toml" <<EOF_CFG
umask = 0o022

[data]
    codename = "${PROFILE_CODENAME}"
    personal = ${personal_bool}
    vault = "${PROFILE_VAULT}"
    headless = true
    client = ${client_bool}
    agent = ${agent_bool}
    secretsEnabled = false
    gitName = "Thanh Phan"
    gitEmail = "thanhph111@gmail.com"
    gitSigningKey = "DC49B16FF2563A32"

[onepassword]
    prompt = false
EOF_CFG

cat >"$tmpdir/chezmoi-wrapper" <<'EOF_WRAP'
#!/usr/bin/env bash
set -euo pipefail

args=()
for arg in "$@"; do
    if [[ "$arg" == "--init" ]]; then
        continue
    fi
    args+=("$arg")
done

exec "${CHEZMOI_REAL_BIN:?}" "${args[@]}"
EOF_WRAP
chmod +x "$tmpdir/chezmoi-wrapper"

if [[ "${PROFILE_WITH_TOKEN}" == "1" ]]; then
    export OP_SERVICE_ACCOUNT_TOKEN="dummy"
else
    unset OP_SERVICE_ACCOUNT_TOKEN || true
fi

output="$({
    PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin" \
        CHEZMOI_REAL_BIN="$(command -v chezmoi)" \
        CHEZMOI_CMD="$tmpdir/chezmoi-wrapper" \
        /repo/script/bootstrap-first-run \
        --dry-run \
        --exclude scripts \
        --config "$tmpdir/chezmoi.test.toml" \
        -S /repo \
        -D "$tmpdir/home" \
        --persistent-state "$tmpdir/state.boltdb" \
        --cache "$tmpdir/cache" \
        "$tmpdir/home/.zshrc"
} 2>&1)"

printf '%s\n' "$output"
