import pandas as pd
import numpy as np
from dataclasses import dataclass

# -----------------------------
# Config
# -----------------------------
@dataclass
class EOPOpts:
    train_end: str = "2021-12-01"   # months <= train_end used to estimate phi
    weight_col: str = "weight_ij"   # or "weight_ratio_ij"
    eps: float = 1.0                # guard for tiny mu_hat when reconstructing flows

# -----------------------------
# Helpers
# -----------------------------
def _ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s)
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out)

# -----------------------------
# Core
# -----------------------------
def compute_eop_from_triads(df: pd.DataFrame, opts: EOPOpts) -> pd.DataFrame:
    """
    Expects columns:
      month, i, j, k, excess_pct_jk, mu_hat_jk, weight_ij (and/or weight_ratio_ij)

    Produces:
      flow_jk (reconstructed if missing), z_std_jk, EOP_pct, EOP_z
    """
    req = {"month","i","j","k","excess_pct_jk","mu_hat_jk"}
    missing = req - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    if opts.weight_col not in df.columns:
        raise ValueError(f"Weight column '{opts.weight_col}' not found. "
                         f"Available: {sorted(df.columns)}")

    d = df.copy()
    d["month"] = _ensure_month(d["month"])

    # 1) Reconstruct observed flow on j->k if not provided: F = mu_hat * (1 + excess_pct)
    if "flow_jk" not in d.columns:
        d["flow_jk"] = d["mu_hat_jk"].astype(float) * (1.0 + d["excess_pct_jk"].astype(float))
    # numeric guards
    d["mu_hat_jk"] = d["mu_hat_jk"].astype(float).clip(lower=1e-9)
    d["flow_jk"]   = d["flow_jk"].astype(float).clip(lower=0.0)

    # 2) Estimate phi (Pearson dispersion) on training window
    train_mask = d["month"] <= pd.to_datetime(opts.train_end)
    train = d.loc[train_mask].copy()
    if train.empty:
        raise ValueError("Training window is empty; adjust opts.train_end to include some rows.")

    mu = np.maximum(train["mu_hat_jk"].values, 1e-9)
    chi2 = ((train["flow_jk"].values - mu)**2) / mu
    n = len(train)
    # DOF approximation: (#unique (j,k) pairs - 1) + (#months - 1)
    p_pairs  = train[["j","k"]].drop_duplicates().shape[0] - 1
    p_months = train["month"].nunique() - 1
    p_eff = max(p_pairs + p_months, 1)
    dof = max(n - p_eff, 1)
    phi_hat = float(np.sum(chi2) / dof)

    # 3) Standardized anomaly on j->k: z = (F - mu) / sqrt(phi * mu)
    denom = np.sqrt(np.maximum(phi_hat * np.maximum(d["mu_hat_jk"].values, 1e-9), 1e-9))
    d["z_std_jk"] = (d["flow_jk"].values - d["mu_hat_jk"].values) / denom

    # 4) EOPs (choose your weight column)
    w = d[opts.weight_col].astype(float).fillna(0.0)
    d["EOP_pct"] = d["excess_pct_jk"].astype(float) * w
    d["EOP_z"]   = d["z_std_jk"].astype(float)       * w

    # 5) Tidy ordering
    out_cols = ["month","i","j","k",
                "flow_jk","mu_hat_jk","excess_pct_jk","z_std_jk",
                opts.weight_col,"EOP_pct","EOP_z"]
    d = d[out_cols].sort_values(["i","j","k","month"]).reset_index(drop=True)

    # Attach metadata
    d.attrs["phi_hat"] = phi_hat
    d.attrs["train_end"] = opts.train_end
    return d

# -----------------------------
# Example usage (uncomment to run)
# -----------------------------
# df = pd.read_csv("your_triads_table.csv")
# opts = EOPOpts(train_end="2021-12-01", weight_col="weight_ij")
# eop = compute_eop_from_triads(df, opts)
# print("phi_hat:", eop.attrs.get("phi_hat"))
# eop.to_csv("eop_from_triads.csv", index=False)
