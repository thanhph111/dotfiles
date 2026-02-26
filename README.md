# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) for a consistent
development environment across multiple machines (macOS, Debian, Windows).

## Machines

| Codename | OS      | Type             | Vault    |
| -------- | ------- | ---------------- | -------- |
| TARS     | macOS   | personal, client | Personal |
| Grid     | macOS   | agent            | CLU      |
| Madison  | macOS   | personal, client | Personal |
| HAL      | macOS   | work, client     | HDBank   |
| GFT      | macOS   | work, client     | GFT      |
| T-X      | Linux   | personal         | Personal |
| Rev-9    | Linux   | personal         | Personal |
| Arwen    | Windows | personal         | Personal |

## Setup: new machine

### 1. Prepare the repo (on an existing machine)

- Create a Brewfile at [`home/.Brewfiles/<codename>`](./home/.Brewfiles) (lowercase)
- Add hostname detection in [`home/.chezmoi.toml.tmpl`](./home/.chezmoi.toml.tmpl)
- Push to the repository

### 2. Set hostname (on the new machine)

On macOS, the `ComputerName` must match the codename exactly (case-sensitive):

```bash
sudo scutil --set ComputerName "Grid"  # or your codename
```

### 3. Install chezmoi and clone

macOS / Linux:

```bash
mkdir -p ~/Documents/Projects/Personal
sh -c "$(curl -fsLS get.chezmoi.io)"

# May trigger Xcode Command Line Tools install — rerun after installation
./bin/chezmoi init -S ~/Documents/Projects/Personal/dotfiles thanhph111
```

Windows (PowerShell):

```powershell
New-Item -ItemType Directory -Force "$HOME\Documents\Projects\Personal" | Out-Null
iex "&{$(irm 'https://get.chezmoi.io/ps1')}"   # installs chezmoi
chezmoi init --source "$HOME\Documents\Projects\Personal\dotfiles" thanhph111
```

### 4. Bootstrap first run (recommended)

macOS / Linux:

```bash
./script/bootstrap-first-run
```

Windows (PowerShell):

```powershell
& "$HOME\Documents\Projects\Personal\dotfiles\script\bootstrap-first-run.ps1"
```

The bootstrap scripts:

- Run `chezmoi apply` once to install dependencies and baseline config
- Refresh environment in-process (no mandatory shell reload)
- Run a second apply with `CHEZMOI_ENABLE_SECRETS=1` only when secrets are ready:
  - `OP_SERVICE_ACCOUNT_TOKEN` is set, or
  - `op vault list` succeeds

If secrets are not ready, bootstrap exits successfully and prints the next step.

### 5. If secrets were deferred

Client machines (interactive):

```bash
op account add
eval "$(op signin)"
./script/bootstrap-first-run
```

Agent machines (service account):

```bash
export OP_SERVICE_ACCOUNT_TOKEN="<token>"
./script/bootstrap-first-run
```

### 6. Troubleshooting fallback (manual two-pass)

If you need full manual control, this still works:

```bash
chezmoi apply
eval "$(op signin)"   # or export OP_SERVICE_ACCOUNT_TOKEN
CHEZMOI_ENABLE_SECRETS=1 chezmoi apply
```

The process remains idempotent and safe to run repeatedly.

## Managing dotfiles

```bash
chezmoi edit ~/.zshrc      # Edit a managed file
chezmoi diff               # Preview changes before applying
chezmoi apply              # Apply changes
chezmoi add ~/.config/app  # Add a new file to management
chezmoi update             # Pull and apply from repository
```

## Adding a new machine

1. Choose a codename and create `home/.Brewfiles/<codename>` with the package list
2. Add the hostname case to `home/.chezmoi.toml.tmpl`:

   ```text
   {{- else if eq $hostname "NewMachine" }}
   {{-     $codename = "NewMachine" -}}
   {{-     $vault = "VaultName" -}}
   {{-     $client = true -}}
   ```

3. Set variables as needed: `$client`, `$agent`, `$personal`, `$gitName`, `$gitEmail`
4. Push and follow the setup steps above

## Testing

Testing is Python-first (`uv` + `pytest`) and run through `mise` tasks.

Official commands:

```bash
mise run test                            # local tier, docker-only
mise run test --tier smoke               # CI-style smoke selection
mise run test --tier full --platform all # widest matrix
mise run test --report pretty            # html + junit + summary (default)
```

Local policy: runtime tests are Docker-only. Native test execution is CI-only.
