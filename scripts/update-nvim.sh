#!/bin/bash
set -e

BUILDDIR=$(mktemp -d)
trap 'rm -rf "$BUILDDIR"' EXIT

echo "Cloning neovim stable..."
git clone --depth 1 --branch stable https://github.com/neovim/neovim.git "$BUILDDIR"

echo "Building..."
make -C "$BUILDDIR" CMAKE_BUILD_TYPE=Release

echo "Installing (requires sudo)..."
sudo make -C "$BUILDDIR" install

echo "Done: $(nvim --version | head -1)"
