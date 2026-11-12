FROM debian:bookworm-slim AS heimdall-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    ca-certificates \
    autoconf \
    automake \
    libtool \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Build static libusb
RUN git clone --depth 1 https://github.com/libusb/libusb.git && \
    cd libusb && \
    NOCONFIGURE=1 ./autogen.sh && \
    ./configure --enable-static --disable-shared --disable-udev --prefix=/opt/libusb-static && \
    make -j$(nproc) && \
    make install

# Build heimdall
RUN git clone --depth 1 https://github.com/Benjamin-Dobell/Heimdall.git && \
    mkdir -p Heimdall/build && cd Heimdall/build && \
    PKG_CONFIG_PATH=/opt/libusb-static/lib/pkgconfig cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DDISABLE_FRONTEND=ON \
    -Dlibusb_USE_STATIC_LIBS=YES \
    -DLIBUSB_INCLUDE_DIR=/opt/libusb-static/include/libusb-1.0 \
    -DLIBUSB_LIBRARY=/opt/libusb-static/lib/libusb-1.0.a \
    -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" && \
    make -j$(nproc) heimdall && \
    strip bin/heimdall

FROM alpine:edge AS downloader

RUN apk add --no-cache curl jq tar

WORKDIR /downloads

# Add scrcpy (comes with adb ootb)
RUN SCRCPY_URL=$(curl -fsSL https://api.github.com/repos/Genymobile/scrcpy/releases/latest \
    | jq -r '.assets[] | select(.name | test("scrcpy-linux-x86_64-.*\\.tar\\.gz$")) | .browser_download_url') && \
    curl -fsSL -o scrcpy.tar.gz "$SCRCPY_URL"

# Assemble rootfs layout
RUN mkdir -p /rootfs/usr/lib/scrcpy /rootfs/usr/bin /rootfs/usr/lib/udev/rules.d && \
    tar -xzf scrcpy.tar.gz -C /rootfs/usr/lib/scrcpy --strip-components=1 && \
    ln -sf ../lib/scrcpy/scrcpy /rootfs/usr/bin/scrcpy && \
    ln -sf ../lib/scrcpy/adb /rootfs/usr/bin/adb

# Copy compiled Heimdall binary
COPY --from=heimdall-builder /src/Heimdall/build/bin/heimdall /rootfs/usr/bin/heimdall
RUN chmod 0755 /rootfs/usr/bin/heimdall

# Add udev rules for ADB
RUN printf '%s\n' \
    '# Samsung (Heimdall)' \
    'SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev", TAG+="uaccess"' \
    '# ADB & Fastboot' \
    'SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev", TAG+="uaccess"' \
    > /rootfs/usr/lib/udev/rules.d/51-android-heimdall.rules

FROM alpine:edge AS builder

ENV SYSEXT_NAME=androidtools
RUN apk add --no-cache erofs-utils zstd

COPY --from=downloader /rootfs /staging/

RUN V=$(date -u +%Y%m%d%H%M%S) && \
    mkdir -p /staging/usr/lib/extension-release.d && \
    printf 'ID=_any\nARCHITECTURE=x86-64\n' > /staging/usr/lib/extension-release.d/extension-release.${SYSEXT_NAME}_$V && \
    mkfs.erofs /${SYSEXT_NAME}_$V.raw /staging && \
    zstd -7 /${SYSEXT_NAME}_$V.raw

FROM scratch
COPY --from=builder /*.raw.zst /