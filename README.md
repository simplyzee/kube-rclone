# kube-rclone

kube-rclone mounts an [rclone](https://rclone.org) remote, such as Google Drive or S3, on every node of a Kubernetes cluster. It runs rclone as a DaemonSet and mounts the remote on a `hostPath`, so other workloads (for example [kube-plex](https://github.com/munnerz/kube-plex)) can read the files as if they were local.

## Quick start

1. Create an rclone config on your own machine with `rclone config`.
2. Install the chart:

```bash
helm repo add simplyzee https://charts.simplyzee.dev
helm repo update

helm install rclone simplyzee/kube-rclone \
  --namespace rclone --create-namespace \
  --set-file rclone.config=./rclone.conf \
  --set rclone.remote=gdrive: \
  --set rclone.path=/mnt/disks/gdrive
```

To install from this repo instead, use `./kube-rclone` in place of `simplyzee/kube-rclone`.

rclone then mounts the remote at `/mnt/disks/gdrive` on each node, read-only by default. Mount options are in the [rclone docs](https://rclone.org/commands/rclone_mount/#options) and can be passed through `rclone.additionalArgs`.

The [chart README](kube-rclone/README.md) has every setting, how to keep your config in your own Secret, how to use the mount from another pod, and upgrade notes from 0.1.x.

## What's in 0.2.0

- **Secure config:** stored in a Secret instead of a ConfigMap. Supply it with `--set-file`, an existing Secret, or the old `files/rclone.conf`.
- **Official image:** the multi-arch `rclone/rclone` image, pinned to 1.75.2, so it also runs on arm64 nodes.
- **Self-healing:** a liveness probe restarts the pod if the FUSE mount dies, and pods roll when the config changes.
- **Persistent cache:** rclone's VFS cache lives on the node, so it survives restarts.
- **Safe multi-install:** two releases no longer clash.
- **More options:** tolerations, affinity, priority class, pod annotations and labels, environment variables and update strategy.
- **Validation:** a values schema, plus a clear error if no config is provided.
- **CI:** every change is linted, rendered and checked against the Kubernetes schemas.

Need more than one remote? Install the chart once per remote; see [Mounting more than one remote](kube-rclone/README.md#mounting-more-than-one-remote). Prefer plain manifests? See [Without Helm](kube-rclone/README.md#without-helm).

## Constraints

kube-rclone needs privileged pods on Linux nodes, because FUSE mounts that other pods can see require bidirectional mount propagation. Windows nodes aren't supported. It has been used with [kube-plex](https://github.com/munnerz/kube-plex). Other media apps such as [Radarr](https://github.com/Radarr/Radarr) and [Sonarr](https://github.com/Sonarr/Sonarr/) work best with `rclone.readOnly=false` and `--vfs-cache-mode=full`.

## Contributing

Please raise an issue or pull request if you have any issues, questions or features.

## Credits

Full credit list at: [CREDITS.md](https://github.com/simplyzee/kube-rclone/blob/master/CREDITS.md)
