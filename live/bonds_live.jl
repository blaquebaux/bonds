#!/usr/bin/env julia
# ============================================================================
# bonds_live.jl — BLAQUE BAUX BONDS live driver (the stock-bond regime overlay).
#
# Runs on the Blaque Baux ENGINE (engine/ submodule) — same governed order path + Layer-3
# safety gate as the spine.  data(SPY, IEF, SHY) -> regime read -> overlay book -> [ GATE ] -> orders.
#
# THE KEEPER IS THE REGIME READ (research #1): the 63-day stock-bond correlation swings sign and is
# ~72% persistent a quarter out; the bond hedge only WORKS when that correlation is negative. This
# driver does two things:
#   1) PUBLISHES the regime read to $BB_REGIME_PATH (default ~/.config/blaquebaux/bonds_regime.txt)
#      so the equity sleeves / keeper book can size regime-aware instead of assuming a permanent
#      negative correlation. This is the sleeve's real product.
#   2) Trades the concrete OVERLAY BOOK the research studied: 60% SPY + 40% hedge, where the hedge is
#      IEF (7-10y Treasury) when the correlation is negative (hedge live) and SHY (~cash) when it is
#      positive (hedge dead). Long-only, ~1x gross, monthly/regime rebalance.
#
# HONEST STATUS: research #4 found regime-TIMING the overlay adds only ~+0.02 Sharpe over static
# 60/40 — the diversification is the value, not the timing. So this is a governed DEFENSIVE OVERLAY +
# a signal emitter, NOT a standalone-alpha keeper. It graduates to the paper/dry-run path; it is not a
# live-money endorsement. See live/bonds_validation.jl for the overlay-appropriate bar.
#
# MODES: dry-run by default via the wrapper (BB_DRYRUN=1 -> compute + log + emit signal, NO venue).
# Paper: unset BB_DRYRUN with paper keys. Real money requires BB_LIVE_CONFIRM=I_UNDERSTAND_THIS_IS_REAL_MONEY.
# Kill switch: ~/.config/blaquebaux/HALT.  Run:  julia --project=engine live/bonds_live.jl
# ============================================================================
using Dates, Printf, Statistics, LinearAlgebra

const REPO   = normpath(joinpath(@__DIR__, ".."))
const ENGINE = joinpath(REPO, "engine")
include(joinpath(ENGINE, "src/module_7_execution/module_7_execution.jl"))
include(joinpath(ENGINE, "src/module_10_feedback/module_10_feedback.jl"))
include(joinpath(ENGINE, "src/module_13_portfolio/module_13_portfolio.jl"))
include(joinpath(ENGINE, "src/module_1_data/equity_panel.jl"))
include(joinpath(ENGINE, "src/module_1_data/alpaca_panel.jl"))
include(joinpath(ENGINE, "src/module_8_governance/safety_gate.jl"))
using .ExecutionLayer, .FeedbackLayer, .PortfolioOptModule, .EquityPanel, .AlpacaPanel, .SafetyGate
include(joinpath(ENGINE, "scripts/live_execution.jl"))

const UNIVERSE = ["SPY", "IEF", "SHY"]
const LIVE_SENTINEL = "I_UNDERSTAND_THIS_IS_REAL_MONEY"
const EQUITY_W = 0.60          # equity sleeve of the overlay book
const HEDGE_W  = 0.40          # bond/cash hedge sleeve
const CORR_WIN = 63            # ~one quarter — the regime window (research #1)

_readf(p) = isfile(p) ? (v = tryparse(Float64, strip(read(p, String))); v === nothing ? NaN : v) : NaN
_writef(p, x) = (mkpath(dirname(p)); write(p, string(x)))

