FROM alpine:edge AS downloader
RUN apk add --no-cache curl tar
WORKDIR /downloads

RUN curl -fsSL -o xppen.tar.gz https://download01.xp-pen.com/file/2026/04/XPPenLinux4.0.15-260422.tar.gz && \
    mkdir src && tar -xzf xppen.tar.gz -C src --strip-components=1

RUN set -eux; \
    mkdir -p /rootfs/usr/share; \
    cp -a src/App/usr/. /rootfs/usr/; \
    mkdir -p /rootfs/usr/lib; \
    cp -a src/App/lib/. /rootfs/usr/lib/; \
    mv src/App/etc/xdg /rootfs/usr/share/xdg

# xppen writes to /usr/share/pentablet/, makes it a symlink to /var
RUN set -eux; \
    CONF=/rootfs/usr/lib/pentablet/conf; \
    mkdir -p /rootfs/usr/share/pentablet/conf-default /rootfs/usr/lib/sysusers.d /rootfs/usr/lib/tmpfiles.d; \
    cp -a "$CONF"/. /rootfs/usr/share/pentablet/conf-default/; rm -rf "$CONF"; \
    ln -s /var/lib/pentablet/conf "$CONF"; \
    printf 'C /var/lib/pentablet/conf 0777 root root - /usr/share/pentablet/conf-default\nZ /var/lib/pentablet/conf 0777 - - -\n' \
    > /rootfs/usr/lib/tmpfiles.d/pentablet.conf

FROM alpine:edge AS builder
ENV SYSEXT_NAME=xppen
RUN apk add --no-cache erofs-utils zstd
COPY --from=downloader /rootfs /staging/
RUN V=$(date -u +%Y%m%d%H%M%S) && \
    mkdir -p /staging/usr/lib/extension-release.d && \
    printf 'ID=_any\nARCHITECTURE=x86-64\n' > /staging/usr/lib/extension-release.d/extension-release.${SYSEXT_NAME}_$V && \
    mkfs.erofs /${SYSEXT_NAME}_$V.raw /staging && \
    zstd -7 /${SYSEXT_NAME}_$V.raw

FROM scratch
COPY --from=builder /*.raw.zst /