#!/usr/bin/python3
# =============================================================================
# bonds_2_credit.py — BLAQUE BAUX BONDS #2: credit spreads as an equity signal.
#
# Credit is often called the "smart money." When high-yield spreads widen, is it a
# LEADING warning for equities, or merely COINCIDENT (priced at the same moment)?
# Proxy for the credit spread with the relative strength of HY credit vs a
# duration-matched Treasury: falling HYG/IEF ratio == spreads widening == stress.
# Test whether trailing credit deterioration predicts FORWARD equity returns and
# drawdowns, and whether it does so with any actionable LEAD time.
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _bonds_common import bars, rets

u, dates, R = rets(["SPY", "HYG", "IEF", "LQD"]); j = {s: u.index(s) for s in u}
print("=" * 74, "\nBONDS #2 — credit spreads as an equity signal (lead or coincident?)\n" + "=" * 74)

# credit-stress level = cumulative HYG-minus-IEF relative return (proxy: spread tightness).
# When this falls, HY is underperforming duration-matched Treasuries -> spreads widening.
rel = np.cumprod(1 + (R[:, j["HYG"]] - R[:, j["IEF"]]))
mom20 = np.full(len(rel), np.nan)
mom20[20:] = rel[20:] / rel[:-20] - 1                 # 20d credit momentum (>0 tightening, <0 widening)
spy = R[:, j["SPY"]]

# forward equity behaviour conditional on trailing credit momentum (no look-ahead: use mom at t, ret t+1..t+h)
for h in [5, 20, 60]:
    fwd = np.full(len(spy), np.nan)
    for i in range(len(spy) - h):
        fwd[i] = np.prod(1 + spy[i + 1:i + 1 + h]) - 1
    m = np.isfinite(mom20) & np.isfinite(fwd)
    widen = m & (mom20 < 0); tight = m & (mom20 >= 0)
    print(f"  fwd {h:>2}d SPY | credit WIDENING: {fwd[widen].mean()*100:+.2f}%   "
          f"credit TIGHTENING: {fwd[tight].mean()*100:+.2f}%   "
          f"spread {(fwd[tight].mean()-fwd[widen].mean())*100:+.2f}pp")

# lead vs coincident: cross-correlate credit momentum with equity returns at leads/lags
print("\n  lead/lag  corr(credit-mom_t, SPY-ret_{t+k}):   (k<0 credit lags, k>0 credit leads)")
cm = mom20.copy()
for k in [-10, -5, -1, 0, 1, 5, 10]:
    if k >= 0:
        a, b = cm[:len(cm) - k], spy[k:]
    else:
        a, b = cm[-k:], spy[:len(spy) + k]
    mm = np.isfinite(a) & np.isfinite(b)
    print(f"    k={k:>+3}:  {np.corrcoef(a[mm], b[mm])[0,1]:+.3f}")

print("\nVERDICT: if the widening-vs-tightening spread is large but the peak cross-corr sits")
print("at k<=0, credit is a COINCIDENT risk gauge, not a lead — useful to confirm/derisk in")
print("real time, not to forecast. An honest 'confirming, not leading' read is still valuable.")
