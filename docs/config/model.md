# Config Model

This config has one job: decide what this machine is, then let templates use that answer.

Use this mental model:

```text
broad defaults -> reusable profile -> named machine -> local or user override
```

Plain meaning: start with the broad answer, then let the more specific answer replace it.

There are two paths, because identity and packages are different kinds of choices.

## Owners

| Owner                                                                           | What it owns                                                               |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [`packages.yaml`](../../home/.chezmoidata/packages.yaml)                        | Default package settings for each operating system.                        |
| [`profiles.yaml`](../../home/.chezmoidata/profiles.yaml)                        | Reusable machine shapes, profile defaults, and profile package choices.    |
| [`machines.yaml`](../../home/.chezmoidata/machines.yaml)                        | Known hostnames, named machines, host-only exceptions, and per-user rules. |
| Local chezmoi config                                                            | Private answers for one unknown or ad-hoc machine.                         |
| [`resolved-machine.json`](../../home/.chezmoitemplates/resolved-machine.json)   | Shared resolver for identity and trust.                                    |
| [`resolved-packages.json`](../../home/.chezmoitemplates/resolved-packages.json) | Shared resolver for package settings.                                      |
| Scripts and templates                                                           | Apply the resolved answer. They should not invent ownership rules.         |

## Identity And Trust Flow

Identity and trust means fields like `displayName`, `profile`, `vault`, `hasSudo`, `shared`, and Git identity.

Setup starts in [`home/.chezmoi.toml.tmpl`](../../home/.chezmoi.toml.tmpl). Normal templates read the final identity and trust values from [`resolved-machine.json`](../../home/.chezmoitemplates/resolved-machine.json).

For a known machine, the flow is:

```text
global machine defaults
-> matched machine chooses a profile
-> selected profile defaults
-> matched machine overrides
-> matched user overrides
```

The matched machine is read twice on purpose. First it can choose the profile. Then it can override that profile.

For an unknown interactive machine, the flow is:

```text
global machine defaults
-> operating-system default profile
-> local display name/profile prompts
-> selected profile defaults
-> local headless/setup prompts
```

Those local prompt answers are saved under `[data.local]` in the local chezmoi config. Normal `chezmoi apply` does not ask again.

For an unknown non-interactive Linux machine with no local profile, setup falls back to `linux-minimal`.

## Package Flow

Package settings are resolved by [`resolved-packages.json`](../../home/.chezmoitemplates/resolved-packages.json).

The package flow is:

```text
packages.yaml
-> selected profile packages
-> matched machine packages
```

There is no user package layer today.

The helper uses `resolved-machine.json` to find the active profile and machine. Both helpers are source templates, not cache files. When `packages.yaml`, `profiles.yaml`, or `machines.yaml` changes, templates read the new resolved data the next time chezmoi renders them.

Scripts read package settings like this:

```gotemplate
{{- $packages := includeTemplate "resolved-packages.json" . | fromJson -}}
{{- $linux := get $packages "linux" | default dict -}}
{{- $system := get $linux "system" | default dict -}}
```

That keeps the package merge rule in one place.

## Where To Put A Change

Use the narrowest owner that still matches the real pattern.

| Change                                               | Put it here                   |
| ---------------------------------------------------- | ----------------------------- |
| Every machine on one operating system should get it. | `packages.yaml`               |
| A reusable kind of machine should get it.            | `profiles.yaml`               |
| One known host should get it.                        | `machines.yaml`               |
| One private ad-hoc host should get it.               | Local chezmoi config          |
| One user on a shared known host should get it.       | `machines.yaml` under `users` |

## More Detail

- [Profiles and machines](./profiles-and-machines.md) explains when to use a profile, a machine entry, local config, or per-user rules.
- [Packages](./packages.md) explains package settings, manifests, and the shared package resolver.
- [Local config](./local-config.md) explains setup prompts and prompt-once behavior.
- [Security](../security/README.md) explains trust-sensitive settings.

## Checks

After changing config data or templates, run:

```bash
mise run lint
```

For package resolution changes, also render the helper:

```bash
chezmoi execute-template '{{ includeTemplate "resolved-packages.json" . }}' |
    python3 -m json.tool
```
