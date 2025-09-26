from dataclasses import dataclass
from typing import List, Tuple, Optional, Dict
import numpy as np
import pandas as pd

def _ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s)
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out)

def _complete_grid_pairs_months(df: pd.DataFrame) -> pd.DataFrame:
    d = df.copy()
    d['month'] = _ensure_month(d['month'])
    pairs = d[['orig','dest']].drop_duplicates().assign(key=1)
    months = pd.date_range(d['month'].min(), d['month'].max(), freq='MS')
    months_df = pd.DataFrame({'month': months, 'key':1})
    full = pairs.merge(months_df, on='key', how='outer').drop(columns='key')
    out = full.merge(d, on=['orig','dest','month'], how='left')
    out['flow'] = out['flow'].fillna(0.0)
    return out

# ---------------- Anomalies from pred.csv ----------------

@dataclass
class AnomalyConfig:
    train_end: str = "2021-12-01"
    eps: float = 1.0
    use_standardized: bool = True

def anomalies_from_pred(pred_df: pd.DataFrame, cfg: AnomalyConfig) -> pd.DataFrame:
    d = pred_df.copy()
    req = {'orig','dest','month','flow','mu_hat'}
    if not req.issubset(set(d.columns)):
        missing = req - set(d.columns)
        raise ValueError(f"pred_df is missing columns: {missing}")
    d['month'] = _ensure_month(d['month'])
    train_mask = d['month'] <= pd.to_datetime(cfg.train_end)
    train = d.loc[train_mask].copy()
    mu = np.maximum(train['mu_hat'].values, 1e-9)
    chi2 = ((train['flow'].values - mu)**2) / mu
    n = len(train)
    p_pairs = train[['orig','dest']].drop_duplicates().shape[0] - 1
    p_months = train['month'].nunique() - 1
    p_eff = max(p_pairs + p_months, 1)
    dof = max(n - p_eff, 1)
    phi_hat = float(np.sum(chi2) / dof)
    denom_sd = np.sqrt(np.maximum(phi_hat * np.maximum(d['mu_hat'].values, 1e-9), 1e-9))
    z_std = (d['flow'].values - d['mu_hat'].values) / denom_sd
    excess = (d['flow'].values - d['mu_hat'].values) / np.maximum(d['mu_hat'].values, cfg.eps)
    d['z_std'] = z_std
    d['excess_pct'] = excess
    d.attrs['phi_hat'] = phi_hat
    d.attrs['train_end'] = cfg.train_end
    return d

# ---------------- Share-based weights (as you had) ----------------

@dataclass
class WeightConfig:
    window: str = "m12_24"   # 'm0_12','m6_18','m12_24','upto_12'
    smooth_ma: int = 0
    gate_mode: Optional[str] = None   # None, 'zscore', 'percentile'  (share-based gate)
    z_thresh: float = 1.0
    perc_thresh: float = 0.9
    train_end: str = "2021-12-01"
    min_months: int = 3
    use_mad: bool = False
    label: Optional[str] = None

def _weight_label(cfg: WeightConfig) -> str:
    base = cfg.window
    if cfg.gate_mode == "zscore":
        base += f"|z≥{cfg.z_thresh:g}"
    elif cfg.gate_mode == "percentile":
        base += f"|p{int(cfg.perc_thresh*100)}"
    if cfg.smooth_ma and cfg.smooth_ma > 1:
        base += f"|ma{cfg.smooth_ma}"
    return base

def _window_months(all_months: pd.DatetimeIndex, t: pd.Timestamp, kind: str) -> pd.DatetimeIndex:
    if kind == "m0_12":
        start = t - pd.offsets.DateOffset(months=11); end = t
    elif kind == "m6_18":
        start = t - pd.offsets.DateOffset(months=18); end = t - pd.offsets.DateOffset(months=6)
    elif kind == "m12_24":
        start = t - pd.offsets.DateOffset(months=24); end = t - pd.offsets.DateOffset(months=12)
    elif kind == "upto_12":
        start = all_months.min(); end = t - pd.offsets.DateOffset(months=12)
    else:
        raise ValueError("Unknown window kind")
    return all_months[(all_months >= start) & (all_months <= end)]

