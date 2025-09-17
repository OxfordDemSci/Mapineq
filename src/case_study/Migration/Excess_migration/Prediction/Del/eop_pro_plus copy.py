from dataclasses import dataclass
from typing import List, Tuple, Optional
import numpy as np
import pandas as pd
from scipy import sparse
from sklearn.preprocessing import OneHotEncoder
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_absolute_error

def ensure_month(df, col='month'):
    out = df.copy()
    out[col] = pd.to_datetime(out[col]).values.astype("datetime64[M]")
    out[col] = pd.to_datetime(out[col])
    return out

def complete_grid(df):
    d = ensure_month(df)
    months = pd.date_range(d['month'].min(), d['month'].max(), freq='MS')
    pairs = d[['orig','dest']].drop_duplicates().assign(key=1)
    months_df = pd.DataFrame({'month':months,'key':1})
    full = pairs.merge(months_df, on='key', how='outer').drop(columns='key')
    d = full.merge(d, on=['orig','dest','month'], how='left')
    d['flow'] = d['flow'].fillna(0.0).astype(float)
    d['pair'] = d['orig'] + '→' + d['dest']
    d['time_id'] = d['month'].dt.strftime('%Y-%m')
    d['year'] = d['month'].dt.year
    return d

@dataclass
class ProPlusConfig:
    train_end: str = "2021-12-01"
    val_start: str = "2021-07-01"
    alphas: tuple = (1e-6,1e-5,1e-4,1e-3,1e-2)
    pair_mode: str = "orig_dest"     # 'pair' or 'orig_dest'
    time_effect: str = "global_index" # 'month_fe', 'global_index', or 'both'
    include_sci: bool = True
    include_pop: bool = True
    use_log_sci: bool = True
    use_log_pop: bool = True
    sci_eps: float = 1e-9
    eps: float = 1.0
    trailing_window: int = 12
    lag_offset: int = 12
    smoothing: int = 1
    gating_mode: str = "none"        # 'none'|'binary'|'soft'
    gating_threshold_z: float = 0.0
    gating_soft_k: float = 2.0

