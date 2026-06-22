# ============================================================
# Richa — XMRig Monero Miner/Benchmark
# Supports: linux/amd64, linux/arm64
# ============================================================
FROM ubuntu:22.04

ARG XMRIG_VERSION=6.22.2
ARG TARGETARCH

# ── System dependencies ─────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libhwloc15 \
        libuv1 \
        libssl3 \
    && rm -rf /var/lib/apt/lists/*

# ── Download XMRig static binary ────────────────────────────
RUN set -eux; \
    case "${TARGETARCH:-$(uname -m)}" in \
        amd64|x86_64)  ARCH="x64"      ;; \
        arm64|aarch64) ARCH="aarch64"  ;; \
        *) echo "Unsupported arch"; exit 1 ;; \
    esac; \
    curl -fsSL \
        "https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/xmrig-${XMRIG_VERSION}-linux-static-${ARCH}.tar.gz" \
        -o /tmp/xmrig.tar.gz; \
    tar -xzf /tmp/xmrig.tar.gz -C /tmp; \
    mv "/tmp/xmrig-${XMRIG_VERSION}/xmrig" /usr/local/bin/xmrig; \
    chmod +x /usr/local/bin/xmrig; \
    rm -rf /tmp/xmrig*

WORKDIR /app

COPY config.json   /app/config.json
COPY mine.sh       /app/mine.sh
RUN chmod +x /app/mine.sh

# MODE=benchmark  → pure hashrate test, no pool needed
# MODE=mine       → real mining (requires WALLET_ADDRESS + POOL)
ENV MODE=benchmark

ENTRYPOINT ["/app/mine.sh"]
