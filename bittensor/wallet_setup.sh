#!/usr/bin/env bash
# ============================================================
# wallet_setup.sh — creates Bittensor cold + hotkey if absent
# Called automatically by bittensor_run.sh on first start
# ============================================================
set -euo pipefail

WALLET_NAME="${WALLET_NAME:-richa}"
HOTKEY_NAME="${HOTKEY_NAME:-default}"
WALLET_DIR="/root/.bittensor/wallets/${WALLET_NAME}"

SEP="============================================================"

echo "${SEP}"
echo "  RICHA — Bittensor Wallet Setup"
echo "${SEP}"

# ── Cold key ────────────────────────────────────────────────
if [ ! -f "${WALLET_DIR}/coldkey" ]; then
    echo ""
    echo "  Creating new coldkey: ${WALLET_NAME}"
    echo "  !! SAVE THE MNEMONIC SHOWN BELOW — you cannot recover it later !!"
    echo ""
    btcli wallet new_coldkey \
        --wallet.name "${WALLET_NAME}" \
        --no_password \
        --no_prompt
else
    echo "  Coldkey already exists: ${WALLET_NAME}"
fi

# ── Hot key ─────────────────────────────────────────────────
if [ ! -f "${WALLET_DIR}/hotkeys/${HOTKEY_NAME}" ]; then
    echo ""
    echo "  Creating hotkey: ${HOTKEY_NAME}"
    btcli wallet new_hotkey \
        --wallet.name "${WALLET_NAME}" \
        --wallet.hotkey "${HOTKEY_NAME}" \
        --no_prompt
else
    echo "  Hotkey already exists: ${HOTKEY_NAME}"
fi

echo ""
echo "  Wallet ready."
echo "${SEP}"
