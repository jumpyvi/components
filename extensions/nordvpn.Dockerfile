FROM debian:trixie AS downloader

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
    rm -rf /rootfs/opt /rootfs/etc && \
    mkdir -p /rootfs/usr/bin && \
    ln -sf ../lib/nordvpn-gui/nordvpn-gui /rootfs/usr/bin/nordvpn-gui

RUN for f in /rootfs/usr/lib/nordvpn/*.so; do \
    ln -sf nordvpn/$(basename "$f") /rootfs/usr/lib/$(basename "$f"); \
    done

RUN mkdir -p /rootfs/usr/lib/sysusers.d && \
    echo 'g nordvpn -' > /rootfs/usr/lib/sysusers.d/nordvpn.conf

FROM alpine:edge AS builder
ENV SYSEXT_NAME=nordvpn
RUN apk add --no-cache curl erofs-utils bash zstd
RUN curl -fsSL https://raw.githubusercontent.com/tulilirockz/sysextbuddy/main/sysextbuddy \
    -o /usr/local/bin/sysextbuddy && chmod +x /usr/local/bin/sysextbuddy
COPY --from=downloader /rootfs /staging/
WORKDIR /staging/
RUN sysextbuddy --name="${SYSEXT_NAME}_$(date -u +%Y%m%d%H%M%S)" /staging/
RUN zstd -7 /staging/*.raw

FROM scratch
COPY --from=builder /staging/*.raw.zst /