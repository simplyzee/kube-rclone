# kube-rclone

## Introduction

kube-rclone is a rclone mount solution for Kubernetes. It allows you to sync files and directories to and from different cloud storage providers i.e Google Drive. It creates a Daemonset across the Kubernetes cluster which mounts a volume on the `hostPath` that can be used with other services such as [kube-plex](https://github.com/munnerz/kube-plex)

## Prerequisites
* rclone config that has the cloud storage drive defined

This can be created by running `rclone config` which will take you through an interactive configuration session to generate the `rclone.conf` file.

## Setup
The setup guide will help you get rclone running as a Daemonset on Kubernetes.

1. Add the contents of the `rclone.conf` file into `files/rclone.conf`
2. Deploy the kube-rclone chart with the correct remote and path defined from the `rclone.conf` file

```bash
> helm install ./kube-rclone --name rclone \
    --namespace rclone \
    --set rclone.remote=[insert remote to mount here] \
    --set rclone.path=[insert mount path for remote] \
    --set rclone.readOnly=true
```

This will deploy a Daemonset across the Kubernetes cluster that will run rclone with the mounted remote i.e Google Drive on the `hostPath` of the node which can be used with other services.

Additional arguments can be set to customise `rclone mount` depending on the Kubernetes node resources. Some additional arguments have been commented out which are based on several user set-ups. They can be used based on user preference. Mount options can be found [here](https://rclone.org/commands/rclone_mount/#options)

Example of pod logs:
```bash
2019/06/28 22:15:58 INFO  : gcache: Cache DB path: /home/rclone/rclone-cache/cache.db
2019/06/28 22:15:58 INFO  : gcache: Cache chunk path: /home/rclone/rclone-cache/cache
2019/06/28 22:15:58 INFO  : gcache: Chunk Memory: true
2019/06/28 22:15:58 INFO  : gcache: Chunk Size: 16M
2019/06/28 22:15:58 INFO  : gcache: Chunk Total Size: 20G
2019/06/28 22:15:58 INFO  : gcache: Chunk Clean Interval: 1m0s
2019/06/28 22:15:58 INFO  : gcache: Workers: 4
2019/06/28 22:15:58 INFO  : gcache: File Age: 2d
```

## Constraints

It has only been tested with [kube-plex](https://github.com/munnerz/kube-plex) so far. There's still more work to be done to make it stable for other services e.g [Radarr](https://github.com/Radarr/Radarr) and [Sonarr](https://github.com/Sonarr/Sonarr/).

## Contributing

Please raise an issue or pull request if you have any issues, questions or features.

## Credits

Full credit list at: [https://github.com/zee-ahmed/kube-rclone/CREDITS.md](https://github.com/zee-ahmed/kube-rclone/blob/master/CREDITS.md)
