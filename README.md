# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) for a consistent
development environment across multiple machines (macOS, Debian, Windows).

## Machines

Machines are selected by a small local profile, not by creating package files for
every host. Known hosts are declared in [`home/.chezmoidata/machines.yaml`](./home/.chezmoidata/machines.yaml);
unknown hosts can choose an existing profile during `chezmoi init` without a
repo change.

| Codename | OS      | Profile           |
| -------- | ------- | ----------------- |
| Arwen    | Windows | `windows-desktop` |
| Rev-9    | Linux   | `linux-desktop`   |
| Sonny    | Linux   | `linux-minimal`   |
| TARS     | macOS   | `darwin-personal` |

| Profile             | Use for                             |
| ------------------- | ----------------------------------- |
| `linux-desktop`     | Primary GNOME Linux desktop         |
| `linux-workstation` | Heavier reusable Linux workstation  |
| `linux-vm-dev`      | Headless Azure/Linux development VM |
| `linux-minimal`     | Shared/headless Linux machine       |
| `darwin-personal`   | Personal macOS machine              |
| `darwin-work`       | Work macOS machine                  |
| `darwin-agent`      | Lightweight macOS agent machine     |
| `windows-desktop`   | Personal Windows desktop            |

Profile definitions live in [`home/.chezmoidata/profiles.yaml`](./home/.chezmoidata/profiles.yaml).
Feature flags live in [`home/.chezmoidata/packages.yaml`](./home/.chezmoidata/packages.yaml).
Machine identity and per-host overrides live in [`home/.chezmoidata/machines.yaml`](./home/.chezmoidata/machines.yaml).

## Setup: new Mac

### 1. Set the ComputerName

Known machines are auto-detected. For a new machine, this only needs to be a
useful local name; it does not need a committed package manifest.

```bash
sudo scutil --set ComputerName "Grid"  # or your codename
```

### 2. Install chezmoi and clone

```bash
mkdir -p ~/Documents/Projects/Personal
sh -c "$(curl -fsLS get.chezmoi.io)"

# May trigger Xcode Command Line Tools install — rerun after installation
./bin/chezmoi init -S ~/Documents/Projects/Personal/dotfiles thanhph111
```

For an unknown host, init asks for a codename and one of the reusable profiles.
You only need to commit a new machine entry when the machine needs persistent
identity details such as a special vault, Git identity, or shared/sudo behavior.

### 3. First apply

```bash
./bin/chezmoi apply
```

This installs Homebrew or platform package managers as needed, then applies the
manifests selected by the profile.

### 4. Sign into 1Password CLI (client machines only)

```bash
op account add
eval $(op signin)
op vault list  # verify access
```

### 5. Second apply (client machines only)

```bash
chezmoi apply
```

The process is idempotent — safe to run as many times as needed.

## Git signing

Git commits and tags are signed with SSH. SSH signing means Git asks your SSH
agent, such as Secretive or 1Password, to prove that your key made the commit.
The private key stays in the agent.

Add the public key from `gitSigningKey` in
[`home/.chezmoidata/machines.yaml`](./home/.chezmoidata/machines.yaml) to GitHub
as an SSH signing key.

On remote machines, use the same signing key through SSH agent forwarding only
for machines you trust. Agent forwarding lets the remote machine ask your local
agent to sign, but it should not be enabled for every host. Keep it opt-in with
per-host files under `~/.ssh/config.d/`.

## Managing dotfiles

```bash
chezmoi edit ~/.zshrc      # Edit a managed file
chezmoi diff               # Preview changes before applying
chezmoi apply              # Apply changes
chezmoi add ~/.config/app  # Add a new file to management
chezmoi update             # Pull and apply from repository
```

## Adding a new machine

1. Pick the closest existing profile during `chezmoi init`.
2. Avoid committing anything for one-off local differences.
3. Add or change a profile only when the pattern should be reused on future machines.
4. Add a machine entry in [`home/.chezmoidata/machines.yaml`](./home/.chezmoidata/machines.yaml) only for machines that need special identity, vault, or Git settings.

Package manifests are profile-oriented:

- APT: [`home/.apt`](./home/.apt)
- Homebrew: [`home/.Brewfiles`](./home/.Brewfiles)
- Flatpak: [`home/.flatpak`](./home/.flatpak)
- GNOME: [`home/.gnome`](./home/.gnome)
- Windows: [`home/.winget`](./home/.winget), [`home/.scoop`](./home/.scoop)

Homebrew is intentionally one Brewfile per profile. On Linux and macOS,
`~/.Brewfile` is a symlink to the active profile manifest, so `generate-brewfile`
and `brew bundle dump --file ~/.Brewfile` update the reusable profile recipe.

Prefer Homebrew core/cask packages over third-party taps when available.
Third-party formulas or casks should stay fully qualified, for example
`brew "user/tap/formula"`. The shared brew installer trusts only those explicit
items before running `brew bundle` with tap trust checks enabled, matching the
upcoming Homebrew default without trusting whole taps. If a package moves into
Homebrew core/cask, remove the old Brewfile tap entry and do a one-time cleanup
on machines that already installed the package from the old tap.
