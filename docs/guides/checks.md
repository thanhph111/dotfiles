# Checks

Run checks before applying config changes.

## Normal check

```bash
mise run lint
git diff --check
```

## Render facts

```bash
chezmoi execute-template '{{ includeTemplate "resolved-machine.json" . }}' |
    jq -S .
```

## Render features

```bash
chezmoi execute-template '{{ includeTemplate "resolved-features.json" . }}' |
    jq -S .
```

## Render Rev-9

```bash
chezmoi execute-template \
    --override-data '{"chezmoi":{"os":"linux","hostname":"Rev-9","username":"thanhph111","homeDir":"/home/thanhph111"}}' \
    '{{ includeTemplate "resolved-features.json" . }}' |
    jq -S '.linux | {security, network, services}'
```

## Preview apply

For regular file changes:

```bash
chezmoi diff
chezmoi apply --exclude=scripts
```

When scripts, features, setup, package manifests, or secrets sync changed:

```bash
chezmoi diff --exclude=none --no-pager
```

Use a full `chezmoi apply` only after the script-aware diff is understood.
