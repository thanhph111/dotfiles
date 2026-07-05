# Shell startup trust

Shell startup should only trust files and arguments that are owned by the local machine or the current project.

## Project environment files

Do not load `.env` files globally.

Projects that need `.env` should opt in from a trusted `.envrc`:

```sh
dotenv_if_exists .env
```

Then run `direnv allow` for that project after reading the `.envrc`.

Keep secrets and personal overrides out of Git, but let each project own that choice in its own `.gitignore`. This dotfiles repo does not ignore `.env` globally because some projects intentionally track env files such as `.env.example`, `.env.test`, or even a non-secret `.env`.

## Startup eval

Some local terminal profiles start the shell with an extra command:

```sh
bash -is eval 'piccel ~/.local/bin/pac-man.json'
zsh -ils eval 'piccel ~/.local/bin/pac-man.json'
```

This is kept on purpose for local terminal profiles. Treat it like `bash -ic 'command'`: the caller already controls the command string.

Do not feed this argument from a project file, remote input, or generated data.

## Chezmoi script path

Chezmoi scripts use a fixed `PATH` from known user, package-manager, and system directories. They should not inherit the full caller `PATH`, because apply may run from a project shell with project-local commands.
