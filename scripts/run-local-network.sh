#!/bin/bash
# Manual script to run local development network
# This is an alternative to zombienet for manual control
#
# Usage:
#   ./scripts/run-local-network.sh
#
# Prerequisites:
#   - Build rootchain: cd ../rootchain && cargo build --release
#   - Build leafchain: cargo build --release

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEAFCHAIN_DIR="$(dirname "$SCRIPT_DIR")"
ROOTCHAIN_DIR="$(dirname "$LEAFCHAIN_DIR")/rootchain"

RELAY_BIN="$ROOTCHAIN_DIR/target/release/polkadot"
COLLATOR_BIN="$LEAFCHAIN_DIR/target/release/thxnet-leafchain"

# Check binaries exist
if [ ! -f "$RELAY_BIN" ]; then
    echo "Error: Relay chain binary not found at $RELAY_BIN"
    echo "Please build the rootchain first:"
    echo "  cd $ROOTCHAIN_DIR && cargo build --release"
    exit 1
fi

if [ ! -f "$COLLATOR_BIN" ]; then
    echo "Error: Collator binary not found at $COLLATOR_BIN"
    echo "Please build the leafchain first:"
    echo "  cd $LEAFCHAIN_DIR && cargo build --release"
    exit 1
fi

# Create base directory for chain data
BASE_DIR="/tmp/local-parachain-test"
rm -rf "$BASE_DIR"
mkdir -p "$BASE_DIR"

echo "=== Starting Local Parachain Network ==="
echo "Base directory: $BASE_DIR"
echo ""

# Function to run a command in background and log
run_bg() {
    local name=$1
    local logfile="$BASE_DIR/$name.log"
    shift
    echo "Starting $name (log: $logfile)"
    "$@" > "$logfile" 2>&1 &
    echo $! > "$BASE_DIR/$name.pid"
}

# ===== RELAY CHAIN =====
echo "--- Starting Relay Chain Validators ---"

# Alice - Relay Validator 1
run_bg "relay-alice" "$RELAY_BIN" \
    --alice \
    --validator \
    --base-path "$BASE_DIR/relay-alice" \
    --chain thxnet-local \
    --port 30333 \
    --rpc-port 9944 \
    --rpc-cors all \
    --unsafe-rpc-external

sleep 2

# Bob - Relay Validator 2
run_bg "relay-bob" "$RELAY_BIN" \
    --bob \
    --validator \
    --base-path "$BASE_DIR/relay-bob" \
    --chain thxnet-local \
    --port 30334 \
    --rpc-port 9945 \
    --rpc-cors all \
    --unsafe-rpc-external \
    --bootnodes "/ip4/127.0.0.1/tcp/30333/p2p/$(cat $BASE_DIR/relay-alice.log 2>/dev/null | grep 'Local node identity' | head -1 | sed 's/.*: //' || echo 'pending')"

echo "Waiting for relay chain to start producing blocks..."
sleep 10

# ===== LEAFCHAIN A (Para ID 2000) =====
echo ""
echo "--- Exporting genesis for LeafchainA (Para ID 2000) ---"

# Export genesis state and wasm
"$COLLATOR_BIN" export-genesis-state --chain leafchain-a-local > "$BASE_DIR/leafchain-a-genesis-state"
"$COLLATOR_BIN" export-genesis-wasm --chain leafchain-a-local > "$BASE_DIR/leafchain-a-genesis-wasm"

echo ""
echo "--- Starting LeafchainA Collators ---"

# Alice collator for LeafchainA
run_bg "leafchain-a-alice" "$COLLATOR_BIN" \
    --alice \
    --collator \
    --force-authoring \
    --base-path "$BASE_DIR/leafchain-a-alice" \
    --chain leafchain-a-local \
    --port 31333 \
    --rpc-port 9946 \
    --rpc-cors all \
    --unsafe-rpc-external \
    -- \
    --chain thxnet-local \
    --port 31334 \
    --rpc-port 9947 \
    --bootnodes "/ip4/127.0.0.1/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp"

sleep 2

