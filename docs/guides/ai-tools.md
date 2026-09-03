# AI tools

This repo manages the hand-written config for Codex (the CLI and the ChatGPT desktop app) and Claude Code on every machine. State, caches, logins, and the allow lists the apps grow on their own stay on each machine.

## What is managed

| Target                                      | Source                                                         | How                                                                                     |
| ------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md` | `home/.chezmoitemplates/agent-constitution.md`                 | One shared working agreement, rendered once per agent with a short agent-specific tail. |
| `~/.codex/config.toml`                      | `agents.codex.config` in `home/.chezmoidata/agents.yaml`       | Managed keys merged into the existing file.                                             |
| `~/.claude/settings.json`                   | `agents.claude.settings` in the same file                      | Managed keys merged into the existing file.                                             |
| `~/.agents/skills/*`                        | `home/dot_agents/skills`                                       | Plain files. Codex reads this directory as its user skills.                             |
| `~/.claude/skills/*`                        | The same files, included from `home/dot_claude/skills`         | Claude Code does not read `~/.agents`, so each shared skill is rendered a second time.  |
| Claude Code plugins                         | `enabledPlugins` and `extraKnownMarketplaces` in `agents.yaml` | Declared only. Claude Code does not install from settings; see below.                   |

Everything else under `~/.codex` and `~/.claude` is ignored: `auth.json`, `~/.claude.json`, sessions, transcripts, plugin caches, memories, and the allow lists (`~/.codex/rules`, Codex project trust, Claude `permissions`). Claude's `permissions` and `autoMode` keys are never touched because they are machine-local and can hold work-specific text.

`~/.claude/rules`, `~/.claude/agents`, `~/.claude/skills`, and `~/.claude/keybindings.json` are allowlisted, so a new file there can be added with `chezmoi add`.

## Plugins on a new machine

`enabledPlugins` tells Claude Code which plugins should be on, but it installs nothing by itself; it reports a declared plugin as not installed until you install it. Once per machine, after the first login:

```bash
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install commit-commands@claude-plugins-official
claude plugin install codex@openai-codex
```

Repeat the install line for each plugin listed in `agents.yaml`. Codex plugins are toggled in the app; the toggles it writes to `config.toml` stay machine-local.

## The merge rule

Codex writes project trust, plugin toggles, marketplaces, and notices into `config.toml`. Claude Code writes `/model`, `/effort`, plugin installs, and auto mode into `settings.json`. A plain managed file would delete that state on every apply, so both files are `modify_` templates: the repo wins for the keys in `agents.yaml`, the app wins for everything else.

Plain meaning:

- Change a preference in `agents.yaml` and apply; the app's own entries survive.
- Remove a key from `agents.yaml` and the machine keeps its current value. Delete it by hand, or add a `deleteValueAtPath` line to the template for one apply.
- The merged files come out with sorted keys and no comments. Both apps keep that layout on their own later edits.
- After an app appends something new, `chezmoi status` shows `MM` on that file and `chezmoi diff` shows a reorder. The next apply folds it in.

Restart Codex after `config.toml` changes. Claude Code reloads its settings on its own.

## Apply safely

The two merged files are the only targets with app state in them. Before the first apply on a machine, and after a change to `agents.yaml`:

1. Quit the ChatGPT app and finish open Claude Code sessions, so nothing rewrites the files while chezmoi does.
2. Keep a copy to fall back on:

   ```bash
   cp ~/.codex/config.toml ~/.codex/config.toml.bak
   cp ~/.claude/settings.json ~/.claude/settings.json.bak
   ```

3. Review. The first `config.toml` diff is long because the file is re-serialized. Check that every `[projects."..."]`, `[plugins."..."]`, and `[marketplaces.*]` table appears on the `+` side, and that `permissions` and `autoMode` survive in `settings.json`:

   ```bash
   chezmoi diff ~/.codex/AGENTS.md ~/.claude/CLAUDE.md
   chezmoi diff ~/.codex/config.toml ~/.claude/settings.json
   ```

4. Apply files only, then start Codex and Claude Code once; both fail loudly on a config they cannot read:

   ```bash
   chezmoi apply --exclude=scripts
   ```

If something is wrong, copy the `.bak` files back. A later `chezmoi status` showing `MM` on these two files is normal after the apps write to them; see the merge rule above.

## Per-machine values

The `codex-lb` base URL is the one value that differs per machine:

```yaml
features:
  linux:
    apps:
      codex:
        provider_base_url: https://codex-lb.thanhph111.com/backend-api/codex
```

Rev-9 hosts the balancer in Docker and points at `http://127.0.0.1:2455/backend-api/codex` in `machines.yaml`. Other machines reach the public URL through Cloudflare Access, which lets WARP-enrolled devices through without a service token. A machine that still needs the token can add `http_headers` under `[model_providers.codex-lb]` by hand; the merge keeps it.

## Change a preference

Edit `home/.chezmoidata/agents.yaml`, then preview and apply:

```bash
chezmoi diff ~/.codex/config.toml ~/.claude/settings.json
chezmoi apply
```

The working agreement lives in `home/.chezmoitemplates/agent-constitution.md`. Keep it under 200 lines: both agents load it into every session, and shorter files are followed more reliably.

## Add a shared skill

1. Put `SKILL.md` under `home/dot_agents/skills/<name>/`.
2. When Claude Code should see it too, add `home/dot_claude/skills/<name>/SKILL.md.tmpl` containing:

```gotemplate
{{ include "dot_agents/skills/<name>/SKILL.md" -}}
```

## Secrets

Nothing here needs a secret. Logins live in `~/.codex/auth.json`, `~/.claude/.credentials.json` on Linux, and the macOS keychain. Log in once on each machine; never copy those files into the repo.
