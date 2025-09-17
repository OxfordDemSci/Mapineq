from dataclasses import dataclass
from typing import Optional, Tuple
import pandas as pd
import numpy as np
from scipy import sparse
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_absolute_error

def ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s)
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out)

def complete_grid(df: pd.DataFrame) -> pd.DataFrame:
    d = df.copy()
    d['month'] = ensure_month(d['month'])
    months = pd.date_range(d['month'].min(), d['month'].max(), freq="MS")
    pairs = d[['orig','dest']].drop_duplicates().assign(key=1)
    months_df = pd.DataFrame({'month': months, 'key':1})
    full = pairs.merge(months_df, on='key', how='outer').drop(columns='key')
    out = full.merge(d[['orig','dest','month','flow']], on=['orig','dest','month'], how='left')
    out['flow'] = out['flow'].fillna(0.0).astype(float)
    return out

def add_pair_moy(df: pd.DataFrame) -> pd.DataFrame:
    d = df.copy()
    d['pair'] = d['orig'] + '→' + d['dest']
    d['moy'] = d['month'].dt.month
    d['year'] = d['month'].dt.year
    return d

def prepare_population(pop_df: pd.DataFrame) -> pd.DataFrame:
    p = pop_df.copy()
    p = p.rename(columns={'iso3':'iso3', 'population':'population', 'year':'year'})
    p = p[['iso3','year','population']].dropna()
    p['population'] = p['population'].astype(float)
    p = p.groupby(['iso3','year'], as_index=False)['population'].mean()
    return p

def attach_populations(df: pd.DataFrame, pop_df: pd.DataFrame) -> pd.DataFrame:
    d = add_pair_moy(df)
    p = prepare_population(pop_df)
    def expand_country_series(p_sub: pd.DataFrame, years: np.ndarray) -> pd.DataFrame:
        idx = pd.Index(years, name='year')
        ser = p_sub.set_index('year')['population'].sort_index()
        ser = ser.reindex(idx, method=None)
        ser = ser.ffill().bfill()
        return ser.reset_index().rename(columns={0:'population'})
    years_full = np.arange(d['year'].min(), d['year'].max()+1)
    po = p.rename(columns={'iso3':'orig'})
    pdst = p.rename(columns={'iso3':'dest'})
    po_full = (po.groupby('orig', group_keys=False)
                 .apply(lambda g: expand_country_series(g[['year','population']], years_full).assign(orig=g['orig'].iloc[0])))
    pd_full = (pdst.groupby('dest', group_keys=False)
                 .apply(lambda g: expand_country_series(g[['year','population']], years_full).assign(dest=g['dest'].iloc[0])))
    po_full = po_full.rename(columns={'population':'pop_o'})
    pd_full = pd_full.rename(columns={'population':'pop_d'})
    d = d.merge(po_full, on=['orig','year'], how='left').merge(pd_full, on=['dest','year'], how='left')
    d['pop_o'] = d['pop_o'].fillna(d['pop_o'].median()).clip(lower=1.0)
    d['pop_d'] = d['pop_d'].fillna(d['pop_d'].median()).clip(lower=1.0)
    d['log_pop_o'] = np.log(d['pop_o'].values)
    d['log_pop_d'] = np.log(d['pop_d'].values)
    return d

def compute_global_moy_baseline(df: pd.DataFrame, baseline_years=(2019,)) -> pd.Series:
    d = df.copy()
    d['month'] = ensure_month(d['month'])
    d['moy'] = d['month'].dt.month
    d['year'] = d['month'].dt.year
    base = d[d['year'].isin(baseline_years)]
    glob_by_moy = base.groupby('moy')['flow'].sum()
    S = glob_by_moy / glob_by_moy.mean() if glob_by_moy.mean() != 0 else glob_by_moy/glob_by_moy.replace(0,np.nan).mean()
    return S

def compute_global_shock_index(df: pd.DataFrame, baseline_years=(2019,)) -> pd.Series:
    d = df.copy()
    d['month'] = ensure_month(d['month'])
    d['moy'] = d['month'].dt.month
    monthly_total = d.groupby('month')['flow'].sum().sort_index()
    S = compute_global_moy_baseline(df, baseline_years=baseline_years)
    mean_total = monthly_total.mean() if monthly_total.mean() != 0 else 1.0
    expected = monthly_total.index.to_series().dt.month.map(S).values * mean_total / S.mean()
    ratio = (monthly_total.values + 1e-9) / np.maximum(expected, 1e-9)
    H = np.log(ratio)
    return pd.Series(H, index=monthly_total.index, name='H_t')

@dataclass
class CFPlusConfig:
    train_end: str = "2021-12-01"
    val_start: str = "2021-07-01"
    alphas: tuple = (1e-6,1e-5,1e-4,1e-3,1e-2)
    baseline_years: tuple = (2019,)
    use_external_covid: bool = False
    standardize_continuous: bool = True

