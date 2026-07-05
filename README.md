# Dotfiles

This repo sets up my machines with [chezmoi](https://www.chezmoi.io/).

It manages shell files, app config, package lists, desktop settings, services, and a few system settings across macOS, Linux, and Windows.

## Start here

- Set up a machine: [set up a machine](./docs/setup.md).
- Understand how config is resolved: [config model](./docs/model.md).
- Add a machine or profile: [add a machine](./docs/guides/add-machine.md).
- Change packages, apps, or settings lists: [change manifests](./docs/guides/change-manifests.md).
- Work on SSH, RDP, code-server, UFW, or sudo: [remote access](./docs/guides/remote-access.md).
- Review shell startup trust: [shell startup](./docs/guides/shell-startup.md).
- Run checks before applying: [checks](./docs/guides/checks.md).

## The model

The repo keeps two ideas separate:

- **Facts** say what this machine or user is.
- **Features** say what dotfiles should install, configure, start, stop, or manage.

Scripts do not read raw profiles or machines directly. They read the final answers from:

- [`resolved-machine.json`](./home/.chezmoitemplates/resolved-machine.json)
- [`resolved-features.json`](./home/.chezmoitemplates/resolved-features.json)

The source files are:

- [`features.yaml`](./home/.chezmoidata/features.yaml): default features for each operating system
- [`profiles.yaml`](./home/.chezmoidata/profiles.yaml): profile defaults, setup choices, and reusable machine shapes
- [`machines.yaml`](./home/.chezmoidata/machines.yaml): machine defaults, hostname matches, and known machine entries

Local chezmoi config is for private facts on unknown machines. It does not override features. Features come from defaults, then the selected profile, then the matched machine.

## Known machines

| Machine | OS      | Profile           |
| ------- | ------- | ----------------- |
| Arwen   | Windows | `windows-desktop` |
| Rev-9   | Linux   | `linux-desktop`   |
| Sonny   | Linux   | `linux-minimal`   |
| TARS    | macOS   | `darwin-personal` |

Known machines are matched by hostname. Unknown machines can choose a profile during `chezmoi init` without adding a new file or committing a host entry.

## Common commands

```bash
chezmoi diff               # Preview regular file changes
chezmoi diff --exclude=none # Preview scripts too
chezmoi apply              # Apply changes
chezmoi update             # Pull and apply this repo
chezmoi edit ~/.zshrc      # Edit a managed file
chezmoi add ~/.config/app  # Add a new file to management
```
