# kube-rclone helm chart

## Configuration

The following tables lists the configurable parameters of the kube-rclone chart and their default values.

| Parameter                  | Description                         | Default                                                 |
|----------------------------|-------------------------------------|---------------------------------------------------------|
| `images.initContainer.repository`         | Image init container repository | `busybox` |
| `image.initContainer.tag`         | Image init container tag | `latest` |
| `image.container.repository`         | Image repository | `quay.io/chaosaffe/rclone` |
| `image.container.tag`                | Image tag. Possible values listed [here](https://quay.io/repository/chaosaffe/rclone?tab=tags).| `v1.47.0`|
| `image.pullPolicy`         | Image pull policy | `IfNotPresent` |
| `rclone.remote`         | rclone remote to use | `gcache:` |
| `rclone.path`         | rclone remote path to mount | `/mnt/disks/gdrive` |
| `rclone.readOnly`         | rclone read only file system | `enabled` |
| `rclone.additionalArgs`         | rclone additional arguments to pass for mount options | `` |
| `nodeSelector`             | Node labels for pod assignment | `` |
| `resources`                | CPU/Memory resource requests/limits | `{}` |

Read through the [values.yaml](values.yaml) file. It has several commented out suggested values.
