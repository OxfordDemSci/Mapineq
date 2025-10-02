# cf_plus_core.py — Poisson FE gravity with month-year fixed effects (clean)
from dataclasses import dataclass
from typing import Tuple, Dict
import warnings
import numpy as np
import pandas as pd
from scipy import sparse
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_absolute_error

try:
    from tqdm.auto import tqdm
except Exception:
    def tqdm(x, **kwargs): return x

# ---------- utilities ----------
def ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s, errors='coerce')
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out, errors='coerce')

def complete_grid(df: pd.DataFrame) -> pd.DataFrame:
    d = df.copy()
    d['month'] = ensure_month(d['month'])
    months = pd.date_range(d['month'].min(), d['month'].max(), freq="MS")
    pairs = d[['orig','dest']].drop_duplicates().assign(key=1)
    months_df = pd.DataFrame({'month': months, 'key': 1})
    full = pairs.merge(months_df, on='key', how='outer').drop(columns='key')
    out = full.merge(d[['orig','dest','month','flow']], on=['orig','dest','month'], how='left')
    out['flow'] = out['flow'].fillna(0.0).astype(float)
    return out

def add_pair_my(df: pd.DataFrame) -> pd.DataFrame:
    d = df.copy()
    d['pair'] = d['orig'] + '→' + d['dest']
    d['year'] = d['month'].dt.year
    d['month_year'] = d['month'].dt.to_period('M').astype(str)
    return d

def prepare_population(pop_df: pd.DataFrame) -> pd.DataFrame:
    p = pop_df.rename(columns={'iso3':'iso3','year':'year','population':'population'})[['iso3','year','population']]
    p = p.dropna()
    p['population'] = p['population'].astype(float)
    return p.groupby(['iso3','year'], as_index=False)['population'].mean()

def _year_medians(p: pd.DataFrame) -> Dict[int, float]:
    med = p.groupby('year')['population'].median()
    if med.empty or med.isna().all():
        return {y: 1e6 for y in range(1900, 2101)}
    return med.to_dict()

def attach_populations(df: pd.DataFrame, pop_df: pd.DataFrame) -> pd.DataFrame:
    d = add_pair_my(df)
    p = prepare_population(pop_df)
    year_med = _year_medians(p)

    def expand_country_series(p_sub: pd.DataFrame, years: np.ndarray) -> pd.DataFrame:
        idx = pd.Index(years, name='year')
        ser = p_sub.set_index('year')['population'].sort_index().reindex(idx)
        ser = ser.fillna(pd.Series({y: year_med.get(y, np.nan) for y in years})).ffill().bfill()
        return ser.reset_index().rename(columns={0: 'population'})

    years_full = np.arange(d['year'].min(), d['year'].max() + 1)

    po = prepare_population(pop_df).rename(columns={'iso3': 'orig'})
    pdst = prepare_population(pop_df).rename(columns={'iso3': 'dest'})

    po_full = (po.groupby('orig', group_keys=False)
                 .apply(lambda g: expand_country_series(g[['year','population']], years_full).assign(orig=g['orig'].iloc[0]))
               if not po.empty else pd.DataFrame(columns=['year','population','orig']))
    pd_full = (pdst.groupby('dest', group_keys=False)
                 .apply(lambda g: expand_country_series(g[['year','population']], years_full).assign(dest=g['dest'].iloc[0]))
               if not pdst.empty else pd.DataFrame(columns=['year','population','dest']))

    po_full = po_full.rename(columns={'population': 'pop_o'})
    pd_full = pd_full.rename(columns={'population': 'pop_d'})

    d = d.merge(po_full, on=['orig','year'], how='left').merge(pd_full, on=['dest','year'], how='left')
    global_med = float(p['population'].median()) if not p.empty else 1e6
    d['pop_o'] = d['pop_o'].fillna(d['year'].map(year_med)).fillna(global_med).clip(lower=1.0)
    d['pop_d'] = d['pop_d'].fillna(d['year'].map(year_med)).fillna(global_med).clip(lower=1.0)
    d['log_pop_o'] = np.log(d['pop_o'])
    d['log_pop_d'] = np.log(d['pop_d'])
    return d


# ---------- pre check ----------

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



# ---------- model ----------
@dataclass
class CFPlusConfig:
    train_end: str = "2021-12-01"
    val_start: str = "2021-07-01"
    alphas: Tuple[float, ...] = (1e-6,1e-5,1e-4,1e-3,1e-2,5e-2,1e-1,5e-1,1.0)
    standardize_continuous: bool = True
    max_iter: int = 20000
    tol: float = 1e-7
    progress: bool = True
    # optional: speed up validation via warm start
    warm_start: bool = True

