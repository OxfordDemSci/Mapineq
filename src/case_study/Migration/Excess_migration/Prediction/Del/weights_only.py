# This is very complicated, so we are trying to build a easy one. 

import numpy as np
import pandas as pd
from dataclasses import dataclass
from typing import Optional, Tuple
from scipy.optimize import nnls

def ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s)
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out)

def complete_grid_inbound(flows_df: pd.DataFrame, j: str) -> pd.DataFrame:
    d = flows_df[['orig','dest','month','flow']].copy()
    d['month'] = ensure_month(d['month'])
    d = d[d['dest'] == j]
    by_mo = d.groupby(['month','orig'])['flow'].sum().unstack('orig').fillna(0.0).sort_index()
    return by_mo

def monthly_share_series(flows_df: pd.DataFrame, i: str, j: str) -> pd.DataFrame:
    inbound = complete_grid_inbound(flows_df, j=j)
    inbound_j = inbound.sum(axis=1)
    share_ij = inbound.get(i, pd.Series(0.0, index=inbound.index)) / inbound_j.replace(0, np.nan)
    share_ij = share_ij.fillna(0.0)
    return pd.DataFrame({'share_ij': share_ij, 'inbound_j': inbound_j})

def select_window(months: pd.DatetimeIndex, t: pd.Timestamp, kind: str) -> pd.DatetimeIndex:
    if kind == "m0_12":
        start = t - pd.offsets.DateOffset(months=11); end = t
    elif kind == "m6_18":
        start = t - pd.offsets.DateOffset(months=18); end = t - pd.offsets.DateOffset(months=6)
    elif kind == "m12_24":
        start = t - pd.offsets.DateOffset(months=24); end = t - pd.offsets.DateOffset(months=12)
    elif kind == "upto_12":
        start = months.min(); end = t - pd.offsets.DateOffset(months=12)
    else:
        raise ValueError("Unknown window kind")
    return months[(months >= start) & (months <= end)]

def rolling_ma(x: pd.Series, k: int) -> pd.Series:
    return x.rolling(k, min_periods=1).mean() if (k and k>1) else x

from dataclasses import dataclass

@dataclass
class GateConfig:
    mode: Optional[str] = None   # None, 'zscore', 'percentile'
    z_thresh: float = 1.0
    perc_thresh: float = 0.90
    train_end: str = "2021-12-01"
    use_mad: bool = False

def _baseline_stats(base_series: pd.Series, use_mad: bool=False) -> Tuple[float,float]:
    mu = float(base_series.mean())
    if use_mad:
        med = float(base_series.median())
        mad = float((base_series - med).abs().median())
        sd = 1.4826*mad if mad>0 else float(base_series.std(ddof=1))
    else:
        sd = float(base_series.std(ddof=1))
    return mu, sd

def apply_gate(w_raw: float, share_window: pd.Series, share_baseline_monthly: pd.Series, gate: GateConfig) -> float:
    if gate.mode is None:
        return w_raw
    mean_share = float(share_window.mean()) if len(share_window)>0 else 0.0
    if gate.mode == "zscore":
        mu, sd = _baseline_stats(share_baseline_monthly, gate.use_mad)
        se = (sd / np.sqrt(max(len(share_window),1))) if sd>0 else 0.0
        z = (mean_share - mu) / (se if se>0 else 1.0)
        return w_raw if z >= gate.z_thresh else 0.0
    elif gate.mode == "percentile":
        thr = float(np.quantile(share_baseline_monthly.values, gate.perc_thresh))
        return w_raw if mean_share >= thr else 0.0
    else:
        raise ValueError("Unknown gate mode")

@dataclass
class RawShareConfig:
    window: str = "m12_24"
    smooth_ma: int = 0
    gate: GateConfig = GateConfig()
    min_months: int = 3
    volume_weighted: bool = True

