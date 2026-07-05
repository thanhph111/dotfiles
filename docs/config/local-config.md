# Local Chezmoi Config

Local chezmoi config stores answers for the current machine only.

It should store choices, not resolved repo data.

Good:

```toml
[data]
displayName = "Grid"
profile = "linux-minimal"
setupMode = "custom"

[data.local]
headless = true
hasSudo = true
```

Bad:

```toml
[data]
packagesResolved = { ... }
```

Why bad? Resolved package data would become stale when the repo changes.

## Where it comes from

[`home/.chezmoi.toml.tmpl`](../../home/.chezmoi.toml.tmpl) creates local config during `chezmoi init`.

Known machines are found by hostname and do not need profile prompts.

Unknown machines ask for:

- display name
- profile
- headless
- local setup mode

The local setup modes are:

- `profile`: use the selected profile as-is.
- `custom`: ask extra local identity and trust questions.

Local answers are written under `[data.local]`. `custom` can ask for:

- `personal`
- `vault`
- `client`
- `agent`
- `shared`
- `hasSudo`
- `gitName`
- `gitEmail`
- `gitSigningKey`

## Prompt once behavior

Setup uses `promptStringOnce`, `promptChoiceOnce`, and `promptBoolOnce`.

Those are chezmoi prompt helpers. They ask once, then save the answer in local config. Normal `chezmoi apply` does not ask again.

It can ask again if:

- the local config is deleted
- a new prompt key is added
- setup is forced to prompt again
- the local config does not contain that value

## What belongs here

Use local config for private one-off choices:

- a temporary VM profile choice
- a one-machine Git identity
- a one-machine `hasSudo` value under `[data.local]`
- a local `headless` answer under `[data.local]`

Do not use local config for reusable patterns. If a choice should help future machines, put it in a profile or a machine entry.
