# Profiles and machines

Profiles are reusable machine shapes.

Machines are named real hosts.

Use a profile when the same setup should make sense on more than one machine. Use a machine entry when one real host needs stable detection or a narrow exception.

## Profiles

Profiles live in [`profiles.yaml`](../../home/.chezmoidata/profiles.yaml).

The profile catalog has three parts:

- `profiles.defaults`: default profile by operating system.
- `profiles.choices`: setup choices shown during `chezmoi init`.
- `profiles.entries`: reusable machine shapes.

A profile entry can set:

- fact defaults under `defaults`
- feature choices under `features`

Example:

```yaml
profiles:
  entries:
    <profile-name>:
      defaults:
        headless: true
      features:
        linux:
          install:
            homebrew:
              enabled: true
              manifests:
                - <manifest-name>
          security:
            sudo_ssh_agent_auth:
              enabled: true
```

Plain meaning: every machine using `<profile-name>` is headless, uses `<manifest-name>`, and enables sudo SSH agent auth.

## Profile choices

`profiles.defaults` chooses the default profile for each operating system.

`profiles.choices` controls what `chezmoi init` can offer for an unknown interactive machine.

Keep this list short. If a profile is too specific to explain in one line, it is probably a machine override instead.

## Machines

Machines live in [`machines.yaml`](../../home/.chezmoidata/machines.yaml).

The machine catalog has three parts:

- `machines.defaults`: broad fact defaults.
- `machines.matches`: hostname lookup tables.
- `machines.entries`: known hosts.

The global match registry maps hostnames to machine keys:

```yaml
machines:
  matches:
    hostnames:
      <hostname>: <machine-key>
    hostnamePrefixes:
      <hostname-prefix>: <machine-key>
```

Exact hostname keys cannot be duplicated because they are YAML map keys. Prefix keys work the same way.

A machine entry owns profile, host-only facts, and host-only features:

```yaml
machines:
  entries:
    <machine-key>:
      displayName: <display-name>
      profile: <profile-name>
      features:
        linux:
          services:
            ssh_server:
              enabled: true
```

Plain meaning: the matched machine uses a reusable profile, then enables one host-only service.

Exact hostname matches win over prefix matches. If more than one prefix matches, the longest prefix wins.

## Per-user facts

Use `users` when a shared known host has different facts for different accounts:

```yaml
machines:
  entries:
    <machine-key>:
      displayName: <display-name>
      profile: <profile-name>
      users:
        <username>:
          shared: false
          hasSudo: true
```

Per-user entries hold facts only. Features are machine-wide today.
