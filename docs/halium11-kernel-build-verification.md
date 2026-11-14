# Astro Slide 5G — Halium 11 Kernel Build Verification

Project: NyxCoreLabs Astro Ubuntu Touch

Status: Experimental kernel build milestone verified.

Hardware boot status: NOT TESTED.

## 1. Objective

Establish separate, repeatable ARM64 kernel build procedures
for the Astro Slide 5G Android baseline and experimental
Halium 11 configuration.

## 2. Kernel Source

Upstream:
planet-community/android_kernel_planetcom_mt6873

Pinned revision:

95aa6718350e3edfa32500df6d565b9dec049fc2

Architecture: ARM64

Kernel version: Linux 4.14.186

Device defconfig: k6873v1_64_defconfig

## 3. Build Environment

Docker image:

astro-kernel-lab:22.04

Verified Docker image ID:

sha256:2ceb1cc223116c0f99d3ba649099326ee86d79b8ef45e276de569876768af043

Compiler: Clang 14

Cross-toolchain: aarch64-linux-gnu

## 4. Android Baseline

Builder:

scripts/build-kernel.sh

Kernel corrections:

- 0001-udi-sscanf-bounds.patch
- 0002-dpmaif-pointer-logging.patch

Verified configuration SHA256:

232c7a4e6b69cfdf45a843f34ea5848de29cb314ab8d6fa6d0a90163b3dd397d

Regression-build Image.gz SHA256:

fd681079464b4513a77126b5ec62870f9653a392700588b02ee96401f98a1aa8

Result:

Clean automated build PASS.
Configuration checksum reproduced.
Kernel gzip integrity PASS.

## 5. Experimental Halium 11 Candidate

Builder:

scripts/build-halium11.sh

Additional kernel correction:

patches/halium/0003-vt-selection-duplicate.patch

Configuration fragment:

config/halium11.config

Nine verified settings:

- CONFIG_DEVTMPFS=y
- CONFIG_FHANDLE=y
- CONFIG_SYSVIPC=y
- CONFIG_IPC_NS=y
- CONFIG_NET_NS=y
- CONFIG_PID_NS=y
- CONFIG_USER_NS=y
- CONFIG_UTS_NS=y
- CONFIG_VT=y

Verified resolved configuration SHA256:

f1d453687e16b0ce1d45620bb6c7cb4a1778a8c489a17b7a5e38f56dce17690a

Automated-build Image.gz SHA256:

cbdf7658bd7930e3a0de9ce13cf3cc6ecff790a6f7a6ed276f660b4f822812cf

Result:

Clean-source automated build PASS.
All nine settings enabled.
Configuration checksum reproduced.
Kernel gzip integrity PASS.

## 6. Kernel Source Correction

Enabling virtual terminals exposed two definitions of
set_selection() in drivers/tty/vt/selection.c.

The duplicate implementation lacking sel_lock was removed.

The mutex-protected implementation was retained.

Patch verification:

- Applies to pinned upstream source.
- Matches corrected Halium source.
- Removes 11 lines.
- Passes source whitespace validation.

## 7. Verified Build Commands

From the repository root:

Android baseline:

    ./scripts/build-kernel.sh

Experimental Halium 11 candidate:

    ./scripts/build-halium11.sh

Both builders require the pinned upstream kernel revision
and the configured Docker toolchain.

Outputs and manifests are stored in separate directories
under out/.

## 8. Limitations

This milestone demonstrates kernel compilation only.

It does not establish:

- Successful physical device boot.
- Full Halium compatibility.
- Working Ubuntu Touch userspace.
- Functional display, keyboard, modem, or sensors.
- Verified recovery or flashing procedures.
- Bit-for-bit reproducible kernel binaries.

The Halium configuration is an initial candidate.
Additional compatibility and security review is required.

No device partitions were modified during this milestone.

## 9. Next Development Gates

1. Review and integrate verified source files.
2. Confirm Android baseline remains unaffected.
3. Audit broader Halium 11 requirements.
4. Develop device-specific userspace integration.
5. Verify device recovery and firmware compatibility.
6. Authorize physical boot testing separately.
