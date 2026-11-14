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

## License

Original NyxCoreLabs development tools and documentation
in this repository are licensed under GPL-2.0-only.

Kernel patches modify GPLv2-licensed Linux kernel sources
and retain the applicable upstream licensing requirements.

The upstream kernel, external dependencies, and third-party
tools retain their respective licenses and copyrights.

See LICENSE for the GPL version 2 license text.

## Build Checkpoints

- [Build Checkpoint 001](docs/build-checkpoint-001.md) —
  First successful ARM64 kernel compilation.
  Device boot remains untested.
