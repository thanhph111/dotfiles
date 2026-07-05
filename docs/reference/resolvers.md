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

## Render Rev-9

```bash
chezmoi execute-template \
    --override-data '{"chezmoi":{"os":"linux","hostname":"Rev-9","username":"thanhph111","homeDir":"/home/thanhph111"}}' \
    '{{ includeTemplate "resolved-features.json" . }}' |
    jq -S '.linux | {install, security, network, services}'
```

Rev-9 should show:

- `services.ssh_server.enabled: true`
- `services.xrdp.enabled: true`
- `services.code_server.enabled: true`
- `network.ufw.rules.ssh.enabled: false`
- `network.ufw.rules.xrdp.enabled: false`
