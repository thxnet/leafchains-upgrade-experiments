#!/usr/bin/env bash
# Wrapper to run nix-built v0.9.40 polkadot binary outside of nix develop shell.
set -euo pipefail

NIX_LD="/nix/store/3n58xw4373jp0ljirf06d8077j15pc4j-glibc-2.37-8/lib/ld-linux-x86-64.so.2"
NIX_LIBS="/nix/store/wmi7ifah7ggl9bah85zpmsgxv6lk04a7-zlib-1.2.13/lib:/nix/store/4l1wp6kyi2yz7krzq8lmz8fb9i18yplf-gcc-12.3.0-libgcc/lib:/nix/store/3n58xw4373jp0ljirf06d8077j15pc4j-glibc-2.37-8/lib"
POLKADOT="/home/raj/thxnet/rootchain/target/release/polkadot"

exec env LD_LIBRARY_PATH="${NIX_LIBS}" "${NIX_LD}" "${POLKADOT}" "$@"
