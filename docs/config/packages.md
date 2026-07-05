# Packages

Package config has two parts:

```text
package settings decide what package managers run
manifest files list what those package managers install
```

## Package settings

Global package settings live in [`packages.yaml`](../../home/.chezmoidata/packages.yaml).

Profiles and machines can override those settings under their own `packages` block.

The resolved package config is built by [`resolved-packages.json`](../../home/.chezmoitemplates/resolved-packages.json):

```text
packages.yaml
-> selected profile packages
-> matching machine packages
```

Scripts use that helper instead of rebuilding the merge rule themselves.

That helper reads the active profile and machine from [`resolved-machine.json`](../../home/.chezmoitemplates/resolved-machine.json).

It is not an intermediate file that gets written to disk. It is a source template. Chezmoi renders it whenever another template includes it.

So if `packages.yaml`, `profiles.yaml`, or `machines.yaml` changes, the next template render sees the new resolved package config.

## Manifest locations

Profiles choose manifest names. The manifest files hold the package lists.

| Package area | Manifest directory                         |
| ------------ | ------------------------------------------ |
| APT          | [`home/.apt`](../../home/.apt)             |
| Homebrew     | [`home/.Brewfiles`](../../home/.Brewfiles) |
| Flatpak      | [`home/.flatpak`](../../home/.flatpak)     |
| GNOME        | [`home/.gnome`](../../home/.gnome)         |
| winget       | [`home/.winget`](../../home/.winget)       |
| scoop        | [`home/.scoop`](../../home/.scoop)         |

Example profile package block:

```yaml
profiles:
  linux-desktop:
    packages:
      linux:
        apt:
          enabled: true
          manifests:
            - linux-desktop
        brew:
          enabled: true
          manifests:
            - linux-desktop
```

Plain meaning: use `home/.apt/linux-desktop` for APT packages and `home/.Brewfiles/linux-desktop` for Homebrew packages.

## Remote access

Remote access is opt-in. A profile can install common server packages, but managed services stay stopped unless the resolved package data asks for them. UFW is fully owned by the resolved config: apply resets UFW, sets the defaults below, and then adds only the listed rules.

Useful Linux system settings:

```yaml
packages:
  linux:
    system:
      code_server:
        enabled: true
        command: code
        host: 127.0.0.1
        port: 9999
      ssh_server:
        enabled: true
        open_firewall: true
        disable_password_login: true
        trusted_user_ca_keys: /etc/ssh/ca.pub
      rdp:
        enabled: false
        open_firewall: false
      ufw:
        enabled: true
        default_incoming: deny
        default_outgoing: allow
        allow_tcp_ports: []
```

Plain meaning: start the SSH server, allow SSH through UFW, and manage SSH server hardening. RDP stays stopped. The VS Code web service stays bound to localhost; reach it with SSH forwarding, Tailscale, Cloudflare Access, or another named access layer. Cloudflare Tunnel normally needs outgoing access only, so it does not need an inbound UFW rule for a localhost service; use `ssh_server.enabled: true` with `open_firewall: false` for that shape. Manual UFW rules are removed on apply; put every wanted port in data.

## Homebrew

Homebrew is one Brewfile per profile.

On Linux and macOS, `~/.Brewfile` links to the first Homebrew manifest for the selected profile. That keeps commands like this pointed at the profile recipe:

```bash
brew bundle dump --file ~/.Brewfile
```

Prefer Homebrew core and cask packages when available. If a third-party package is needed, keep it fully qualified:

```ruby
brew "user/tap/formula"
cask "user/tap/app"
```

## Machine-only package overrides

Use machine package overrides for one real host.

Example:

```yaml
machines:
  rev-9:
    displayName: Rev-9
    profile: linux-desktop
    packages:
      linux:
        system:
          sudo_ssh_agent_auth:
            enabled: true
```

Plain meaning: Rev-9 changes only this package setting. It still gets the rest of `linux-desktop`.

Use a profile instead when many hosts should share the setting.

## Checking package resolution

Render the resolved package data:

```bash
chezmoi execute-template '{{ includeTemplate "resolved-packages.json" . }}' |
    python3 -m json.tool
```

To check a specific value for a simulated machine:

```bash
chezmoi execute-template \
    --override-data '{"chezmoi":{"os":"linux","hostname":"Rev-9"}}' \
    '{{ includeTemplate "resolved-packages.json" . }}' |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["linux"]["system"]["sudo_ssh_agent_auth"]["enabled"])'
```