class CFPlus:
    def __init__(self, cfg: CFPlusConfig):
        self.cfg = cfg
        self.enc_pair = None
        self.enc_moy = None
        self.scaler = None
        self.model = None
        self.best_alpha_ = None

    def _build_encoders(self, pairs: pd.Series, moy: pd.Series):
        self.enc_pair = OneHotEncoder(handle_unknown='ignore', drop='first', sparse=True).fit(pairs.to_frame())
        self.enc_moy  = OneHotEncoder(handle_unknown='ignore', drop='first', sparse=True).fit(moy.to_frame())
        self.scaler   = StandardScaler(with_mean=False) if self.cfg.standardize_continuous else None

    def _transform(self, pairs: pd.Series, moy: pd.Series, Xcont: np.ndarray) -> sparse.csr_matrix:
        Xp = self.enc_pair.transform(pairs.to_frame())
        Xm = self.enc_moy.transform(moy.to_frame())
        if self.scaler is not None:
            Xc = self.scaler.fit_transform(Xcont) if not hasattr(self.scaler, 'mean_') else self.scaler.transform(Xcont)
        else:
            Xc = sparse.csr_matrix(Xcont)
        if not sparse.issparse(Xc):
            Xc = sparse.csr_matrix(Xc)
        return sparse.hstack([Xp, Xm, Xc], format='csr')

    def _build_design(self, flows_df: pd.DataFrame, pop_df: pd.DataFrame, covid_df: Optional[pd.DataFrame]=None) -> pd.DataFrame:
        d = complete_grid(flows_df)
        d = attach_populations(d, pop_df)
        H = compute_global_shock_index(d[['orig','dest','month','flow']],
                                       baseline_years=self.cfg.baseline_years)
        d = d.merge(H.rename('H_t'), left_on='month', right_index=True, how='left')
        if self.cfg.use_external_covid and covid_df is not None:
            c = covid_df.copy()
            c['month'] = ensure_month(c['month'])
            d = d.merge(c[['month','covid_idx']], on='month', how='left')
            d['covid_idx'] = d['covid_idx'].fillna(0.0)
        else:
            d['covid_idx'] = 0.0
        return d

    def fit(self, flows_df: pd.DataFrame, pop_df: pd.DataFrame, covid_df: Optional[pd.DataFrame]=None):
        d = self._build_design(flows_df, pop_df, covid_df)
        pairs = (d['orig'] + '→' + d['dest'])
        moy   = d['moy']
        Xcont = d[['log_pop_o','log_pop_d','H_t','covid_idx']].values
        y     = d['flow'].values
        d['month'] = ensure_month(d['month'])
        train_mask = d['month'] <= pd.to_datetime(self.cfg.train_end)
        val_mask   = (d['month'] >= pd.to_datetime(self.cfg.val_start)) & train_mask
        fit_mask   = train_mask & (~val_mask)
        if val_mask.sum()==0:
            tmax = d.loc[train_mask,'month'].max()
            cutoff = tmax - pd.offsets.DateOffset(months=6)
            val_mask = train_mask & (d['month'] > cutoff)
            fit_mask = train_mask & (~val_mask)
        self._build_encoders(pairs, moy)
        X_fit = self._transform(pairs[fit_mask], moy[fit_mask], Xcont[fit_mask])
        y_fit = y[fit_mask]
        X_val = self._transform(pairs[val_mask], moy[val_mask], Xcont[val_mask])
        y_val = y[val_mask]
        best_alpha, best_mae = None, np.inf
        for a in self.cfg.alphas:
            mdl = PoissonRegressor(alpha=a, fit_intercept=False, max_iter=5000)
            mdl.fit(X_fit, y_fit)
            pred = mdl.predict(X_val)
            mae  = mean_absolute_error(y_val, pred)
            if mae < best_mae:
                best_mae, best_alpha = mae, a
        self.best_alpha_ = float(best_alpha)
        X_train = self._transform(pairs[train_mask], moy[train_mask], Xcont[train_mask])
        y_train = y[train_mask]
        self.model = PoissonRegressor(alpha=self.best_alpha_, fit_intercept=False, max_iter=5000)
        self.model.fit(X_train, y_train)
        return self

    def predict_mu(self, flows_df: pd.DataFrame, pop_df: pd.DataFrame, covid_df: Optional[pd.DataFrame]=None) -> pd.DataFrame:
        if self.model is None:
            raise RuntimeError("Model not fit yet.")
        d = self._build_design(flows_df, pop_df, covid_df)
        pairs = (d['orig'] + '→' + d['dest'])
        moy   = d['moy']
        Xcont = d[['log_pop_o','log_pop_d','H_t','covid_idx']].values
        X = self._transform(pairs, moy, Xcont)
        mu_hat = self.model.predict(X)
        out = d[['orig','dest','month','flow']].copy()
        out['mu_hat'] = mu_hat
        out['excess_pct'] = (out['flow'] - out['mu_hat']) / np.maximum(out['mu_hat'], 1.0)
        return out