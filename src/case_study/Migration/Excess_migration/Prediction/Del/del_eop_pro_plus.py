from dataclasses import dataclass
from typing import List, Tuple, Optional
import pandas as pd
import numpy as np
from scipy import sparse
from sklearn.preprocessing import OneHotEncoder
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_absolute_error
from tqdm.auto import tqdm   # NEW

# ---------- OneHotEncoder (version-safe) ----------
def _make_ohe(drop_first=True):
    """Create a OneHotEncoder that works on sklearn>=1.4 and older versions."""
    kw = dict(handle_unknown='ignore')
    if drop_first:
        kw['drop'] = 'first'
    try:
        # sklearn >= 1.2 (esp. 1.4+) uses 'sparse_output'
        return OneHotEncoder(sparse_output=True, **kw)
    except TypeError:
        # sklearn <= 1.1 uses 'sparse'
        return OneHotEncoder(sparse=True, **kw)

# ---------- helpers for month grid ----------
def _ensure_month(df: pd.DataFrame, col='month'):
    out = df.copy()
    out[col] = pd.to_datetime(out[col])
    out[col] = out[col].values.astype("datetime64[M]")
    out[col] = pd.to_datetime(out[col])
    return out

def _complete_grid(df: pd.DataFrame):
    d = _ensure_month(df)
    d['pair'] = d['orig'] + '→' + d['dest']
    d['time_id'] = d['month'].dt.strftime('%Y-%m')
    months = pd.date_range(d['month'].min(), d['month'].max(), freq='MS')
    pairs = d[['pair','orig','dest']].drop_duplicates().assign(key=1)
    months_df = pd.DataFrame({'month': months, 'time_id': months.strftime('%Y-%m'), 'key':1})
    full = pairs.merge(months_df, on='key', how='outer').drop(columns='key')
    d = full.merge(d[['pair','month','time_id','flow']], on=['pair','month','time_id'], how='left')
    d['flow'] = d['flow'].fillna(0.0)
    d[['orig','dest']] = d['pair'].str.split('→', expand=True)
    return d[['orig','dest','pair','month','time_id','flow']].sort_values(['pair','month']).reset_index(drop=True)

# # ---------- config ----------
# @dataclass
# class EOPPlusConfig:
#     train_end: str = "2021-12-01"
#     val_start: str = "2021-07-01"
#     alphas: tuple = (1e-6,1e-5,1e-4,1e-3,1e-2)
#     include_pair_fe: bool = True
#     include_origin_time_fe: bool = True
#     include_dest_time_fe: bool = True
#     use_global_time_fe: bool = False
#     add_sci: bool = True
#     eps: float = 1.0
#     trailing_window: int = 12
#     weight_mode: str = "excess_share"   # "share" or "excess_share"
#     concentration_adjust: bool = False
#     hhi_relative: bool = False
#     # --- NEW: progress bar controls ---
#     progress: bool = True
#     pbar_leave: bool = False
#     pbar_ncols: int = 80

# class EOPProPlus:
#     def __init__(self, cfg: EOPPlusConfig, sci_df: Optional[pd.DataFrame] = None):
#         self.cfg = cfg
#         self.enc_pair = None
#         self.enc_time = None
#         self.enc_orig_time = None
#         self.enc_dest_time = None
#         self.model = None
#         self.best_alpha_ = None
#         self.phi_ = None
#         if sci_df is not None and self.cfg.add_sci:
#             s = sci_df.copy()
#             s['pair'] = s['orig'] + '→' + s['dest']
#             s['sci_logz'] = np.log(s['sci'].clip(lower=1e-12))
#             s['sci_logz'] = (s['sci_logz'] - s['sci_logz'].mean())/(s['sci_logz'].std() + 1e-12)
#             self.sci_lookup = s.set_index('pair')['sci_logz'].to_dict()
#         else:
#             self.sci_lookup = None

