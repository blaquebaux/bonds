#!/usr/bin/python3
# =============================================================================
# bonds_1_correlation.py — BLAQUE BAUX BONDS #1: the stock-bond correlation regime.
#
# The single most important macro variable an equity book ignores: is the
# stock-bond correlation NEGATIVE (bonds hedge equities — the 1998-2020 world) or
# POSITIVE (they fall together — the 2022+ world)? A negative-corr regime makes a
# bond hedge valuable; a positive-corr regime makes "60/40" a single bet in
# disguise. Two questions: (a) how big is the swing, (b) is the regime PERSISTENT
# enough to be detectable in advance (or only in hindsight)?
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _bonds_common import rets, roll_corr, stats

u, dates, R = rets(["SPY", "IEF", "TLT"]); j = {s: u.index(s) for s in u}
print("=" * 74, "\nBONDS #1 — the stock-bond correlation regime\n" + "=" * 74)
print(f"window: {dates[0]} .. {dates[-1]}   ({len(dates)} trading days)\n")

for bond in ["IEF", "TLT"]:
    c = roll_corr(R[:, j["SPY"]], R[:, j[bond]], 63)   # ~quarter
    cc = c[np.isfinite(c)]
    neg = 100 * (cc < 0).mean()
    print(f"  SPY vs {bond}: 63d corr  min {cc.min():+.2f}  mean {cc.mean():+.2f}  max {cc.max():+.2f}"
          f"  |  negative-regime {neg:.0f}% of days")

# ---- Is the regime PERSISTENT (detectable in advance)? ----
# Compare corr in this quarter to corr in the NEXT quarter; and test a naive
# "sign persists" rule: does today's 63d corr sign predict the next 63d corr sign?
c = roll_corr(R[:, j["SPY"]], R[:, j["IEF"]], 63)
idx = np.where(np.isfinite(c))[0]
now, nxt = [], []
for i in idx:
    if i + 63 < len(c) and np.isfinite(c[i + 63]):
        now.append(c[i]); nxt.append(c[i + 63])
now, nxt = np.array(now), np.array(nxt)
persist = np.corrcoef(now, nxt)[0, 1]
sign_hit = 100 * (np.sign(now) == np.sign(nxt)).mean()
print(f"\n  Persistence (SPY-IEF): corr(this-qtr, next-qtr corr) = {persist:+.2f}")
print(f"  Sign of the correlation regime repeats {sign_hit:.0f}% of the time one quarter out.")

# ---- Does the regime CHANGE whether bonds hedge? ----
# Split days by trailing 63d corr sign; measure how bonds behaved on the worst
# equity days in each regime (the only day that matters for a hedge).
spy, ief = R[:, j["SPY"]], R[:, j["IEF"]]
c_lag = np.concatenate([[np.nan], c[:-1]])          # yesterday's regime, no look-ahead
worst = spy < np.nanpercentile(spy, 10)             # worst 10% equity days
for lbl, mask in [("neg-corr regime", (c_lag < 0)), ("pos-corr regime", (c_lag >= 0))]:
    m = mask & worst & np.isfinite(ief)
    if m.sum() > 20:
        print(f"  On worst-decile equity days, {lbl:<16}: IEF avg {ief[m].mean()*100:+.2f}%  "
              f"(hedge {'WORKS' if ief[m].mean() > 0 else 'FAILS'}, n={m.sum()})")

print("\nVERDICT: the regime is real and swings sign; if persistence is high the sign is")
print("knowable a quarter ahead (a slow-moving state, not a trade). The payoff is knowing")
print("WHEN the bond hedge actually works — fed to sizing, not traded on its own.")
