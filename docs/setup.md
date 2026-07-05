# Set up a machine

This guide is for a new machine or a fresh reinstall.

## 1. Give the machine a good local name

Known machines are matched by hostname. On macOS, chezmoi uses `ComputerName`, so set it before init:

```bash
sudo scutil --set ComputerName "Grid"
```

For an unknown machine, the name only needs to be useful to you. It does not need a committed machine entry.

## 2. Install chezmoi and clone this repo

```bash
mkdir -p ~/Documents/Projects/Personal
sh -c "$(curl -fsLS get.chezmoi.io)"

./bin/chezmoi init -S ~/Documents/Projects/Personal/dotfiles thanhph111
```

On macOS, this may trigger Xcode Command Line Tools. If it does, finish that install and rerun the `chezmoi init` command.

## 3. Answer setup prompts

Known machines are selected automatically by hostname.

Unknown machines ask for:

- display name
- profile
- whether the machine is headless
- whether to keep the profile defaults or customize private local facts

Those answers are saved in the machine's local chezmoi config. They are private to that checkout.

## 4. Run the first apply

```bash
./bin/chezmoi apply
```

This installs package-manager basics and applies the features selected by the profile.

## 5. Sign in to 1Password on client machines

Do this only on machines that should use client secrets.

```bash
op account add
eval $(op signin)
op vault list
```

## 6. Run apply again

```bash
chezmoi apply
```

The apply should be safe to repeat. If scripts changed, review with:

```bash
chezmoi diff --exclude=none
```

## When to add a machine to the repo

Add a machine entry only when the host should be remembered by the repo.

Good reasons:

- hostname should pick a profile automatically
- one host needs a stable feature override
- a shared host needs per-user facts
- the identity should survive reinstall

For a temporary or one-off machine, use local setup answers instead.
