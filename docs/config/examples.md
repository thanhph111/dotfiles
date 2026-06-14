# Config Examples

## Add an ad-hoc machine

During `chezmoi init`, pick the closest profile and use local setup answers.

No repo change is needed unless the machine should become known.

## Add a known machine

Add hostname mapping and a machine entry:

```yaml
hostname_machines:
  grid: grid

machines:
  grid:
    codename: Grid
    profile: darwin-personal
```

## Add one package to a profile

If the package belongs to an existing profile, edit that profile's manifest.

Example for Linux desktop APT packages:

```bash
chezmoi edit ~/.apt/linux-desktop
```

Then add the package name to `home/.apt/linux-desktop`.

## Add a new profile

Add the profile in [`profiles.yaml`](../../home/.chezmoidata/profiles.yaml):

```yaml
profiles:
  linux-build:
    defaults:
      headless: true
    packages:
      linux:
        apt:
          enabled: true
          manifests:
            - linux-build
        brew:
          enabled: true
          manifests:
            - linux-build
```

Then add matching manifest files:

```text
home/.apt/linux-build
home/.Brewfiles/linux-build
```

## Add a machine-only package override

Use this when one named host differs from its profile.

```yaml
machines:
  rev-9:
    codename: Rev-9
    profile: linux-desktop
    packages:
      linux:
        system:
          sudo_ssh_agent_auth:
            enabled: true
```

This is how Rev-9 enables sudo SSH agent auth without changing every `linux-desktop` machine.

## Give one user sudo on a shared machine

Use a per-user rule:

```yaml
machines:
  sonny:
    codename: Sonny
    profile: linux-minimal
    users:
      thanhph111:
        shared: false
        hasSudo: true
```

## Check resolved package data

Render machine data for the current machine:

```bash
chezmoi execute-template '{{ includeTemplate "resolved-machine.json" . }}' |
    python3 -m json.tool
```

Render package data for the current machine:

```bash
chezmoi execute-template '{{ includeTemplate "resolved-packages.json" . }}' |
    python3 -m json.tool
```

Check Rev-9's sudo SSH agent setting:

```bash
chezmoi execute-template \
    --override-data '{"codename":"Rev-9","profile":"linux-desktop","chezmoi":{"os":"linux"}}' \
    '{{ includeTemplate "resolved-packages.json" . }}' |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["linux"]["system"]["sudo_ssh_agent_auth"]["enabled"])'
```

## Check before applying

Preview changes:

```bash
chezmoi diff
```

Render one managed file:

```bash
chezmoi cat ~/.gitconfig
```

Run repo checks:

```bash
mise run lint
```
