# Dotfiles

Personal dotfiles for macOS managed with [chezmoi](https://www.chezmoi.io/) for a consistent development environment across multiple machines (including macOS, Debian and Windows).

## Setup instructions

### For a new Mac

1. **Configure for your machine**:
   - Set up new [`home/.Brewfiles`](./home/.Brewfiles) for the new machine
   - Add machine-specific settings in [`home/.chezmoi.toml.tmpl`](./home/.chezmoi.toml.tmpl)
   - Push changes to the repository

2. **Install on the new Mac**:
   ```bash
   mkdir -p ~/Documents/Projects/Personal
   sh -c "$(curl -fsLS get.chezmoi.io)"

   # Clone the repo - you may see a popup to install Xcode Command Line Tools, rerun after installation:
   ./bin/chezmoi init -S ~/Documents/Projects/Personal/dotfiles thanhph111

   # Apply configurations - run multiple times if needed, the process is idempotent
   ./bin/chezmoi apply
   ```

## Managing dotfiles

```bash
# Edit a configuration file
chezmoi edit ~/.zshrc

# Preview changes before applying
chezmoi diff

# Apply changes
chezmoi apply

# Add a new file to be managed
chezmoi add ~/.config/app/config

# Update from repository
chezmoi update
```
