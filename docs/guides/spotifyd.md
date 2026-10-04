# Spotifyd

Spotifyd makes a Linux machine appear as a Spotify Connect player. It uses OAuth, which is a browser login that saves a reusable token instead of storing the Spotify password.

The token stays in `~/.cache/spotifyd/oauth/credentials.json`. It is a secret. Never commit it, paste it into logs, or copy it into a dotfiles template. If it is lost, run the login again.

LAN discovery is disabled. Spotifyd signs in to Spotify directly, so WARP does not need to carry local multicast traffic and UFW does not need Spotify discovery rules.

## First login on a headless server

Run the login on the server from your normal SSH session. The command accepts the returned browser URL and sends the callback to Spotifyd locally.

Review and apply the dotfiles first:

```bash
chezmoi diff --exclude=none --no-pager
chezmoi apply
systemctl --user daemon-reload
```

In the server shell, run the login:

```bash
dot-spotifyd login
```

Complete these steps in your browser and the same server terminal:

1. Open the printed `Browse to` link in your browser and approve Spotify access.
2. After approval, copy the full `http://127.0.0.1:8000/login?...` URL from the address bar. A connection error on this page is expected when the browser runs on another machine.
3. Paste the URL at the command's `Returned URL` prompt and press Enter. The pasted URL is hidden. If the browser already reports success, press Enter without pasting a URL.

The command sends the callback to the server's local listener, protects the saved credentials, and starts the player. If you cancel or login fails, it stops the login process and restarts the player if it was running before login.

The browser URL contains a temporary login code. Paste it into the command's prompt so it stays out of shell history. See [Operation commands](./operation-commands.md).

Verify the service and then open Spotify's device list while WARP is connected:

```bash
dot-service check spotifyd.service
```

The service should report an OAuth login and authentication. Spotify should list the configured device name without opening a public route or a local firewall port.
