# Facts

Facts describe this machine or this user.

They answer questions like:

- What profile should this host use?
- Is this machine headless?
- Is this a shared account?
- Can scripts use sudo?
- Which Git identity should this user use?
- Which 1Password vault should secret templates read?

## Current facts

[`resolved-machine.json`](../../home/.chezmoitemplates/resolved-machine.json) returns these keys:

| Fact            | Meaning                                             |
| --------------- | --------------------------------------------------- |
| `machineKey`    | The matched key in `machines.yaml`, if any.         |
| `displayName`   | Human-friendly machine name.                        |
| `profile`       | Reusable shape selected for this machine.           |
| `personal`      | Whether this is a personal machine.                 |
| `vault`         | 1Password vault used by secret templates.           |
| `headless`      | Whether desktop and GUI behavior should stay off.   |
| `client`        | Whether this machine should receive client secrets. |
| `agent`         | Whether this machine runs agent-style app setup.    |
| `shared`        | Whether this account is shared or low-trust.        |
| `hasSudo`       | Whether scripts may try sudo-gated changes.         |
| `gitName`       | Git author name.                                    |
| `gitEmail`      | Git author email.                                   |
| `gitSigningKey` | SSH public key used for Git signing.                |

## Fact owners

| Owner                | Use it for                              |
| -------------------- | --------------------------------------- |
| `machines.defaults`  | Broad machine and user fact defaults.   |
| `machines.entries`   | Known hosts and per-user facts.         |
| `profiles.entries`   | Reusable fact defaults for one profile. |
| Local chezmoi config | Private facts for one unknown machine.  |

Facts should not directly say what to install or start. Put that under features.
