# NVIDIA containers

The NVIDIA Container Toolkit gives containers access to a host GPU: pods in [k3s](./k3s.md), and Docker services on a machine that enables Docker. A workload still has to ask for the GPU, because the NVIDIA runtime is never the default.

## Ownership

Dotfiles owns the host side:

- NVIDIA's production APT repository and signing key;
- the exact toolkit package version;
- Docker's NVIDIA runtime registration and restart, on a machine that enables Docker;
- host-level verification.

Each application owns whether its workload requests the GPU and which video features it enables.

The feature is off by default and enabled per machine in `machines.yaml`. `features.yaml` owns the pinned package version. Upgrade it deliberately there after reviewing NVIDIA's release notes.

## Apply

Preview every setup script, because this change installs packages and, where Docker is enabled, updates `/etc/docker/daemon.json` and restarts Docker:

```bash
chezmoi diff --exclude=none --no-pager
chezmoi apply
```

Where Docker is enabled, the runtime setup uses NVIDIA's supported command:

```bash
sudo nvidia-ctk runtime configure --runtime=docker
```

It preserves Docker's other daemon settings and does not select NVIDIA as the default runtime.

On a host that also runs [k3s](./k3s.md), k3s registers the toolkit's runtimes in its own containerd when it starts, and its setup script restarts k3s whenever the toolkit changes. Pods ask for the GPU with `runtimeClassName: nvidia`.

## Verify

Run the read-only host check:

```bash
dot-nvidia check
```

It checks the host driver, the toolkit's access to it, and the `nvidia` runtime of Docker and of k3s, each where it is installed. Application-level GPU use needs an application-specific workload. For a media server, force a transcode and confirm both the GPU process and output codec; a normal HTTP health check is not enough.

## References

- [NVIDIA Container Toolkit install guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [Jellyfin NVIDIA hardware acceleration](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia/)
