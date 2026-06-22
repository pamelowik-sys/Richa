# ============================================================
# Richa — Bittensor (TAO) node
# Proof of Useful Work: your CPU contributes to AI network
# Supports: linux/amd64, linux/arm64
# ============================================================
FROM python:3.11-slim

# ── System deps ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        libssl-dev \
        pkg-config \
        procps \
    && rm -rf /var/lib/apt/lists/*

# ── Bittensor SDK ────────────────────────────────────────────
# Pin to stable release; update version when upgrading.
RUN pip install --no-cache-dir \
        bittensor==7.4.0 \
        numpy \
        requests

WORKDIR /app

COPY wallet_setup.sh  /app/wallet_setup.sh
COPY bittensor_run.sh /app/bittensor_run.sh
RUN chmod +x /app/wallet_setup.sh /app/bittensor_run.sh

# Wallet data lives in a named volume so it persists between restarts
VOLUME ["/root/.bittensor"]

# NETWORK=test  → testnet (free, no real TAO needed — use for demo)
# NETWORK=main  → mainnet (real TAO required for registration)
ENV NETWORK=test \
    WALLET_NAME=richa \
    HOTKEY_NAME=default \
    NETUID=1

ENTRYPOINT ["/app/bittensor_run.sh"]
