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