def weight_raw_share(flows_df: pd.DataFrame, i: str, j: str, cfg: RawShareConfig) -> pd.Series:
    sj = monthly_share_series(flows_df, i, j)
    months = sj.index
    base_mask = months <= pd.to_datetime(cfg.gate.train_end)
    base_monthly = sj.loc[base_mask, 'share_ij'] if base_mask.any() else sj['share_ij']
    vals = []
    for t in months:
        win = select_window(months, t, cfg.window)
        if len(win) < cfg.min_months:
            vals.append(0.0); continue
        if cfg.volume_weighted:
            num = (sj.loc[win, 'share_ij'] * sj.loc[win, 'inbound_j']).sum()
            den = sj.loc[win, 'inbound_j'].sum()
            w_raw = float(num / den) if den>0 else 0.0
        else:
            w_raw = float(sj.loc[win, 'share_ij'].mean())
        w_raw = apply_gate(w_raw, sj.loc[win, 'share_ij'], base_monthly, cfg.gate)
        vals.append(w_raw)
    w = pd.Series(vals, index=months, name=f"w_raw_{i}_to_{j}_{cfg.window}")
    return rolling_ma(w, cfg.smooth_ma)

@dataclass
class RatioShareConfig:
    window: str = "m12_24"
    smooth_ma: int = 0
    gate: GateConfig = GateConfig()
    min_months: int = 3
    volume_weighted: bool = False
    train_end: str = "2021-12-01"
    eps: float = 1e-6
    cap: Optional[float] = None

def weight_ratio_share(flows_df: pd.DataFrame, i: str, j: str, cfg: RatioShareConfig) -> pd.Series:
    sj = monthly_share_series(flows_df, i, j)
    months = sj.index
    base_mask = months <= pd.to_datetime(cfg.train_end)
    base_series = sj.loc[base_mask, 'share_ij'] if base_mask.any() else sj['share_ij']
    base_mean = float(base_series.mean())
    base_mean = max(base_mean, cfg.eps)
    vals = []
    for t in months:
        win = select_window(months, t, cfg.window)
        if len(win) < cfg.min_months:
            vals.append(0.0); continue
        if cfg.volume_weighted:
            num = (sj.loc[win, 'share_ij'] * sj.loc[win, 'inbound_j']).sum()
            den = sj.loc[win, 'inbound_j'].sum()
            win_mean = float(num / den) if den>0 else 0.0
        else:
            win_mean = float(sj.loc[win, 'share_ij'].mean())
        ratio = win_mean / base_mean
        if cfg.cap is not None:
            ratio = float(np.clip(ratio, 0.0, cfg.cap))
        gated = apply_gate(ratio, sj.loc[win, 'share_ij'], base_series, cfg.gate)
        vals.append(gated)
    w = pd.Series(vals, index=months, name=f"w_ratio_{i}_to_{j}_{cfg.window}")
    return rolling_ma(w, cfg.smooth_ma)

@dataclass
class StockConfig:
    shift_months: int = 12
    half_life_months: int = 18
    smooth_ma: int = 0

def weight_stock(flows_df: pd.DataFrame, i: str, j: str, cfg: StockConfig) -> pd.Series:
    inbound = complete_grid_inbound(flows_df, j=j)
    months = inbound.index
    shifted = inbound.shift(cfg.shift_months).fillna(0.0)
    r = float(np.exp(-np.log(2)/cfg.half_life_months))
    stocks = shifted.copy()
    for t in range(1, len(stocks)):
        stocks.iloc[t] = r*stocks.iloc[t-1] + shifted.iloc[t]
    total_stock = stocks.sum(axis=1).replace(0, np.nan)
    w = (stocks.get(i, pd.Series(0.0, index=months)) / total_stock).fillna(0.0)
    w.name = f"w_stock_{i}_to_{j}"
    return rolling_ma(w, cfg.smooth_ma)

@dataclass
class LagKernelConfig:
    max_lag: int = 24
    train_end: str = "2021-12-01"
    smooth_ma: int = 0

