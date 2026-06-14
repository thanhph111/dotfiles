# Profiles And Machines

Use this rule:

```text
profiles are reusable patterns
machines are named real hosts
local config is for private one-off setup
```

## Where The Data Lives

- Profile defaults and choices live in [`profiles.yaml`](../../home/.chezmoidata/profiles.yaml).
- Hostname matching and known machines live in [`machines.yaml`](../../home/.chezmoidata/machines.yaml).
- Local one-off answers live in this machine's chezmoi config.

## Use a profile when the pattern will repeat

Profiles live in [`profiles.yaml`](../../home/.chezmoidata/profiles.yaml).

Make or change a profile when the same setup should be useful later:

- a normal Linux desktop
- a headless Linux development VM
- a personal macOS laptop
- a small macOS agent machine

Example:

```yaml
profiles:
  linux-vm-dev:
    defaults:
      headless: true
    packages:
      linux:
        system:
          sudo_ssh_agent_auth:
            enabled: true
```

Plain meaning: every machine with the `linux-vm-dev` profile gets this behavior.

`profile_defaults` chooses the normal profile for each operating system. `profile_choices` controls what setup can offer for an unknown interactive machine.

## Use a machine entry when the host is special

Machines live in [`machines.yaml`](../../home/.chezmoidata/machines.yaml).

Add or change a machine when one real host needs a stable exception:

- a hostname should auto-select a profile
- one host needs a package setting that its profile does not need
- one host has per-user rules
- one host should keep the same identity every time it is reinstalled

Example:

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

Plain meaning: Rev-9 stays a Linux desktop, but only Rev-9 gets sudo SSH agent auth.

Machine entries can be matched by exact hostname or hostname prefix. A machine entry can choose a profile and still override that profile.

## Use local config for one-off machines

Unknown machines can answer setup prompts during `chezmoi init`. Those answers are saved in the local chezmoi config.

Use this for a temporary VM, a borrowed machine, or anything that should not become repo history.

Example local config:

```toml
[data]
codename = "Grid"
profile = "linux-minimal"
setupMode = "custom"

[data.local]
hasSudo = true
```

Plain meaning: only this local machine gets this answer.

Use this when committing the machine would only add noise to the repo.

## Per-user rules

Use per-user rules when a shared host has different trust levels for different accounts.

Example:

```yaml
machines:
  sonny:
    codename: Sonny
    profile: linux-minimal
    users:
      thanhph111:
        shared: false
        hasSudo: true
        gitName: Thanh Phan
        gitEmail: thanhph111@gmail.com
```

Plain meaning: the `linux-minimal` profile stays safe and shared by default, but the `thanhph111` account gets sudo and Git identity on Sonny.
