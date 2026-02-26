set -euo pipefail

mockbin="$(mktemp -d)"

cat >"$mockbin/op" <<'EOF_OP'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "vault" && "${2:-}" == "list" ]]; then
    [[ "${MOCK_OP_AUTH:-0}" == "1" ]] && exit 0
    exit 1
fi
exit 0
EOF_OP

cat >"$mockbin/openclaw" <<'EOF_OC'
#!/usr/bin/env bash
set -euo pipefail
echo "openclaw $*" >>"${OPENCLAW_LOG_PATH:?}"
EOF_OC

cat >"$mockbin/launchctl" <<'EOF_LC'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "list" ]]; then
    if [[ "${MOCK_DAEMON_PRESENT:-0}" == "1" ]]; then
        echo "123\t0\topenclaw"
    else
        echo "123\t0\tother"
    fi
fi
EOF_LC

chmod +x "$mockbin/op" "$mockbin/openclaw" "$mockbin/launchctl"

PATH="/usr/bin:/bin" {{SCRIPT_PATH}} >/dev/null 2>&1

PATH="$mockbin:/usr/bin:/bin" MOCK_OP_AUTH=0 OPENCLAW_LOG_PATH={{LOG_PATH}} {{SCRIPT_PATH}} >/dev/null 2>&1
[[ ! -f {{LOG_PATH}} ]]

PATH="$mockbin:/usr/bin:/bin" MOCK_OP_AUTH=1 MOCK_DAEMON_PRESENT=0 OPENCLAW_LOG_PATH={{LOG_PATH}} {{SCRIPT_PATH}} >/dev/null 2>&1
grep -q "openclaw onboard --install-daemon" {{LOG_PATH}}

before_lines="$(wc -l <{{LOG_PATH}})"
PATH="$mockbin:/usr/bin:/bin" MOCK_OP_AUTH=1 MOCK_DAEMON_PRESENT=1 OPENCLAW_LOG_PATH={{LOG_PATH}} {{SCRIPT_PATH}} >/dev/null 2>&1
after_lines="$(wc -l <{{LOG_PATH}})"
[[ "$before_lines" == "$after_lines" ]]
