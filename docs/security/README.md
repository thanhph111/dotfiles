# Security Docs

Security docs cover trust-sensitive setup.

- [Shell startup trust](./shell-startup.md): `.env`, terminal startup commands, and chezmoi script `PATH`.
- [Sudo with SSH agent auth](./sudo-ssh-agent-auth.md): let a trusted Linux host use a forwarded SSH agent for sudo.

Keep security choices narrow. Prefer one machine or one profile over a global default unless every machine really should get the behavior.

These fields are trust choices:

- `vault`
- `gitName`
- `gitEmail`
- `gitSigningKey`
- `shared`
- `hasSudo`
- `client`
- `agent`
- `packages.*.system.sudo_ssh_agent_auth.enabled`
