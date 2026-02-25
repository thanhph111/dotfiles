# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) for a consistent
development environment across multiple machines (macOS, Debian, Windows).

## Machines

| Codename | OS | Type | Vault |
|-|-|-|-|
| TARS | macOS | personal, client | Personal |
| Grid | macOS | agent | CLU |
| Madison | macOS | personal, client | Personal |
| HAL | macOS | work, client | HDBank |
| GFT | macOS | work, client | GFT |
| T-X | Linux | personal | Personal |
| Rev-9 | Linux | personal | Personal |
| Arwen | Windows | personal | Personal |

## Setup: new Mac

### 1. Prepare the repo (on an existing machine)

- Create a Brewfile at [`home/.Brewfiles/<codename>`](./home/.Brewfiles) (lowercase)
- Add hostname detection in [`home/.chezmoi.toml.tmpl`](./home/.chezmoi.toml.tmpl)
- Push to the repository

### 2. Set the ComputerName (on the new machine)

The hostname must match the codename exactly (case-sensitive):

```bash
sudo scutil --set ComputerName "Grid"  # or your codename
```

### 3. Install chezmoi and clone

```bash
mkdir -p ~/Documents/Projects/Personal
sh -c "$(curl -fsLS get.chezmoi.io)"

# May trigger Xcode Command Line Tools install — rerun after installation
./bin/chezmoi init -S ~/Documents/Projects/Personal/dotfiles thanhph111
```

### 4. First apply (installs Homebrew + packages)

```bash
./bin/chezmoi apply
```

This installs Homebrew (if missing) and all packages from the machine's Brewfile.
For client machines, 1Password secrets are skipped since `op` isn't signed in yet.

### 5. Sign into 1Password CLI (client machines only)

```bash
op account add
eval $(op signin)
op vault list  # verify access
```

### 6. Second apply (client machines only — pulls 1Password secrets)

```bash
chezmoi apply
```

The process is idempotent — safe to run as many times as needed.

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
   ```
   {{- else if eq $hostname "NewMachine" }}
   {{-     $codename = "NewMachine" -}}
   {{-     $vault = "VaultName" -}}
   {{-     $client = true -}}
   ```
3. Set variables as needed: `$client`, `$agent`, `$personal`, `$gitName`, `$gitEmail`
4. Push and follow the setup steps above
