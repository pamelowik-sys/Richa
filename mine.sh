#!/usr/bin/env bash
# ============================================================
# Richa — XMRig adaptive launcher
#
# On start:
#   1. Detects CPU cores, speed, and available RAM
#   2. Calculates threads = floor(cores * 30%)  (never > 30% load)
#   3. If hardware is very weak (< 2 cores / < 1 GB RAM) → still mines,
#      just with 1 thread at lowest priority
#   4. Runs XMRig capped at MAX_CPU_USAGE % (default 30)
# ============================================================
set -euo pipefail

# ── Configurable limits ─────────────────────────────────────
MAX_CPU_USAGE="${MAX_CPU_USAGE:-30}"   # never exceed this % of CPU
MODE="${MODE:-benchmark}"
WALLET_ADDRESS="${WALLET_ADDRESS:-}"
POOL="${POOL:-pool.supportxmr.com:3333}"
BENCH_SIZE="${BENCH_SIZE:-1M}"

SEP="============================================================"

# ── Hardware detection ───────────────────────────────────────
detect_hardware() {
    TOTAL_CORES=$(nproc 2>/dev/null || echo 1)
    TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 512)
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //' || echo "Unknown CPU")

    # Calculate 30% of cores, minimum 1
    THREADS=$(awk "BEGIN {t=int(${TOTAL_CORES}*${MAX_CPU_USAGE}/100); print (t<1)?1:t}")

    # Classify hardware tier
    if   [ "${TOTAL_CORES}" -ge 8 ] && [ "${TOTAL_RAM_MB}" -ge 4096 ]; then
        HW_TIER="STRONG"
    elif [ "${TOTAL_CORES}" -ge 4 ] && [ "${TOTAL_RAM_MB}" -ge 2048 ]; then
        HW_TIER="MEDIUM"
    elif [ "${TOTAL_CORES}" -ge 2 ] && [ "${TOTAL_RAM_MB}" -ge 1024 ]; then
        HW_TIER="WEAK"
    else
        HW_TIER="MINIMAL"   # 1 thread, lowest priority — still works
        THREADS=1
    fi
}

# ── Header ───────────────────────────────────────────────────
print_header() {
    echo "${SEP}"
    echo "  RICHA — Monero (XMR) Mining Engine  [mode: ${MODE^^}]"
    echo "${SEP}"
    echo ""
    echo "  HARDWARE SCAN:"
    echo "    CPU         : ${CPU_MODEL}"
    echo "    Cores       : ${TOTAL_CORES} logical"
    echo "    RAM         : ${TOTAL_RAM_MB} MB"
    echo "    Tier        : ${HW_TIER}"
    echo ""
    echo "  MINING SETTINGS:"
    echo "    Threads     : ${THREADS}  (${MAX_CPU_USAGE}% CPU cap)"
    echo "    Priority    : $([ "${HW_TIER}" = "MINIMAL" ] && echo "idle (lowest)" || echo "normal")"
    echo "${SEP}"
    echo ""
}

# ── BENCHMARK ────────────────────────────────────────────────
run_benchmark() {
    echo "Starting RandomX benchmark (${BENCH_SIZE} iterations)..."
    echo "Expected duration: 1-3 minutes."
    echo ""

    # MINIMAL hardware: warn but still run
    if [ "${HW_TIER}" = "MINIMAL" ]; then
        echo "  [NOTICE] Very limited hardware detected."
        echo "  Mining will use 1 thread at idle priority — still works, just slower."
        echo ""
    fi

    PRIORITY_FLAG=""
    [ "${HW_TIER}" = "MINIMAL" ] && PRIORITY_FLAG="--priority=0"

    xmrig \
        --bench="${BENCH_SIZE}" \
        --threads="${THREADS}" \
        --max-cpu-usage="${MAX_CPU_USAGE}" \
        --no-color \
        ${PRIORITY_FLAG} \
        2>&1 | tee /tmp/bench_output.txt

    HASHRATE=$(grep -oP '\d+\.\d+ H/s' /tmp/bench_output.txt | tail -1 || echo "see above")

    echo ""
    echo "${SEP}"
    echo "  BENCHMARK COMPLETE"
    echo "  Hashrate : ${HASHRATE}"
    echo "  Threads  : ${THREADS} / ${TOTAL_CORES} cores  (${MAX_CPU_USAGE}% cap)"
    echo ""
    echo "  Earnings forecast:"
    echo "    python3 projection.py --hashrate <value from above>"
    echo "${SEP}"
}

# ── MINING ───────────────────────────────────────────────────
run_mining() {
    if [ -z "${WALLET_ADDRESS}" ]; then
        echo "ERROR: WALLET_ADDRESS not set."
        echo ""
        echo "Usage: docker run -e MODE=mine -e WALLET_ADDRESS=<your_xmr_address> richa-xmrig"
        echo "Free wallet: https://www.getmonero.org/downloads/#gui"
        exit 1
    fi

    echo "Pool   : ${POOL}"
    echo "Wallet : ${WALLET_ADDRESS:0:15}...${WALLET_ADDRESS: -5}"
    echo "Press Ctrl+C to stop."
    echo ""

    PRIORITY_FLAG=""
    [ "${HW_TIER}" = "MINIMAL" ] && PRIORITY_FLAG="--priority=0"

    xmrig \
        --url="${POOL}" \
        --user="${WALLET_ADDRESS}" \
        --pass="richa-worker" \
        --threads="${THREADS}" \
        --max-cpu-usage="${MAX_CPU_USAGE}" \
        --no-color \
        ${PRIORITY_FLAG} \
        2>&1
}

# ── Entry point ──────────────────────────────────────────────
detect_hardware
print_header

case "${MODE}" in
    benchmark) run_benchmark ;;
    mine)      run_mining    ;;
    *)
        echo "Unknown MODE: '${MODE}'. Valid values: benchmark, mine"
        exit 1
        ;;
esac
