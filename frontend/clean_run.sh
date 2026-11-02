#!/bin/bash

# Exit on error
set -e

# Add log level selector with default to INFO
LOG_LEVEL=${1:-info}

case $LOG_LEVEL in
    info|debug|trace)
        export RUST_LOG=$LOG_LEVEL
        ;;
    *)
        echo "Invalid log level: $LOG_LEVEL. Valid options: info, debug, trace"
        exit 1
        ;;
esac

# Clean up previous builds
echo "Cleaning up previous builds..."
#rm -rf target/
#rm -rf src-tauri/target
#rm -rf src-tauri/gen

# Clean up npm, pnp and next
echo "Cleaning up npm, pnp and next..."
rm -rf node_modules
rm -rf .next
rm -rf .pnp.cjs
rm -rf out

echo "Installing dependencies..."
pnpm install

# Build the Next.js application first
echo "Building Next.js application..."
pnpm run build

# Set environment variables for the build
echo "Setting up build environment..."

# tauri.conf.json bundles binaries/llama-helper as a sidecar; tauri dev fails without it
echo "Building llama-helper sidecar..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LLAMA_FEATURES=""
[[ "$OSTYPE" == "darwin"* && "$(uname -m)" == "arm64" ]] && LLAMA_FEATURES="--features metal"
(cd "$SCRIPT_DIR/../llama-helper" && cargo build $LLAMA_FEATURES)
TARGET_TRIPLE=$(rustc -vV | awk '/host:/{print $2}')
mkdir -p "$SCRIPT_DIR/src-tauri/binaries"
cp "$SCRIPT_DIR/../target/debug/llama-helper" "$SCRIPT_DIR/src-tauri/binaries/llama-helper-$TARGET_TRIPLE"

echo "Building Tauri app..."
pnpm run tauri dev
sleep