def _monthly_share_series(flows_df: pd.DataFrame, i: str, j: str) -> pd.DataFrame:
    d = _complete_grid_pairs_months(flows_df[['orig','dest','month','flow']])
    d = d[d['dest']==j].copy()
    by_mo = d.groupby(['month','orig'])['flow'].sum().unstack('orig').fillna(0.0).sort_index()
    inbound = by_mo.sum(axis=1)
    share_ij = by_mo.get(i, pd.Series(0.0, index=by_mo.index)) / inbound.replace(0, np.nan)
    share_ij = share_ij.fillna(0.0)
    out = pd.DataFrame({'share_ij': share_ij, 'inbound_j': inbound})
    return out

def _baseline_stats_for_gating(share_df: pd.DataFrame, train_end: str, use_mad: bool=False) -> dict:
    mask = share_df.index <= pd.to_datetime(train_end)
    base = share_df.loc[mask, 'share_ij']
    mu = float(base.mean())
    if use_mad:
        med = float(base.median()); mad = float((base - med).abs().median())
        sd = 1.4826*mad if mad>0 else float(base.std(ddof=1))
    else:
        sd = float(base.std(ddof=1))
    return {'mean': mu, 'sd': sd}

def weight_series(flows_df: pd.DataFrame, i: str, j: str, cfg: WeightConfig) -> pd.Series:
    shares = _monthly_share_series(flows_df, i, j)
    months = shares.index
    base_stats = _baseline_stats_for_gating(shares, cfg.train_end, cfg.use_mad) if cfg.gate_mode else None
    w_vals = []
    for t in months:
        win = _window_months(months, t, cfg.window)
        if len(win) < cfg.min_months:
            w_vals.append(0.0); continue
        inbound_win = shares.loc[win, 'inbound_j'].sum()
        if inbound_win <= 0:
            w_vals.append(0.0); continue
        num = (shares.loc[win, 'share_ij'] * shares.loc[win, 'inbound_j']).sum()
        w_raw = float(num / inbound_win)
        if cfg.gate_mode:
            mean_share = float(shares.loc[win, 'share_ij'].mean())
            if cfg.gate_mode == 'zscore':
                mu, sd = base_stats['mean'], base_stats['sd']
                se = (sd/np.sqrt(len(win))) if sd>0 else 0.0
                z = (mean_share - mu) / (se if se>0 else 1.0)
                if not (z >= cfg.z_thresh):
                    w_raw = 0.0
            elif cfg.gate_mode == 'percentile':
                base_monthly = shares.loc[shares.index <= pd.to_datetime(cfg.train_end), 'share_ij']
                thr = float(np.quantile(base_monthly.values, cfg.perc_thresh))
                if not (mean_share >= thr):
                    w_raw = 0.0
            else:
                raise ValueError("Unknown gate_mode")
        w_vals.append(w_raw)
    w = pd.Series(w_vals, index=months, name=f"w_{i}_to_{j}_{cfg.window}")
    if cfg.smooth_ma and cfg.smooth_ma>1:
        w = w.rolling(cfg.smooth_ma, min_periods=1).mean()
    return w

# ---------------- NEW: anomaly-based gate ----------------

@dataclass
class GateConfig:
    use_downstream_anom: bool = False   # gate on Z_{j->k,t}
    use_upstream_anom: bool = False     # gate on Z_{i->j,t}
    logic: str = "and"                  # 'and' or 'or' when both True
    z_thresh_jk: float = 1.0            # threshold for downstream anomaly
    z_thresh_ij: float = 1.0            # threshold for upstream anomaly
    anomaly_col: str = "z_std"          # or 'excess_pct'
    soft: bool = False                  # if True, soft ramp gate in [0,1]; else hard 0/1
    label: Optional[str] = None         # optional suffix label for output

