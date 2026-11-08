FROM alpine:edge AS downloader

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl gpg ca-certificates binutils xz-utils zstd && \
    curl -fsSL https://repo.nordvpn.com/gpg/nordvpn_public.asc | gpg --dearmor -o /usr/share/keyrings/nordvpn-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nordvpn-archive-keyring.gpg arch=amd64] https://repo.nordvpn.com/deb/nordvpn/debian stable main" > /etc/apt/sources.list.d/nordvpn.list

WORKDIR /downloads

RUN apt-get update && \
    apt-get download nordvpn nordvpn-gui

RUN set -eux; \
    mkdir -p /rootfs /tmp/deb; \
    for deb in /downloads/*.deb; do \
    (cd /tmp/deb && ar x "$deb" && tar -xf data.tar.* -C /rootfs && rm -f *); \
    done

RUN mv /rootfs/opt/nordvpn-gui /rootfs/usr/lib/nordvpn-gui && \
    rmdir /rootfs/opt && \
    mkdir -p /rootfs/usr/bin && \
    ln -sf ../lib/nordvpn-gui/nordvpn-gui /rootfs/usr/bin/nordvpn-gui

FROM scratch
COPY --from=downloader /rootfs/ /