# Blaque Baux Bonds — research

First-pass Path-A research on the **bond–equity relationship** as a macro overlay — not a
bond-picking strategy. All sketches read Alpaca SIP daily bars, are read-only, and print their own
results. Universe: the liquid fixed-income + equity ETFs a US book can actually trade
(SPY, TLT, IEF, SHY, AGG, LQD, HYG), 2016-01 – 2026-08.

```bash
export $(grep -v '^#' ~/.config/blaquebaux/alpaca.env | xargs)   # or source it
python research/bonds_1_correlation.py   # the stock-bond correlation regime  (flagship)
python research/bonds_2_credit.py        # credit spreads: lead or coincident?
python research/bonds_3_curve.py         # where on the curve is the room for growth?
python research/bonds_4_overlay.py       # does a regime overlay beat static 60/40?
```

## Scorecard

| # | Question | Result | Verdict |
|---|----------|--------|---------|
| 1 | Is the stock-bond correlation regime real & knowable in advance? | 63d corr swings **−0.68 → +0.67**; sign **72% persistent** one quarter out (persistence +0.55); hedge **works in neg-corr** (IEF +0.21% on worst equity days) and **fails in pos-corr** (−0.01%) | ✅ **flagship** — a slow, detectable state that says *when the hedge is live* |
| 2 | Do credit spreads *lead* equities? | fwd-return spread widening-vs-tightening tiny/wrong-signed (−0.08pp @20d); cross-corr peaks at **k ≤ 0**, negative for k > 0 | ❌ null — credit is **coincident**, not a lead (a real-time gauge, not a forecast) |
| 3 | Where on the curve is the room for growth? | SHY +1.08 Sharpe (but +1.7% CAGR — cash); IEF +0.19; TLT **+0.01, −48% DD**; AGG +0.37 | ⚠️ thin — **duration barely paid** in a hike era; duration budgeting, not alpha |
| 4 | Does a bond-regime overlay beat static 60/40? | A equity **+0.89** / B 60/40 **+0.92** / C regime-switched **+0.94**; B & C both halve crisis loss (−1.16% vs −2.02%) | ➖ near-null — **diversification is the value; timing adds ~+0.02** |

## The synthesis

**Bonds is a risk/overlay sleeve, exactly as designed — a guardrail, not a money-maker.** The one
genuinely valuable, non-obvious finding is **#1**: the stock–bond correlation is not a constant, it
swings sign (−0.68 to +0.67 over the decade), and — crucially — the sign is **persistent enough to be
known a quarter ahead** (it repeats 72% of the time). That matters because the hedge only works in the
negative-correlation regime: on the worst-decile equity days, intermediate Treasuries returned
**+0.21%** when trailing correlation was negative and **−0.01%** when it was positive. The "bonds
diversify stocks" assumption baked into every 60/40 is *regime-conditional*, and the regime is
legible in advance.

Everything downstream of that is honest deflation. **Credit does not lead equities** (#2) — the
widening/tightening forward-return gap is tiny and the cross-correlation peaks coincidentally or with
credit *lagging*; it is a real-time risk confirmation, not a forecast. **Duration barely paid** (#3)
across a rate-hike decade: the front end wins on Sharpe only because it is essentially cash (+1.7%
CAGR), the belly (IEF) is the best actual-duration point, and the long end (TLT) is a pure regime bet
(Sharpe ~0 on a −48% drawdown). And **timing the overlay barely beats holding it** (#4): a
regime-switched book edges static 60/40 by just +0.02 Sharpe — the *diversification* is the value, and
both cut crisis losses roughly in half versus equity alone.

**The keeper is the regime read, not a trade.** Bonds' job is to tell the equity sleeves *when the
bond hedge is actually live* so sizing and hedging stop assuming a permanent negative correlation —
the natural partner to [Bleed](https://github.com/blaquebaux/bleed) (tail insurance) and to the
keeper book's regime brake. No standalone alpha, and the sleeve says so.

## Status
**Research: first pass complete** (`research/`). A macro-overlay / risk sleeve — the correlation-regime
read is the keeper; credit-as-lead, duration-alpha, and overlay-timing are honest nulls. No live
driver; nothing validated to the spine's bar.
