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

## Research plan (Path A — not yet built)

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

Nothing above is implemented or validated. This is the map, not the territory.

## Status
**Concept.** Thesis and research plan only — no sketches run, no driver, nothing validated to the
spine's bar. A macro-relationship study meant to inform sizing and hedging, not to trade in isolation.

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
research/   the research plan (Path A) — sketches land here once run
live/       governed live drivers (once a sleeve graduates to paper A/B)
```

## License
[MIT](LICENSE). (c) 2026 Carter Warrens.
