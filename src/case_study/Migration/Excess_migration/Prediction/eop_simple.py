import pandas as pd
import numpy as np
from dataclasses import dataclass
from tqdm import tqdm

# -----------------------------
# Config
# -----------------------------
@dataclass
class EOPOpts:
    train_end: str = "2021-12-01"   # months <= train_end used to estimate phi
    weight_col: str = "weight_ij"   # or "weight_ratio_ij"
    eps: float = 1.0                # guard for tiny mu_hat when reconstructing flows
    use_progress: bool = False      # if True, process groups with tqdm
    group_batch_size: int = 1000    # when using progress, number of groups per batch (controls mem)

# -----------------------------
# Helpers
# -----------------------------
def _ensure_month(s: pd.Series) -> pd.Series:
    out = pd.to_datetime(s)
    out = out.values.astype("datetime64[M]")
    return pd.to_datetime(out)

# -----------------------------
# Core (progress-enabled)
# -----------------------------
def compute_eop_from_triads(df: pd.DataFrame, opts: EOPOpts) -> pd.DataFrame:
    """
    Expects columns:
      month, i, j, k, excess_pct_jk, mu_hat_jk, weight_ij (and/or weight_ratio_ij)

    Produces:
      DataFrame with columns:
        month,i,j,k,flow_jk,mu_hat_jk,excess_pct_jk,z_std_jk, <weight_col>, EOP_pct, EOP_z

    Options:
      opts.use_progress: if True, iterate over (i,j,k) groups with tqdm (useful for very large tables)
    """
    req = {"month","i","j","k","excess_pct_jk","mu_hat_jk"}
    missing = req - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")

    if opts.weight_col not in df.columns:
        raise ValueError(f"Weight column '{opts.weight_col}' not found. Available: {sorted(df.columns)}")

    d = df.copy()
    d["month"] = _ensure_month(d["month"])

    # 1) Reconstruct observed flow on j->k if not provided: F = mu_hat * (1 + excess_pct)
    if "flow_jk" not in d.columns:
        d["flow_jk"] = d["mu_hat_jk"].astype(float) * (1.0 + d["excess_pct_jk"].astype(float))

    # numeric guards
    d["mu_hat_jk"] = d["mu_hat_jk"].astype(float).clip(lower=1e-9)
    d["flow_jk"]   = d["flow_jk"].astype(float).clip(lower=0.0)

    # 2) Estimate phi (Pearson dispersion) on training window (global)
    train_mask = d["month"] <= pd.to_datetime(opts.train_end)
    train = d.loc[train_mask].copy()
    if train.empty:
        raise ValueError("Training window is empty; adjust opts.train_end to include some rows.")

    mu = np.maximum(train["mu_hat_jk"].values, 1e-9)
    chi2 = ((train["flow_jk"].values - mu)**2) / mu
    n = len(train)
    p_pairs  = train[["j","k"]].drop_duplicates().shape[0] - 1
    p_months = train["month"].nunique() - 1
    p_eff = max(p_pairs + p_months, 1)
    dof = max(n - p_eff, 1)
    phi_hat = float(np.sum(chi2) / dof)

    # If not using progress, compute z vectorized (fast)
    if not opts.use_progress:
        denom = np.sqrt(np.maximum(phi_hat * d["mu_hat_jk"].values, 1e-9))
        d["z_std_jk"] = (d["flow_jk"].values - d["mu_hat_jk"].values) / denom

        # weights and EOPs
        w = d[opts.weight_col].astype(float).fillna(0.0)
        d["EOP_pct"] = d["excess_pct_jk"].astype(float) * w
        d["EOP_z"]   = d["z_std_jk"].astype(float)       * w

        out_cols = ["month","i","j","k",
                    "flow_jk","mu_hat_jk","excess_pct_jk","z_std_jk",
                    opts.weight_col,"EOP_pct","EOP_z"]
        d = d[out_cols].sort_values(["i","j","k","month"]).reset_index(drop=True)
        d.attrs["phi_hat"] = phi_hat
        d.attrs["train_end"] = opts.train_end
        return d

    # -----------------------
    # Progress-enabled (groupwise) path
    # -----------------------
    # We'll iterate over unique (i,j,k) triplets and compute groupwise z values,
    # which is useful when outputting many groups to track progress.
    triplets = d[["i","j","k"]].drop_duplicates().reset_index(drop=True)
    triplets['trip'] = triplets.apply(lambda row: (row['i'],row['j'],row['k']), axis=1)
    trip_list = triplets['trip'].tolist()

    # Prepare an output list
    outputs = []
    # iterate with tqdm
    for t in tqdm(trip_list, desc="Computing EOP per triad", unit="triad"):
        i_val, j_val, k_val = t
        sub = d[(d["i"]==i_val) & (d["j"]==j_val) & (d["k"]==k_val)].copy()
        if sub.empty:
            continue
        denom = np.sqrt(np.maximum(phi_hat * sub["mu_hat_jk"].values, 1e-9))
        sub["z_std_jk"] = (sub["flow_jk"].values - sub["mu_hat_jk"].values) / denom
        w = sub[opts.weight_col].astype(float).fillna(0.0)
        sub["EOP_pct"] = sub["excess_pct_jk"].astype(float) * w
        sub["EOP_z"]   = sub["z_std_jk"].astype(float)       * w

        outputs.append(sub[["month","i","j","k","flow_jk","mu_hat_jk",
                            "excess_pct_jk","z_std_jk",opts.weight_col,
                            "EOP_pct","EOP_z"]])

    # concat outputs
    if outputs:
        out = pd.concat(outputs, axis=0).sort_values(["i","j","k","month"]).reset_index(drop=True)
    else:
        # fallback to empty frame with correct columns
        out = pd.DataFrame(columns=["month","i","j","k","flow_jk","mu_hat_jk",
                                    "excess_pct_jk","z_std_jk",opts.weight_col,
                                    "EOP_pct","EOP_z"])

    out.attrs["phi_hat"] = phi_hat
    out.attrs["train_end"] = opts.train_end
    return out
