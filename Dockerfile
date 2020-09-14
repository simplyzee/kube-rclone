FROM alpine:3.12

ENV RCLONE_VERSION 1.53.1

RUN apk add --no-cache --virtual=build-dependencies wget unzip && \
    cd tmp && \
    wget -q --no-check-certificate https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip && \
    unzip /tmp/rclone-v${RCLONE_VERSION}-linux-amd64.zip && \
    mv /tmp/rclone-v${RCLONE_VERSION}-linux-amd64/rclone /usr/bin

RUN apk -U add curl fuse ca-certificates && \
    rm -rf /var/cache/apk/*

RUN apk del --purge build-dependencies && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENTRYPOINT ["/usr/bin/rclone"]