#     # --- NEW: small wrapper to centralize tqdm settings
#     def _tqdm(self, iterable, desc: str):
#         return tqdm(
#             iterable, desc=desc,
#             disable=not self.cfg.progress,
#             leave=self.cfg.pbar_leave,
#             ncols=self.cfg.pbar_ncols
#         )

#     def _build_encoders(self, df: pd.DataFrame):
#         if self.cfg.include_pair_fe:
#             self.enc_pair = _make_ohe(drop_first=True).fit(df[['pair']])             # CHANGED to _make_ohe
#         self.enc_time = _make_ohe(drop_first=True).fit(df[['time_id']])              # CHANGED to _make_ohe
#         if self.cfg.include_origin_time_fe:
#             ot = df[['orig','time_id']].astype(str).agg('×'.join, axis=1).to_frame('orig_time')
#             self.enc_orig_time = _make_ohe(drop_first=True).fit(ot)                  # CHANGED to _make_ohe
#         if self.cfg.include_dest_time_fe:
#             dt = df[['dest','time_id']].astype(str).agg('×'.join, axis=1).to_frame('dest_time')
#             self.enc_dest_time = _make_ohe(drop_first=True).fit(dt)                  # CHANGED to _make_ohe

#     def _transform(self, df: pd.DataFrame) -> sparse.csr_matrix:
#         mats = []
#         if self.cfg.include_pair_fe:
#             mats.append(self.enc_pair.transform(df[['pair']]))
#         if self.cfg.use_global_time_fe:
#             mats.append(self.enc_time.transform(df[['time_id']]))
#         if self.cfg.include_origin_time_fe:
#             ot = df[['orig','time_id']].astype(str).agg('×'.join, axis=1).to_frame('orig_time')
#             mats.append(self.enc_orig_time.transform(ot))
#         if self.cfg.include_dest_time_fe:
#             dt = df[['dest','time_id']].astype(str).agg('×'.join, axis=1).to_frame('dest_time')
#             mats.append(self.enc_dest_time.transform(dt))
#         if self.sci_lookup is not None and self.cfg.add_sci:
#             sci = df['pair'].map(self.sci_lookup).fillna(0.0).to_numpy().reshape(-1,1)
#             mats.append(sparse.csr_matrix(sci))
#         if not mats:
#             raise ValueError("No features selected.")
#         return sparse.hstack(mats, format='csr')

#     def fit(self, df_in: pd.DataFrame):
#         d = _complete_grid(df_in)
#         train_mask = d['month'] <= pd.to_datetime(self.cfg.train_end)
#         d_train = d.loc[train_mask].copy()
#         val_start = pd.to_datetime(self.cfg.val_start)
#         val_mask = d_train['month'] >= val_start
#         d_fit = d_train.loc[~val_mask].copy()
#         d_val = d_train.loc[val_mask].copy()
#         if d_val.empty:
#             last6 = d_train['month'].max() - pd.offsets.DateOffset(months=5)
#             val_mask = d_train['month'] >= last6
#             d_fit = d_train.loc[~val_mask].copy()
#             d_val = d_train.loc[val_mask].copy()

#         self._build_encoders(d)
#         X_fit = self._transform(d_fit); y_fit = d_fit['flow'].values
#         X_val = self._transform(d_val); y_val = d_val['flow'].values

#         # --- grid search with progress bar ---
#         best_alpha, best_mae = None, np.inf
#         for a in self._tqdm(self.cfg.alphas, desc="Grid search α"):   # NEW
#             mdl = PoissonRegressor(alpha=a, fit_intercept=False, max_iter=5000)
#             mdl.fit(X_fit, y_fit)
#             pred = mdl.predict(X_val)
#             mae = mean_absolute_error(y_val, pred)
#             if mae < best_mae:
#                 best_mae, best_alpha = mae, a

#         self.best_alpha_ = float(best_alpha)
#         self.model = PoissonRegressor(alpha=self.best_alpha_, fit_intercept=False, max_iter=5000)
#         X_train = self._transform(d_train); y_train = d_train['flow'].values
#         self.model.fit(X_train, y_train)

