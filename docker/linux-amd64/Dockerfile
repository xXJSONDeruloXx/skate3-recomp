FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget gnupg lsb-release ca-certificates software-properties-common \
    && wget -q https://apt.llvm.org/llvm.sh -O /tmp/llvm.sh \
    && chmod +x /tmp/llvm.sh \
    && /tmp/llvm.sh 20 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        cmake ninja-build build-essential git curl unzip autoconf pkg-config zip \
        clang-20 lld-20 \
        libgtk-3-dev libx11-xcb-dev libvulkan-dev glslc glslang-tools \
        libasound2-dev libpulse-dev libpipewire-0.3-dev python3-venv \
    && rm -rf /var/lib/apt/lists/* /tmp/llvm.sh

ENV CC=/usr/bin/clang-20
ENV CXX=/usr/bin/clang++-20

WORKDIR /work
