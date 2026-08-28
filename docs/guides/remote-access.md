# Remote access

This guide explains the shared rules for remotely reachable services, UFW firewall policy, SSH agent forwarding, and sudo with SSH agent auth.

## Services and firewall are separate

Services start daemons. UFW opens ports.

Turning on SSH server does not open port 22:

```yaml
features:
  linux:
    services:
      ssh_server:
        enabled: true
```

Opening port 22 belongs to UFW:

```yaml
features:
  linux:
    network:
      ufw:
        rules:
          ssh:
            enabled: true
```

This keeps the firewall policy visible in one place.

## Samba

When `services.samba.enabled` is true, package setup installs Samba and system setup creates the configured share. The share is writable only through the current Linux user's Samba login. Guest access, SMB1, and old NetBIOS discovery are disabled.

For example, this machine override enables Samba without changing its separately owned UFW rule:

```yaml
machines:
  entries:
    <machine-key>:
      features:
        linux:
          services:
            samba:
              enabled: true
```

The resolved firewall value still comes from the operating-system defaults and profile. If the Samba rule remains disabled, use that shape only when a separate private network path can reach the host.

Create the Samba password once after the first apply:

```bash
sudo smbpasswd -a "$USER"
```

The password is deliberately not stored in this repo.

Network routing and client enrollment are outside this repo. Enabling Samba does not open TCP port 445; UFW owns that choice separately. Use a private network path and do not expose SMB to the public internet.

After a client can reach the host, connect to `smb://<host>/<share-name>`.

## UFW lockout guard

The UFW script refuses to reset UFW during a direct SSH session when no enabled rule allows TCP port 22.

It allows local proxy sessions because UFW does not need a public inbound SSH rule for that path. That includes tunnels that reach sshd through `127.0.0.1` and tunnels that reach sshd through the machine's own LAN IP.

Use this override only when you already have another way back in:

```bash
DOTFILES_ALLOW_UFW_LOCKOUT=1 chezmoi apply
```

## code-server

The code-server feature controls whether the user service is enabled or disabled.

The support unit file can still render on non-shared Linux machines. That is okay: the script decides whether the service is active.

Example loopback-only bind:

```yaml
code_server:
  enabled: false
  command: code
  host: 127.0.0.1
  port: 9999
```

Binding to `127.0.0.1` means the service listens only on the machine itself. Reach it through a tunnel or local proxy.

## Codex Remote

The `codex_remote_control` feature expects the official Codex CLI installed by the selected Linux Homebrew manifest and enables `codex-remote-control.service`. The service runs `codex remote-control` in the foreground so systemd owns its complete lifecycle. It does not run the CLI's separate background-daemon command.

The service uses Codex's normal `~/.codex` state. Its login, configuration, skills, and saved chats are therefore the same ones used by the ordinary CLI on that machine. Never commit or expose `~/.codex/auth.json`; it contains login tokens.

The service makes outbound connections and does not add a listening port or a UFW rule. Do not add a public app-server hostname for it.

Direct phone access to a Linux host is experimental. Current [OpenAI Remote documentation](https://learn.chatgpt.com/docs/remote) officially lists Mac and Windows hosts. Treat Rev-9 appearing in the mobile app as the acceptance test for the installed CLI and mobile app versions.

After the first apply, sign in from the host terminal. Device authentication works over SSH:

```bash
codex login --device-auth
codex login status
```

Start the enabled service:

```bash
systemctl --user start codex-remote-control.service
```

The foreground service registers Rev-9 with the signed-in account. Open ChatGPT mobile's Remote screen and select Rev-9. Do not run `codex remote-control pair` for this service: that command talks to the CLI-managed background daemon created by `codex remote-control start`, not the foreground process owned by systemd.

If the app does not show Rev-9 or rejects the Linux host, use a supported Mac or Windows Remote host and connect that desktop app to this machine over SSH.

Check the durable service with:

```bash
systemctl --user status codex-remote-control.service --no-pager
journalctl --user --unit=codex-remote-control.service --lines=100 --no-pager
```

The apply script enables systemd user lingering when the feature is on. Lingering starts the user service during boot without waiting for a desktop login. A cold-reboot test is still required before relying on the host remotely.

Review and apply Codex upgrades deliberately. Homebrew owns the CLI installation and update:

```bash
brew upgrade --cask codex
systemctl --user restart codex-remote-control.service
codex --version
systemctl --user is-active codex-remote-control.service
```

## SSH agent forwarding

Agent forwarding lets a remote machine ask your local SSH agent to prove that it holds a key. The private key stays on the local machine.

Keep forwarding host-specific:

```sshconfig
Host <ssh-alias>
    HostName <hostname>
    User <username>
    ForwardAgent yes
```

Do not enable `ForwardAgent yes` under `Host *`.

## Sudo with SSH agent auth

The `sudo_ssh_agent_auth` feature lets a trusted Linux host accept sudo authentication from a forwarded SSH agent.

It is enabled only when the resolved feature config turns on:

```text
features.linux.security.sudo_ssh_agent_auth.enabled
```

It also requires a non-shared Linux user with `hasSudo: true`.

When enabled, dotfiles:

- installs `libpam-ssh-agent-auth` on apt-based Linux systems
- creates `/etc/security/sudo_authorized_keys`
- preserves `SSH_AUTH_SOCK` for sudo
- adds a managed `pam_ssh_agent_auth` block to `/etc/pam.d/sudo`

Dotfiles does not add public keys automatically. That key is a manual trust choice.

From the client machine, list keys currently available in the agent:

```bash
ssh-add -L
```

On the remote machine, add only the chosen public key:

```bash
key='<public-key>'
printf '%s\n' "$key" | sudo tee /etc/security/sudo_authorized_keys/"$USER" >/dev/null
sudo chown root:root /etc/security/sudo_authorized_keys/"$USER"
sudo chmod 0644 /etc/security/sudo_authorized_keys/"$USER"
```

To remove access later:

```bash
sudo rm -f /etc/security/sudo_authorized_keys/"$USER"
```

Test from another terminal while keeping one root-capable session open:

```bash
ssh_alias='<ssh-alias>'
ssh "$ssh_alias"
sudo -k
sudo -v
```

If the agent key matches the remote sudo key file, sudo should not ask for a password. If it does ask, password sudo should still work because the PAM rule is `sufficient`, not required.
