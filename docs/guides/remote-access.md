# Remote access

This guide covers the pieces that affect remote login or remote control:

- SSH server
- UFW firewall rules
- xrdp
- code-server
- SSH agent forwarding
- sudo with SSH agent auth

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

## Rev-9 shape

Rev-9 enables SSH server, xrdp, and code-server:

```yaml
machines:
  entries:
    rev-9:
      features:
        linux:
          services:
            ssh_server:
              enabled: true
            xrdp:
              enabled: true
            code_server:
              enabled: true
              host: 127.0.0.1
              port: 9999
```

Rev-9 leaves UFW inbound SSH and xrdp rules disabled. That is right when access goes through a tunnel or private path that does not need a public inbound firewall opening.

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

Default bind:

```yaml
code_server:
  enabled: false
  command: code
  host: 127.0.0.1
  port: 9999
```

Binding to `127.0.0.1` means the service listens only on the machine itself. Reach it through a tunnel or local proxy.

## SSH agent forwarding

Agent forwarding lets a remote machine ask your local SSH agent to prove that it holds a key. The private key stays on the local machine.

Keep forwarding host-specific:

```sshconfig
Host trusted-server
    HostName example.com
    User thanhph111
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
key='ssh-ed25519 AAAA... comment'
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
ssh trusted-server
sudo -k
sudo -v
```

If the agent key matches the remote sudo key file, sudo should not ask for a password. If it does ask, password sudo should still work because the PAM rule is `sufficient`, not required.