class EOPProPlus:
    def __init__(self, cfg: ProPlusConfig, sci: Optional[pd.DataFrame]=None, pop: Optional[pd.DataFrame]=None, g_index: Optional[pd.Series]=None):
        self.cfg = cfg
        self.sci = sci
        self.pop = pop
        self.g_index = g_index
        self.enc_pair = None
        self.enc_time = None
        self.enc_orig = None
        self.enc_dest = None
        self.model = None
        self.best_alpha_ = None
        self.phi_ = None

    def _prepare_design(self, df: pd.DataFrame):
        d = complete_grid(df)
        feats = d[['orig','dest','pair','month','time_id','year']].copy()
        # merge SCI
        if self.cfg.include_sci and self.sci is not None:
            feats = feats.merge(self.sci.rename(columns={'sci':'SCI'}), on=['orig','dest'], how='left')
        else:
            feats['SCI'] = np.nan
        # merge POP (origin & dest by year)
        if self.cfg.include_pop and self.pop is not None:
            feats = feats.merge(self.pop.rename(columns={'iso3':'orig','population':'pop_o'}), on=['orig','year'], how='left')
            feats = feats.merge(self.pop.rename(columns={'iso3':'dest','population':'pop_d'}), on=['dest','year'], how='left')
        else:
            feats['pop_o']=np.nan; feats['pop_d']=np.nan
        # merge global index if requested
        if self.cfg.time_effect in ("global_index","both"):
            if isinstance(self.g_index, pd.Series):
                feats = feats.merge(self.g_index.rename('g_index'), left_on='month', right_index=True, how='left')
            else:
                feats['g_index']=np.nan
        else:
            feats['g_index']=np.nan

        # build encoders
        if self.cfg.pair_mode == "pair":
            self.enc_pair = OneHotEncoder(handle_unknown='ignore', drop='first', sparse=True).fit(feats[['pair']])
        else:
            self.enc_orig = OneHotEncoder(handle_unknown='ignore', drop='first', sparse=True).fit(feats[['orig']])
            self.enc_dest = OneHotEncoder(handle_unknown='ignore', drop='first', sparse=True).fit(feats[['dest']])
        if self.cfg.time_effect in ("month_fe","both"):
            self.enc_time = OneHotEncoder(handle_unknown='ignore', drop='first', sparse=True).fit(feats[['time_id']])

        mats=[]
        if self.cfg.pair_mode == "pair":
            mats.append(self.enc_pair.transform(feats[['pair']]))
        else:
            mats.append(self.enc_orig.transform(feats[['orig']]))
            mats.append(self.enc_dest.transform(feats[['dest']]))
        if self.cfg.time_effect in ("month_fe","both"):
            mats.append(self.enc_time.transform(feats[['time_id']]))

        # numeric features
        num_cols=[]
        if self.cfg.include_sci:
            sci_vals = feats['SCI'].fillna(feats['SCI'].median() if feats['SCI'].notna().any() else 1e-9).values
            if self.cfg.use_log_sci:
                sci_vals = np.log(sci_vals + self.cfg.sci_eps)
            num_cols.append(sci_vals.reshape(-1,1))
        if self.cfg.include_pop:
            po = feats['pop_o'].fillna(feats['pop_o'].median() if feats['pop_o'].notna().any() else 1.0).values
            pd_ = feats['pop_d'].fillna(feats['pop_d'].median() if feats['pop_d'].notna().any() else 1.0).values
            if self.cfg.use_log_pop:
                po = np.log(po+1.0); pd_ = np.log(pd_+1.0)
            num_cols.extend([po.reshape(-1,1), pd_.reshape(-1,1)])
        if self.cfg.time_effect in ("global_index","both"):
            gi = feats['g_index'].fillna(1.0).values.reshape(-1,1)
            num_cols.append(gi)
        if num_cols:
            X_num = np.hstack(num_cols).astype(float)
            mats.append(sparse.csr_matrix(X_num))

        X = mats[0]
        for m in mats[1:]:
            X = sparse.hstack([X,m], format='csr')
        return X, d['flow'].values, feats[['orig','dest','month']]

    def fit(self, df: pd.DataFrame):
        X_all, y_all, meta = self._prepare_design(df)
        d_meta = meta.copy(); d_meta['flow']=y_all; d_meta = ensure_month(d_meta)
        train_mask = (d_meta['month'] <= pd.to_datetime(self.cfg.train_end))
        val_mask = (d_meta['month'] >= pd.to_datetime(self.cfg.val_start)) & train_mask
        fit_mask = train_mask & (~val_mask)
        X_fit, y_fit = X_all[fit_mask.values], y_all[fit_mask.values]
        X_val, y_val = X_all[val_mask.values], y_all[val_mask.values]
        best_alpha, best_mae = None, np.inf
        for a in self.cfg.alphas:
            mdl = PoissonRegressor(alpha=a, fit_intercept=False, max_iter=5000)
            mdl.fit(X_fit, y_fit)
            pred = mdl.predict(X_val)
            mae = mean_absolute_error(y_val, pred)
            if mae < best_mae:
                best_mae, best_alpha = mae, a
        self.best_alpha_ = float(best_alpha)
        self.model = PoissonRegressor(alpha=self.best_alpha_, fit_intercept=False, max_iter=5000)
        X_train, y_train = X_all[train_mask.values], y_all[train_mask.values]
        self.model.fit(X_train, y_train)
        mu_train = self.model.predict(X_train)
        phi_num = ((y_train - mu_train)**2 / np.maximum(mu_train,1e-9)).sum()
        p_eff = int(np.sum(self.model.coef_!=0))
        dof = max(len(y_train)-p_eff,1)
        self.phi_ = float(phi_num/dof)
        return self

    def predict_mu(self, df: pd.DataFrame) -> pd.DataFrame:
        X_all, y_all, meta = self._prepare_design(df)
        mu = self.model.predict(X_all)
        out = meta.copy(); out['mu_hat']=mu; out['flow']=y_all
        return out

    def anomalies(self, df: pd.DataFrame) -> pd.DataFrame:
        out = self.predict_mu(df)
        phi = self.phi_ if (self.phi_ and self.phi_>0) else 1.0
        out['z_std'] = (out['flow'] - out['mu_hat'])/np.sqrt(np.maximum(phi*out['mu_hat'],1e-9))
        out['excess_pct'] = (out['flow'] - out['mu_hat'])/np.maximum(out['mu_hat'],1.0)
        return out

    def lagged_share_series(self, df: pd.DataFrame, i: str, j: str) -> pd.Series:
        d = complete_grid(df)
        inbound = d[d['dest']==j].copy()
        pivot = inbound.pivot_table(index='month', columns='orig', values='flow', aggfunc='sum').fillna(0.0).sort_index()
        num = pivot.get(i, pd.Series(0.0, index=pivot.index))
        den = pivot.sum(axis=1).replace(0, np.nan)
        s = (num/den).fillna(0.0).rename('share_ij')
        return s

    def lagged_attribution(self, df: pd.DataFrame, i: str, j: str) -> pd.DataFrame:
        L, W = self.cfg.lag_offset, self.cfg.trailing_window
        s = self.lagged_share_series(df, i=i, j=j)
        # use mean share over the W months ending at t-L
        w = s.rolling(W, min_periods=1).mean().shift(L).fillna(0.0)
        if self.cfg.smoothing and self.cfg.smoothing>1:
            w = w.rolling(self.cfg.smoothing, min_periods=1).mean()
        gate = pd.Series(1.0, index=w.index)
        if self.cfg.gating_mode != "none":
            months = w.index
            train_mask = (months <= pd.to_datetime(self.cfg.train_end))
            s_train = s.loc[train_mask]
            m, sd = s_train.mean(), s_train.std(ddof=1) if len(s_train)>1 else 0.0
            z = (s - m) / (sd if sd>1e-9 else 1.0)
            z = z.shift(L)
            thr = self.cfg.gating_threshold_z
            if self.cfg.gating_mode == "binary":
                gate = (z >= thr).astype(float)
            elif self.cfg.gating_mode == "soft":
                gate = 1/(1 + np.exp(-self.cfg.gating_soft_k*(z - thr)))
        return pd.DataFrame({'w': w.fillna(0.0), 'gate': gate.fillna(1.0)})

    def eop(self, df: pd.DataFrame, triads: List[Tuple[str,str,str]], use_standardized=True) -> pd.DataFrame:
        A = self.anomalies(df).rename(columns={'orig':'j','dest':'k'})
        out_list=[]
        for (i,j,k) in triads:
            sub = A[(A['j']==j)&(A['k']==k)].copy().sort_values('month')
            if sub.empty: continue
            anom = sub['z_std'] if use_standardized else sub['excess_pct']
            wg = self.lagged_attribution(df, i=i, j=j)
            sub = sub.merge(wg, left_on='month', right_index=True, how='left')
            sub['w']=sub['w'].fillna(0.0); sub['gate']=sub['gate'].fillna(1.0)
            sub['EOP'] = anom.values * sub['w'].values * sub['gate'].values
            x = pd.DataFrame({
                'i':i,'j':j,'k':k,'month':sub['month'],
                'flow_jk':sub['flow'],'mu_hat_jk':sub['mu_hat'],
                'anom_jk':anom,'w_ij':sub['w'],'gate':sub['gate'],'EOP':sub['EOP']
            })
            out_list.append(x)
        if not out_list:
            return pd.DataFrame(columns=['i','j','k','month','flow_jk','mu_hat_jk','anom_jk','w_ij','gate','EOP'])
        return pd.concat(out_list, ignore_index=True).sort_values(['i','j','k','month'])