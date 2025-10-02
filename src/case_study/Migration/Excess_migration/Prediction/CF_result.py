import math
import json
import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from cf_plus_core import penalty_report_monthyear

# ---------- helpers ----------
def _ensure_month_index(s):
    s = pd.to_datetime(s, errors="coerce")
    return pd.to_datetime(s.values.astype("datetime64[M]"), errors="coerce")

def _require_cols(df, cols):
    missing = [c for c in cols if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

# ---------- Figure 1: Validation curve ----------
def plot_validation_curve(cf, *, save_path="validation_curve.png"):
    """
    Plot MAE vs alpha using cf.val_curve_ (recorded during CFPlus.fit()).
    """
    if not getattr(cf, "val_curve_", None):
        raise ValueError("cf.val_curve_ is empty. Fit the model first.")
    vc = pd.DataFrame(cf.val_curve_, columns=["alpha","val_mae"]).sort_values("alpha")
    x = vc["alpha"].values
    y = vc["val_mae"].values

    plt.figure(figsize=(6,4), dpi=150)
    plt.plot(np.log10(x), y, marker="o")
    i_best = int(np.argmin(y))
    plt.scatter([math.log10(x[i_best])], [y[i_best]])
    plt.xlabel("log10(alpha)")
    plt.ylabel("Validation MAE")
    plt.title(f"Validation curve (best α={x[i_best]:.1e}, MAE={y[i_best]:.3f})")
    plt.tight_layout()
    plt.savefig(save_path, bbox_inches="tight")
    plt.close()
    return save_path

# ---------- Figure 2: Obs vs Pred using masks (fit/val) ----------
def plot_obs_vs_pred_masks(preds_df, mask, *, save_path="obs_vs_pred.png", title="Observed vs predicted", hexbin=False):
    """
    Scatter/hexbin of observed vs predicted on log10 axes for a row subset controlled by a boolean mask.
    The mask must be aligned with preds_df row order (use cf.fit_mask_ or cf.val_mask_).
    """
    _require_cols(preds_df, ["flow","mu_hat"])
    if mask is None:
        raise ValueError("mask is None. Pass cf.fit_mask_ or cf.val_mask_.")
    if len(mask) != len(preds_df):
        raise ValueError("mask length must match preds_df length.")

    df = preds_df.loc[mask].copy()
    eps = 1e-9
    x = df["mu_hat"].astype(float).clip(lower=eps)
    y = df["flow"].astype(float).clip(lower=eps)

    X = np.log10(x.values)
    Y = np.log10(y.values)

    plt.figure(figsize=(6,6), dpi=150)
    if hexbin:
        hb = plt.hexbin(X, Y, gridsize=60, mincnt=1)
        cb = plt.colorbar(hb); cb.set_label("count")
    else:
        plt.scatter(X, Y, s=5, alpha=0.4)

    lims = np.array([min(X.min(), Y.min()), max(X.max(), Y.max())])
    plt.plot(lims, lims)
    plt.xlabel("log10(predicted μ̂)")
    plt.ylabel("log10(observed y)")
    plt.title(title)
    plt.tight_layout()
    plt.savefig(save_path, bbox_inches="tight")
    plt.close()
    return save_path

# ---------- Figure 3: Residual histogram (excess_pct or z) ----------
def plot_residual_histogram(preds_df, *, col="excess_pct", bins=80, xlim=None, logy=False, save_path="residual_hist.png", title=None):
    """
    Histogram of residual metrics. Default 'excess_pct'. For standardized residuals use col='z_std_jk'.
    """
    if col not in preds_df.columns:
        raise ValueError(f"Column '{col}' not found in preds_df.")
    x = pd.to_numeric(preds_df[col], errors="coerce").dropna().values

    plt.figure(figsize=(6,4), dpi=150)
    plt.hist(x, bins=bins)
    if xlim is not None:
        plt.xlim(xlim)
    if logy:
        plt.yscale("log")
    if col.lower().startswith("z"):
        plt.axvline(0, linestyle="--")
        plt.axvline(2, linestyle=":")
        plt.axvline(-2, linestyle=":")
    plt.xlabel(col)
    plt.ylabel("Count")
    plt.title(title or f"Distribution of {col}")
    plt.tight_layout()
    plt.savefig(save_path, bbox_inches="tight")
    plt.close()
    return save_path

# ---------- Figure 4: Penalty composition with percentages ----------
def plot_penalty_composition(penalty_report: dict, *, save_path="penalty_composition.png"):
    """
    Bar chart of penalty group squares from penalty_report_monthyear(...).
    """
    if "groups_sq" not in penalty_report:
        raise ValueError("penalty_report must have a 'groups_sq' dict.")
    labels, values = zip(*penalty_report["groups_sq"].items())
    vals = np.array(values, dtype=float)
    pct = 100 * vals / np.maximum(vals.sum(), 1e-12)

    plt.figure(figsize=(7,4), dpi=150)
    plt.bar(range(len(vals)), vals)
    xt = [f"{lab}\n({p:.1f}%)" for lab, p in zip(labels, pct)]
    plt.xticks(range(len(vals)), xt, rotation=0, ha="center")
    plt.ylabel("Squared L2 norm (scaled space)")
    plt.title("Penalty composition")
    plt.tight_layout()
    plt.savefig(save_path, bbox_inches="tight")
    plt.close()
    return save_path

# -----------------------------------------------------------
# -------------------- Training Result ---------------------
# -----------------------------------------------------------

# ---------- One-shot: export all to a single PDF ----------
def save_all_diagnostics(cf, preds_df, penalty_report: dict, *,
                         train_title="Observed vs predicted (fit slice)",
                         val_title="Observed vs predicted (validation slice)",
                         pdf_path="diagnostics.pdf",
                         train_hexbin=False, val_hexbin=False,
                         residual_col="excess_pct", residual_xlim=None, residual_logy=False):
    """
    Writes a multi-page PDF with: validation curve, obs-vs-pred (fit), obs-vs-pred (val), residual histogram, penalty composition.
    """
    if not getattr(cf, "val_curve_", None):
        raise ValueError("cf.val_curve_ is empty. Fit the model first.")
    if not hasattr(cf, "fit_mask_") or not hasattr(cf, "val_mask_"):
        raise ValueError("cf.fit_mask_ / cf.val_mask_ missing. Add them in CFPlus.fit and refit.")

    vc = pd.DataFrame(cf.val_curve_, columns=["alpha","val_mae"]).sort_values("alpha")
    x = vc["alpha"].values; y = vc["val_mae"].values
    best_i = int(np.argmin(y))

    with PdfPages(pdf_path) as pdf:
        # Page 1: Validation curve
        plt.figure(figsize=(6,4), dpi=150)
        plt.plot(np.log10(x), y, marker="o")
        plt.scatter([math.log10(x[best_i])], [y[best_i]])
        plt.xlabel("log10(alpha)"); plt.ylabel("Validation MAE")
        plt.title(f"Validation curve (best α={x[best_i]:.1e}, MAE={y[best_i]:.3f})")
        plt.tight_layout(); pdf.savefig(); plt.close()

        # Page 2: Obs vs Pred (fit slice)
        mask = cf.fit_mask_
        _require_cols(preds_df, ["flow","mu_hat"])
        df = preds_df.loc[mask]
        eps = 1e-9
        X = np.log10(df["mu_hat"].astype(float).clip(lower=eps).values)
        Y = np.log10(df["flow"].astype(float).clip(lower=eps).values)
        plt.figure(figsize=(6,6), dpi=150)
        if train_hexbin:
            hb = plt.hexbin(X, Y, gridsize=60, mincnt=1); cb = plt.colorbar(hb); cb.set_label("count")
        else:
            plt.scatter(X, Y, s=5, alpha=0.4)
        lims = np.array([min(X.min(), Y.min()), max(X.max(), Y.max())])
        plt.plot(lims, lims)
        plt.xlabel("log10(predicted μ̂)"); plt.ylabel("log10(observed y)"); plt.title(train_title)
        plt.tight_layout(); pdf.savefig(); plt.close()

        # Page 3: Obs vs Pred (validation slice)
        mask = cf.val_mask_
        df = preds_df.loc[mask]
        X = np.log10(df["mu_hat"].astype(float).clip(lower=eps).values)
        Y = np.log10(df["flow"].astype(float).clip(lower=eps).values)
        plt.figure(figsize=(6,6), dpi=150)
        if val_hexbin:
            hb = plt.hexbin(X, Y, gridsize=60, mincnt=1); cb = plt.colorbar(hb); cb.set_label("count")
        else:
            plt.scatter(X, Y, s=5, alpha=0.4)
        lims = np.array([min(X.min(), Y.min()), max(X.max(), Y.max())])
        plt.plot(lims, lims)
        plt.xlabel("log10(predicted μ̂)"); plt.ylabel("log10(observed y)"); plt.title(val_title)
        plt.tight_layout(); pdf.savefig(); plt.close()

        # Page 4: Residual histogram
        col = residual_col
        if col not in preds_df.columns:
            raise ValueError(f"Column '{col}' not found in preds_df.")
        data = pd.to_numeric(preds_df[col], errors="coerce").dropna().values
        plt.figure(figsize=(6,4), dpi=150)
        plt.hist(data, bins=80)
        if residual_xlim is not None:
            plt.xlim(residual_xlim)
        if residual_logy:
            plt.yscale("log")
        if col.lower().startswith("z"):
            plt.axvline(0, linestyle="--"); plt.axvline(2, linestyle=":"); plt.axvline(-2, linestyle=":")
        plt.xlabel(col); plt.ylabel("Count"); plt.title(f"Distribution of {col}")
        plt.tight_layout(); pdf.savefig(); plt.close()

        # Page 5: Penalty composition
        if "groups_sq" not in penalty_report:
            raise ValueError("penalty_report must have a 'groups_sq' dict.")
        labels, values = zip(*penalty_report["groups_sq"].items())
        vals = np.array(values, dtype=float)
        pct = 100 * vals / np.maximum(vals.sum(), 1e-12)
        plt.figure(figsize=(7,4), dpi=150)
        plt.bar(range(len(vals)), vals)
        xt = [f"{lab}\n({p:.1f}%)" for lab, p in zip(labels, pct)]
        plt.xticks(range(len(vals)), xt, rotation=0, ha="center")
        plt.ylabel("Squared L2 norm (scaled space)")
        plt.title("Penalty composition")
        plt.tight_layout(); pdf.savefig(); plt.close()

    return pdf_path


# ---------- Get all .csv for plot in R ----------
def export_validation_curve(cf, path_csv="val_curve.csv"):
    """
    Saves the alpha vs validation MAE table recorded during CFPlus.fit().
    """
    if not getattr(cf, "val_curve_", None):
        raise ValueError("cf.val_curve_ is empty. Fit the model first.")
    vc = (pd.DataFrame(cf.val_curve_, columns=["alpha","val_mae"])
            .sort_values("alpha").reset_index(drop=True))
    vc.to_csv(path_csv, index=False)
    return vc

def export_preds_with_masks(cf, preds_df, path_csv="preds_with_masks.csv", include_cols=None):
    """
    Saves predictions with boolean masks so you can filter 'fit' and 'val' elsewhere.
    include_cols lets you keep extra columns (e.g., 'pair', 'region', etc.) if present.
    """
    if not hasattr(cf, "fit_mask_") or not hasattr(cf, "val_mask_"):
        raise ValueError("Missing cf.fit_mask_ / cf.val_mask_. Add them in CFPlus.fit.")
    out = preds_df.copy()
    out["is_fit_slice"] = np.array(cf.fit_mask_, dtype=bool)
    out["is_val_slice"] = np.array(cf.val_mask_, dtype=bool)
    base_cols = ["orig","dest","month","flow","mu_hat","excess_pct","is_fit_slice","is_val_slice"]
    if include_cols:
        keep = [c for c in include_cols if c in out.columns]
        base_cols += keep
        base_cols = list(dict.fromkeys(base_cols))  # de-dup
    out = out[base_cols]
    # Make month ISO so other tools parse it easily
    out["month"] = pd.to_datetime(out["month"]).dt.to_period("M").astype(str)
    out.to_csv(path_csv, index=False)
    return out

def export_penalty_report(cf, flows_df, pop_df,
                          path_json="penalty_report.json", path_csv="penalty_groups.csv"):
    """
    Saves the full penalty report as JSON, and a skinny CSV of group squares for plotting.
    """
    rep = penalty_report_monthyear(cf, return_deviance=True, flows_df=flows_df, pop_df=pop_df)
    # JSON (everything, including deviance/objective and de-standardized coefs)
    with open(path_json, "w") as f:
        json.dump(rep, f, indent=2)
    # CSV (bar chart-ready)
    groups = pd.DataFrame(list(rep["groups_sq"].items()), columns=["group","squared_l2"])
    groups.to_csv(path_csv, index=False)
    return rep, groups

def export_residuals_only(preds_df, col="excess_pct", path_csv="residuals.csv"):
    """
    Saves a one-column residual file (plus basic keys) for simple histogramming elsewhere.
    """
    if col not in preds_df.columns:
        raise ValueError(f"Column '{col}' not found in preds_df.")
    out = preds_df[["orig","dest","month",col]].copy()
    out["month"] = pd.to_datetime(out["month"]).dt.to_period("M").astype(str)
    out.to_csv(path_csv, index=False)
    return out



# -----------------------------------------------------------
# ------------------ Global Result Figure --------------------
# -----------------------------------------------------------

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ------------- CORE AGGREGATION + CALIBRATION -------------
def build_global_series(df):
    """
    Input df columns: ['orig','dest','month','flow','mu_hat'].
    Returns:
      df_cal : original df + calibrated mu_hat_cal
      G      : monthly global aggregates incl. pos/abs excess, shares, cumulatives
    """
    df = df.copy()
    df["month"] = pd.to_datetime(df["month"])
    df.sort_values("month", inplace=True)

    # Monthly calibration so global totals match by construction
    g = df.groupby("month", as_index=False).agg(obs=("flow","sum"), hat=("mu_hat","sum"))
    g["s"] = g["obs"] / g["hat"]
    df = df.merge(g[["month","s"]], on="month", how="left")
    df["mu_hat_cal"] = df["mu_hat"] * df["s"]

    # Per-corridor residuals (calibrated)
    df["resid"] = df["flow"] - df["mu_hat_cal"]
    df["pos"] = df["resid"].clip(lower=0)
    df["ab"]  = df["resid"].abs()

    # Monthly global aggregates (level + redistribution)
    tmp = df.groupby("month").agg(
        obs=("flow","sum"),
        hat_cal=("mu_hat_cal","sum"),
        pos=("pos","sum"),
        ab=("ab","sum")
    ).reset_index()

    tmp["excess"] = tmp["obs"] - tmp["hat_cal"]                 # should be ~0 after calibration
    tmp["excess_share"] = tmp["excess"] / tmp["hat_cal"]        # ~0 line (net)
    tmp["pos_excess_share"] = tmp["pos"] / tmp["hat_cal"]       # one-sided (no cancellation)
    tmp["abs_excess_share"] = tmp["ab"]  / tmp["hat_cal"]       # absolute (no cancellation)

    # Cumulatives (useful to show persistence)
    tmp["cum_abs_excess"]  = tmp["ab"].cumsum()
    tmp["cum_pos_excess"]  = tmp["pos"].cumsum()

    return df, tmp.rename(columns={"month":"date"})

# ------------- PLOTTING: GLOBAL PANEL -------------
def plot_global_baseline_and_redistribution(G, covid_start="2020-03-01", covid_end="2022-03-01"):
    """
    Two-panel figure:
      Top: Observed vs Calibrated counterfactual (should overlap — shows levels are captured)
      Bottom: positive-excess share and absolute-excess share (redistribution signal)
    """
    G = G.copy()
    G["date"] = pd.to_datetime(G["date"])
    covid_start = pd.to_datetime(covid_start)
    covid_end   = pd.to_datetime(covid_end)

    fig = plt.figure(figsize=(9,6), dpi=150)
    gs = fig.add_gridspec(nrows=2, ncols=1, height_ratios=[3,1], hspace=0.1)

    # Top panel
    ax1 = fig.add_subplot(gs[0,0])
    ax1.plot(G["date"], G["obs"], label="Observed", linewidth=2)
    ax1.plot(G["date"], G["hat_cal"], label="Calibrated counterfactual", linestyle="--")
    ax1.axvspan(covid_start, covid_end, alpha=0.15)
    ax1.set_ylabel("Global monthly flows")
    ax1.legend(frameon=False, loc="upper left")

    # Bottom panel
    ax2 = fig.add_subplot(gs[1,0], sharex=ax1)
    ax2.plot(G["date"], G["pos_excess_share"]*100, label="Positive-excess share (%)", linewidth=1.5)
    ax2.plot(G["date"], G["abs_excess_share"]*100, label="Absolute-excess share (%)", linewidth=1.0)
    ax2.axhline(0, linestyle="--", linewidth=1)
    ax2.axvspan(covid_start, covid_end, alpha=0.15)
    ax2.set_ylabel("Excess (%)")
    ax2.set_xlabel("Month")
    ax2.legend(frameon=False, loc="upper left")

    plt.tight_layout()
    return fig

# ------------- OPTIONAL: CUMULATIVE PANEL -------------
def plot_cumulative_excess(G, covid_start="2020-03-01", covid_end="2022-03-01"):
    """
    Optional single-panel figure for paper/appendix: cumulative positive/absolute excess.
    """
    G = G.copy()
    G["date"] = pd.to_datetime(G["date"])
    covid_start = pd.to_datetime(covid_start); covid_end = pd.to_datetime(covid_end)

    plt.figure(figsize=(8,4), dpi=150)
    plt.plot(G["date"], G["cum_pos_excess"], label="Cumulative positive excess")
    plt.plot(G["date"], G["cum_abs_excess"], label="Cumulative absolute excess", linestyle="--")
    plt.axvspan(covid_start, covid_end, alpha=0.15)
    plt.xlabel("Month"); plt.ylabel("Cumulative excess (flows)")
    plt.legend(frameon=False)
    plt.tight_layout()

# ------------- OPTIONAL: WHO DRIVES IT? TOP-K STACK -------------
def plot_topk_positive_excess(df_cal, k=8):
    """
    Shows which corridors drive positive excess each month.
    Picks top-k corridors by total positive excess over the whole period and stacks them.
    """
    df = df_cal.copy()
    df["key"] = df["orig"] + "→" + df["dest"]
    topk = (df.groupby("key")["pos"].sum()
              .sort_values(ascending=False)
              .head(k)
              .index.tolist())

    # Pivot positive excess for top-k
    top_df = df[df["key"].isin(topk)].pivot_table(
        index="month", columns="key", values="pos", aggfunc="sum", fill_value=0.0
    ).sort_index()

    # Stackplot (compact, clean)
    plt.figure(figsize=(10,4), dpi=150)
    plt.stackplot(top_df.index, *[top_df[col].values for col in top_df.columns], labels=top_df.columns)
    plt.ylabel("Monthly positive excess (flows)")
    plt.xlabel("Month")
    plt.legend(ncol=2, fontsize=8, frameon=False, loc="upper left")
    plt.tight_layout()


# -----------------------------------------------------------
# ------------ Global redistribution metrics ----------------
# -----------------------------------------------------------

import pandas as pd
import numpy as np

# ----- CONFIG -----
COVID_START = pd.Timestamp("2020-03-01")
COVID_END   = pd.Timestamp("2020-10-01")

def _period_mask(G, start=None, end=None):
    d = G["date"]
    m = pd.Series(True, index=G.index)
    if start is not None:
        m &= d >= pd.Timestamp(start)
    if end is not None:
        m &= d <= pd.Timestamp(end)
    return m

def _pct(x):  # format as percentage with one decimal
    return f"{100*x:.1f}%"

def _mil(x):  # format counts in millions with one decimal
    return f"{x/1e6:.1f}M"

def compute_global_stats(G, covid_start=COVID_START, covid_end=COVID_END):
    """Return a dict of key stats for text/captions."""
    G = G.copy()
    # ensure datetime
    G["date"] = pd.to_datetime(G["date"])

    # PERIODS
    m_all   = _period_mask(G)
    m_pre   = _period_mask(G, end=covid_start - pd.offsets.MonthBegin(0))
    m_covid = _period_mask(G, start=covid_start, end=covid_end)
    m_post  = _period_mask(G, start=covid_end + pd.offsets.MonthBegin(0))

    # SHARES (means & peaks)
    def share_stats(mask, col):
        s = G.loc[mask, col].dropna()
        if s.empty:
            return {"mean": np.nan, "median": np.nan, "max": (np.nan, None)}
        idxmax = s.idxmax()
        return {
            "mean": s.mean(),
            "median": s.median(),
            "max": (s.loc[idxmax], G.loc[idxmax, "date"])
        }

    pos_all   = share_stats(m_all,   "pos_excess_share")
    pos_pre   = share_stats(m_pre,   "pos_excess_share")
    pos_covid = share_stats(m_covid, "pos_excess_share")
    pos_post  = share_stats(m_post,  "pos_excess_share")

    abs_all   = share_stats(m_all,   "abs_excess_share")
    abs_pre   = share_stats(m_pre,   "abs_excess_share")
    abs_covid = share_stats(m_covid, "abs_excess_share")
    abs_post  = share_stats(m_post,  "abs_excess_share")

    # CUMULATIVES at period ends
    # (cum_* already accumulate over the whole series; to get period totals, sum monthly)
    tot_pos_all   = G.loc[m_all,   "pos"].sum()
    tot_abs_all   = G.loc[m_all,   "ab"].sum()
    tot_pos_pre   = G.loc[m_pre,   "pos"].sum()
    tot_abs_pre   = G.loc[m_pre,   "ab"].sum()
    tot_pos_covid = G.loc[m_covid, "pos"].sum()
    tot_abs_covid = G.loc[m_covid, "ab"].sum()
    tot_pos_post  = G.loc[m_post,  "pos"].sum()
    tot_abs_post  = G.loc[m_post,  "ab"].sum()

    # OPTIONAL: typical monthly global baseline size (for context)
    mean_baseline_all = G.loc[m_all, "hat_cal"].mean()

    return {
        "periods": {
            "pre":   (G.loc[m_pre, "date"].min(),   G.loc[m_pre, "date"].max()),
            "covid": (G.loc[m_covid, "date"].min(), G.loc[m_covid, "date"].max()),
            "post":  (G.loc[m_post, "date"].min(),  G.loc[m_post, "date"].max()),
        },
        "pos_share": {
            "all":   pos_all,
            "pre":   pos_pre,
            "covid": pos_covid,
            "post":  pos_post,
        },
        "abs_share": {
            "all":   abs_all,
            "pre":   abs_pre,
            "covid": abs_covid,
            "post":  abs_post,
        },
        "totals": {
            "pos":  {"all": tot_pos_all, "pre": tot_pos_pre, "covid": tot_pos_covid, "post": tot_pos_post},
            "abs":  {"all": tot_abs_all, "pre": tot_abs_pre, "covid": tot_abs_covid, "post": tot_abs_post},
        },
        "context": {"mean_monthly_baseline": mean_baseline_all},
    }

# Pretty-print a short summary (for your paper text)
def print_global_stats(stats):
    pos_all = stats["pos_share"]["all"]; abs_all = stats["abs_share"]["all"]
    pos_covid = stats["pos_share"]["covid"]; abs_covid = stats["abs_share"]["covid"]

    print("=== Global redistribution metrics ===")
    print(f"Average positive-excess share: {_pct(pos_all['mean'])} (median {_pct(pos_all['median'])}); "
          f"peak {_pct(pos_all['max'][0])} in {pos_all['max'][1].date() if pos_all['max'][1] else 'NA'}")
    print(f"Average absolute-excess share: {_pct(abs_all['mean'])} (median {_pct(abs_all['median'])}); "
          f"peak {_pct(abs_all['max'][0])} in {abs_all['max'][1].date() if abs_all['max'][1] else 'NA'}")

    print("\n— COVID window —")
    print(f"Positive-excess share (mean): {_pct(pos_covid['mean'])}; peak {_pct(pos_covid['max'][0])} "
          f"in {pos_covid['max'][1].date() if pos_covid['max'][1] else 'NA'}")
    print(f"Absolute-excess share (mean): {_pct(abs_covid['mean'])}; peak {_pct(abs_covid['max'][0])} "
          f"in {abs_covid['max'][1].date() if abs_covid['max'][1] else 'NA'}")

    print("\nCumulative totals (flows):")
    print(f"  Positive-excess: {_mil(stats['totals']['pos']['all'])} "
          f"(pre {_mil(stats['totals']['pos']['pre'])}, covid {_mil(stats['totals']['pos']['covid'])}, "
          f"post {_mil(stats['totals']['pos']['post'])})")
    print(f"  Absolute-excess: {_mil(stats['totals']['abs']['all'])} "
          f"(pre {_mil(stats['totals']['abs']['pre'])}, covid {_mil(stats['totals']['abs']['covid'])}, "
          f"post {_mil(stats['totals']['abs']['post'])})")

    print(f"\nContext: mean monthly global baseline size ≈ {_mil(stats['context']['mean_monthly_baseline'])}")


# -----------------------------------------------------------
# ------------------------ Line Fit ----------------------------
# -----------------------------------------------------------

import numpy as np
import pandas as pd

def _safe_mape(y, yhat):
    y = np.asarray(y, dtype=float)
    yhat = np.asarray(yhat, dtype=float)
    mask = y != 0
    if not np.any(mask): 
        return np.nan
    return np.mean(np.abs((y[mask]-yhat[mask]) / y[mask]))

def _smape(y, yhat):
    y = np.asarray(y, dtype=float)
    yhat = np.asarray(yhat, dtype=float)
    denom = (np.abs(y) + np.abs(yhat))
    mask = denom != 0
    if not np.any(mask):
        return np.nan
    return np.mean(2.0 * np.abs(y[mask]-yhat[mask]) / denom[mask])

def _ccc(y, yhat):
    # Lin's concordance correlation coefficient
    y = np.asarray(y, dtype=float); yhat = np.asarray(yhat, dtype=float)
    mu_y, mu_h = np.mean(y), np.mean(yhat)
    s2_y, s2_h = np.var(y, ddof=1), np.var(yhat, ddof=1)
    cov = np.cov(y, yhat, ddof=1)[0,1]
    return (2*cov) / (s2_y + s2_h + (mu_y - mu_h)**2) if (s2_y + s2_h + (mu_y - mu_h)**2)!=0 else np.nan

def _nse(y, yhat):
    y = np.asarray(y, dtype=float); yhat = np.asarray(yhat, dtype=float)
    denom = np.sum((y - np.mean(y))**2)
    if denom == 0: 
        return np.nan
    return 1.0 - np.sum((y - yhat)**2) / denom

def _theil_u2(y, yhat):
    # Compare model errors to naive (y_{t-1})
    y = np.asarray(y, dtype=float); yhat = np.asarray(yhat, dtype=float)
    if len(y) < 2:
        return np.nan
    err_model = y[1:] - yhat[1:]
    err_naive = y[1:] - y[:-1]
    denom = np.sqrt(np.mean(err_naive**2))
    return np.sqrt(np.mean(err_model**2)) / denom if denom != 0 else np.nan

def _diff_corr(y, yhat):
    y = np.asarray(y, dtype=float); yhat = np.asarray(yhat, dtype=float)
    if len(y) < 2:
        return np.nan
    dy, dh = np.diff(y), np.diff(yhat)
    if np.std(dy)==0 or np.std(dh)==0:
        return np.nan
    return np.corrcoef(dy, dh)[0,1]

def _series_metrics(y, yhat):
    y = np.asarray(y, dtype=float); yhat = np.asarray(yhat, dtype=float)
    rmse = np.sqrt(np.mean((y - yhat)**2))
    nrmse_mean = rmse / (np.mean(y) if np.mean(y)!=0 else np.nan)
    y_range = np.max(y) - np.min(y)
    nrmse_range = rmse / (y_range if y_range!=0 else np.nan)
    r = np.corrcoef(y, yhat)[0,1] if np.std(y)>0 and np.std(yhat)>0 else np.nan
    return {
        "NSE(R2_1to1)": _nse(y, yhat),
        "RMSE": rmse,
        "NRMSE_mean": nrmse_mean,
        "NRMSE_range": nrmse_range,
        "MAPE": _safe_mape(y, yhat),
        "sMAPE": _smape(y, yhat),
        "Pearson_r": r,
        "CCC": _ccc(y, yhat),
        "Delta_corr": _diff_corr(y, yhat),
        "Theil_U2_vs_naive": _theil_u2(y, yhat),
    }

def metrics_for_global(df_cal):
    g = (df_cal.groupby("month", as_index=False)
                 .agg(flow=("flow","sum"), hat=("mu_hat_cal","sum"))
                 .sort_values("month"))
    return pd.Series(_series_metrics(g["flow"].values, g["hat"].values), name="GLOBAL")

def metrics_for_corridors(df_cal, corridors):
    """
    corridors: list of (orig, dest) tuples, e.g. [('FR','DE'), ('CA','US')]
    Returns a DataFrame with one row per corridor that exists in the data.
    """
    rows = []
    for o,d in corridors:
        sub = (df_cal[(df_cal["orig"]==o) & (df_cal["dest"]==d)]
                      .sort_values("month")[["month","flow","mu_hat_cal"]])
        if len(sub) == 0:
            rows.append(pd.Series({"orig":o,"dest":d,"note":"no data"}, name=f"{o}->{d}"))
            continue
        m = _series_metrics(sub["flow"].values, sub["mu_hat_cal"].values)
        s = pd.Series(m, name=f"{o}->{d}")
        s["orig"], s["dest"] = o, d
        rows.append(s)
    return pd.DataFrame(rows)


# -----------------------------------------------------------
# -------------------- Actual vs Counterfactual -------------------------
# -----------------------------------------------------------

import pandas as pd
import matplotlib.pyplot as plt
from typing import List, Tuple, Optional, Dict
import numpy as np

def plot_pair_actual_vs_counterfactual(
    pred_df: pd.DataFrame,
    orig: str, dest: str,
    policies: Optional[List[Tuple[str, str, Optional[str]]]] = None,
    line_colors: Optional[Dict[str, str]] = None,
    yscale: str = "linear",
    pred_col: str = "mu_hat",     # column in `pred_df` for counterfactual
    flow_col: str = "flow",       # column in `pred_df` for actual
):
    """
    Plot Actual vs Counterfactual for a single pair orig→dest using the CF+ output.

    Parameters
    ----------
    pred_df : DataFrame
        Columns required: ['orig','dest','month', flow_col, pred_col]
        Defaults align with CFPlus.predict_mu() -> flow_col='flow', pred_col='mu_hat'.
    orig, dest : str
        ISO3 (or whatever your IDs are) for origin and destination.
    policies : list of (date, label, color), optional
        e.g. [("2021-09-15","Policy A","tab:green")]
    line_colors : dict, optional
        e.g. {"actual": "tab:blue", "counterfactual": "tab:orange"}
    yscale : 'linear' | 'log' | 'symlog'
    pred_col, flow_col : str
        Column names for the counterfactual and actual series.
    """
    df = pred_df.copy()
    df["month"] = pd.to_datetime(df["month"], errors="coerce")

    sub = df[(df["orig"] == orig) & (df["dest"] == dest)].sort_values("month")
    if sub.empty:
        print(f"No rows for pair {orig}→{dest}")
        return

    # pick colors
    lc_actual = (line_colors or {}).get("actual", None)
    lc_pred   = (line_colors or {}).get("counterfactual", None)

    # plot
    plt.figure(figsize=(10, 4.5))
    plt.plot(sub["month"], sub[flow_col], label=f"Actual {orig}→{dest}", color=lc_actual, linewidth=2)
    plt.plot(sub["month"], sub[pred_col], label=f"Counterfactual {orig}→{dest}",
             color=lc_pred, linestyle="--", linewidth=2)

    if yscale in {"linear", "log", "symlog"}:
        plt.yscale(yscale)

    if policies:
        ylim_top = plt.ylim()[1]
        for date, name, color in policies:
            d = pd.to_datetime(date, errors="coerce")
            if pd.isna(d):
                continue
            plt.axvline(x=d, color=color, linestyle=":", linewidth=2)
            if name:
                plt.text(d, ylim_top * 0.95, name, color=color,
                         rotation=90, va="top", ha="right", fontsize=11)

    plt.title(f"Actual vs Counterfactual for {orig}→{dest}", fontsize=15, weight="bold")
    plt.xlabel("Month", fontsize=12)
    plt.ylabel("Monthly Flow", fontsize=12)
    plt.legend(frameon=False, fontsize=11)
    plt.tight_layout()
    plt.show()


def plot_triad_eop(
    eop_df: pd.DataFrame,
    i: str, j: str, k: str,
    ma: int = 3,
    policies: Optional[List[Tuple[str, str, Optional[str]]]] = None,
    line_colors: Optional[Dict[str, str]] = None,
    eop_col: str = "EOP",
):
    """
    Plot EOP (moving average) for a triad i→j→k.

    Parameters
    ----------
    eop_df : DataFrame
        Must include ['i','j','k','month', eop_col].
    i, j, k : str
        Triad identifiers (e.g., "VE","PE","US").
    ma : int
        Moving average window for the EOP plot.
    policies : list of (date, label, color), optional
        e.g. [("2022-10-12","US policy","tab:green")]
    line_colors : dict, optional
        e.g. {"eop": "tab:red"}
    eop_col : str
        Column name for the EOP series. Default "EOP".
    """
    df = eop_df.copy()
    df["month"] = pd.to_datetime(df["month"], errors="coerce")

    sub = df[(df["i"] == i) & (df["j"] == j) & (df["k"] == k)].sort_values("month")
    if sub.empty:
        print(f"No rows for triad {i}-{j}-{k}")
        return

    if eop_col not in sub.columns:
        raise ValueError(f"EOP column '{eop_col}' not found in DataFrame.")

    # pick color
    lc_eop = (line_colors or {}).get("eop", None)

    # moving average
    y = sub.set_index("month")[eop_col].astype(float).replace([np.inf, -np.inf], np.nan).fillna(0.0)
    y_ma = y.rolling(ma, min_periods=1).mean()

    # plot
    plt.figure(figsize=(10, 3.8))
    plt.plot(y_ma.index, y_ma.values, color=lc_eop, linewidth=2)
    plt.axhline(0, color="gray", linestyle="--", linewidth=1)

    if policies:
        ylim_top = plt.ylim()[1]
        for date, name, color in policies:
            d = pd.to_datetime(date, errors="coerce")
            if pd.isna(d):
                continue
            plt.axvline(x=d, color=color, linestyle=":", linewidth=2)
            if name:
                plt.text(d, ylim_top * 0.95, name, color=color,
                         rotation=90, va="top", ha="right", fontsize=11)

    plt.title(f"EOP ({ma}-month MA) for {i}→{j}→{k}", fontsize=15, weight="bold")
    plt.xlabel("Month", fontsize=12)
    plt.ylabel("Index", fontsize=12)
    plt.tight_layout()
    plt.show()


def use_nature_style():
    """
    Apply a Nature-style aesthetic to matplotlib plots:
    - Clean fonts (sans-serif)
    - Larger font sizes for readability
    - Minimal gridlines
    - Thicker lines and ticks
    - Consistent figure size
    """
    mpl.rcParams.update({
        "figure.figsize": (6, 4),
        "figure.dpi": 150,
        "font.family": "sans-serif",
        "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
        "font.size": 11,
        "axes.labelsize": 12,
        "axes.titlesize": 13,
        "axes.linewidth": 1,
        "axes.grid": False,
        "xtick.labelsize": 11,
        "ytick.labelsize": 11,
        "xtick.direction": "out",
        "ytick.direction": "out",
        "xtick.major.size": 4,
        "ytick.major.size": 4,
        "lines.linewidth": 1.5,
        "lines.markersize": 5,
        "legend.frameon": False,
        "legend.fontsize": 10,
        "savefig.bbox": "tight",
        "savefig.dpi": 300,
        "grid.alpha": 0.3,
        "grid.linestyle": "--",
        "axes.spines.top": False,
        "axes.spines.right": False
    })
use_nature_style()
