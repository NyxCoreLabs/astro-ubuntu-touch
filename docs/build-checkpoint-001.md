# Astro Kernel — Build Checkpoint 001

**Project:** NyxCoreLabs Astro Ubuntu Touch  
**Date:** November 13, 2026  
**Status:** Kernel compilation successful; device boot untested.

## Objective

Compile a complete ARM64 Linux kernel for the
Planet Computers Astro Slide 5G using a containerized
development environment.

## Source

Upstream repository:
https://github.com/planet-community/android_kernel_planetcom_mt6873

Base revision:

95aa6718350e3edfa32500df6d565b9dec049fc2

Board configuration:

arch/arm64/configs/k6873v1_64_defconfig

## Applied Kernel Patches

1. `patches/0001-udi-sscanf-bounds.patch`
2. `patches/0002-dpmaif-pointer-logging.patch`

Both patches were applied to the base revision
and validated before the successful combined build.

## Build Environment

- Host: Ubuntu Linux
- Container base: Ubuntu 22.04
- Compiler: Clang 14.0.0
- Cross-compiler: GCC 11.4.0
- Binutils: 2.38
- Architecture: ARM64

Docker image ID:

sha256:2ceb1cc223116c0f99d3ba649099326ee86d79b8ef45e276de569876768af043

## Compiler Compatibility Flags

KCFLAGS="-Wno-error=unused-but-set-variable -fno-builtin-stpcpy"

The first flag allows compilation past an existing
unused-variable diagnostic.

The second prevents Clang from introducing unresolved
stpcpy references during kernel compilation.

These flags require further review before upstream submission.

## Kernel Configuration

CONFIG_ARM64=y
CONFIG_LOCALVERSION=""
CONFIG_CC_STACKPROTECTOR_STRONG=y

Configuration SHA256:

232c7a4e6b69cfdf45a843f34ea5848de29cb314ab8d6fa6d0a90163b3dd397d

## Build Result

Target:

Image.gz

Result:

PASS — Complete ARM64 kernel image generated.

Kernel image SHA256:

017e61155cf2ba32ebdcec91e88dd599f4e0b85ec6e8d6498f989d7486fb650e

The generated image passed gzip integrity verification.

The output was approximately 10 MiB compressed.

## Remaining Warnings

- GNU objdump reported unrecognized DWARF forms.
- Container UID lookup produced a nonfatal whoami warning.

Neither prevented completion of this build.

## Limitations

This result establishes successful kernel compilation only.

It does not establish:

- Successful boot on Astro hardware
- Boot-image packaging compatibility
- Halium compatibility
- Ubuntu Touch functionality
- Working cellular modem or other hardware
- Reproducibility on an independent development machine

No device flashing was performed.

The kernel artifact is not a verified device-ready image.

## Next Objectives

1. Create and test a reusable kernel build script.
2. Verify a clean build from the published sources.
3. Investigate boot-image packaging and device trees.
4. Evaluate Halium requirements.
5. Prepare a controlled hardware boot experiment.
