# Spotifyd

Spotifyd makes a Linux machine appear as a Spotify Connect player. It uses OAuth, which is a browser login that saves a reusable token instead of storing the Spotify password.

The token stays in `~/.cache/spotifyd/oauth/credentials.json`. It is a secret. Never commit it, paste it into logs, or copy it into a dotfiles template. If it is lost, run the login again.

LAN discovery is disabled. Spotifyd signs in to Spotify directly, so WARP does not need to carry local multicast traffic and UFW does not need Spotify discovery rules.

## First login on a headless server

Spotifyd listens for the OAuth callback only on the server's loopback address. When the browser runs on another machine, use a temporary SSH local forward. This does not open a public route or firewall port.

Review and apply the dotfiles first:

```bash
chezmoi diff --exclude=none --no-pager
chezmoi apply
systemctl --user daemon-reload
```

From the machine running the browser, connect to the server using its existing private SSH name:

```bash
ssh -o ExitOnForwardFailure=yes \
    -L 127.0.0.1:8000:127.0.0.1:8000 \
    <server-private-SSH-name>
```

Keep that SSH session open. In its server shell, stop the old process, protect files created during login, and start the browser login:

```bash
systemctl --user stop spotifyd.service
install -d -m 700 "$HOME/.cache/spotifyd"
umask 077
spotifyd authenticate
```

Open the printed `Browse to` link on the machine running the browser. The local forward carries its loopback callback to Spotifyd on the server. When the server terminal reports a successful login, protect the saved token and start the player:

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

The service should report an OAuth login and authentication. Spotify should list the configured device name without opening a public route or a local firewall port.
