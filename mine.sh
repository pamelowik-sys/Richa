#!/usr/bin/env bash
# ============================================================
# Richa — XMRig launcher
# Handles both benchmark mode and real mining mode
# ============================================================
set -euo pipefail

MODE="${MODE:-benchmark}"
WALLET_ADDRESS="${WALLET_ADDRESS:-}"
POOL="${POOL:-pool.supportxmr.com:3333}"
BENCH_SIZE="${BENCH_SIZE:-1M}"
THREADS="${THREADS:-0}"

header() {
    echo "============================================================"
    echo "  RICHA — Monero (XMR) Mining Engine"
    echo "  Mode: ${MODE^^}"
    echo "============================================================"
    echo ""
}

# ── BENCHMARK MODE ───────────────────────────────────────────
run_benchmark() {
    echo "Starting RandomX benchmark (${BENCH_SIZE} dataset iterations)..."
    echo "This will take 1-3 minutes. Please wait."
    echo ""

    THREAD_ARGS=""
    if [ "${THREADS}" -gt 0 ] 2>/dev/null; then
        THREAD_ARGS="--threads=${THREADS}"
    fi

    xmrig \
        --bench="${BENCH_SIZE}" \
        --no-color \
        ${THREAD_ARGS} \
        2>&1 | tee /tmp/bench_output.txt

    HASHRATE=$(grep -oP '\d+\.\d+ H/s' /tmp/bench_output.txt | tail -1 || echo "see above")
    echo ""
    echo "============================================================"
    echo "  BENCHMARK COMPLETE"
    echo "  Result: ${HASHRATE}"
    echo ""
    echo "  Run projection.py to see earnings forecast:"
    echo "  python3 projection.py --hashrate <H/s value>"
    echo "============================================================"
}

# ── MINING MODE ──────────────────────────────────────────────
run_mining() {
    if [ -z "${WALLET_ADDRESS}" ]; then
        echo "ERROR: WALLET_ADDRESS is not set."
        echo ""
        echo "Set your Monero wallet address:"
        echo "  docker run -e MODE=mine -e WALLET_ADDRESS=<your_xmr_address> richa-xmrig"
        echo ""
        echo "Get a free wallet at: https://www.getmonero.org/downloads/#gui"
        exit 1
    fi

    echo "Pool:   ${POOL}"
    echo "Wallet: ${WALLET_ADDRESS:0:15}...${WALLET_ADDRESS: -5}"
    echo "Press Ctrl+C to stop."
    echo ""

    THREAD_ARGS=""
    if [ "${THREADS}" -gt 0 ] 2>/dev/null; then
        THREAD_ARGS="--threads=${THREADS}"
    fi

    xmrig \
        --url="${POOL}" \
        --user="${WALLET_ADDRESS}" \
        --pass="richa-worker" \
        --no-color \
        ${THREAD_ARGS} \
        2>&1
}

# ── Entry point ──────────────────────────────────────────────
header

case "${MODE}" in
    benchmark) run_benchmark ;;
    mine)      run_mining    ;;
    *)
        echo "Unknown MODE: ${MODE}"
        echo "Valid values: benchmark, mine"
        exit 1
        ;;
esac