#         mu_train = self.model.predict(X_train)
#         resid_sq_over_mu = ((y_train - mu_train)**2) / np.maximum(mu_train, 1e-9)
#         p_eff = int(np.sum(self.model.coef_ != 0))
#         dof = max(len(y_train) - p_eff, 1)
#         self.phi_ = float(resid_sq_over_mu.sum() / dof)
#         return self

#     def predict_mu(self, df_in: pd.DataFrame) -> pd.DataFrame:
#         d = _complete_grid(df_in)
#         X = self._transform(d)
#         mu = self.model.predict(X)
#         out = d[['orig','dest','month']].copy()
#         out['mu_hat'] = mu
#         return out

#     def standardized_excess(self, df_in: pd.DataFrame) -> pd.DataFrame:
#         d = _complete_grid(df_in)
#         mu = self.predict_mu(df_in)
#         d = d.merge(mu, on=['orig','dest','month'], how='left')
#         phi = self.phi_ if (self.phi_ is not None and self.phi_>0) else 1.0
#         d['z_std'] = (d['flow'] - d['mu_hat']) / np.sqrt(np.maximum(phi * d['mu_hat'], 1e-9))
#         d['excess_pct'] = (d['flow'] - d['mu_hat']) / np.maximum(d['mu_hat'], self.cfg.eps)
#         return d[['orig','dest','month','flow','mu_hat','z_std','excess_pct']]

#     # Attribution helpers
#     def _trailing_share(self, df_in: pd.DataFrame, i: str, j: str, window: int) -> pd.Series:
#         d = _complete_grid(df_in); d = d[d['dest']==j].copy()
#         mat = d.pivot_table(index='month', columns='orig', values='flow', aggfunc='sum').fillna(0.0).sort_index()
#         num = mat.get(i, pd.Series(0.0, index=mat.index)).rolling(window, min_periods=1).sum()
#         den = mat.rolling(window, min_periods=1).sum().sum(axis=1)
#         return (num / den.replace(0, np.nan)).fillna(0.0)

#     def _baseline_share(self, df_in: pd.DataFrame, i: str, j: str) -> float:
#         d = _complete_grid(df_in)
#         train_mask = d['month'] <= pd.to_datetime(self.cfg.train_end)
#         d = d[train_mask & (d['dest']==j)].copy()
#         mat = d.pivot_table(index='month', columns='orig', values='flow', aggfunc='sum').fillna(0.0)
#         totals = mat.sum(axis=1)
#         share_ts = mat.get(i, pd.Series(0.0, index=mat.index)) / totals.replace(0, np.nan)
#         return float(share_ts.fillna(0.0).mean())

#     def _inflow_hhi(self, df_in: pd.DataFrame, j: str, relative: bool=False) -> pd.Series:
#         d = _complete_grid(df_in); d = d[d['dest']==j].copy()
#         mat = d.pivot_table(index='month', columns='orig', values='flow', aggfunc='sum').fillna(0.0).sort_index()
#         shares = mat.div(mat.sum(axis=1).replace(0, np.nan), axis=0).fillna(0.0)
#         hhi = (shares**2).sum(axis=1)
#         if relative:
#             train_mask = hhi.index <= pd.to_datetime(self.cfg.train_end)
#             h0 = hhi[train_mask].mean()
#             hhi = (hhi / max(h0, 1e-9)).clip(lower=0.0)
#         return hhi