"63-day stock-bond correlation regime + the concrete overlay book (60% SPY + 40% IEF|SHY)."
function bonds_target(panel, cap)
    syms = panel.symbols; R = panel.returns; T = size(R, 1)
    idx(s) = findfirst(==(s), syms); px(s) = panel.prices[idx(s)]
    spy = R[:, idx("SPY")]; ief = R[:, idx("IEF")]
    w = min(CORR_WIN, T - 1)
    a = spy[T-w+1:T]; b = ief[T-w+1:T]
    corr = (std(a) > 0 && std(b) > 0) ? cor(a, b) : 0.0
    hedge_on = corr < 0                                   # neg-corr => the bond hedge is live
    net = Dict{String,Float64}("SPY" => EQUITY_W,
                               "IEF" => hedge_on ? HEDGE_W : 0.0,
                               "SHY" => hedge_on ? 0.0 : HEDGE_W)
    price = Dict(s => px(s) for s in UNIVERSE)
    targets = Dict(s => round(Float64, get(net, s, 0.0) * cap / price[s]) for s in UNIVERSE)
    (targets = targets, prices = price, net = net, corr = corr, hedge_on = hedge_on)
end

"Publish the regime read for the rest of the family to size against. THIS is the sleeve's product."
function emit_regime(path, bk, asof)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Blaque Baux Bonds — stock-bond correlation regime (research #1)")
        println(io, "asof=", asof)
        @printf(io, "corr63=%.4f\n", bk.corr)
        println(io, "regime=", bk.hedge_on ? "neg-corr" : "pos-corr")
        println(io, "hedge_on=", bk.hedge_on ? 1 : 0)   # 1 = bond hedge is LIVE; 0 = hedge is DEAD (use cash)
        println(io, "hedge_instrument=", bk.hedge_on ? "IEF" : "SHY")
    end
end

function main(; capital = nothing, pool = "us", limits::SafetyLimits = SafetyLimits(),
              db_path     = get(ENV, "BB_LEDGER_PATH", joinpath(REPO, "alpaca_ledger_bonds.sqlite")),
              audit_path  = get(ENV, "BB_AUDIT_PATH",  joinpath(REPO, "alpaca_audit_bonds.jsonl")),
              hwm_path    = get(ENV, "BB_HWM_PATH",    joinpath(homedir(), ".config", "blaquebaux", "equity_hwm_bonds.txt")),
              equity_path = get(ENV, "BB_EQUITY_PATH", joinpath(homedir(), ".config", "blaquebaux", "equity_last_bonds.txt")),
              regime_path = get(ENV, "BB_REGIME_PATH", joinpath(homedir(), ".config", "blaquebaux", "bonds_regime.txt")))
    (get(ENV, "ALPACA_KEY_ID", "") == "" || get(ENV, "ALPACA_SECRET_KEY", "") == "") &&
        error("Set ALPACA_KEY_ID and ALPACA_SECRET_KEY (read-only bars are needed even in dry-run).")
    dryrun = get(ENV, "BB_DRYRUN", "") in ("1", "true", "yes")

    if dryrun
        panel = panel_at(AlpacaPanelProvider(UNIVERSE; lookback = 250))
        bk = bonds_target(panel, capital === nothing ? 100_000.0 : capital)
        emit_regime(regime_path, bk, panel.asof)
        @info "BONDS dry run" asof=panel.asof corr63=round(bk.corr, digits=3) regime=(bk.hedge_on ? "neg-corr (hedge LIVE)" : "pos-corr (hedge DEAD)")
        println("\n  Regime read (published to $regime_path):")
        @printf("    63d SPY-IEF corr = %+.3f  ->  %s\n", bk.corr,
                bk.hedge_on ? "NEG-corr: bond hedge is LIVE (hold IEF)" : "POS-corr: bond hedge is DEAD (hold cash/SHY)")
        println("\n  Overlay book (60% SPY + 40% hedge):")
        for (s, w) in sort(collect(bk.net), by = x -> -abs(x[2]))
            abs(w) < 1e-4 && continue
            @printf("    %-4s %5.1f%%  -> %d sh @ \$%.2f\n", s, 100w, Int(get(bk.targets, s, 0.0)), get(bk.prices, s, NaN))
        end
        ok, reasons = preflight(; account_status = "ACTIVE", equity = 100_000.0, hwm = 100_000.0,
            last_equity = 100_000.0, buying_power = 100_000.0, data_fresh = (Dates.today() - panel.asof) <= Day(5),
            targets = bk.targets, prices = bk.prices, limits = limits)
        println("\n  DRY RUN — no venue, no orders. Gate: ", ok ? "PASS" : "ABORT: " * join(reasons, "; "))
        return ok ? :dryrun_ok : :dryrun_gate_abort
    end

    live = get(ENV, "BB_LIVE_CONFIRM", "") == LIVE_SENTINEL; paper = !live
    mode = live ? "*** LIVE REAL MONEY ***" : "paper"
    @info "bonds_live starting" mode
    live && alert("BONDS LIVE REAL-MONEY mode engaged"; level = :critical)
    venue = AlpacaVenue(AlpacaConfig(; paper = paper))
    built = build_live_controller(; venue = venue, ledger_config = LedgerConfig(; db_path = db_path), audit_path = audit_path)
    ctrl, ledger = built.ctrl, built.ledger
    try
        connect!(venue) || (alert("ABORT [$mode]: Alpaca connect failed (bonds)"; level = :critical); return :connect_failed)
        acct = account_info(venue)
        acct === nothing && (alert("ABORT [$mode]: could not read account (bonds)"; level = :critical); return :no_account)
        cap = capital === nothing ? acct.equity : capital
        hwm = max(load_hwm(hwm_path), acct.equity); last_eq = _readf(equity_path)
        panel = panel_at(AlpacaPanelProvider(UNIVERSE; lookback = 250)); fresh = (Dates.today() - panel.asof) <= Day(5)
        bk = bonds_target(panel, cap)
        emit_regime(regime_path, bk, panel.asof)         # publish the read even if the gate later halts trading
        ok, reasons = preflight(; account_status = acct.status, trading_blocked = acct.trading_blocked,
            account_blocked = acct.account_blocked, equity = acct.equity, hwm = hwm, last_equity = last_eq,
            buying_power = acct.buying_power, data_fresh = fresh, targets = bk.targets, prices = bk.prices, limits = limits)
        save_hwm(hwm, hwm_path); _writef(equity_path, acct.equity)
        if !ok
            msg = "SAFETY ABORT [$mode] (bonds): " * join(reasons, "; "); @error msg
            halt!(ctrl, "safety gate"); alert(msg; level = :critical); return :aborted
        end
        reset_daily!(ctrl)
        set_pool_budget!(ctrl, pool, limits.max_gross_leverage * acct.equity)
        set_pool_loss_limit!(ctrl, pool, limits.max_daily_loss)
        set_pool_staleness!(ctrl, pool, Day(5)); feed_staleness!(ctrl, pool; stale = !fresh)
        isfinite(last_eq) && update_pnl!(ctrl, pool, acct.equity - last_eq)
        ncanc = cancel_all_open!(venue); ncanc > 0 && sleep(2)
        for (sym, qty) in positions(venue, ctrl.account); apply_fill!(ctrl, sym, qty); end
        res = execute_rebalance!(ctrl, ledger; targets = bk.targets, prices = bk.prices,
            signal_id = "bonds", regime = (bk.hedge_on ? "neg-corr" : "pos-corr"),
            solve_id = Dates.format(panel.asof, "yyyymmdd"), pool_id = pool, settle_secs = 20)
        !res.reconciled && (alert("RECONCILE FAILED [$mode] (bonds) — halting"; level = :critical); halt!(ctrl, "reconcile mismatch"))
        summary = "[$mode] bonds overlay ($(bk.hedge_on ? "hedge LIVE / IEF" : "hedge DEAD / SHY")); orders=$(length(res.acks)) fills=$(length(res.fills)) reconciled=$(res.reconciled) equity=$(round(Int, acct.equity))"
        @info "bonds_live complete" summary; alert(summary; level = :info)
        return res.reconciled ? :ok : :reconcile_failed
    finally
        disconnect!(venue); close_ledger(ledger)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
