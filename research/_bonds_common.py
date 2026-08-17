#!/usr/bin/python3
# =============================================================================
# _bonds_common.py — shared helpers for the Blaque Baux Bonds sketches.
# Alpaca SIP daily bars; reads ALPACA_KEY_ID / ALPACA_SECRET_KEY from env. Read-only.
#
# This is a MACRO-OVERLAY study, not a bond-picking strategy. The universe is the
# liquid fixed-income + equity ETF set a US book can actually trade:
#   SPY  equities            TLT  20y+ Treasury     IEF  7-10y Treasury
#   SHY  1-3y Treasury       AGG  aggregate bond     LQD  IG credit
#   HYG  HY credit
# =============================================================================
import os, json, urllib.request, math
import numpy as np

H = {"APCA-API-KEY-ID": os.environ["ALPACA_KEY_ID"], "APCA-API-SECRET-KEY": os.environ["ALPACA_SECRET_KEY"]}
START, END = "2016-01-01", "2026-08-01"
_cache = {}

UNIVERSE = ["SPY", "TLT", "IEF", "SHY", "AGG", "LQD", "HYG"]

def bars(s):
    if s in _cache: return _cache[s]
    u = (f"https://data.alpaca.markets/v2/stocks/bars?symbols={s}&timeframe=1Day"
         f"&start={START}&end={END}&adjustment=all&feed=sip&limit=10000")
    try:
        d = json.load(urllib.request.urlopen(urllib.request.Request(u, headers=H), timeout=40))
        _cache[s] = {b["t"][:10]: b for b in d.get("bars", {}).get(s, [])}
    except Exception:
        _cache[s] = {}
    return _cache[s]

def rets(syms):
    D = {s: bars(s) for s in syms}; D = {s: v for s, v in D.items() if len(v) > 500}
    u = list(D); dates = sorted(set.intersection(*[set(D[s]) for s in u]))
    M = np.array([[D[s][d]["c"] for s in u] for d in dates], float)
    return u, dates[1:], M[1:] / M[:-1] - 1

def stats(r):
    r = np.asarray(r, float); r = r[np.isfinite(r)]
    if len(r) < 30 or r.std() == 0: return dict(sh=float('nan'), cagr=float('nan'), dd=float('nan'), vol=float('nan'))
    cum = np.cumprod(1 + r)
    return dict(sh=r.mean() / r.std() * math.sqrt(252), cagr=cum[-1] ** (252 / len(r)) - 1,
                dd=(cum / np.maximum.accumulate(cum) - 1).min(), vol=r.std() * math.sqrt(252))

def roll_corr(a, b, w):
    a = np.asarray(a, float); b = np.asarray(b, float); n = len(a); out = np.full(n, np.nan)
    for i in range(w, n):
        x, y = a[i - w:i], b[i - w:i]
        if x.std() > 0 and y.std() > 0: out[i] = np.corrcoef(x, y)[0, 1]
    return out
