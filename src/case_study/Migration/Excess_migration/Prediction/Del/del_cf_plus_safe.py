from dataclasses import dataclass
from typing import Optional, Tuple, Dict
import pandas as pd
import numpy as np
from scipy import sparse
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_absolute_error

def ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s, errors='coerce')
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out, errors='coerce')

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

def _year_medians(p: pd.DataFrame) -> Dict[int, float]:
    med = p.groupby('year')['population'].median()
    if med.empty or med.isna().all():
        return {y:1e6 for y in range(1900, 2101)}
    return med.to_dict()

def attach_populations(df: pd.DataFrame, pop_df: pd.DataFrame) -> pd.DataFrame:
    d = add_pair_moy(df)
    p = prepare_population(pop_df)
    year_med = _year_medians(p)
    def expand_country_series(p_sub: pd.DataFrame, years: np.ndarray) -> pd.DataFrame:
        idx = pd.Index(years, name='year')
        ser = p_sub.set_index('year')['population'].sort_index()
        ser = ser.reindex(idx)
        ser = ser.fillna(pd.Series({y:year_med.get(y, np.nan) for y in years}))
        ser = ser.ffill().bfill()
        return ser.reset_index().rename(columns={0:'population'})
    years_full = np.arange(d['year'].min(), d['year'].max()+1)
    po = p.rename(columns={'iso3':'orig'})
    pdst = p.rename(columns={'iso3':'dest'})
    if not po.empty:
        po_full = (po.groupby('orig', group_keys=False)
                     .apply(lambda g: expand_country_series(g[['year','population']], years_full).assign(orig=g['orig'].iloc[0])))
    else:
        po_full = pd.DataFrame(columns=['year','population','orig'])
    if not pdst.empty:
        pd_full = (pdst.groupby('dest', group_keys=False)
                     .apply(lambda g: expand_country_series(g[['year','population']], years_full).assign(dest=g['dest'].iloc[0])))
    else:
        pd_full = pd.DataFrame(columns=['year','population','dest'])
    po_full = po_full.rename(columns={'population':'pop_o'})
    pd_full = pd_full.rename(columns={'population':'pop_d'})
    d = d.merge(po_full, on=['orig','year'], how='left').merge(pd_full, on=['dest','year'], how='left')
    global_med_pop = float(p['population'].median()) if not p.empty else 1e6
    d['pop_o'] = d['pop_o'].fillna(d['year'].map(year_med)).fillna(global_med_pop).clip(lower=1.0)
    d['pop_d'] = d['pop_d'].fillna(d['year'].map(year_med)).fillna(global_med_pop).clip(lower=1.0)
    d['log_pop_o'] = np.log(d['pop_o'].values)
    d['log_pop_d'] = np.log(d['pop_d'].values)
    return d

def compute_global_moy_baseline(df: pd.DataFrame, baseline_years=(2019,)) -> pd.Series:
    d = df.copy()
    d['month'] = ensure_month(d['month'])
    d['moy'] = d['month'].dt.month
    d['year'] = d['month'].dt.year
    base = d[d['year'].isin(baseline_years)]
    if base.empty:
        return pd.Series({m:1.0 for m in range(1,13)})
    glob_by_moy = base.groupby('moy')['flow'].sum()
    mean_val = glob_by_moy.mean()
    if pd.isna(mean_val) or mean_val == 0:
        return pd.Series({m:1.0 for m in range(1,13)})
    S = glob_by_moy / mean_val
    S = S.reindex(range(1,13)).fillna(1.0)
    return S

