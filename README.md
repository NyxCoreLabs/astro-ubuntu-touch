# Astro Ubuntu Touch

An experimental open-source development project by NyxCoreLabs.

## Mission

Bring Ubuntu Touch to the Planet Computers Astro Slide 5G
and contribute improvements to its Linux hardware support.

## Hardware

- Device: Planet Computers Astro Slide 5G
- SoC: MediaTek MT6873
- Architecture: ARM64
- Original OS: Android 11
- Kernel: Linux 4.14.186
- Target: Ubuntu Touch / Halium 11

## Development Environment

- Ubuntu Linux development workstation
- Docker-based ARM64 kernel builder
- Clang/LLVM cross-compilation
- Git-controlled kernel patches

## Current Status

EXPERIMENTAL — Ubuntu Touch is not yet booting.

Completed:
- Kernel source identification
- Docker build environment
- ARM64 compiler configuration
- UDI input-bounds correction (compilation verified)
- DPMAIF pointer-format correction (compilation verified)

In progress:
- Full kernel compilation
- Toolchain compatibility
- Halium integration

Not yet verified:
- Ubuntu Touch boot
- Display and keyboard functionality
- Wi-Fi and Bluetooth
- Cellular data, VoLTE, and SMS
- Suspend/resume and battery management

## Upstream

Kernel:
https://github.com/planet-community/android_kernel_planetcom_mt6873

Community build tools:
https://github.com/planet-community/android_build_planetcom_kernel

## Contributions

Contributions and technical discussion are welcome.

Experimental software. No working device images are
currently provided.