# Bob collator for LeafchainA
run_bg "leafchain-a-bob" "$COLLATOR_BIN" \
    --bob \
    --collator \
    --force-authoring \
    --base-path "$BASE_DIR/leafchain-a-bob" \
    --chain leafchain-a-local \
    --port 31335 \
    --rpc-port 9948 \
    --rpc-cors all \
    --unsafe-rpc-external \
    -- \
    --chain thxnet-local \
    --port 31336 \
    --rpc-port 9949 \
    --bootnodes "/ip4/127.0.0.1/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp"

# ===== LEAFCHAIN B (Para ID 2001) =====
echo ""
echo "--- Exporting genesis for LeafchainB (Para ID 2001) ---"

"$COLLATOR_BIN" export-genesis-state --chain leafchain-b-local > "$BASE_DIR/leafchain-b-genesis-state"
"$COLLATOR_BIN" export-genesis-wasm --chain leafchain-b-local > "$BASE_DIR/leafchain-b-genesis-wasm"

echo ""
echo "--- Starting LeafchainB Collators ---"

# Charlie collator for LeafchainB
run_bg "leafchain-b-charlie" "$COLLATOR_BIN" \
    --charlie \
    --collator \
    --force-authoring \
    --base-path "$BASE_DIR/leafchain-b-charlie" \
    --chain leafchain-b-local \
    --port 32333 \
    --rpc-port 9950 \
    --rpc-cors all \
    --unsafe-rpc-external \
    -- \
    --chain thxnet-local \
    --port 32334 \
    --rpc-port 9951 \
    --bootnodes "/ip4/127.0.0.1/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp"

sleep 2

# Dave collator for LeafchainB
run_bg "leafchain-b-dave" "$COLLATOR_BIN" \
    --dave \
    --collator \
    --force-authoring \
    --base-path "$BASE_DIR/leafchain-b-dave" \
    --chain leafchain-b-local \
    --port 32335 \
    --rpc-port 9952 \
    --rpc-cors all \
    --unsafe-rpc-external \
    -- \
    --chain thxnet-local \
    --port 32336 \
    --rpc-port 9953 \
    --bootnodes "/ip4/127.0.0.1/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp"

echo ""
echo "=== Network Started ==="
echo ""
echo "RPC Endpoints:"
echo "  Relay Chain (Alice): ws://127.0.0.1:9944"
echo "  Relay Chain (Bob):   ws://127.0.0.1:9945"
echo "  LeafchainA (Alice):  ws://127.0.0.1:9946"
echo "  LeafchainA (Bob):    ws://127.0.0.1:9948"
echo "  LeafchainB (Charlie): ws://127.0.0.1:9950"
echo "  LeafchainB (Dave):    ws://127.0.0.1:9952"
echo ""
echo "Genesis files:"
echo "  LeafchainA state: $BASE_DIR/leafchain-a-genesis-state"
echo "  LeafchainA wasm:  $BASE_DIR/leafchain-a-genesis-wasm"
echo "  LeafchainB state: $BASE_DIR/leafchain-b-genesis-state"
echo "  LeafchainB wasm:  $BASE_DIR/leafchain-b-genesis-wasm"
echo ""
echo "Log files: $BASE_DIR/*.log"
echo ""
echo "IMPORTANT: You need to register the parachains manually using Polkadot.js Apps"
echo "1. Go to https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:9944"
echo "2. Navigate to Developer -> Sudo"
echo "3. Use paraSudoWrapper.sudoScheduleParaInitialize to register:"
echo "   - Para ID 2000 with LeafchainA genesis state and wasm"
echo "   - Para ID 2001 with LeafchainB genesis state and wasm"
echo ""
echo "To stop: kill \$(cat $BASE_DIR/*.pid)"
echo ""

# Keep script running and show logs
echo "Press Ctrl+C to stop all nodes..."
trap "echo 'Stopping...'; kill \$(cat $BASE_DIR/*.pid 2>/dev/null) 2>/dev/null; exit 0" INT TERM

# Tail all logs
tail -f "$BASE_DIR"/*.log
