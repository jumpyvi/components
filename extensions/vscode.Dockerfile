FROM alpine:edge AS downloader
RUN apk add --no-cache curl tar
WORKDIR /downloads

# Get latest
RUN curl -fsSL -o vscode.tar.gz https://update.code.visualstudio.com/latest/linux-x64/stable

RUN mkdir -p /rootfs/usr/lib/vscode /rootfs/usr/bin && \
    tar -xzf vscode.tar.gz -C /rootfs/usr/lib/vscode --strip-components=1 && \
    ln -sf ../lib/vscode/bin/code /rootfs/usr/bin/code

RUN chown root:root /rootfs/usr/lib/vscode/chrome-sandbox && \
    chmod 4755 /rootfs/usr/lib/vscode/chrome-sandbox

FROM alpine:edge AS builder
ENV SYSEXT_NAME=vscode
RUN apk add --no-cache erofs-utils zstd
COPY --from=downloader /rootfs /staging/
RUN V=$(date -u +%Y%m%d%H%M%S) && \
    mkdir -p /staging/usr/lib/extension-release.d && \
    printf 'ID=_any\nARCHITECTURE=x86-64\n' > /staging/usr/lib/extension-release.d/extension-release.${SYSEXT_NAME}_$V && \
    mkfs.erofs /${SYSEXT_NAME}_$V.raw /staging && \
    zstd -7 /${SYSEXT_NAME}_$V.raw

FROM scratch
COPY --from=builder /*.raw.zst /