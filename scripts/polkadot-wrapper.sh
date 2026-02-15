#!/usr/bin/env bash
# Wrapper to run nix-built polkadot binary outside of nix develop shell.
# The binary links against nix store glibc/libz, so we invoke it via the nix ld-linux.
set -euo pipefail

NIX_LD="/nix/store/pf5avvvl4ssd6kylcvg2g23hcjp71h19-glibc-2.39-52/lib/ld-linux-x86-64.so.2"
NIX_LIBS="/nix/store/f2q5ld1nipl8w1r2w8m6azhlm2varqgb-zlib-1.3.1/lib:/nix/store/90yn7340r8yab8kxpb0p7y0c9j3snjam-gcc-13.2.0-lib/lib"
POLKADOT="/home/raj/thxnet/rootchain-upgrade-experiments/target/release/polkadot"

exec env LD_LIBRARY_PATH="${NIX_LIBS}" "${NIX_LD}" "${POLKADOT}" "$@"
