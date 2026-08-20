# Spotifyd

Spotifyd makes a Linux machine appear as a Spotify Connect player. It uses OAuth, which is a browser login that saves a reusable token instead of storing the Spotify password.

The token stays in `~/.cache/spotifyd/oauth/credentials.json`. It is a secret. Never commit it, paste it into logs, or copy it into a dotfiles template. If it is lost, run the login again.

LAN discovery is disabled. Spotifyd signs in to Spotify directly, so WARP does not need to carry local multicast traffic and UFW does not need Spotify discovery rules.

## First login on Rev-9

Use Rev-9's local GNOME desktop or its existing private RDP session. The browser and OAuth callback must both run on Rev-9.

Review and apply the dotfiles first:

```bash
chezmoi diff --exclude=none --no-pager
chezmoi apply
systemctl --user daemon-reload
```

Stop the old process, protect files created during login, and start the browser login:

```bash
systemctl --user stop spotifyd.service
install -d -m 700 "$HOME/.cache/spotifyd"
umask 077
spotifyd authenticate
```

Complete the Spotify login in the browser. When the terminal reports a successful login, protect the saved token and start the player:

```bash
chmod 700 "$HOME/.cache/spotifyd/oauth"
chmod 600 "$HOME/.cache/spotifyd/oauth/credentials.json"
systemctl --user start spotifyd.service
```

Verify the service and then open Spotify's device list while WARP is connected:

```bash
systemctl --user is-active spotifyd.service
journalctl --user --unit=spotifyd.service --lines=40 --no-pager
```

The service should report an OAuth login and authentication. Spotify should list Rev-9 without opening a public Cloudflare route or a local UFW port.
