# Config model

This repo has one main rule:

```text
facts describe the machine
features describe what dotfiles does
```

A fact is a piece of identity, such as `displayName`, `profile`, `headless`, `shared`, `hasSudo`, or Git identity.

A feature is behavior managed by this repo, such as installing APT packages, applying GNOME settings, managing UFW, enabling SSH server, or setting up code-server.

## Owners

- [`features.yaml`](../home/.chezmoidata/features.yaml) owns default features for each operating system.
- [`profiles.yaml`](../home/.chezmoidata/profiles.yaml) owns profile defaults, setup choices, and reusable profile entries.
- [`machines.yaml`](../home/.chezmoidata/machines.yaml) owns machine defaults, hostname matches, and known machine entries.
- Local chezmoi config owns private facts for one unknown machine.
- [`resolved-machine.json`](../home/.chezmoitemplates/resolved-machine.json) returns final facts for scripts and templates.
- [`resolved-features.json`](../home/.chezmoitemplates/resolved-features.json) returns final features for scripts and templates.
- Manifest files own concrete lists of packages, apps, extensions, and settings.
- [`agents.yaml`](../home/.chezmoidata/agents.yaml) owns the Codex and Claude Code preferences that are merged into their config files.
- Scripts and templates apply the final facts and features.

## Catalog words

The YAML catalogs use the same words in each file:

- `defaults`: broad starting values.
- `choices`: setup options shown to a user.
- `matches`: lookup tables that point to entries.
- `entries`: named records keyed by a machine or profile name.

In documentation examples, text inside `<...>` is a placeholder that must be replaced. Catalog keys such as `entries`, feature names such as `ssh_server`, and literal settings such as `enabled: true` are not placeholders.

Machine and profile facts use existing lower camel case names such as `displayName`, `hasSudo`, and `gitSigningKey`.

Feature option names keep the existing snake case shape, such as `ssh_server` and `default_incoming`, because scripts already read those keys.

## Fact flow

For a known machine:

```text
machine defaults
-> operating-system defaults
-> hostname match
-> selected profile defaults
-> machine facts
-> per-user machine facts
```

For an unknown machine:

```text
machine defaults
-> operating-system default profile
-> local display name and profile
-> selected profile defaults
-> local setup answers
```

Local answers do not override known machines. That keeps stale local config from changing a known host after its hostname already matched.

## Feature flow

Features are resolved in this order:

```text
feature defaults
-> selected profile features
-> matched machine features
```

Later values win.

There is no local feature override layer today. Local config is for private facts about an unknown machine, not for long-term behavior.

## Script rule

Scripts and templates should read resolved data:

```gotemplate
{{- $machine := includeTemplate "resolved-machine.json" . | fromJson -}}
{{- $features := includeTemplate "resolved-features.json" . | fromJson -}}
```

They should not rebuild profile, machine, or merge rules.

## Where to put a change

Use the narrowest owner that matches the real pattern.

| Change                                           | Put it here                |
| ------------------------------------------------ | -------------------------- |
| Every machine on one operating system needs it.  | `features.yaml`            |
| A reusable kind of machine needs it.             | `profiles.entries`         |
| One known host needs it.                         | `machines.entries`         |
| One unknown host needs a private fact.           | Local chezmoi config       |
| One user on a shared known host needs a fact.    | `machines.entries.*.users` |
| A package, app, extension, or settings item list | A manifest file            |

## Keep the boundary clear

Good fact:

```yaml
hasSudo: true
```

Good feature:

```yaml
features:
  linux:
    services:
      ssh_server:
        enabled: true
```

Avoid mixing them:

```yaml
hasSshServer: true
```

That should be a feature, not a fact.
