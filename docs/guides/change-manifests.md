# Change manifests

Manifests are the concrete lists of packages, apps, extensions, and settings.

Features choose which manifests run.

## Add one package to a profile

Edit the manifest for that profile.

Linux desktop APT example:

```bash
chezmoi edit ~/.apt/linux-desktop
```

Then add the package name to `home/.apt/linux-desktop`.

## Add one Homebrew package

Edit the selected Brewfile:

```bash
chezmoi edit ~/.Brewfile
```

On Linux and macOS, `~/.Brewfile` links to the first Homebrew manifest selected by the active profile.

## Add a manifest to a profile

Add the manifest name under the feature:

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
                - linux-gpu
```

Then create the matching manifest file:

```text
home/.apt/linux-gpu
```

## Add a tool to every machine on one OS

Change the default feature only when every machine on that operating system should get it.

For narrower changes, prefer a profile or machine override.

## Third-party Homebrew items

Prefer Homebrew core and cask packages when available.

If a third-party package is needed, keep it fully qualified:

```ruby
brew "user/tap/formula"
cask "user/tap/app"
```

If a package later moves into Homebrew core or cask, remove the old tap entry and clean up already-installed machines once.
