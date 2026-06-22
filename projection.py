#!/usr/bin/env python3
"""
Richa — Mining Projection Calculator
=====================================
Takes a measured XMRig hashrate and projects expected earnings
at different user-base scales.

Usage:
    python projection.py --hashrate 5000
    python projection.py --hashrate 5000 --xmr-price 180
    python projection.py --hashrate 5000 --users 100000,500000,1000000,5000000
"""

import argparse
from dataclasses import dataclass, field
from typing import List


# ---------------------------------------------------------------------------
# Monero network constants (update periodically)
# ---------------------------------------------------------------------------
DEFAULT_BLOCK_REWARD_XMR     = 0.6        # XMR per block
DEFAULT_BLOCK_TIME_MIN       = 2.0        # minutes between blocks
DEFAULT_NETWORK_HASHRATE_GHS = 3.2        # GH/s — total network hashrate
DEFAULT_XMR_PRICE_USD        = 165.0      # USD per XMR
DEFAULT_POOL_FEE_PCT         = 1.0        # typical pool fee %


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class NetworkParams:
    block_reward_xmr: float = DEFAULT_BLOCK_REWARD_XMR
    block_time_min:   float = DEFAULT_BLOCK_TIME_MIN
    network_hr_ghs:   float = DEFAULT_NETWORK_HASHRATE_GHS
    xmr_price_usd:    float = DEFAULT_XMR_PRICE_USD
    pool_fee_pct:     float = DEFAULT_POOL_FEE_PCT

    @property
    def network_hr_hs(self) -> float:
        return self.network_hr_ghs * 1e9

    @property
    def blocks_per_day(self) -> float:
        return (24 * 60) / self.block_time_min

    @property
    def network_xmr_per_day(self) -> float:
        return self.blocks_per_day * self.block_reward_xmr


@dataclass
class MinerStats:
    hashrate_hs: float
    user_counts: List[int]      = field(default_factory=lambda: [1, 1_000, 10_000,
                                                                  100_000, 1_000_000])
    params:      NetworkParams  = field(default_factory=NetworkParams)

    def miner_share(self) -> float:
        return self.hashrate_hs / self.params.network_hr_hs

    def daily_xmr_per_machine(self) -> float:
        raw = self.miner_share() * self.params.network_xmr_per_day
        return raw * (1 - self.params.pool_fee_pct / 100)

    def daily_usd_per_machine(self) -> float:
        return self.daily_xmr_per_machine() * self.params.xmr_price_usd

    def network_share_pct(self, user_count: int) -> float:
        return (self.hashrate_hs * user_count / self.params.network_hr_hs) * 100


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _fmt_usd(n: float) -> str:
    if n >= 1_000_000_000:
        return f"${n / 1_000_000_000:.2f}B"
    if n >= 1_000_000:
        return f"${n / 1_000_000:.2f}M"
    if n >= 1_000:
        return f"${n / 1_000:.2f}K"
    return f"${n:.2f}"


def _fmt_hr(h: float) -> str:
    if h >= 1e9:
        return f"{h / 1e9:.2f} GH/s"
    if h >= 1e6:
        return f"{h / 1e6:.2f} MH/s"
    if h >= 1e3:
        return f"{h / 1e3:.2f} KH/s"
    return f"{h:.1f} H/s"


def _fmt_users(n: int) -> str:
    if n >= 1_000_000:
        return f"{n // 1_000_000}M пользователей"
    if n >= 1_000:
        return f"{n // 1_000}K пользователей"
    return f"{n} пользователей"


SEP = "=" * 70


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

def print_report(stats: MinerStats) -> None:
    p = stats.params
    daily_xmr = stats.daily_xmr_per_machine()
    daily_usd = stats.daily_usd_per_machine()

    print(SEP)
    print("  RICHA — ПРОЕКЦИЯ ЗАРАБОТКА (Monero XMR)")
    print(SEP)
    print()
    print("  ПАРАМЕТРЫ СЕТИ MONERO:")
    print(f"    Hashrate сети       : {_fmt_hr(p.network_hr_hs)}")
    print(f"    Награда за блок     : {p.block_reward_xmr} XMR  (каждые {p.block_time_min} мин)")
    print(f"    Курс XMR            : ${p.xmr_price_usd:.2f}")
    print(f"    Комиссия пула       : {p.pool_fee_pct}%")
    print()
    print("  ОДНА МАШИНА:")
    print(f"    Hashrate            : {_fmt_hr(stats.hashrate_hs)}")
    print(f"    Доля сети           : {stats.miner_share():.8%}")
    print(f"    Заработок / день    : {_fmt_usd(daily_usd)}")
    print(f"    Заработок / месяц   : {_fmt_usd(daily_usd * 30)}")
    print(f"    Заработок / год     : {_fmt_usd(daily_usd * 365)}")
    print()
    print(f"  {'МАСШТАБ':<24} {'Hashrate':>12} {'% сети':>9} {'в день':>12} {'в месяц':>12} {'в год':>14}")
    print("  " + "-" * 83)

    for u in stats.user_counts:
        total_hr = stats.hashrate_hs * u
        d_usd    = daily_usd * u
        pct      = stats.network_share_pct(u)
        print(
            f"  {_fmt_users(u):<24}"
            f" {_fmt_hr(total_hr):>12}"
            f" {pct:>8.2f}%"
            f" {_fmt_usd(d_usd):>12}"
            f" {_fmt_usd(d_usd * 30):>12}"
            f" {_fmt_usd(d_usd * 365):>14}"
        )

    print()
    one_m_usd = daily_usd * 1_000_000
    print(f"  >>> 1 млн пользователей: {_fmt_usd(one_m_usd)}/день  —  {_fmt_usd(one_m_usd * 365)}/год")
    print()
    print("  ВАЖНО: пользователи должны явно соглашаться (opt-in).")
    print("  Актуальные данные: https://www.coinwarz.com/mining/monero/calculator")
    print(SEP)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _parse_users(value: str) -> List[int]:
    try:
        return [int(v.strip().replace("_", "")) for v in value.split(",")]
    except ValueError:
        raise argparse.ArgumentTypeError(f"Invalid user list: '{value}'")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Richa — проекция заработка от XMR-майнинга"
    )
    parser.add_argument("--hashrate", "-r", type=float, required=True,
                        help="Hashrate одной машины в H/s (из XMRig benchmark)")
    parser.add_argument("--xmr-price",    type=float, default=DEFAULT_XMR_PRICE_USD)
    parser.add_argument("--network-hr",   type=float, default=DEFAULT_NETWORK_HASHRATE_GHS)
    parser.add_argument("--block-reward", type=float, default=DEFAULT_BLOCK_REWARD_XMR)
    parser.add_argument("--pool-fee",     type=float, default=DEFAULT_POOL_FEE_PCT)
    parser.add_argument("--users",        type=_parse_users,
                        default="1,1000,10000,100000,1000000,5000000")

    args = parser.parse_args()

    params = NetworkParams(
        block_reward_xmr=args.block_reward,
        block_time_min=DEFAULT_BLOCK_TIME_MIN,
        network_hr_ghs=args.network_hr,
        xmr_price_usd=args.xmr_price,
        pool_fee_pct=args.pool_fee,
    )
    stats = MinerStats(hashrate_hs=args.hashrate, user_counts=args.users, params=params)
    print_report(stats)


if __name__ == "__main__":
    main()
