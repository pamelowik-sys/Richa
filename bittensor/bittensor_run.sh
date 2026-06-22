#!/usr/bin/env bash
# ============================================================
# bittensor_run.sh — Richa Bittensor node launcher
#
# What it does:
#   1. Creates wallet if it doesn't exist
#   2. Shows wallet address and balance
#   3. Checks subnet registration status
#   4. On testnet: shows demo instructions
#   5. On mainnet: starts miner if registered
# ============================================================
set -euo pipefail

NETWORK="${NETWORK:-test}"
WALLET_NAME="${WALLET_NAME:-richa}"
HOTKEY_NAME="${HOTKEY_NAME:-default}"
NETUID="${NETUID:-1}"

SEP="============================================================"

# Set subtensor endpoint based on network
if [ "${NETWORK}" = "test" ]; then
    SUBTENSOR_ENDPOINT="wss://test.finney.opentensor.ai:443"
    NETWORK_LABEL="TESTNET (free — no real TAO)"
else
    SUBTENSOR_ENDPOINT="wss://entrypoint-finney.opentensor.ai:443"
    NETWORK_LABEL="MAINNET"
fi

# ── Step 1: wallet setup ─────────────────────────────────────
/app/wallet_setup.sh

# ── Step 2: show wallet info ─────────────────────────────────
echo ""
echo "${SEP}"
echo "  BITTENSOR NODE STATUS"
echo "  Network : ${NETWORK_LABEL}"
echo "  Subnet  : ${NETUID}"
echo "${SEP}"
echo ""

echo "  Wallet overview:"
btcli wallet overview \
    --wallet.name "${WALLET_NAME}" \
    --wallet.hotkey "${HOTKEY_NAME}" \
    --subtensor.network "${NETWORK}" \
    --no_prompt 2>&1 || echo "  (could not fetch balance — check network)"

echo ""

# ── Step 3: registration check ───────────────────────────────
echo "  Checking subnet ${NETUID} registration..."
REGISTERED=$(python3 - <<'PYEOF'
import bittensor as bt, os, sys
try:
    sub = bt.subtensor(network=os.environ.get("SUBTENSOR_ENDPOINT", "test"))
    w   = bt.wallet(
        name   = os.environ.get("WALLET_NAME", "richa"),
        hotkey = os.environ.get("WALLET_HOTKEY", "default")
    )
    uid = sub.get_uid_for_hotkey_on_subnet(
        hotkey_ss58 = w.hotkey.ss58_address,
        netuid      = int(os.environ.get("NETUID", "1"))
    )
    print("yes" if uid is not None else "no")
except Exception as e:
    print(f"error: {e}", file=sys.stderr)
    print("no")
PYEOF
)

# ── Step 4: branch on network + registration ─────────────────
if [ "${NETWORK}" = "test" ]; then
    echo ""
    echo "${SEP}"
    echo "  DEMO MODE — TESTNET"
    echo "${SEP}"
    echo ""
    echo "  Your node is connected to Bittensor testnet."
    echo "  No real TAO is at stake — safe for demos and testing."
    echo ""
    echo "  Hotkey address:"
    python3 -c "
import bittensor as bt, os
w = bt.wallet(name=os.environ['WALLET_NAME'], hotkey=os.environ['HOTKEY_NAME'])
print('    ' + w.hotkey.ss58_address)
" 2>/dev/null || echo "    (run wallet_setup.sh first)"
    echo ""
    echo "  To go to mainnet and earn real TAO:"
    echo "    1. Buy TAO on an exchange (e.g. MEXC, Bitget)"
    echo "    2. Transfer to your coldkey address above"
    echo "    3. Run: docker compose up bittensor-main"
    echo ""
    echo "  TAO price today: check https://taostats.io"
    echo "${SEP}"

elif [ "${REGISTERED}" = "yes" ]; then
    echo "  Registered on subnet ${NETUID}. Starting miner..."
    echo ""
    # Run a minimal text-serving miner on subnet 1 (example)
    python3 -c "
import bittensor as bt
import os, time

network   = os.environ['NETWORK']
wallet_n  = os.environ['WALLET_NAME']
hotkey_n  = os.environ['HOTKEY_NAME']
netuid    = int(os.environ['NETUID'])
endpoint  = os.environ['SUBTENSOR_ENDPOINT']

subtensor = bt.subtensor(network=network)
wallet    = bt.wallet(name=wallet_n, hotkey=hotkey_n)
metagraph = subtensor.metagraph(netuid)

uid = subtensor.get_uid_for_hotkey_on_subnet(wallet.hotkey.ss58_address, netuid)
print(f'  UID on subnet {netuid}: {uid}')
print(f'  Incentive:  {metagraph.I[uid].item():.6f}')
print(f'  Emission:   {metagraph.E[uid].item():.6f} TAO/block')
print()
print('  Miner active. Press Ctrl+C to stop.')
print('  Dashboard: https://taostats.io')

# Keep alive — replace with real miner axon in a production setup
while True:
    time.sleep(60)
    metagraph.sync()
    print(f'  [{time.strftime(\"%H:%M:%S\")}] stake={metagraph.S[uid].item():.4f} TAO')
"
else
    echo ""
    echo "${SEP}"
    echo "  NOT REGISTERED on subnet ${NETUID}"
    echo "${SEP}"
    echo ""
    echo "  To register on mainnet you need TAO tokens."
    echo "  Current registration cost: check https://taostats.io/subnets"
    echo ""
    echo "  Registration command (run when you have TAO):"
    echo "    btcli subnet register \\"
    echo "      --netuid ${NETUID} \\"
    echo "      --wallet.name ${WALLET_NAME} \\"
    echo "      --wallet.hotkey ${HOTKEY_NAME} \\"
    echo "      --subtensor.network ${NETWORK}"
    echo ""
    echo "  Switching to testnet for demo:"
    NETWORK=test /app/bittensor_run.sh
fi