def fit_lag_kernel(flows_df: pd.DataFrame, i: str, j: str, anom_jk: pd.Series, cfg: LagKernelConfig) -> np.ndarray:
    sj = monthly_share_series(flows_df, i, j)['share_ij']
    s = sj.copy(); s.index = pd.to_datetime(s.index).values.astype('datetime64[M]')
    z = anom_jk.copy(); z.index = pd.to_datetime(z.index).values.astype('datetime64[M]')
    idx = s.index.intersection(z.index)
    s, z = s.loc[idx], z.loc[idx]
    X = np.column_stack([s.shift(l).fillna(0.0).values for l in range(cfg.max_lag+1)])
    train_mask = idx <= pd.to_datetime(cfg.train_end)
    Xtr = X[train_mask.values, :]
    ytr = z.loc[train_mask].values
    k_raw, _ = nnls(Xtr, np.maximum(ytr, 0.0))
    if k_raw.sum() == 0:
        k = np.ones(cfg.max_lag+1) / (cfg.max_lag+1)
    else:
        k = k_raw / k_raw.sum()
    return k

def weight_lag_kernel(flows_df: pd.DataFrame, i: str, j: str, kernel: np.ndarray, smooth_ma: int = 0) -> pd.Series:
    sj = monthly_share_series(flows_df, i, j)['share_ij']
    s = sj.copy(); s.index = pd.to_datetime(s.index).values.astype('datetime64[M]')
    L = len(kernel)-1
    mat = np.column_stack([s.shift(l).fillna(0.0).values for l in range(L+1)])
    w = pd.Series(mat @ kernel, index=s.index, name=f"w_lagkernel_{i}_to_{j}")
    return rolling_ma(w, smooth_ma)

@dataclass
class VWBaselineRatioConfig:
    window: str = "m12_24"
    smooth_ma: int = 0
    min_months: int = 3
    gate: GateConfig = GateConfig(mode=None)
    # Set your baseline explicitly; if None, uses the full observed range.
    baseline_start: Optional[str] = None
    baseline_end: Optional[str] = None
    eps: float = 1e-6
    cap: Optional[float] = None

def weight_ratio_vw_baseline(flows_df: pd.DataFrame, i: str, j: str, cfg: VWBaselineRatioConfig) -> pd.Series:
    sj = monthly_share_series(flows_df, i, j)  # columns: share_ij, inbound_j
    months = sj.index

    # ---- Baseline period (defaults to full data if not supplied)
    base_start = pd.to_datetime(cfg.baseline_start) if cfg.baseline_start else months.min()
    base_end   = pd.to_datetime(cfg.baseline_end)   if cfg.baseline_end   else months.max()
    base_mask = (months >= base_start) & (months <= base_end)

    shares_b = sj.loc[base_mask, 'share_ij']
    inb_b    = sj.loc[base_mask, 'inbound_j']
    base_flow = float((shares_b * inb_b).sum())
    base_inb  = float(inb_b.sum())
    baseline_vw_share = base_flow / base_inb if base_inb > 0 else 0.0
    baseline_vw_share = max(baseline_vw_share, cfg.eps)

    # We'll use the monthly baseline shares for gating, if enabled
    baseline_monthly_series = shares_b

    # ---- Per-t month computation
    vals = []
    for t in months:
        win = select_window(months, t, cfg.window)
        if len(win) < cfg.min_months:
            vals.append(0.0); continue

        shares_w = sj.loc[win, 'share_ij']
        inb_w    = sj.loc[win, 'inbound_j']
        num = float((shares_w * inb_w).sum())
        den = float(inb_w.sum())
        win_vw_share = num / den if den > 0 else 0.0

        ratio = win_vw_share / baseline_vw_share
        if cfg.cap is not None:
            ratio = float(np.clip(ratio, 0.0, cfg.cap))

        # Gate against the raw share window vs baseline monthly (same behavior as other weights)
        gated = apply_gate(ratio, shares_w, baseline_monthly_series, cfg.gate)
        vals.append(gated)

    s = pd.Series(vals, index=months, name=f"w_ratio_vw_{i}_to_{j}_{cfg.window}")
    return rolling_ma(s, cfg.smooth_ma)


# //////////////////////////////////

# --- helpers to attach weights back onto flows_df ---