#     def eop_index(self, df_in: pd.DataFrame, triads: List[Tuple[str,str,str]], use_standardized: bool=True) -> pd.DataFrame:
#         an = self.standardized_excess(df_in).rename(columns={'orig':'j','dest':'k'})
#         out = []
#         # --- triad loop with progress bar ---
#         for (i,j,k) in self._tqdm(triads, desc="EOP triads"):     # NEW
#             sub = an[(an['j']==j)&(an['k']==k)].copy().sort_values('month')
#             if sub.empty: 
#                 continue
#             anom = sub['z_std'] if use_standardized else sub['excess_pct']
#             w_tr = self._trailing_share(df_in, i, j, self.cfg.trailing_window)
#             if self.cfg.weight_mode == "excess_share":
#                 w0 = self._baseline_share(df_in, i, j)
#                 w = (w_tr - w0).clip(lower=0.0)
#             else:
#                 w = w_tr
#             if self.cfg.concentration_adjust:
#                 hhi = self._inflow_hhi(df_in, j, self.cfg.hhi_relative)
#                 w = (pd.DataFrame({'w':w}).merge(hhi.rename('hhi'), left_index=True, right_index=True, how='left').fillna({'hhi':1.0}))
#                 w = (w['w'] * w['hhi'])
#             sub = sub.merge(w.rename('w'), left_on='month', right_index=True, how='left')
#             sub['w'] = sub['w'].fillna(0.0)
#             sub['EOP'] = anom.values * sub['w'].values
#             out.append(pd.DataFrame({
#                 'i': i, 'j': j, 'k': k, 'month': sub['month'].values,
#                 'flow_jk': sub['flow'].values, 'mu_hat_jk': sub['mu_hat'].values,
#                 'anom_jk': anom.values, 'w_ij': sub['w'].values, 'EOP': sub['EOP'].values
#             }))
#         if not out:
#             return pd.DataFrame(columns=['i','j','k','month','flow_jk','mu_hat_jk','anom_jk','w_ij','EOP'])
#         return pd.concat(out, ignore_index=True).sort_values(['i','j','k','month'])


# --- keep your _make_ohe, _ensure_month, _complete_grid as-is ---

@dataclass
class EOPPlusConfig:
    train_end: str = "2021-12-01"
    val_start: str = "2021-07-01"
    alphas: tuple = (1e-6,1e-5,1e-4,1e-3,1e-2)
    include_pair_fe: bool = True
    include_origin_time_fe: bool = True
    include_dest_time_fe: bool = True
    use_global_time_fe: bool = False
    add_sci: bool = True
    eps: float = 1.0
    trailing_window: int = 12
    weight_mode: str = "excess_share"   # "share" or "excess_share"
    concentration_adjust: bool = False
    hhi_relative: bool = False
    # NEW: progress-bar controls
    progress: bool = True
    pbar_leave: bool = False
    pbar_ncols: int = 80

