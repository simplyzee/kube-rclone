# kube-rclone

Mounts any [rclone](https://rclone.org) remote (Google Drive, S3, Dropbox, OneDrive and [many more](https://rclone.org/overview/)) on every node in your cluster, using a DaemonSet. Other workloads read the files through a `hostPath`.

## Install

```bash
helm repo add simplyzee https://charts.simplyzee.dev
helm repo update

helm install rclone simplyzee/kube-rclone \
  --namespace rclone --create-namespace \
  --set-file rclone.config=./rclone.conf \
  --set rclone.remote=gdrive: \
  --set rclone.path=/mnt/disks/gdrive
```

Create `rclone.conf` with `rclone config` on your own machine first.

## Supplying your rclone config

The config is always stored in a Kubernetes Secret, because it contains OAuth tokens and keys. Pick one option:

| Option | How | Best for |
|---|---|---|
| Existing Secret | `--set rclone.existingSecret=my-secret` (key `rclone.conf`, or set `rclone.existingSecretKey`) | GitOps, external secret managers |
| Inline | `--set-file rclone.config=./rclone.conf` | Quick installs |
| Chart file | Paste into `files/rclone.conf` (0.1.x behaviour) | Existing setups |

If none of these is set, the install stops with a clear error instead of creating pods that crash-loop.

## Using the mount from another workload

Mount the same host path with `HostToContainer` propagation so the pod sees the FUSE mount:

```yaml
volumes:
  - name: rclone
    hostPath:
      path: /mnt/disks/gdrive
containers:
  - name: app
    volumeMounts:
      - name: rclone
        mountPath: /data
        mountPropagation: HostToContainer
```

## Mounting more than one remote

Install the chart once per remote, with a different release name and path. Each release gets its own pods, Secret and selector, so they never clash:

```bash
helm install gdrive simplyzee/kube-rclone -n rclone --set-file rclone.config=./rclone.conf \
  --set rclone.remote=gdrive: --set rclone.path=/mnt/disks/gdrive

helm install backups simplyzee/kube-rclone -n rclone --set-file rclone.config=./rclone.conf \
  --set rclone.remote=s3:backups --set rclone.path=/mnt/disks/backups
```

## Without Helm

To get plain Kubernetes manifests, render the chart once and apply the output with `kubectl` or Kustomize:

```bash
helm template rclone simplyzee/kube-rclone -n rclone \
  --set-file rclone.config=./rclone.conf --set rclone.remote=gdrive: > kube-rclone.yaml
kubectl apply -n rclone -f kube-rclone.yaml
```

The rendered file includes your config in a Secret, so don't commit it unencrypted.

## Troubleshooting

- **`couldn't fetch token` or `Token refresh failed`:** the token in your config has expired or was revoked. Run `rclone config reconnect <remote>:` on your own machine and reinstall with the new config. rclone writes refreshed tokens to a writable copy inside the pod, so this won't happen again once the token is valid.
- **`dial tcp 192.168.x.x:443: connect: connection refused` when reaching Google or another provider:** the cluster's DNS is resolving the provider's hostname to a local address. Check with `kubectl run dnstest -it --rm --image=busybox --restart=Never -- nslookup oauth2.googleapis.com`. If it returns a private IP, fix the upstream DNS used by CoreDNS (on k3s, often the node's `/etc/resolv.conf` or a router doing DNS rewriting).
- **Pods never start on some nodes:** FUSE mounts only work on Linux, so the chart only schedules on Linux nodes (`kubernetes.io/os: linux`). For Google Cloud Storage on GKE, including Windows workloads, the managed [Cloud Storage FUSE CSI driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver) is the better fit.
- **Other pods see an empty directory:** they need `mountPropagation: HostToContainer` on the volume mount (see above), and they must start after the mount is up.

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | rclone image (official, multi-arch) | `rclone/rclone` |
| `image.tag` | Image tag; empty uses the chart's `appVersion` | `""` (`1.75.2`) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Pull secrets for private registries | `[]` |
| `rclone.remote` | Remote to mount, as named in your config; can include a path | `gcache:` |
| `rclone.path` | Host path the remote is mounted at on each node | `/mnt/disks/gdrive` |
| `rclone.readOnly` | Mount read-only to protect files on the remote | `true` |
| `rclone.allowOther` | Let other users and pods on the node read the mount | `true` |
| `rclone.allowNonEmpty` | Allow mounting over a non-empty directory | `true` |
| `rclone.cacheDir` | Host path for rclone's VFS cache, kept across restarts | `/var/lib/rclone` |
| `rclone.existingSecret` | Use your own Secret for the config | `""` |
| `rclone.existingSecretKey` | Key in that Secret holding the config | `rclone.conf` |
| `rclone.config` | Config contents, stored in a Secret the chart creates | `""` |
| `rclone.additionalArgs` | Extra [`rclone mount` flags](https://rclone.org/commands/rclone_mount/#options) | `[]` |
| `rclone.env` | Extra environment variables, e.g. `RCLONE_*` | `[]` |
| `livenessProbe.enabled` | Restart the pod when the mount dies | `true` |
| `livenessProbe.*` | `initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, `failureThreshold` | `30`, `30`, `10`, `3` |
| `securityContext` | Container security context (FUSE needs privileged) | `privileged: true`, `SYS_ADMIN` |
| `terminationGracePeriodSeconds` | Time allowed to unmount cleanly | `120` |
| `updateStrategy` | DaemonSet update strategy | `RollingUpdate` |
| `priorityClassName` | e.g. `system-node-critical` | `""` |
| `podAnnotations`, `podLabels` | Extra pod metadata | `{}` |
| `resources` | CPU and memory requests and limits | `{}` |
| `nodeSelector` | Node labels for scheduling (Linux only; FUSE doesn't work on Windows) | `kubernetes.io/os: linux` |
| `tolerations`, `affinity` | Pod scheduling | `[]`, `{}` |

Pods restart automatically when a chart-managed config changes.

## Upgrading from 0.1.x

- **Reinstall rather than upgrade.** The pod selector now includes the release name so two installs never clash. Kubernetes doesn't allow changing a DaemonSet selector in place, so run `helm uninstall` then `helm install`.
- **The config moved from a ConfigMap to a Secret.** Your `files/rclone.conf` still works, but `--set-file` or `existingSecret` is preferred.
- **The default image is now the official `rclone/rclone`.** Old `images.container.*` and `images.pullPolicy` values are still honoured.
- **The busybox init container is gone.** The rclone image copies the config itself.
