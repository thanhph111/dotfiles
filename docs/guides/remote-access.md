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
