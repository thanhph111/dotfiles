# Manifests

Manifests are concrete lists.

Features decide whether a tool runs. Manifests decide what that tool installs or applies.

## Manifest paths

- Linux APT: [`home/.apt`](../../home/.apt)
- Homebrew: [`home/.Brewfiles`](../../home/.Brewfiles)
- Linux Flatpak: [`home/.flatpak`](../../home/.flatpak)
- GNOME Shell extensions: [`home/.gnome/extensions`](../../home/.gnome/extensions)
- GNOME settings: [`home/.gnome/settings`](../../home/.gnome/settings)
- Windows winget: [`home/.winget`](../../home/.winget)
- Windows scoop: [`home/.scoop`](../../home/.scoop)

## How profiles choose manifests

Example:

```yaml
profiles:
  entries:
    linux-desktop:
      features:
        linux:
          install:
            apt:
              manifests:
                - linux-desktop
            homebrew:
              manifests:
                - linux-desktop
```

Plain meaning:

- APT reads `home/.apt/linux-desktop`.
- Homebrew reads `home/.Brewfiles/linux-desktop`.

## Homebrew

Homebrew uses one Brewfile per profile.

On Linux and macOS, `~/.Brewfile` links to the first Homebrew manifest for the selected profile. That keeps this command pointed at the reusable profile file:

```bash
brew bundle dump --file ~/.Brewfile
```

Prefer Homebrew core and cask packages when available.

If a third-party package is needed, keep it fully qualified:

```ruby
brew "user/tap/formula"
cask "user/tap/app"
```

The shared Homebrew installer trusts only explicit third-party items before running `brew bundle` with tap trust checks.