def _anom_gate_values(sub_jk: pd.DataFrame,
                      up_ij: pd.Series,
                      gc: GateConfig,
                      anomaly_kind: str) -> np.ndarray:
    # downstream gate
    if gc.use_downstream_anom:
        zjk = sub_jk[anomaly_kind].astype(float).values
        if gc.soft:
            g_jk = np.clip(zjk / max(gc.z_thresh_jk, 1e-9), 0.0, 1.0)
        else:
            g_jk = (zjk >= gc.z_thresh_jk).astype(float)
    else:
        g_jk = np.ones(len(sub_jk), dtype=float)

    # upstream gate (align by month)
    if gc.use_upstream_anom:
        z_up = up_ij.reindex(sub_jk['month']).astype(float).values
        if gc.soft:
            g_ij = np.clip(z_up / max(gc.z_thresh_ij, 1e-9), 0.0, 1.0)
        else:
            g_ij = (z_up >= gc.z_thresh_ij).astype(float)
    else:
        g_ij = np.ones(len(sub_jk), dtype=float)

    if gc.use_downstream_anom and gc.use_upstream_anom:
        if gc.logic.lower() == "and":
            g = g_jk * g_ij
        elif gc.logic.lower() == "or":
            g = np.maximum(g_jk, g_ij) if gc.soft else ((np.maximum(g_jk, g_ij) > 0).astype(float))
        else:
            raise ValueError("GateConfig.logic must be 'and' or 'or'")
    else:
        g = g_jk if gc.use_downstream_anom else g_ij
    return g

def _gate_label(gc: Optional[GateConfig]) -> str:
    if not gc or (not gc.use_downstream_anom and not gc.use_upstream_anom):
        return ""
    parts = []
    if gc.use_downstream_anom:
        parts.append(f"dj≥{gc.z_thresh_jk:g}")
    if gc.use_upstream_anom:
        parts.append(f"ui≥{gc.z_thresh_ij:g}")
    if gc.logic and gc.use_downstream_anom and gc.use_upstream_anom:
        parts.append(gc.logic.lower())
    if gc.soft:
        parts.append("soft")
    return "|A:" + ",".join(parts)

# ---------------- Assemble EOP with optional anomaly gate ----------------

def compute_eop(pred_with_anom: pd.DataFrame,
                flows_df: pd.DataFrame,
                triads: List[Tuple[str,str,str]],
                windows: List[WeightConfig],
                anomaly_kind: str = "z_std",
                gate_cfg: Optional[GateConfig] = None) -> pd.DataFrame:
    d = pred_with_anom.copy()
    d['month'] = _ensure_month(d['month'])
    out = []
    for (i,j,k) in triads:
        sub = d[(d['orig']==j)&(d['dest']==k)].copy().sort_values('month')
        if sub.empty: 
            continue
        up = d[(d['orig']==i)&(d['dest']==j)].copy()
        up = up.set_index('month')[anomaly_kind] if not up.empty else pd.Series(0.0, index=sub['month']).rename(anomaly_kind)
        for wcfg in windows:
            w_series = weight_series(flows_df, i, j, wcfg)
            subw = sub.merge(w_series.rename('w_ij'), left_on='month', right_index=True, how='left')
            subw['w_ij'] = subw['w_ij'].fillna(0.0)
            eop_val = subw[anomaly_kind].values * subw['w_ij'].values
            if gate_cfg:
                g = _anom_gate_values(subw[['month', anomaly_kind]], up, gate_cfg, anomaly_kind)
                eop_val = eop_val * g
                gate_suffix = gate_cfg.label or _gate_label(gate_cfg)
            else:
                gate_suffix = ""
            win_label = (wcfg.label or _weight_label(wcfg)) + gate_suffix
            eop = pd.DataFrame({
                'i': i, 'j': j, 'k': k,
                'label': win_label,
                'window': wcfg.window,
                'month': subw['month'].values,
                'flow_jk': subw['flow'].values,
                'mu_hat_jk': subw['mu_hat'].values,
                'anom_jk': subw[anomaly_kind].values,
                'w_ij': subw['w_ij'].values,
                'EOP': eop_val
            })
            out.append(eop)
    if not out:
        return pd.DataFrame(columns=['i','j','k','window','month','flow_jk','mu_hat_jk','anom_jk','w_ij','EOP'])
    return pd.concat(out, ignore_index=True).sort_values(['i','j','k','window','month'])