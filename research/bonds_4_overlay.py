#!/usr/bin/python3
# =============================================================================
# bonds_4_overlay.py — BLAQUE BAUX BONDS #4: does a bond-regime overlay earn its keep?
#
# The real test. Take an equity book (SPY as the keeper proxy) and ask whether a
# bond overlay improves its RISK-ADJUSTED return, three ways:
#   (A) equity only
#   (B) static 60/40 (60 SPY / 40 IEF, daily rebalance) — the classic diversifier
#   (C) REGIME-SWITCHED: hold the bond hedge (IEF) only when the trailing stock-bond
#       correlation is negative (bonds actually hedge); otherwise park the 40% in SHY
#       (cash-like). "Hedge when it works, sit in cash when it doesn't."
# If (C) does not beat (B), the honest finding is that the DIVERSIFICATION is the
# value and the TIMING adds little — a perfectly good null for a guardrail sleeve.
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _bonds_common import rets, stats, roll_corr

u, dates, R = rets(["SPY", "IEF", "SHY"]); j = {s: u.index(s) for s in u}
spy, ief, shy = R[:, j["SPY"]], R[:, j["IEF"]], R[:, j["SHY"]]
c = roll_corr(spy, ief, 63); c_lag = np.concatenate([[np.nan], c[:-1]])  # yesterday's regime, no look-ahead

# only score once the regime signal exists
start = np.where(np.isfinite(c_lag))[0][0]
sl = slice(start, len(spy))
A = spy[sl]
B = 0.6 * spy[sl] + 0.4 * ief[sl]
hedge_on = (c_lag[sl] < 0)
C = 0.6 * spy[sl] + 0.4 * np.where(hedge_on, ief[sl], shy[sl])

print("=" * 74, "\nBONDS #4 — does the bond-regime overlay beat static 60/40?\n" + "=" * 74)
print(f"  scored {dates[start]} .. {dates[-1]}   ({len(A)} days)   "
      f"hedge-on {100*hedge_on.mean():.0f}% of days\n")
print(f"  {'book':<28}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}")
for lbl, r in [("A  equity only (SPY)", A), ("B  static 60/40 (SPY/IEF)", B),
               ("C  regime-switched overlay", C)]:
    st = stats(r)
    print(f"  {lbl:<28}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")

# crisis behaviour: worst-decile equity days
worst = A < np.percentile(A, 10)
print(f"\n  on worst-decile equity days (n={worst.sum()}):")
for lbl, r in [("A equity", A), ("B 60/40", B), ("C overlay", C)]:
    print(f"    {lbl:<10} avg {r[worst].mean()*100:+.2f}%")

sh = {k: stats(v)['sh'] for k, v in [("A", A), ("B", B), ("C", C)]}
verdict = ("C beats B — regime timing adds risk-adjusted value" if sh["C"] > sh["B"] + 0.05
           else "C ~ B — the DIVERSIFICATION is the value; timing adds little (a clean null)")
print(f"\nVERDICT: {verdict}.")
print("Either way the sleeve's job is the same: tell the equity book WHEN the bond hedge is")
print("live, so sizing/hedging is regime-aware instead of assuming a permanent negative corr.")
