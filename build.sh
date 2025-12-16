#!/bin/sh
set -e

# Ensure Zig and Cosmocc are available.
# This script assumes they are in /tmp/zig and /tmp/cosmocc respectively,
# as per the environment setup. Adjust paths if necessary.
ZIG_EXE="/tmp/zig/zig"
COSMOCC_DIR="/tmp/cosmocc"
CC="$COSMOCC_DIR/bin/x86_64-unknown-cosmo-cc"
OBJCOPY="$COSMOCC_DIR/bin/x86_64-linux-cosmo-objcopy"

if [ ! -f "$ZIG_EXE" ]; then
    echo "Zig compiler not found at $ZIG_EXE. Please install Zig 0.13.0."
    exit 1
fi

if [ ! -d "$COSMOCC_DIR" ]; then
    echo "Cosmopolitan toolchain not found at $COSMOCC_DIR. Please install cosmocc 4.0.2."
    exit 1
fi

echo "Building hello.o with Zig..."
# We target x86_64-freestanding to avoid system libc dependencies.
# We use -lc to satisfy Zig's requirement for C ABI functions, but since we rely on Cosmopolitan
# for the actual implementation, we don't need Zig's libc.
# -fno-stack-check prevents Zig from emitting stack probe calls that might be missing in Cosmo.
$ZIG_EXE build-obj hello.zig -target x86_64-freestanding -fno-stack-check -lc -O ReleaseSmall

echo "Linking with Cosmopolitan..."
$CC -Os -o hello hello.o

echo "Creating APE..."
$OBJCOPY -SO binary hello hello.com

echo "Done! Run ./hello.com to test."
ls -lh hello.com
