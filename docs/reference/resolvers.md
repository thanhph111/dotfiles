# Resolvers

Resolvers are chezmoi templates that return final JSON.

They are source templates, not cache files. Chezmoi renders them whenever another template includes them.

## Current resolvers

- [`resolved-machine.json`](../../home/.chezmoitemplates/resolved-machine.json): final facts.
- [`resolved-features.json`](../../home/.chezmoitemplates/resolved-features.json): final feature settings.

## Script rule

Scripts should read resolvers instead of raw data files.

Good:

```gotemplate
{{- $machine := includeTemplate "resolved-machine.json" . | fromJson -}}
{{- $features := includeTemplate "resolved-features.json" . | fromJson -}}
```

Bad:

```gotemplate
{{- $profile := get (get .profiles "entries") .profile -}}
```

The bad shape rebuilds merge rules in each script.

`resolved-features.json` always returns `linux`, `darwin`, and `windows` blocks. Scripts still need to check `.chezmoi.os` before doing OS-specific work.

## Render current machine

```bash
chezmoi execute-template '{{ includeTemplate "resolved-machine.json" . }}' |
    jq -S .
```

```bash
chezmoi execute-template '{{ includeTemplate "resolved-features.json" . }}' |
    jq -S .
```

## Render another machine

Use quoted placeholders to inspect a machine without changing the current chezmoi config:

```bash
chezmoi execute-template \
    --override-data '{"chezmoi":{"os":"<operating-system>","hostname":"<hostname>","username":"<username>","homeDir":"<home-directory>"}}' \
    '{{ includeTemplate "resolved-features.json" . }}' |
    jq -S .
```

Use `linux`, `darwin`, or `windows` for `<operating-system>`.
