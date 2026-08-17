# Blaque Baux Bonds

**The bond–equity relationship — where the stock/bond regime leaves room for growth.**

Bonds is a member of the Blaque Baux family. The [core repo](https://github.com/blaquebaux/base)
is the **engine and blueprint** — a governed, systematic platform (Julia) with a venue-agnostic
execution controller and a Layer-3 live-money safety gate. Bonds points that engine in its own
direction and inherits the governance wholesale.

> **Not investment advice.** Educational/research software. Nothing here is validated. See [LICENSE](LICENSE).

```bash
git clone --recursive https://github.com/blaquebaux/bonds.git
julia --project=engine -e 'using Pkg; Pkg.instantiate()'   # one-time engine setup
```

## The thesis

This is **not a bond-picking sleeve.** It studies the *relationship* between the fixed-income market
and equities — the single most important macro variable most equity books ignore. The stock–bond
correlation is not a constant: for two decades bonds were the reliable hedge (negative correlation),
then in 2022 the sign flipped and stocks and bonds fell together. Whether that correlation is positive
or negative changes the value of every "60/40" assumption, every hedge, and the right way to size an
equity book.

Bonds maps that terrain and asks **where the room for growth actually is** across the stock/bond
regime: the level and slope of the curve, the term premium, and credit spreads as a *forward* signal
for equity risk. The output is less a standalone strategy than a **macro overlay** — a regime read
that tells the equity sleeves when the diversifier is working, when duration is a tailwind or a trap,
and when widening credit is warning of an equity drawdown before price does. It is the natural partner
to [Bleed](https://github.com/blaquebaux/bleed) (tail insurance) and the sizing logic in the keeper
book.

## Research plan (Path A)

- **The correlation regime.** Estimate the time-varying stock–bond correlation and identify the
  regimes (bond-as-hedge vs. bond-as-co-mover). Test whether the regime is *detectable in advance*
  or only in hindsight.
- **Credit spreads as an equity signal.** Test whether widening HY/IG spreads and the term-premium
  lead equity drawdowns with enough lead time to act, net of the whipsaw.
- **Curve positioning.** Where in the curve (front vs. long end, steepener vs. flattener) is the
  risk-adjusted room for growth given the regime — as an overlay, not a rates punt.
- **Overlay value, honestly.** The real test: does a bond-regime overlay *improve the keeper equity
  book's* risk-adjusted return, or is it just another thing to whipsaw on? A null overlay is still a
  useful risk read.

## Research — first pass done

Full detail in [`research/README.md`](research/README.md). The scorecard (Alpaca SIP, 2016–2026):

| # | Question | Verdict |
|---|----------|---------|
| 1 | Is the stock-bond correlation regime real & knowable ahead? | ✅ **flagship** — corr swings −0.68→+0.67, sign **72% persistent** a quarter out; the hedge works in neg-corr (+0.21% on worst equity days), fails in pos-corr (−0.01%) |
| 2 | Do credit spreads *lead* equities? | ❌ null — **coincident**, not leading (cross-corr peaks at k≤0) |
| 3 | Where on the curve is the room for growth? | ⚠️ thin — **duration barely paid** in a hike era; TLT +0.01 Sharpe on −48% DD; duration budgeting, not alpha |
| 4 | Does a regime overlay beat static 60/40? | ➖ near-null — timing adds **+0.02** Sharpe; the *diversification* is the value (both halve crisis loss) |

**The synthesis:** Bonds is a **risk/overlay sleeve, exactly as designed** — a guardrail, not a
money-maker. The one non-obvious keeper is #1: the stock–bond correlation swings sign and is
**detectable a quarter ahead**, and the bond hedge only works in the negative-correlation regime. So
the "bonds diversify stocks" assumption in every 60/40 is regime-conditional, and the regime is
legible in advance. Everything else is honest deflation — credit doesn't lead (it confirms),
duration barely paid this decade, and *timing* the overlay barely beats simply *holding* it. The
keeper is **the regime read, not a trade**: it tells the equity sleeves when the bond hedge is live,
so sizing stops assuming a permanent negative correlation. Natural partner to
[Bleed](https://github.com/blaquebaux/bleed) and the keeper book's regime brake.

## Live driver — built (paper/dry-run)

The research keeper — *the regime read* — is now a governed driver on the engine
([`live/bonds_live.jl`](live/bonds_live.jl)). Each run it:

1. **Publishes the regime read** to `~/.config/blaquebaux/bonds_regime.txt` (the 63-day SPY–IEF
   correlation, the neg/pos regime, and `hedge_on`) — the sleeve's real product, a sizing input the
   equity sleeves consume so they stop assuming a permanent negative correlation.
2. **Trades the overlay book** — 60% SPY + 40% hedge, where the hedge is **IEF when the correlation is
   negative** (hedge live) and **SHY (~cash) when positive** (hedge dead) — through the same Layer-3
   safety gate, ledger, reconcile, kill switch, and HWM as the spine.

```bash
BB_DRYRUN=1 bash live/run_bonds_daily.sh          # compute + publish the regime, place nothing
julia --project=engine live/bonds_validation.jl   # the overlay-appropriate bar
```

**Validation — PASS (as an overlay):** the honest bar for a defensive overlay is drawdown-reduction,
not a Sharpe bar equity beta wins by default. Causal walk-forward, net of cost: the driver **cuts the
equity drawdown 28%** (−22% → −16%), **retains 59% of the return** (14.8% → 8.7%), at **10.5% vol vs
17%**. Regime-*timing* adds ≈0 vs static 60/40 (−0.4%/yr) — exactly as research #4 found: the
diversification is the value, not the timing. So it graduates as a **governed defensive overlay +
regime-signal emitter, not a standalone-alpha keeper** — dry-run by default, paper once
`~/.config/blaquebaux/alpaca_bonds.env` exists, real money gated behind an explicit confirm.

## Status
**Research complete + live driver built — validation PASS (as an overlay), stays on the paper/dry-run
path.** The correlation-regime read is the keeper (now published for the family to size against);
credit-as-lead, duration-alpha, and overlay-timing are honest nulls. Not a live-money endorsement.

## About Blaque Baux

**Blaque Baux** is a quantitative research initiative and a subsidiary of **[Carter Warrens](https://carterwarrens.com)**.
[**BlaqueBaux.com**](https://blaquebaux.com) is the home for the work; the code lives here on GitHub — open to
study, test, and build bespoke strategies on top of.

Anyone can point an AI at a market. The edge is **understanding what the data actually says — and turning it
into something you can act on.** We test relentlessly and put most of it *on the record as rejected, with the
reason*; what survives is built, governed, and validated before it is ever called real. That combination —
honest research, reproducible evidence, and execution you can trust — is why Carter Warrens leads on
**strategy and implementation**, not merely uses the tools everyone now has.

## The Blaque Baux family
This repo is one sleeve of the **Blaque Baux** family — a single governed engine steered in
many directions. The [core repo](https://github.com/blaquebaux/base) is the
base/blueprint and holds the [full family roster](https://github.com/blaquebaux/base#the-blaquebaux-family).

## Layout
```
engine/     the Blaque Baux platform (git submodule -> blaquebaux/base)
research/   four Path-A sketches (correlation regime, credit lead/lag, curve, overlay) + scorecard
live/       bonds_live.jl (overlay + regime emitter) + bonds_validation.jl + run wrapper
```

## License
[MIT](LICENSE). (c) 2026 Carter Warrens.
