# Add a machine

Start with the smallest change that will stay true later.

## One-off machine

During `chezmoi init`, pick the closest profile and save private local answers.

No repo change is needed.

## Known machine

Add one match entry and one machine entry:

```yaml
machines:
  matches:
    hostnames:
      grid: grid

  entries:
    grid:
      displayName: Grid
      profile: darwin-personal
```

Use a known machine when hostname detection matters or when the host has a stable override.

## New profile

Create a profile when the same shape will repeat on more than one machine:

```yaml
profiles:
  entries:
    linux-build:
      defaults:
        headless: true
      features:
        linux:
          install:
            apt:
              enabled: true
              manifests:
                - linux-build
            homebrew:
              enabled: true
              manifests:
                - linux-build
```

Then add matching manifests:

```text
home/.apt/linux-build
home/.Brewfiles/linux-build
```

## Host-only feature override

Use this when one named host differs from its profile:

```yaml
machines:
  entries:
    rev-9:
      features:
        linux:
          security:
            sudo_ssh_agent_auth:
              enabled: true
```

Plain meaning: Rev-9 enables sudo SSH agent auth without changing every Linux desktop.

## Per-user fact override

Use this when one user on a shared machine needs different facts:

```yaml
machines:
  entries:
    sonny:
      users:
        thanhph111:
          shared: false
          hasSudo: true
```

Per-user entries are for facts only. Features are machine-wide today.
