# Features

Features are things dotfiles manages.

A feature can install packages, start a service, change a system setting, write config, or manage a firewall rule.

Default feature settings live in [`features.yaml`](../../home/.chezmoidata/features.yaml). Profiles and machines can override them under their own `features` block.

## Feature groups

| Group      | Meaning                                              |
| ---------- | ---------------------------------------------------- |
| `install`  | Package managers and their manifest choices.         |
| `tools`    | User-level tool setup, such as mise.                 |
| `desktop`  | Desktop settings, GNOME, avatars, and GUI behavior.  |
| `system`   | Operating system settings.                           |
| `security` | Trust-sensitive system setup.                        |
| `network`  | Firewall and network policy.                         |
| `services` | Services that dotfiles starts, stops, or configures. |
| `apps`     | App-specific setup that is not only package install. |

## Linux

Linux features live under `features.linux`.

Important groups:

- `install.apt`: APT repositories and package manifests.
- `install.homebrew`: Linuxbrew package manifests and font links.
- `install.flatpak`: user Flatpak apps from Flathub.
- `desktop.gnome`: GNOME extensions and settings.
- `security.sudoers_disable_admin_flag`: sudoers cleanup.
- `security.sudo_ssh_agent_auth`: sudo through a trusted forwarded SSH agent.
- `network.ufw`: UFW firewall policy.
- `services.ssh_server`: OpenSSH server config.
- `services.xrdp`: RDP service.
- `services.code_server`: user code-server service.

Services do not open firewall ports by themselves. UFW owns firewall policy in one place:

```yaml
network:
  ufw:
    rules:
      ssh:
        enabled: true
        protocol: tcp
        port: 22
```

## macOS

macOS features live under `features.darwin`.

Important groups:

- `install.homebrew`: Homebrew manifests.
- `tools.mise`: user tools managed by mise.
- `system.defaults`: macOS defaults.
- `apps.openclaw`: OpenClaw setup for agent-style machines.

## Windows

Windows features live under `features.windows`.

Important groups:

- `install.winget`: winget manifests.
- `install.scoop`: scoop manifests.
- `tools.mise`: user tools managed by mise.
- `system.settings`: Windows settings scripts.

## Add a feature

Only add a feature when a script or template uses it.

Good feature:

```yaml
services:
  ssh_server:
    enabled: true
```

Not a useful feature yet:

```yaml
future_cloud_mode:
  enabled: true
```

Wait until there is real code that reads it.
