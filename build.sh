#!/bin/bash
set -e

# Build the binary with size optimizations (no UPX)
echo "Building static binary..."
CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o fetch fetch.go

echo "Done. Binary size:"
ls -lh fetch
