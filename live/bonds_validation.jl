#!/usr/bin/env julia
# ============================================================================
# bonds_validation.jl — validate-before-live gate for the BONDS overlay sleeve.
#
# Bonds is an OVERLAY, not a standalone-alpha book, so the generic Sharpe bar is the wrong test —
# a 60/40 book "passes" a Sharpe bar on equity beta alone, which proves nothing. The honest bar for
# a defensive overlay is drawn straight from the research:
#   (1) it must materially REDUCE DRAWDOWN vs holding equity (that is what a hedge is for), and
#   (2) it must RETAIN most of the return (a hedge that gives up all the upside is just cash), and
#   (3) regime-TIMING should ~tie static 60/40 (research #4: timing adds ~+0.02 — the diversification
#       is the value, not the timing). We report that honestly rather than claim timing alpha.
#
# Fully causal walk-forward: each rebalance calls the driver's OWN bonds_target(panel,cap) on data up
# to t0, holds the net weights, accrues instrument-level P&L NET OF COST. Compares the driver's
# regime-switched overlay (C) to equity-only (A) and static 60/40 (B). Reuses bonds_target from
# bonds_live.jl.  Run:  julia --project=engine live/bonds_validation.jl
# ============================================================================
include(joinpath(@__DIR__, "bonds_live.jl"))
using Dates, Printf, Statistics, LinearAlgebra
include(joinpath(ENGINE, "src/module_11_cv/purged_kfold.jl"))
using .PurgedKFold

_sh(r; ann = 252) = (x = r[isfinite.(r)]; s = std(x); s > 0 ? mean(x) / s * sqrt(ann) : NaN)
_dd(r) = (lvl = cumprod(1 .+ r); minimum(lvl ./ accumulate(max, lvl) .- 1))
_cagr(r) = (lvl = cumprod(1 .+ r); lvl[end]^(252 / length(r)) - 1)

function fetch_panel(fetchU, lb = 2600)
    try
        return panel_at(AlpacaPanelProvider(fetchU; lookback = lb, calendar_days = 4300, feed = "sip"), Dates.today() - Day(30))
    catch e
        m = match(r"only (\d+) common", sprint(showerror, e))
        m === nothing && rethrow(e)
        n = parse(Int, m.captures[1]) - 20
        (n < 200 || n >= lb) && rethrow(e)
        return fetch_panel(fetchU, n)
    end
end

function main_validate(; warmup = 400, reb = 21, cost_bps = parse(Float64, get(ENV, "BB_COST_BPS", "5")))
    panel = fetch_panel(UNIVERSE)
    R = panel.returns; syms = panel.symbols; T = size(R, 1)
    si = Dict(s => i for (i, s) in enumerate(syms)); dummy = ones(length(syms)); cost = cost_bps / 1e4
    subpanel(t) = (returns = R[1:t, :], symbols = syms, prices = dummy)
    ret(w, day) = sum(get(w, s, 0.0) * R[day, si[s]] for s in keys(w); init = 0.0)

    # C = the driver's regime-switched overlay (causal). A = equity only. B = static 60/40.
    C = Float64[]; oosidx = Int[]; wprev = Dict{String,Float64}()
    for t0 in warmup:reb:(T-1)
        bk = bonds_target(subpanel(t0), 1.0); w = bk.net
        turn = sum(abs(get(w, s, 0.0) - get(wprev, s, 0.0)) for s in union(keys(w), keys(wprev)); init = 0.0)
        for day in (t0+1):min(t0+reb, T)
            r = ret(w, day); day == t0 + 1 && (r -= turn * cost)
            push!(C, r); push!(oosidx, day)
        end
        wprev = w
    end
    A = [R[i, si["SPY"]] for i in oosidx]
    B = [0.60 * R[i, si["SPY"]] + 0.40 * R[i, si["IEF"]] for i in oosidx]
    betaC = var(A) > 0 ? cov(C, A) / var(A) : 0.0

    println("="^76, "\nBONDS — overlay validation (net $(round(Int,cost*1e4)) bps/side; causal walk-forward)\n", "="^76)
    @printf("\n  OOS days %d   rebalances %d   (warmup %d, reb %d; rule-based — no fitted params)\n",
            length(C), length(warmup:reb:(T-1)), warmup, reb)
    @printf("  %-30s %8s %8s %7s %8s\n", "book", "Sharpe", "CAGR", "vol", "maxDD")
    for (lbl, r) in [("A  equity only (SPY)", A), ("B  static 60/40 (SPY/IEF)", B), ("C  regime overlay (driver)", C)]
        @printf("  %-30s %+8.2f %7.1f%% %6.1f%% %7.0f%%\n", lbl, _sh(r), _cagr(r)*100, std(r)*sqrt(252)*100, _dd(r)*100)
    end
    @printf("  overlay beta-to-equity %+.2f\n", betaC)

    # regime-timing vs static, per purged fold (should be ~0 — honest, not alpha)
    diff = C .- B
    folds = purged_kfold_split(length(diff), PurgedKFoldConfig(; n_splits = 6, embargo_bars = reb); returns = diff)
    fmean = [mean(diff[f.test_idx]) * 252 * 100 for f in folds if length(f.test_idx) > 20]

    ddA, ddC, cagrA, cagrC = _dd(A), _dd(C), _cagr(A), _cagr(C)
    dd_cut = 1 - abs(ddC) / abs(ddA)                     # fraction of equity drawdown removed
    ret_keep = cagrC / cagrA                             # fraction of equity return retained
    println("\n  THE BAR (defensive overlay):")
    checks = [
        ("cuts equity drawdown by >= 25%",  dd_cut >= 0.25,            @sprintf("%.0f%% cut (%.0f%% -> %.0f%%)", dd_cut*100, ddA*100, ddC*100)),
        ("retains >= 50% of equity return", ret_keep >= 0.50,          @sprintf("%.0f%% kept (%.1f%% -> %.1f%%)", ret_keep*100, cagrA*100, cagrC*100)),
        ("lower vol than equity",           std(C) < std(A),           @sprintf("%.1f%% vs %.1f%%", std(C)*sqrt(252)*100, std(A)*sqrt(252)*100)),
    ]
    for (n, ok, v) in checks; @printf("    [%s] %-34s %s\n", ok ? "PASS" : "FAIL", n, v); end
    allpass = all(c -> c[2], checks)
    @printf("\n  regime-timing vs static 60/40: %+.2f%%/yr overall, folds mean %+.2f%%/yr  (research: ~0 — diversification is the value)\n",
            (_cagr(C) - _cagr(B)) * 100, mean(fmean))
    println("\n  VERDICT: ", allpass ?
        "PASS as a governed DEFENSIVE OVERLAY + regime-signal emitter. NOT a standalone-alpha keeper —\n           timing ~ static 60/40 (as research found); graduates to the paper/dry-run path, not live money." :
        "MIXED — does not clear the overlay bar; stays dry-run.")
    return (; pass = allpass, dd_cut, ret_keep, betaC)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_validate()
end
