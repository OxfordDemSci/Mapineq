from dataclasses import dataclass
from typing import List, Tuple, Optional
import pandas as pd
import numpy as np

@dataclass
class CounterfactualConfig:
    train_start: str = "2019-01-01"
    train_end: str   = "2021-12-01"
    corridor_specific_seasonality: bool = True
    eps: float = 1.0

def ensure_month_dtype(df: pd.DataFrame, month_col: str = "month") -> pd.DataFrame:
    out = df.copy()
    if not np.issubdtype(out[month_col].dtype, np.datetime64):
        out[month_col] = pd.to_datetime(out[month_col])
    out[month_col] = out[month_col].values.astype("datetime64[M]")
    out[month_col] = pd.to_datetime(out[month_col])
    return out

def complete_months(df: pd.DataFrame, month_col: str = "month") -> pd.DataFrame:
    out = ensure_month_dtype(df, month_col)
    months = pd.date_range(out[month_col].min(), out[month_col].max(), freq="MS")
    pairs = out[['orig','dest']].drop_duplicates().assign(key=1)
    months_df = pd.DataFrame({month_col: months, 'key':1})
    full = pairs.merge(months_df, on='key', how='outer').drop(columns='key')
    out = full.merge(out, on=['orig','dest',month_col], how='left')
    out['flow'] = out['flow'].fillna(0.0)
    return out

def compute_global_trend(df: pd.DataFrame, cfg: CounterfactualConfig) -> pd.Series:
    d = ensure_month_dtype(df)
    monthly_total = d.groupby('month')['flow'].sum().sort_index()
    train_mask = (monthly_total.index >= pd.to_datetime(cfg.train_start)) &                  (monthly_total.index <= pd.to_datetime(cfg.train_end))
    global_mean = monthly_total.loc[train_mask].mean()
    G = monthly_total / (global_mean if global_mean != 0 else 1.0)
    return G

def compute_mu_and_seasonality(df: pd.DataFrame, cfg: CounterfactualConfig):
    d = complete_months(df)
    d['moy'] = d['month'].dt.month
    train_mask = (d['month'] >= pd.to_datetime(cfg.train_start)) &                  (d['month'] <= pd.to_datetime(cfg.train_end))
    train = d.loc[train_mask].copy()
    mu = train.groupby(['orig','dest'])['flow'].mean().rename('mu')
    if cfg.corridor_specific_seasonality:
        season = (train.groupby(['orig','dest','moy'])['flow']
                        .mean()
                        .to_frame('avg_moy')
                        .join(mu, on=['orig','dest']))
        season['season_factor'] = np.where(season['mu']>0, season['avg_moy']/season['mu'], 1.0)
        S = season['season_factor']
    else:
        global_by_moy = train.groupby('moy')['flow'].sum()
        global_mean = global_by_moy.mean()
        global_S = np.where(global_mean>0, global_by_moy / global_mean, 1.0)
        S = pd.Series(global_S, index=global_by_moy.index).rename('season_factor')
    return mu, S

def build_counterfactual(df: pd.DataFrame, mu: pd.Series, S, G: pd.Series, cfg: CounterfactualConfig) -> pd.Series:
    d = complete_months(df).copy()
    d['moy'] = d['month'].dt.month
    mu_aligned = d.set_index(['orig','dest']).index.map(mu.to_dict()).astype(float)
    if cfg.corridor_specific_seasonality:
        key = list(zip(d['orig'], d['dest'], d['moy']))
        S_dict = S.to_dict()
        S_aligned = np.array([S_dict.get(k, 1.0) for k in key], dtype=float)
    else:
        S_dict = S.to_dict()
        S_aligned = d['moy'].map(S_dict).fillna(1.0).astype(float).values
    G_aligned = d['month'].map(G).fillna(1.0).astype(float).values
    ehat = (mu_aligned * S_aligned * G_aligned)
    ehat = np.nan_to_num(ehat, nan=0.0, posinf=None, neginf=None)
    return pd.Series(ehat, index=d.index, name='ehat')

def compute_percent_excess(actual: pd.Series, ehat: pd.Series, eps: float = 1.0) -> pd.Series:
    denom = np.maximum(ehat.values, eps)
    excess = (actual.values - ehat.values) / denom
    return pd.Series(excess, index=actual.index, name='excess_pct')

def trailing_share_i_to_j(df: pd.DataFrame, i: str, j: str, window: int = 12) -> pd.Series:
    d = complete_months(df)
    d = d[d['dest'] == j].copy()
    mat = d.pivot_table(index='month', columns='orig', values='flow', aggfunc='sum').fillna(0.0).sort_index()
    num = mat.get(i, pd.Series(0.0, index=mat.index)).rolling(window, min_periods=1).sum()
    den = mat.rolling(window, min_periods=1).sum().sum(axis=1)
    w = num / den.replace(0, np.nan)
    return w.fillna(0.0).rename(f"w_{i}_to_{j}")

def compute_eop_lite(df: pd.DataFrame,
                     triads: List[Tuple[str,str,str]],
                     cfg: CounterfactualConfig) -> pd.DataFrame:
    d = complete_months(df).copy()
    G = compute_global_trend(d, cfg)
    mu, S = compute_mu_and_seasonality(d, cfg)
    d['moy'] = d['month'].dt.month
    ehat_all = build_counterfactual(d[['orig','dest','month','flow']], mu, S, G, cfg)
    d = d.join(ehat_all)
    results = []
    for (i,j,k) in triads:
        mask_jk = (d['orig']==j) & (d['dest']==k)
        sub = d.loc[mask_jk, ['month','flow','ehat']].copy().sort_values('month')
        if sub.empty:
            continue
        excess = compute_percent_excess(sub['flow'], sub['ehat'], eps=cfg.eps)
        w = trailing_share_i_to_j(d[['orig','dest','month','flow']], i=i, j=j, window=12)
        aligned = sub[['month']].merge(w.rename('w'), left_on='month', right_index=True, how='left')
        aligned['w'] = aligned['w'].fillna(0.0)
        tmp = pd.DataFrame({
            'i': i, 'j': j, 'k': k,
            'month': sub['month'].values,
            'flow_jk': sub['flow'].values,
            'ehat_jk': sub['ehat'].values,
            'excess_jk': excess.values,
            'w_ij': aligned['w'].values
        })
        tmp['eop_lite'] = tmp['excess_jk'] * tmp['w_ij']
        results.append(tmp)
    if not results:
        return pd.DataFrame(columns=['i','j','k','month','flow_jk','ehat_jk','excess_jk','w_ij','eop_lite'])
    out = pd.concat(results, ignore_index=True).sort_values(['i','j','k','month'])
    return out