FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bc \
        binutils-aarch64-linux-gnu \
        bison \
        build-essential \
        ca-certificates \
        clang-14 \
        cpio \
        file \
        flex \
        gcc-aarch64-linux-gnu \
        git \
        libelf-dev \
        libncurses-dev \
        libssl-dev \
        lld-14 \
        llvm-14 \
        python3 \
        python-is-python3 \
        rsync \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

ENV ARCH=arm64

WORKDIR /work
