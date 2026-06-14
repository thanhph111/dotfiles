# Sudo With SSH Agent Auth

This setup lets a trusted Linux machine accept sudo authentication from a forwarded SSH agent.

It is still authentication. Sudo asks the local agent to prove it holds a matching private key. The private key does not leave the local machine.

This is enabled only when the resolved package config turns on `packages.linux.system.sudo_ssh_agent_auth.enabled`, and only for non-shared Linux users with `hasSudo: true`.

A profile can turn it on for many machines. A machine entry can turn it on for one named machine. See [packages](../config/packages.md) for the package resolver.

## What dotfiles manages

When enabled, chezmoi:

- installs `libpam-ssh-agent-auth` on apt-based Linux systems
- creates `/etc/security/sudo_authorized_keys`
- preserves `SSH_AUTH_SOCK` for sudo in `/etc/sudoers.d/ssh-auth-sock`
- adds a managed `pam_ssh_agent_auth` block to `/etc/pam.d/sudo`

It does not add any public keys.

## Manual key step

Choose the public key you want to allow for sudo. From the client machine, list keys currently available in your agent:

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

## Client SSH config

Keep agent forwarding host-specific. Add a file under `~/.ssh/config.d/` on the client:

```sshconfig
Host trusted-server
    HostName example.com
    User thanhph111
    ForwardAgent yes
```

Do not enable `ForwardAgent yes` under `Host *`.

## Test

Keep one root-capable session open while testing in another terminal.

```bash
ssh trusted-server
sudo -k
sudo -v
```

If the agent key matches the remote sudo key file, sudo should not ask for a password. If it does ask, password sudo should still work because the PAM rule is `sufficient`, not required.

## Rollback

Remove the user key file to disable access for that user.

To remove the managed PAM and sudoers changes, turn off `packages.linux.system.sudo_ssh_agent_auth.enabled` in the same place that enabled it, then run `chezmoi apply` again. If the setting was enabled in a machine entry, turn it off or remove it there. If it was enabled in a profile, turn it off there.

Do this cleanup while the user still has `hasSudo: true` and `shared: false`, because the cleanup script only runs for that kind of user. Dotfiles leaves manually added key files in place, but they are inactive without the PAM rule.
