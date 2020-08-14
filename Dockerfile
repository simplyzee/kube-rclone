FROM alpine:3.12

RUN apk add --no-cache --virtual=build-dependencies wget unzip && \
cd tmp && wget -q --no-check-certificate http://downloads.rclone.org/v1.52.3/rclone-v1.52.3-linux-amd64.zip && \
unzip /tmp/rclone-v1.52.3-linux-amd64.zip && mv /tmp/rclone-v1.52.3-linux-amd64/rclone /usr/bin

RUN apk -U add curl fuse ca-certificates && rm -rf /var/cache/apk/*
RUN apk del --purge build-dependencies && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENTRYPOINT [ "/usr/bin/rclone" ]
