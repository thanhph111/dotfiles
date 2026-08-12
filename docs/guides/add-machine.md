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
      <hostname>: <machine-key>

  entries:
    <machine-key>:
      displayName: <display-name>
      profile: <profile-name>
```

Use a known machine when hostname detection matters or when the host has a stable override.

## New profile

Create a profile when the same shape will repeat on more than one machine:

```yaml
profiles:
  entries:
    <profile-name>:
      defaults:
        headless: true
      features:
        linux:
          install:
            apt:
              enabled: true
              manifests:
                - <manifest-name>
            homebrew:
              enabled: true
              manifests:
                - <manifest-name>
```

Then add matching manifests:

```text
home/.apt/<manifest-name>
home/.Brewfiles/<manifest-name>
```

## Host-only feature override

Use this when one named host differs from its profile:

```yaml
machines:
  entries:
    <machine-key>:
      features:
        linux:
          security:
            sudo_ssh_agent_auth:
              enabled: true
```

Plain meaning: the matched machine enables sudo SSH agent auth without changing every machine that uses its profile.

## Per-user fact override

Use this when one user on a shared machine needs different facts:

```yaml
machines:
  entries:
    <machine-key>:
      users:
        <username>:
          shared: false
          hasSudo: true
```

Per-user entries are for facts only. Features are machine-wide today.
