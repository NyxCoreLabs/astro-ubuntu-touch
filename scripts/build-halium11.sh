#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

BASE="95aa6718350e3edfa32500df6d565b9dec049fc2"
KERNEL_REPO="${1:-$ROOT/../android_kernel_planetcom_mt6873}"
IMAGE="astro-kernel-lab:22.04"

CONFIG="$ROOT/config/halium11.config"

PATCHES=(
    "$ROOT/patches/0001-udi-sscanf-bounds.patch"
    "$ROOT/patches/0002-dpmaif-pointer-logging.patch"
    "$ROOT/patches/halium/0003-vt-selection-duplicate.patch"
)

echo "===== NYXCORELABS HALIUM 11 KERNEL BUILDER ====="

echo "===== VERIFY REQUIREMENTS ====="

for cmd in git tar sha256sum gzip docker; do
    command -v "$cmd" >/dev/null || {
        echo "STOP: Missing $cmd"
        exit 1
    }
done

test -s "$CONFIG" || {
    echo "STOP: Halium configuration missing"
    exit 1
}

for patch in "${PATCHES[@]}"; do
    test -s "$patch" || {
        echo "STOP: Missing patch $patch"
        exit 1
    }
done

git -C "$KERNEL_REPO" cat-file -e \
    "${BASE}^{commit}" 2>/dev/null || {
    echo "STOP: Pinned kernel revision unavailable"
    exit 1
}

echo "PASS: Build inputs available"

echo "===== VERIFY DOCKER TOOLCHAIN ====="

if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
else
    DOCKER=(sudo docker)
fi

if ! "${DOCKER[@]}" image inspect "$IMAGE" \
    >/dev/null 2>&1; then
    echo "STOP: Docker image not available"
    echo "Expected: $IMAGE"
    exit 1
fi

echo "===== CREATE FRESH BUILD WORKSPACE ====="

mkdir -p "$ROOT/out"

RUN_DIR="$(mktemp -d "$ROOT/out/halium11-build-XXXXXXXX")"

SOURCE="$RUN_DIR/source"
OUTPUT="$RUN_DIR/output"

mkdir -p "$SOURCE" "$OUTPUT"

cp "$CONFIG" "$RUN_DIR/halium11.config"

echo "Workspace: $RUN_DIR"

echo "===== EXPORT PINNED KERNEL SOURCE ====="

git -C "$KERNEL_REPO" archive "$BASE" |
    tar -xf - -C "$SOURCE"

echo "===== APPLY KERNEL PATCHES ====="

for patch in "${PATCHES[@]}"; do
    echo "Applying $(basename "$patch")"

    (
        cd "$SOURCE"

        export GIT_CEILING_DIRECTORIES="$ROOT"

        git apply --check "$patch"
        git apply "$patch"
        git apply --reverse --check "$patch"
    )

    echo "PASS: $(basename "$patch")"
done

echo "===== START HALIUM KERNEL BUILD ====="

"${DOCKER[@]}" run --rm -i \
    --network none \
    --user "$(id -u):$(id -g)" \
    --cpus=4 \
    --memory=8g \
    --mount "type=bind,src=$SOURCE,dst=/kernel,readonly" \
    --mount "type=bind,src=$RUN_DIR,dst=/work" \
    "$IMAGE" \
    bash -s <<'CONTAINER'

set -eu

MAKE_ARGS=(
    -C /kernel
    O=/work/output
    ARCH=arm64
    CROSS_COMPILE=aarch64-linux-gnu-
    CC=clang-14
    CLANG_TRIPLE=aarch64-linux-gnu-
    GCC_TOOLCHAIN_DIR=/usr/bin/aarch64-linux-gnu-
    GCC_TOOLCHAIN=/usr
)

echo "===== GENERATE ASTRO DEVICE CONFIG ====="

if ! make "${MAKE_ARGS[@]}" \
    k6873v1_64_defconfig \
    > /work/output/defconfig.log 2>&1; then

    tail -n 50 /work/output/defconfig.log
    exit 1
fi

echo "===== MERGE HALIUM CONFIGURATION ====="

if ! (
    cd /work/output

    KCONFIG_CONFIG=/work/output/.config \
        /kernel/scripts/kconfig/merge_config.sh \
        -m \
        /work/output/.config \
        /work/halium11.config

) > /work/output/merge.log 2>&1; then

    tail -n 50 /work/output/merge.log
    exit 1
fi

echo "===== RESOLVE KCONFIG DEPENDENCIES ====="

if ! make "${MAKE_ARGS[@]}" \
    olddefconfig \
    > /work/output/olddefconfig.log 2>&1; then

    tail -n 50 /work/output/olddefconfig.log
    exit 1
fi

echo "===== VERIFY HALIUM SETTINGS ====="

for option in \
    DEVTMPFS \
    FHANDLE \
    SYSVIPC \
    IPC_NS \
    NET_NS \
    PID_NS \
    USER_NS \
    UTS_NS \
    VT
do
    if grep -Fxq \
        "CONFIG_${option}=y" \
        /work/output/.config; then

        echo "PASS: CONFIG_${option}=y"

    else
        echo "STOP: CONFIG_${option} not enabled"
        exit 1
    fi
done

echo "===== COMPILE ARM64 IMAGE.GZ ====="

if ! make -j4 "${MAKE_ARGS[@]}" \
    KCFLAGS="-Wno-error=unused-but-set-variable -fno-builtin-stpcpy" \
    Image.gz \
    > /work/output/build.log 2>&1; then

    echo "STOP: Kernel compilation failed"
    tail -n 50 /work/output/build.log
    exit 1
fi

echo "===== VERIFY KERNEL ARTIFACT ====="

KERNEL=/work/output/arch/arm64/boot/Image.gz

test -s "$KERNEL"
gzip -t "$KERNEL"

echo "PASS: Halium kernel compiled"
echo "PASS: gzip integrity verified"

CONTAINER

ARTIFACT="$OUTPUT/arch/arm64/boot/Image.gz"

test -s "$ARTIFACT"
gzip -t "$ARTIFACT"

echo "===== RECORD BUILD MANIFEST ====="

{
    echo "Project: NyxCoreLabs Astro Ubuntu Touch"
    echo "Build: Experimental Halium 11 kernel candidate"
    echo "Pinned upstream revision: $BASE"
    echo "Docker image: $IMAGE"

    "${DOCKER[@]}" image inspect "$IMAGE" \
        --format 'Docker image ID: {{.Id}}'

    echo
    echo "Input configuration:"
    sha256sum "$RUN_DIR/halium11.config"

    echo
    echo "Kernel patches:"
    sha256sum "${PATCHES[@]}"

    echo
    echo "Resolved kernel configuration:"
    sha256sum "$OUTPUT/.config"

    echo
    echo "Kernel artifact:"
    sha256sum "$ARTIFACT"

} | tee "$RUN_DIR/build-manifest.txt"

echo
echo "===== BUILD COMPLETE ====="
echo "Artifact: $ARTIFACT"
echo "Manifest: $RUN_DIR/build-manifest.txt"

echo "PASS: HALIUM 11 KERNEL BUILD"
echo "NOTE: Kernel has not been boot-tested on hardware"
