FROM mcr.microsoft.com/devcontainers/base:jammy
LABEL org.opencontainers.image.source="https://github.com/n-i-x/pico-sdk-dev-container"

ENV PICO_SDK_VERSION=2.2.0

RUN apt update \
    && apt install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    libusb-1.0-0-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* /var/log/apt/* /var/log/dpkg.log /var/log/alternatives.log /var/cache/

# Clone Pico SDK first (required by picotool)
RUN git clone -b ${PICO_SDK_VERSION} https://github.com/raspberrypi/pico-sdk.git /opt/pico-sdk \
    && git -C /opt/pico-sdk submodule update --init

ENV PICO_SDK_PATH=/opt/pico-sdk

# Build and install picotool to avoid SDK build warnings
RUN git clone -b ${PICO_SDK_VERSION} https://github.com/raspberrypi/picotool.git /tmp/picotool \
    && mkdir /tmp/picotool/build && cd /tmp/picotool/build \
    && cmake .. \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/picotool

# Build Pico SDK
RUN mkdir /opt/pico-sdk/build \
    && cd /opt/pico-sdk/build \
    && cmake ..
