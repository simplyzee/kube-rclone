# The chart uses the official rclone image (rclone/rclone) by default, which
# already includes fuse3, ca-certificates and a shell. Build this only if you
# need to add your own tools on top, then set image.repository/image.tag.
#
#   docker build -t my-registry/kube-rclone:1.75.2 .
#
ARG RCLONE_VERSION=1.75.2
FROM rclone/rclone:${RCLONE_VERSION}

# Example: add extra packages here.
# RUN apk add --no-cache bash

ENTRYPOINT ["rclone"]
