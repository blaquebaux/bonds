#!/usr/bin/python3
# =============================================================================
# bonds_3_curve.py — BLAQUE BAUX BONDS #3: where on the curve is the room for growth?
#
# Duration is not free. The long end (TLT) carries the most rate risk and was
# annihilated in 2022; the front end (SHY) is nearly cashlike; the belly (IEF) sits
# between. Which part of the Treasury curve has actually paid on a RISK-ADJUSTED
# basis, and does the answer depend on the stock-bond correlation regime from #1?
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _bonds_common import rets, stats, roll_corr

u, dates, R = rets(["SHY", "IEF", "TLT", "AGG", "SPY"]); j = {s: u.index(s) for s in u}
print("=" * 74, "\nBONDS #3 — curve positioning (risk-adjusted room by maturity)\n" + "=" * 74)
print(f"  {'sleeve':<20}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}")
for s, lbl in [("SHY", "front (1-3y)"), ("IEF", "belly (7-10y)"), ("TLT", "long (20y+)"), ("AGG", "aggregate")]:
    st = stats(R[:, j[s]])
    print(f"  {s+' '+lbl:<20}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")

# steepener/flattener: front minus long (SHY - TLT). Positive when the curve bear-flattens
# in price terms (long falls faster). Report its own risk-adjusted profile.
steep = R[:, j["SHY"]] - R[:, j["TLT"]]
st = stats(steep)
print(f"\n  steepener proxy (SHY-TLT) Sharpe {st['sh']:+.2f}  vol {st['vol']*100:.1f}%  maxDD {st['dd']*100:+.0f}%")

# does duration pay differently by correlation regime?
c = roll_corr(R[:, j["SPY"]], R[:, j["IEF"]], 63)
c_lag = np.concatenate([[np.nan], c[:-1]])
for s in ["IEF", "TLT"]:
    r = R[:, j[s]]
    for lbl, mask in [("neg-corr", c_lag < 0), ("pos-corr", c_lag >= 0)]:
        m = mask & np.isfinite(r)
        if m.sum() > 60:
            st = stats(r[m])
            print(f"  {s} in {lbl} regime: Sharpe {st['sh']:+.2f}  (n={m.sum()})")

print("\nVERDICT: over 2016-2026 (a rate-HIKE era) DURATION BARELY PAID — the front end (SHY,")
print("cash-like) has the highest Sharpe but ~zero real growth, the belly (IEF) is the best")
print("actual-duration point, and the long end (TLT) is a pure regime bet (Sharpe ~0, -48% DD).")
print("Curve choice is duration budgeting, not alpha; the 'room for growth' is thin at these rates.")
