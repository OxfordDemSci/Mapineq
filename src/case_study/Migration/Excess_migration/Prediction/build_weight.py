import numpy as np
import pandas as pd
from typing import Optional

# ---------- helpers ----------
def ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s)
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out)

def _window_bounds(t: pd.Timestamp, x_months_ago: int, y_months_ago: int):
    start = t - pd.offsets.DateOffset(months=y_months_ago)
    end   = t - pd.offsets.DateOffset(months=x_months_ago)
    return start, end

def _validate_xy(x_months_ago: int, y_months_ago: int):
    if x_months_ago < 0 or y_months_ago < 0 or y_months_ago < x_months_ago:
        raise ValueError("Require 0 <= x_months_ago <= y_months_ago.")

# ---------- core series ----------
def share_window_ago(
    flows_df: pd.DataFrame,
    i: str,
    j: str,
    *,
    x_months_ago: int,
    y_months_ago: int,
    volume_weighted: bool = False
) -> pd.Series:
    """
    For each month t, average S_{i->j,t'} = (i->j)/(all->j) over t' in [t-y, t-x] (inclusive).
    Unweighted by default; if volume_weighted=True, weight by inbound volume J_{t'}.
    """
    _validate_xy(x_months_ago, y_months_ago)

    d = flows_df[['orig','dest','month','flow']].copy()
    d['month'] = ensure_month(d['month'])

    dj = d[d['dest'] == j]
    inbound_j = dj.groupby('month')['flow'].sum().sort_index().rename('J')

    fij = (dj[dj['orig'] == i]
           .groupby('month')['flow'].sum()
           .reindex(inbound_j.index, fill_value=0.0)
           .rename('Fij'))

    share = (fij / inbound_j.replace(0, np.nan)).fillna(0.0)

    months = inbound_j.index
    out_vals = []
    for t in months:
        start, end = _window_bounds(t, x_months_ago, y_months_ago)
        win = months[(months >= start) & (months <= end)]
        if len(win) == 0:
            out_vals.append(0.0)
            continue
        if volume_weighted:
            num = (share.loc[win] * inbound_j.loc[win]).sum()
            den = inbound_j.loc[win].sum()
            val = float(num / den) if den > 0 else 0.0
        else:
            val = float(share.loc[win].mean())
        out_vals.append(val)

    name = f"share_{i}_to_{j}_m{y_months_ago}_to_m{x_months_ago}"
    return pd.Series(out_vals, index=months, name=name)

# ---------- 1) plain windowed share -> default column 'weight' ----------
def add_share_window_simple(
    flows_df: pd.DataFrame,
    i: str,
    j: str,
    *,
    x_months_ago: int,
    y_months_ago: int,
    volume_weighted: bool = False,
    column_name: Optional[str] = None,
    attach_to_frame: bool = True,
):
    """
    Attach the windowed share (optionally volume-weighted) to `flows_df` in column `column_name` (default 'weight').
    If the column already exists, preserve existing values and write only on (orig==i, dest==j) rows.
    Returns (updated_df, series) if attach_to_frame=True; otherwise just the Series.
    """
    s = share_window_ago(
        flows_df, i, j,
        x_months_ago=x_months_ago,
        y_months_ago=y_months_ago,
        volume_weighted=volume_weighted
    )

    col = column_name or "weight"
    if not attach_to_frame:
        return s.rename(col)

    out = flows_df.copy()
    out['month'] = ensure_month(out['month'])

    # Ensure the target column exists so we can preserve prior values
    if col not in out.columns:
        out[col] = np.nan

    tmpcol = f"__new_{col}"
    s_df = (s.rename(tmpcol)
              .to_frame()
              .reset_index()
              .rename(columns={'index': 'month'}))

    mask = (out['orig'] == i) & (out['dest'] == j)
    out = out.merge(s_df, on='month', how='left')
    # Write only into current (i,j) rows; keep existing elsewhere
    out[col] = np.where(mask, out[tmpcol], out[col])
    out = out.drop(columns=[tmpcol])
    return out, s.rename(col)

# ---------- 2) windowed share / baseline share -> default column 'weight_ratio' ----------
def add_share_window_weight(
    flows_df: pd.DataFrame,
    i: str,
    j: str,
    *,
    x_months_ago: int,
    y_months_ago: int,
    column_name: Optional[str] = None,
    eps: float = 1e-12,
    attach_to_frame: bool = True,
):
    """
    weight_t = (UNWEIGHTED average of (i->j / all->j) over [t-y, t-x]) / baseline_share
    baseline_share = (sum over all months of i->j) / (sum over all months of all->j)

    If the column already exists, preserve existing values and write only on (orig==i, dest==j) rows.
    """
    # 1) unweighted windowed share
    s_unweighted = share_window_ago(
        flows_df, i, j,
        x_months_ago=x_months_ago,
        y_months_ago=y_months_ago,
        volume_weighted=False
    )

    # 2) baseline share
    d = flows_df[['orig','dest','month','flow']].copy()
    d['month'] = ensure_month(d['month'])
    dj = d[d['dest'] == j]
    inbound_j = dj.groupby('month')['flow'].sum().sort_index()
    fij = (dj[dj['orig'] == i]
           .groupby('month')['flow'].sum()
           .reindex(inbound_j.index, fill_value=0.0))

    baseline_share = float(fij.sum() / inbound_j.sum()) if inbound_j.sum() > 0 else 0.0
    baseline_share = max(baseline_share, eps)

    w = (s_unweighted / baseline_share)

    col = column_name or "weight_ratio"
    w = w.rename(col)

    if not attach_to_frame:
        return w

    out = flows_df.copy()
    out['month'] = ensure_month(out['month'])

    # Ensure the target column exists so we can preserve prior values
    if col not in out.columns:
        out[col] = np.nan

    tmpcol = f"__new_{col}"
    w_df = (w.rename(tmpcol)
              .to_frame()
              .reset_index()
              .rename(columns={'index': 'month'}))

    mask = (out['orig'] == i) & (out['dest'] == j)
    out = out.merge(w_df, on='month', how='left')
    out[col] = np.where(mask, out[tmpcol], out[col])
    out = out.drop(columns=[tmpcol])
    return out, w
