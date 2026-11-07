# k3s

k3s is a compact Kubernetes for one machine. On Rev-9 it runs `lotus`, the container platform for my projects. Dotfiles owns the host side of the cluster, and the infrastructure repository owns everything inside it, as its [platform architecture](https://github.com/thanhph111/infrastructure/blob/main/docs/platform/architecture.md) describes.

## Ownership

Dotfiles owns:

- the k3s binary and its systemd service, at the pinned version
- the k3s configuration in `/etc/rancher/k3s/config.yaml`
- the UFW rules that let pods reach the host
- the NVIDIA Container Toolkit, which k3s finds by itself when it starts

The infrastructure repository owns what runs in the cluster: Flux, the gateway, the admission policies, the NVIDIA device plugin, and the tenants.

## Enable

The feature is off by default. Turn it on per machine in `machines.yaml`, together with its UFW rules and strict reverse-path filtering, which [Firewall](#firewall) explains:

```yaml
features:
  linux:
    network:
      ufw:
        rules:
          k3s_pods:
            enabled: true
          k3s_services:
            enabled: true
      reverse_path_filter:
        enabled: true
    services:
      k3s:
        enabled: true
```

Preview every setup script, then apply:

```bash
chezmoi diff --exclude=none --no-pager
chezmoi apply
```

The script installs the pinned release with the installer from that release's own tag, writes the configuration, and restarts k3s. It then waits until the node is Ready and CoreDNS is available. On a host with the NVIDIA Container Toolkit, it also checks that k3s registered the `nvidia` runtime.

## Configuration

- **No packaged Traefik or ServiceLB.** They would take the host's ports 80 and 443. The platform runs its own gateway on `127.0.0.1` instead.
- **Secrets encryption.** k3s encrypts Secrets in its datastore.
- **A root-only admin kubeconfig.** k3s writes `/etc/rancher/k3s/k3s.yaml` owned by root with mode `0600`. If my user could read it, every process of mine, the Codex Remote service included, would hold cluster-admin rights. Use `sudo k3s kubectl` on the host. The plain `kubectl` command stays the Homebrew client.

## Firewall

UFW denies incoming traffic by default, and pods reach the API server and the kubelet on the host itself. The `k3s_pods` and `k3s_services` rules allow k3s's default pod and service networks, as the [k3s requirements](https://docs.k3s.io/installation/requirements) ask. Without them, CoreDNS never becomes available, and the script stops with that message.

Both rules accept traffic only through `cni0`, the bridge that every pod on a single node uses. A rule on the source address alone would also accept a packet that a host on the LAN sends with a forged pod address, on any port. That includes flannel's VXLAN port 8472/udp, which k3s says must not be exposed.

UFW cannot close that path alone. k3s's network policy controller accepts a packet from the address of a running pod before UFW sees it, whatever interface it came through. A k3s host therefore also turns on `network.reverse_path_filter`, so the kernel drops a LAN packet that carries a pod or container address before any firewall rule runs.

The API server's port 6443 stays closed to the LAN. An enrolled WARP device reaches it through the tunnel's private route to Rev-9, because `cloudflared` connects to it from the host itself.

## Upgrade

[`features.yaml`](../../home/.chezmoidata/features.yaml) pins the k3s version. To raise it:

1. Pick the next version from k3s's [stable channel](https://update.k3s.io/v1-release/channels).
2. Check that Flux and every other component in the cluster support that Kubernetes minor version. Flux supports only the three newest minor versions, and its [release notes](https://github.com/fluxcd/flux2/releases) list them.
3. Raise the version by at most one minor version. The script refuses a downgrade or a skipped minor version.
4. Apply, then run the checks in [Verify](#verify).

## Certificates

k3s certificates last 365 days. k3s renews them only when it starts within 120 days of their expiry, so restart k3s or reboot the host at least once in that window. Check their dates with:

```bash
sudo k3s certificate check --output table
```

## Verify

```bash
systemctl status k3s --no-pager
sudo k3s kubectl get nodes
sudo k3s kubectl --namespace kube-system get pods
sudo grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

k3s runs its own containerd, so Docker and its Compose stacks keep running beside it.

## Remove

Turning the feature off leaves k3s installed and running. Removing k3s deletes the cluster's state and every volume on its default storage class, so do it by hand, and only after that data is safe:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

## References

- [k3s requirements](https://docs.k3s.io/installation/requirements)
- [k3s NVIDIA container runtime](https://docs.k3s.io/advanced#nvidia-container-runtime)
- [k3s certificates](https://docs.k3s.io/cli/certificate)
