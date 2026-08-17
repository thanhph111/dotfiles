# NVIDIA containers

The NVIDIA Container Toolkit gives selected Docker Compose services access to a host GPU. The application still has to ask for a GPU; the NVIDIA runtime is not Docker's default runtime.

## Ownership

Dotfiles owns the host side:

- NVIDIA's production APT repository and signing key;
- the exact toolkit package version;
- Docker's NVIDIA runtime registration;
- the Docker restart and host-level verification.

Each application repository owns whether its Compose service requests the GPU and which video features it enables.

The feature is off by default and enabled per machine in `machines.yaml`. `features.yaml` owns the pinned package version. Upgrade it deliberately there after reviewing NVIDIA's release notes.

## Apply

Preview every setup script because this change installs packages, updates `/etc/docker/daemon.json`, and restarts Docker:

```bash
chezmoi diff --exclude=none --no-pager
chezmoi apply
```

The runtime setup uses NVIDIA's supported command:

```bash
sudo nvidia-ctk runtime configure --runtime=docker
```

It preserves Docker's other daemon settings and does not select NVIDIA as the default runtime.

## Verify

Run the read-only host check:

```bash
mise run nvidia-check
```

It checks the host driver, Docker service, registered `nvidia` runtime, and the toolkit's access to the driver. Application-level GPU use needs an application-specific workload. For a media server, force a transcode and confirm both the GPU process and output codec; a normal HTTP health check is not enough.

## References

- [NVIDIA Container Toolkit install guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [Jellyfin NVIDIA hardware acceleration](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia/)
