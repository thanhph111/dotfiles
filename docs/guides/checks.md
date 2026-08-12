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

To inspect a different machine without changing the current config, use the generic [render another machine](../reference/resolvers.md#render-another-machine) example.

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