class CFPlus:
    """
    Poisson regression with pair fixed effects and month-year fixed effects (one dummy per calendar month).
    Stores the validation curve during .fit() to avoid re-fitting later.
    """
    def __init__(self, cfg: CFPlusConfig):
        self.cfg = cfg
        self.enc_pair = None
        self.enc_my = None
        self.scaler = None
        self.model = None
        self.best_alpha_ = None
        self.val_curve_ = None   # [(alpha, val_mae)]

    # encoders / transforms
    def _build_encoders(self, pairs: pd.Series, month_year: pd.Series):
        self.enc_pair = OneHotEncoder(handle_unknown='ignore', drop='first', sparse_output=True).fit(pairs.to_frame())
        self.enc_my   = OneHotEncoder(handle_unknown='ignore', drop='first', sparse_output=True).fit(month_year.to_frame())
        self.scaler   = StandardScaler(with_mean=False) if self.cfg.standardize_continuous else None

    def _transform(self, pairs: pd.Series, month_year: pd.Series, Xcont: np.ndarray, fit_scaler: bool=False) -> sparse.csr_matrix:
        Xp = self.enc_pair.transform(pairs.to_frame())
        Xm = self.enc_my.transform(month_year.to_frame())
        Xcont = np.nan_to_num(Xcont, nan=0.0, posinf=0.0, neginf=0.0)
        if self.scaler is not None:
            Xc = self.scaler.fit_transform(Xcont) if (fit_scaler or not hasattr(self.scaler, 'scale_')) else self.scaler.transform(Xcont)
        else:
            Xc = sparse.csr_matrix(Xcont)
        if not sparse.issparse(Xc):
            Xc = sparse.csr_matrix(Xc)
        return sparse.hstack([Xp, Xm, Xc], format='csr')

    # data prep
    def _build_design(self, flows_df: pd.DataFrame, pop_df: pd.DataFrame) -> pd.DataFrame:
        d = complete_grid(flows_df)
        d = attach_populations(d, pop_df)
        d['month'] = ensure_month(d['month'])
        d['month_year'] = d['month'].dt.to_period('M').astype(str)
        return d

    # fit / predict
    def fit(self, flows_df: pd.DataFrame, pop_df: pd.DataFrame):
        d = self._build_design(flows_df, pop_df)
        pairs = (d['orig'] + '→' + d['dest'])
        my = d['month_year']
        Xcont = d[['log_pop_o', 'log_pop_d']].values
        y = d['flow'].values

        train_mask = d['month'] <= pd.to_datetime(self.cfg.train_end)
        if train_mask.sum() == 0:
            raise ValueError("No rows in training window. Check train_end.")
        val_mask = (d['month'] >= pd.to_datetime(self.cfg.val_start)) & train_mask
        fit_mask = train_mask & (~val_mask)
        if val_mask.sum() == 0 or fit_mask.sum() == 0:
            tmax = d.loc[train_mask, 'month'].max()
            cutoff = tmax - pd.offsets.DateOffset(months=6)
            val_mask = train_mask & (d['month'] > cutoff)
            fit_mask = train_mask & (~val_mask)
            
        # --- add these lines so you can plot later using masks ---
        self.train_mask_ = train_mask.values   ### NEW ###
        self.val_mask_   = val_mask.values     ### NEW ###
        self.fit_mask_   = fit_mask.values     ### NEW ###
        # ---------------------------------------------------------        
        
        self._build_encoders(pairs, my)
        X_fit = self._transform(pairs[fit_mask], my[fit_mask], Xcont[fit_mask], fit_scaler=True); y_fit = y[fit_mask]
        X_val = self._transform(pairs[val_mask], my[val_mask], Xcont[val_mask]); y_val = y[val_mask]

        iterator = tqdm(self.cfg.alphas, desc="Alpha grid", disable=not self.cfg.progress)
        best_alpha, best_mae = None, np.inf
        self.val_curve_ = []

        # optional: warm-start across alphas (large -> small works well)
        alphas = list(self.cfg.alphas)
        if self.cfg.warm_start:
            alphas = sorted(alphas, reverse=True)

        mdl = None
        for a in alphas:
            if mdl is None:
                mdl = PoissonRegressor(alpha=a, fit_intercept=False,
                                       max_iter=self.cfg.max_iter, tol=self.cfg.tol,
                                       warm_start=self.cfg.warm_start)
            else:
                mdl.alpha = a
            mdl.fit(X_fit, y_fit)
            pred = mdl.predict(X_val)
            mae  = mean_absolute_error(y_val, pred)
            self.val_curve_.append((float(a), float(mae)))
            if mae < best_mae:
                best_mae, best_alpha = mae, a
                if self.cfg.progress:
                    iterator.set_postfix(best_alpha=best_alpha, best_mae=round(best_mae, 2))
        self.best_alpha_ = float(best_alpha)

        # train final on entire train window with best alpha
        X_train = self._transform(pairs[train_mask], my[train_mask], Xcont[train_mask])
        y_train = y[train_mask]
        self.model = PoissonRegressor(alpha=self.best_alpha_, fit_intercept=False,
                                      max_iter=self.cfg.max_iter, tol=self.cfg.tol)
        self.model.fit(X_train, y_train)
        return self

    def predict_mu(self, flows_df: pd.DataFrame, pop_df: pd.DataFrame) -> pd.DataFrame:
        if self.model is None:
            raise RuntimeError("Call fit() first.")
        d = self._build_design(flows_df, pop_df)
        pairs = (d['orig'] + '→' + d['dest'])
        my = d['month_year']
        Xcont = d[['log_pop_o', 'log_pop_d']].values
        X = self._transform(pairs, my, Xcont)
        mu_hat = self.model.predict(X)
        out = d[['orig', 'dest', 'month', 'flow']].copy()
        out['mu_hat'] = mu_hat
        out['excess_pct'] = (out['flow'] - out['mu_hat']) / np.maximum(out['mu_hat'], 1.0)
        return out