def compute_global_shock_index(df: pd.DataFrame, baseline_years=(2019,)) -> pd.Series:
    d = df.copy()
    d['month'] = ensure_month(d['month'])
    d['moy'] = d['month'].dt.month
    monthly_total = d.groupby('month')['flow'].sum().sort_index()
    if monthly_total.empty:
        return pd.Series(0.0, index=pd.date_range(d['month'].min(), d['month'].max(), freq='MS'), name='H_t')
    S = compute_global_moy_baseline(df, baseline_years=baseline_years)
    expected = monthly_total.index.to_series().dt.month.map(S).astype(float)
    if expected.isna().all():
        expected = pd.Series(1.0, index=monthly_total.index)
    scale = monthly_total.mean()
    if pd.isna(scale) or scale == 0:
        scale = 1.0
    expected = expected.values * scale / max(S.mean(), 1e-9)
    ratio = (monthly_total.values + 1e-9) / np.maximum(expected, 1e-9)
    H = np.log(ratio)
    H = np.where(np.isfinite(H), H, 0.0)
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
        self.enc_pair = OneHotEncoder(handle_unknown='ignore', drop='first', sparse_output=True).fit(pairs.to_frame())
        self.enc_moy  = OneHotEncoder(handle_unknown='ignore', drop='first', sparse_output=True).fit(moy.to_frame())
        self.scaler   = StandardScaler(with_mean=False) if self.cfg.standardize_continuous else None

    def _transform(self, pairs: pd.Series, moy: pd.Series, Xcont: np.ndarray, fit_scaler: bool=False) -> sparse.csr_matrix:
        Xp = self.enc_pair.transform(pairs.to_frame())
        Xm = self.enc_moy.transform(moy.to_frame())
        Xcont = np.nan_to_num(Xcont, nan=0.0, posinf=0.0, neginf=0.0)
        if self.scaler is not None:
            if fit_scaler or not hasattr(self.scaler, 'scale_'):
                Xc = self.scaler.fit_transform(Xcont)
            else:
                Xc = self.scaler.transform(Xcont)
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
        if train_mask.sum() == 0:
            raise ValueError("No rows fall into training window. Check train_end vs your data range.")
        val_mask   = (d['month'] >= pd.to_datetime(self.cfg.val_start)) & train_mask
        fit_mask   = train_mask & (~val_mask)
        if val_mask.sum()==0 or fit_mask.sum()==0:
            tmax = d.loc[train_mask,'month'].max()
            cutoff = tmax - pd.offsets.DateOffset(months=6)
            val_mask = train_mask & (d['month'] > cutoff)
            fit_mask = train_mask & (~val_mask)
        self._build_encoders(pairs, moy)
        X_fit = self._transform(pairs[fit_mask], moy[fit_mask], Xcont[fit_mask], fit_scaler=True)
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

def diagnose_inputs(flows_df: pd.DataFrame, pop_df: pd.DataFrame, baseline_years=(2019,)) -> pd.DataFrame:
    rep = {}
    m = pd.to_datetime(flows_df['month'], errors='coerce')
    rep['flows_min_month'] = str(m.min())
    rep['flows_max_month'] = str(m.max())
    rep['n_rows_flows'] = int(len(flows_df))
    rep['n_pairs'] = int(flows_df[['orig','dest']].drop_duplicates().shape[0])
    years = m.dt.year
    by_year = years.value_counts().sort_index()
    for y, cnt in by_year.items():
        rep[f'rows_year_{y}'] = int(cnt)
    pop = pop_df.copy()
    rep['pop_cols'] = ','.join(sorted(set(pop.columns)))
    flows_countries = pd.Index(sorted(set(flows_df['orig']).union(set(flows_df['dest']))))
    pop_countries = pd.Index(sorted(pop['iso3'].unique())) if 'iso3' in pop.columns else pd.Index([])
    rep['n_countries_flows'] = int(len(flows_countries))
    rep['n_countries_pop'] = int(len(pop_countries))
    missing_in_pop = flows_countries.difference(pop_countries)
    rep['n_missing_in_pop'] = int(len(missing_in_pop))
    rep['sample_missing'] = ','.join(missing_in_pop[:10])
    tmp = flows_df.copy()
    tmp['month'] = pd.to_datetime(tmp['month'], errors='coerce')
    tmp['year'] = tmp['month'].dt.year
    base = tmp[tmp['year'].isin(baseline_years)]
    rep['has_baseline_years'] = bool(len(base)>0)
    return pd.DataFrame.from_dict(rep, orient='index', columns=['value'])