def _series_to_frame(s: pd.Series, i: str, j: str, colname: str) -> pd.DataFrame:
    """Turn a monthly-indexed Series into a tidy frame to merge back."""
    out = s.rename(colname).to_frame().reset_index().rename(columns={'index': 'month'})
    out['month'] = ensure_month(out['month'])
    out['orig'] = i
    out['dest'] = j
    return out[['orig', 'dest', 'month', colname]]

from typing import Iterable, List, Tuple, Literal

WeightKind = Literal['w_raw', 'w_ratio', 'w_stock', 'w_lagkernel', 'w_ratio_vw']

def add_weight_column(
    flows_df: pd.DataFrame,
    kind: WeightKind,
    pairs: Optional[Iterable[Tuple[str, str]]] = None,
    *,
    raw_cfg: RawShareConfig = RawShareConfig(),
    ratio_cfg: RatioShareConfig = RatioShareConfig(),
    stock_cfg: StockConfig = StockConfig(),
    # For lag-kernel you need a pre-fit kernel per (i,j); see example below.
    lag_kernels: Optional[dict] = None,
    smooth_ma_override: Optional[int] = None,
    column_name: Optional[str] = None,
    ratio_vw_cfg: VWBaselineRatioConfig = VWBaselineRatioConfig(),
) -> pd.DataFrame:
    """
    Compute the requested weight for each (orig,dest) pair and merge the values
    back into flows_df as a single new column. Returns a modified copy.

    - kind: 'w_raw' | 'w_ratio' | 'w_stock' | 'w_lagkernel' | 'w_ratio_vw'
    - pairs: list of (i, j). If None, runs for *all* observed pairs in flows_df.
    - *_cfg: pass your configs; smooth_ma_override can override their smoothing.
    - column_name: name of the added column; defaults to kind.
    """
    d = flows_df.copy()
    d['month'] = ensure_month(d['month'])

    col = column_name or kind

    # Decide which pairs to run
    if pairs is None:
        pairs = d[['orig', 'dest']].drop_duplicates().itertuples(index=False, name=None)

    pieces: List[pd.DataFrame] = []

    for i, j in pairs:
        if kind == 'w_raw':
            cfg = raw_cfg
            if smooth_ma_override is not None:
                cfg = dataclass_replace(cfg, smooth_ma=smooth_ma_override)
            s = weight_raw_share(d, i, j, cfg)

        elif kind == 'w_ratio':
            cfg = ratio_cfg
            if smooth_ma_override is not None:
                cfg = dataclass_replace(cfg, smooth_ma=smooth_ma_override)
            s = weight_ratio_share(d, i, j, cfg)

        elif kind == 'w_stock':
            cfg = stock_cfg
            if smooth_ma_override is not None:
                cfg = dataclass_replace(cfg, smooth_ma=smooth_ma_override)
            s = weight_stock(d, i, j, cfg)

        elif kind == 'w_lagkernel':
            if lag_kernels is None or (i, j) not in lag_kernels:
                # If no kernel provided, skip this pair gracefully.
                continue
            kernel, smooth_ma = lag_kernels[(i, j)]
            sm = smooth_ma_override if smooth_ma_override is not None else smooth_ma
            s = weight_lag_kernel(d, i, j, kernel=kernel, smooth_ma=sm)
            
        elif kind == 'w_ratio_vw':
            cfg = ratio_vw_cfg
            if smooth_ma_override is not None:
                cfg = dataclass_replace(cfg, smooth_ma=smooth_ma_override)
            s = weight_ratio_vw_baseline(d, i, j, cfg)
            
        else:
            raise ValueError(f"Unknown kind={kind}")

        pieces.append(_series_to_frame(s, i, j, col))

    if not pieces:
        # Nothing computed; return the original frame
        d[col] = np.nan
        return d

    weights_df = pd.concat(pieces, ignore_index=True)

    # Merge back onto the original rows; only the matching (i,j,month) rows get values.
    d = d.merge(weights_df, on=['orig', 'dest', 'month'], how='left')

    return d


# small utility to override dataclass fields without mutating originals
from dataclasses import replace as dataclass_replace