# ---------- diagnostics ----------
def penalty_report_monthyear(cf: CFPlus, *, return_deviance=False,
                             flows_df: pd.DataFrame=None, pop_df: pd.DataFrame=None):
    """
    L2 penalty breakdown exactly as optimized by PoissonRegressor, with month-year FEs.
    """
    if cf.model is None:
        raise RuntimeError("Fit the model first.")

    coef = cf.model.coef_.ravel()
    alpha = float(getattr(cf.model, "alpha", cf.best_alpha_))

    n_pair = len(cf.enc_pair.categories_[0]) - 1  # drop='first'
    n_my   = len(cf.enc_my.categories_[0]) - 1    # drop='first'
    n_cont = len(coef) - n_pair - n_my            # should be 2

    i0 = 0
    i1 = i0 + n_pair
    i2 = i1 + n_my
    i3 = i2 + n_cont

    w_pair = coef[i0:i1]
    w_my   = coef[i1:i2]
    w_cont = coef[i2:i3]  # [log_pop_o, log_pop_d] in scaled space

    sq_theta = float(np.dot(w_pair, w_pair))
    sq_my    = float(np.dot(w_my,   w_my))
    names_cont = ["beta_log_pop_o", "beta_log_pop_d"]
    cont_squares_scaled = {nm: float(w_cont[k]**2) for k, nm in enumerate(names_cont)}
    sq_total = sq_theta + sq_my + sum(cont_squares_scaled.values())

    out = {
        "alpha": alpha,
        "groups_sq": {"||theta||^2": sq_theta, "||month_year||^2": sq_my, **cont_squares_scaled},
        "sum_sq_all": sq_total,
        "penalty_value_sklearn": 0.5 * alpha * sq_total,
        "penalty_value_alpha_sum": alpha * sq_total,
    }

    # de-standardize continuous coefs (original feature scale)
    if cf.scaler is not None and hasattr(cf.scaler, "scale_"):
        scales = np.array(cf.scaler.scale_, dtype=float)
        scales[scales == 0.0] = 1.0
        cont_coefs_original = (w_cont / scales).tolist()
    else:
        cont_coefs_original = w_cont.tolist()
    out["continuous_coefs_original_scale"] = dict(zip(names_cont, cont_coefs_original))

    if return_deviance:
        d = cf._build_design(flows_df, pop_df)
        d['month'] = pd.to_datetime(d['month']).values.astype("datetime64[M]")
        train_mask = d['month'] <= pd.to_datetime(cf.cfg.train_end)

        pairs = (d['orig'] + '→' + d['dest'])
        X_fit = cf._transform(pairs[train_mask],
                              d.loc[train_mask, 'month_year'],
                              d.loc[train_mask, ['log_pop_o','log_pop_d']].values)
        y_fit = d.loc[train_mask, 'flow'].values
        mu_fit = cf.model.predict(X_fit)

        eps = 1e-12
        mu_safe = np.clip(mu_fit, eps, None)
        with np.errstate(divide='ignore', invalid='ignore'):
            dev_terms = np.where(y_fit > 0,
                                 y_fit * np.log(y_fit / mu_safe) - (y_fit - mu_safe),
                                 -(y_fit - mu_safe))
        dev = 2.0 * np.nansum(dev_terms)
        out["train_poisson_deviance"] = float(dev)
        out["train_objective_value"]  = float(dev + 0.5 * alpha * sq_total)

    return out

# ---------- convenience wrappers ----------
def build_fit_predict(flows_df: pd.DataFrame, pop_df: pd.DataFrame, cfg: CFPlusConfig):
    """
    Fits CFPlus, returns (cf_model, design_df, preds_df).
    - design_df: internal design after grid completion + populations
    - preds_df : columns ['orig','dest','month','flow','mu_hat','excess_pct']
    """
    cf = CFPlus(cfg).fit(flows_df, pop_df)
    design = cf._build_design(flows_df, pop_df)
    preds = cf.predict_mu(flows_df, pop_df)
    return cf, design, preds

def build_and_fit_cf(flows_df: pd.DataFrame, pop_df: pd.DataFrame, cfg: CFPlusConfig):
    cf = CFPlus(cfg).fit(flows_df, pop_df)
    d = cf._build_design(flows_df, pop_df)
    return cf, d

def validation_curve_df(cf: CFPlus) -> pd.DataFrame:
    """Return the stored validation curve as a DataFrame (no re-fitting)."""
    if not cf.val_curve_:
        return pd.DataFrame(columns=['alpha','val_mae'])
    return (pd.DataFrame(cf.val_curve_, columns=['alpha','val_mae'])
              .sort_values('alpha').reset_index(drop=True))