class EOPProPlus:
    def __init__(self, cfg: EOPPlusConfig, sci_df: Optional[pd.DataFrame] = None):
        self.cfg = cfg
        self.enc_pair = None
        self.enc_time = None
        self.enc_orig_time = None
        self.enc_dest_time = None
        self.model = None
        self.best_alpha_ = None
        self.phi_ = None
        if sci_df is not None and self.cfg.add_sci:
            s = sci_df.copy()
            s['pair'] = s['orig'] + '→' + s['dest']
            s['sci_logz'] = np.log(s['sci'].clip(lower=1e-12))
            s['sci_logz'] = (s['sci_logz'] - s['sci_logz'].mean())/(s['sci_logz'].std() + 1e-12)
            self.sci_lookup = s.set_index('pair')['sci_logz'].to_dict()
        else:
            self.sci_lookup = None

    # ---- NEW: unified tqdm wrapper (forces timely refresh) ----
    def _tqdm(self, iterable, desc: str):
        return tqdm(
            iterable,
            desc=desc,
            disable=not self.cfg.progress,
            leave=self.cfg.pbar_leave,
            ncols=self.cfg.pbar_ncols,
            dynamic_ncols=True,
            mininterval=0.0,
            smoothing=0.0,
        )

    def _build_encoders(self, df: pd.DataFrame):
        if self.cfg.include_pair_fe:
            self.enc_pair = _make_ohe(drop_first=True).fit(df[['pair']])
        self.enc_time = _make_ohe(drop_first=True).fit(df[['time_id']])
        if self.cfg.include_origin_time_fe:
            ot = df[['orig','time_id']].astype(str).agg('×'.join, axis=1).to_frame('orig_time')
            self.enc_orig_time = _make_ohe(drop_first=True).fit(ot)
        if self.cfg.include_dest_time_fe:
            dt = df[['dest','time_id']].astype(str).agg('×'.join, axis=1).to_frame('dest_time')
            self.enc_dest_time = _make_ohe(drop_first=True).fit(dt)

    def _transform(self, df: pd.DataFrame) -> sparse.csr_matrix:
        mats = []
        if self.cfg.include_pair_fe:
            mats.append(self.enc_pair.transform(df[['pair']]))
        if self.cfg.use_global_time_fe:
            mats.append(self.enc_time.transform(df[['time_id']]))
        if self.cfg.include_origin_time_fe:
            ot = df[['orig','time_id']].astype(str).agg('×'.join, axis=1).to_frame('orig_time')
            mats.append(self.enc_orig_time.transform(ot))
        if self.cfg.include_dest_time_fe:
            dt = df[['dest','time_id']].astype(str).agg('×'.join, axis=1).to_frame('dest_time')
            mats.append(self.enc_dest_time.transform(dt))
        if self.sci_lookup is not None and self.cfg.add_sci:
            sci = df['pair'].map(self.sci_lookup).fillna(0.0).to_numpy().reshape(-1,1)
            mats.append(sparse.csr_matrix(sci))
        if not mats:
            raise ValueError("No features selected.")
        return sparse.hstack(mats, format='csr')

    def fit(self, df_in: pd.DataFrame):
        d = _complete_grid(df_in)
        train_mask = d['month'] <= pd.to_datetime(self.cfg.train_end)
        d_train = d.loc[train_mask].copy()
        val_start = pd.to_datetime(self.cfg.val_start)
        val_mask = d_train['month'] >= val_start
        d_fit = d_train.loc[~val_mask].copy()
        d_val = d_train.loc[val_mask].copy()
        if d_val.empty:
            last6 = d_train['month'].max() - pd.offsets.DateOffset(months=5)
            val_mask = d_train['month'] >= last6
            d_fit = d_train.loc[~val_mask].copy()
            d_val = d_train.loc[val_mask].copy()

        self._build_encoders(d)
        X_fit = self._transform(d_fit); y_fit = d_fit['flow'].values
        X_val = self._transform(d_val); y_val = d_val['flow'].values

        # --- grid search with a live bar + postfix ---
        best_alpha, best_mae = None, np.inf
        pbar = self._tqdm(self.cfg.alphas, desc="Grid search α")
        for a in pbar:
            pbar.set_postfix_str(f"α={a:g}")
            pbar.update(0)  # force refresh now
            mdl = PoissonRegressor(alpha=a, fit_intercept=False, max_iter=5000)
            mdl.fit(X_fit, y_fit)
            pred = mdl.predict(X_val)
            mae = mean_absolute_error(y_val, pred)
            if mae < best_mae:
                best_mae, best_alpha = mae, a
        self.best_alpha_ = float(best_alpha)

        self.model = PoissonRegressor(alpha=self.best_alpha_, fit_intercept=False, max_iter=5000)
        X_train = self._transform(d_train); y_train = d_train['flow'].values
        self.model.fit(X_train, y_train)

        mu_train = self.model.predict(X_train)
        resid_sq_over_mu = ((y_train - mu_train)**2) / np.maximum(mu_train, 1e-9)
        p_eff = int(np.sum(self.model.coef_ != 0))
        dof = max(len(y_train) - p_eff, 1)
        self.phi_ = float(resid_sq_over_mu.sum() / dof)
        return self

    # ---------- NEW: precompute shares/HHI once per j ----------
    def _precompute_for_eop(self, df_in: pd.DataFrame):
        d = _complete_grid(df_in)
        js = d['dest'].unique()
        shares_trailing_by_j = {}
        baseline_share_by_j = {}
        hhi_by_j = {}
        window = self.cfg.trailing_window
        train_end = pd.to_datetime(self.cfg.train_end)

        for j in self._tqdm(js, desc="Precompute shares/HHI"):
            inbound = (d[d['dest']==j]
                        .pivot_table(index='month', columns='orig', values='flow',
                                     aggfunc='sum')
                        .fillna(0.0)
                        .sort_index())
            # trailing sums & shares
            rolled = inbound.rolling(window, min_periods=1).sum()
            shares = rolled.div(rolled.sum(axis=1).replace(0, np.nan), axis=0).fillna(0.0)
            shares_trailing_by_j[j] = shares

            # baseline (training mean share per origin)
            mask_train = shares.index <= train_end
            baseline_share_by_j[j] = shares.loc[mask_train].mean(axis=0)  # Series: origin -> mean share

            # HHI (optionally relative to training mean)
            hhi = (shares**2).sum(axis=1)
            if self.cfg.hhi_relative:
                h0 = hhi.loc[mask_train].mean()
                hhi = (hhi / max(h0, 1e-9)).clip(lower=0.0)
            hhi_by_j[j] = hhi

        return shares_trailing_by_j, baseline_share_by_j, hhi_by_j

    def standardized_excess(self, df_in: pd.DataFrame) -> pd.DataFrame:
        d = _complete_grid(df_in)
        mu = self.predict_mu(df_in)
        d = d.merge(mu, on=['orig','dest','month'], how='left')
        phi = self.phi_ if (self.phi_ is not None and self.phi_>0) else 1.0
        d['z_std'] = (d['flow'] - d['mu_hat']) / np.sqrt(np.maximum(phi * d['mu_hat'], 1e-9))
        d['excess_pct'] = (d['flow'] - d['mu_hat']) / np.maximum(d['mu_hat'], self.cfg.eps)
        return d[['orig','dest','month','flow','mu_hat','z_std','excess_pct']]

    def eop_index(self, df_in: pd.DataFrame, triads: List[Tuple[str,str,str]], use_standardized: bool=True) -> pd.DataFrame:
        an = self.standardized_excess(df_in).rename(columns={'orig':'j','dest':'k'}).sort_values(['j','k','month'])
        # PRECOMPUTE once → fast per-triad loop
        shares_by_j, baseline_by_j, hhi_by_j = self._precompute_for_eop(df_in)

        out = []
        for (i,j,k) in self._tqdm(triads, desc="EOP triads"):
            sub = an[(an['j']==j)&(an['k']==k)].copy().sort_values('month')
            if sub.empty: 
                continue

            # anomaly series
            anom = sub['z_std'] if use_standardized else sub['excess_pct']

            # trailing share for this (i,j)
            shares_tr = shares_by_j.get(j, None)
            if shares_tr is None or i not in shares_tr.columns:
                w_series = pd.Series(0.0, index=sub['month'])
            else:
                w_series = shares_tr[i].reindex(sub['month']).fillna(0.0)

            # weight: share vs excess_share
            if self.cfg.weight_mode == "excess_share":
                base_j = baseline_by_j.get(j, pd.Series(dtype=float))
                w0 = float(base_j.get(i, 0.0))
                w = (w_series - w0).clip(lower=0.0)
            else:
                w = w_series

            # optional concentration adjustment
            if self.cfg.concentration_adjust:
                hhi = hhi_by_j.get(j, None)
                if hhi is not None:
                    hhi_aligned = hhi.reindex(sub['month']).fillna(1.0)
                    w = (w * hhi_aligned)

            sub['w'] = w.values
            sub['EOP'] = anom.values * sub['w'].values

            out.append(pd.DataFrame({
                'i': i, 'j': j, 'k': k,
                'month': sub['month'].values,
                'flow_jk': sub['flow'].values,
                'mu_hat_jk': sub['mu_hat'].values,
                'anom_jk': anom.values,
                'w_ij': sub['w'].values,
                'EOP': sub['EOP'].values
            }))

        if not out:
            return pd.DataFrame(columns=['i','j','k','month','flow_jk','mu_hat_jk','anom_jk','w_ij','EOP'])
        return pd.concat(out, ignore_index=True).sort_values(['i','j','k','month'])
