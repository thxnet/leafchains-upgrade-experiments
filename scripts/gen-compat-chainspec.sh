#!/usr/bin/env bash
# Generate a chain spec for binary compatibility testing:
# v0.9.43 binary + v0.9.40 runtime WASM
#
# This creates a chain spec where the genesis :code is the OLD v0.9.40 runtime
# but the binary running the chain is v0.9.43. This tests the "node-only upgrade"
# scenario where operators upgrade their binaries before the runtime is upgraded.
#
# Usage:
#   ./scripts/gen-compat-chainspec.sh
#
# Output:
#   ./scripts/thxnet-local-compat.json  (raw chain spec with v0.9.40 WASM)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLKADOT_WRAPPER="${SCRIPT_DIR}/polkadot-wrapper.sh"

# v0.9.40 WASM paths (built from old repos)
OLD_ROOTCHAIN_WASM="/home/raj/thxnet/rootchain/target/release/wbuild/thxnet-runtime/thxnet_runtime.compact.compressed.wasm"

OUTPUT="${SCRIPT_DIR}/thxnet-local-compat.json"
TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_WORK}"' EXIT

echo "=== Binary Compatibility Chain Spec Generator ==="
echo ""

# Verify inputs exist
if [[ ! -x "${POLKADOT_WRAPPER}" ]]; then
    echo "ERROR: polkadot-wrapper.sh not found at ${POLKADOT_WRAPPER}"
    exit 1
fi

if [[ ! -f "${OLD_ROOTCHAIN_WASM}" ]]; then
    echo "ERROR: v0.9.40 rootchain WASM not found at ${OLD_ROOTCHAIN_WASM}"
    echo "Build it first: cd /home/raj/thxnet/rootchain && nix develop --command bash -c 'cargo build --release --package thxnet-runtime'"
    exit 1
fi

echo "1. Generating v0.9.43 raw chain spec (thxnet-local)..."
"${POLKADOT_WRAPPER}" build-spec --chain thxnet-local --raw --disable-default-bootnode 2>/dev/null > "${TMPDIR_WORK}/spec.json"

echo "2. Encoding v0.9.40 WASM ($(wc -c < "${OLD_ROOTCHAIN_WASM}") bytes) as hex..."
# Write hex-encoded WASM to a file (too large for command-line arg)
printf '0x' > "${TMPDIR_WORK}/wasm.hex"
xxd -p "${OLD_ROOTCHAIN_WASM}" | tr -d '\n' >> "${TMPDIR_WORK}/wasm.hex"

echo "3. Replacing genesis :code with v0.9.40 WASM..."

cat > "${TMPDIR_WORK}/replace_code.py" << 'PYEOF'
import json, sys, os

spec_path = os.environ['SPEC_PATH']
wasm_hex_path = os.environ['WASM_HEX_PATH']
output_path = os.environ['OUTPUT_PATH']

with open(spec_path, 'r') as f:
    spec = json.load(f)

with open(wasm_hex_path, 'r') as f:
    wasm_hex = f.read().strip()

# In raw chain spec, genesis.raw.top has hex-encoded storage keys
# ':code' hex-encoded is '0x3a636f6465'
code_key = '0x3a636f6465'
if code_key in spec['genesis']['raw']['top']:
    old_len = len(spec['genesis']['raw']['top'][code_key])
    spec['genesis']['raw']['top'][code_key] = wasm_hex
    new_len = len(spec['genesis']['raw']['top'][code_key])
    print(f'   Replaced :code ({old_len} hex chars -> {new_len} hex chars)')
else:
    print('ERROR: :code key not found in chain spec', file=sys.stderr)
    sys.exit(1)

# Update the name to indicate this is a compat test spec
spec['name'] = 'THXNet Local (v0.9.40 compat test)'

with open(output_path, 'w') as f:
    json.dump(spec, f, indent=2)
PYEOF

SPEC_PATH="${TMPDIR_WORK}/spec.json" \
WASM_HEX_PATH="${TMPDIR_WORK}/wasm.hex" \
OUTPUT_PATH="${OUTPUT}" \
python3 "${TMPDIR_WORK}/replace_code.py"

echo "4. Chain spec written to: ${OUTPUT}"
echo "   Size: $(wc -c < "${OUTPUT}") bytes"
echo ""
echo "Done. Use this chain spec with zombienet:"
echo "  export RELAY_CHAIN_SPEC=${OUTPUT}"
echo "  zombienet spawn scripts/zombienet-compat-0.9.40-on-0.9.43.toml"
