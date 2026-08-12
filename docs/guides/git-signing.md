# Git signing

Git commits and tags are signed with SSH.

SSH signing means Git asks your SSH agent to prove that a key signed the commit. The private key stays inside the agent, such as Secretive or 1Password.

## Source of truth

The signing public key comes from `gitSigningKey` in [`machines.yaml`](../../home/.chezmoidata/machines.yaml).

That value is a fact because it describes the user identity for this machine. It is not a feature.

## GitHub setup

Add the public key to GitHub as an SSH signing key.

Do this once per signing key.

## Remote machines

On remote machines, use the same signing key through SSH agent forwarding only for hosts you trust.

Agent forwarding lets the remote machine ask your local agent to sign. The key still stays on your local machine, but the remote host can ask the agent to use it while the connection is open.

Keep forwarding host-specific. For the SSH config example and the wider trust rules, see [SSH agent forwarding](./remote-access.md#ssh-agent-forwarding).
