#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

BASE="95aa6718350e3edfa32500df6d565b9dec049fc2"
KERNEL_REPO="${1:-$ROOT/../android_kernel_planetcom_mt6873}"
IMAGE="astro-kernel-lab:22.04"

echo "===== NYXCORELABS ASTRO KERNEL BUILDER ====="

# Verify prerequisites.
for command in git tar sha256sum gzip; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "ERROR: Missing command: $command"
        exit 1
    fi
done

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    exit 1
fi

if ! git -C "$KERNEL_REPO" cat-file -e \
    "${BASE}^{commit}" 2>/dev/null; then
    echo "ERROR: Required upstream kernel revision unavailable."
    echo "Expected: $BASE"
    echo "Repository: $KERNEL_REPO"
    exit 1
fi

# Support both rootless Docker access and sudo Docker.
if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
else
    DOCKER=(sudo docker)
fi

if ! "${DOCKER[@]}" image inspect "$IMAGE" \
    >/dev/null 2>&1; then

    echo "===== BUILDING DOCKER IMAGE ====="

    "${DOCKER[@]}" build \
        -t "$IMAGE" \
        -f "$ROOT/builder/Dockerfile" \
        "$ROOT/builder"
fi

echo "===== CREATING ISOLATED WORKSPACE ====="

mkdir -p "$ROOT/out"

RUN_DIR="$(mktemp -d "$ROOT/out/build-XXXXXXXX")"

SOURCE="$RUN_DIR/source"
OUTPUT="$RUN_DIR/output"

mkdir -p "$SOURCE" "$OUTPUT"

echo "Workspace: $RUN_DIR"

echo "===== EXPORTING PINNED KERNEL SOURCE ====="

git -C "$KERNEL_REPO" archive "$BASE" |
    tar -xf - -C "$SOURCE"

echo "===== APPLYING PUBLISHED PATCHES ====="

for patch in "$ROOT"/patches/*.patch; do
    echo "Checking $(basename "$patch")"

    (
        cd "$SOURCE"

        # Prevent Git from discovering the parent lab repository.
        export GIT_CEILING_DIRECTORIES="$ROOT"

        git apply --check "$patch"
        git apply --verbose "$patch"

        # Verify that the patch is actually present.
        git apply --reverse --check "$patch"
    )
done

echo "===== STARTING DOCKER KERNEL BUILD ====="

"${DOCKER[@]}" run --rm -i \
    --user "$(id -u):$(id -g)" \
    --cpus=4 \
    --memory=8g \
    --mount "type=bind,src=$SOURCE,dst=/kernel,readonly" \
    --mount "type=bind,src=$OUTPUT,dst=/work/out" \
    "$IMAGE" \
    bash -s <<'CONTAINER'

set -eu

MAKE_ARGS=(
    -C /kernel
    O=/work/out
    ARCH=arm64
    CROSS_COMPILE=aarch64-linux-gnu-
    CC=clang-14
    CLANG_TRIPLE=aarch64-linux-gnu-
    GCC_TOOLCHAIN_DIR=/usr/bin/aarch64-linux-gnu-
    GCC_TOOLCHAIN=/usr
)

echo "===== GENERATING DEVICE CONFIG ====="

if ! make "${MAKE_ARGS[@]}" \
    k6873v1_64_defconfig \
    > /work/out/config.log 2>&1; then

    tail -n 40 /work/out/config.log
    exit 1
fi

echo "===== COMPILING ARM64 IMAGE.GZ ====="

if ! make -j4 "${MAKE_ARGS[@]}" \
    KCFLAGS="-Wno-error=unused-but-set-variable -fno-builtin-stpcpy" \
    Image.gz \
    > /work/out/kernel-build.log 2>&1; then

    echo "FAIL: Kernel compilation"
    tail -n 50 /work/out/kernel-build.log
    exit 1
fi

echo "===== VERIFYING KERNEL ====="

file /work/out/arch/arm64/boot/Image.gz

gzip -t /work/out/arch/arm64/boot/Image.gz

echo "PASS: Kernel compiled and gzip integrity verified"

CONTAINER

ARTIFACT="$OUTPUT/arch/arm64/boot/Image.gz"

echo "===== RECORDING BUILD FINGERPRINT ====="

{
    echo "Project: NyxCoreLabs Astro Ubuntu Touch"
    echo "Base revision: $BASE"
    echo "Docker image: $IMAGE"

    "${DOCKER[@]}" image inspect "$IMAGE" \
        --format 'Docker image ID: {{.Id}}'

    echo
    echo "Kernel configuration:"
    sha256sum "$OUTPUT/.config"

    echo
    echo "Kernel artifact:"
    sha256sum "$ARTIFACT"

} | tee "$RUN_DIR/build-manifest.txt"

echo
echo "===== BUILD COMPLETE ====="
echo "Artifact: $ARTIFACT"
echo "Manifest: $RUN_DIR/build-manifest.txt"
echo "PASS: Astro ARM64 kernel build"
