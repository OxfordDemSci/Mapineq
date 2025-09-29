import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from typing import List, Tuple, Optional, Dict

def plot_one_triad_pretty_pro(
    eop_df: pd.DataFrame,
    i: str, j: str, k: str,
    ma: int = 3,
    policies: Optional[List[Tuple[str, str, Optional[str]]]] = None,
    line_colors: Optional[Dict[str, str]] = None,
    yscale: str = "linear",
    eop_col: str = "EOP",
    pred_col: Optional[str] = None,  # auto-detect if None
):
    """
    Plots two separate figures:
      (1) Actual vs Counterfactual for j→k
      (2) EOP (ma-month moving average) for i→j→k

    Parameters
    ----------
    eop_df : DataFrame with columns:
        ['i','j','k','month','flow_jk','mu_hat_jk','anom_jk','w_ij','EOP']
        If using EOP-Lite instead, set eop_col='eop_lite' and pred_col='ehat_jk'.
    i, j, k : str
        Triad identifiers (e.g., "VE","PE","US").
    ma : int
        Moving average window for the EOP plot.
    policies : list of (date, label, color)
        e.g. [("2022-10-12","US policy","tab:green")]
        color is optional; default Matplotlib color is used if None.
    line_colors : dict (optional)
        {"actual": "...", "counterfactual": "...", "eop": "..."}
    yscale : str
        "linear" (default) or "log" for the flow plot.
    eop_col : str
        Column name for the EOP series. Default "EOP".
    pred_col : str or None
        Predicted/counterfactual column. Auto-detects 'mu_hat_jk', else 'ehat_jk' if None.
    """

    df = eop_df.copy()
    # Ensure datetime
    df["month"] = pd.to_datetime(df["month"], errors="coerce")

    # Filter triad
    sub = df[(df["i"] == i) & (df["j"] == j) & (df["k"] == k)].sort_values("month").copy()
    if sub.empty:
        print(f"No rows for triad {i}-{j}-{k}")
        return

    # Pick prediction column
    if pred_col is None:
        if "mu_hat_jk" in sub.columns:
            pred_col = "mu_hat_jk"
        elif "ehat_jk" in sub.columns:
            pred_col = "ehat_jk"
        else:
            raise ValueError("Missing counterfactual column; set pred_col='mu_hat_jk' or 'ehat_jk'.")

    if eop_col not in sub.columns:
        raise ValueError(f"EOP column '{eop_col}' not found in DataFrame. Available: {list(sub.columns)}")

    # Prepare policy list
    policy_list: List[Tuple[pd.Timestamp, Optional[str], Optional[str]]] = []
    if policies:
        for p in policies:
            date = pd.to_datetime(p[0], errors="coerce")
            name = p[1] if len(p) > 1 else None
            color = p[2] if len(p) > 2 else None
            if pd.isna(date):
                print(f"⚠️ Skipping invalid policy date: {p[0]}")
                continue
            policy_list.append((date, name, color))

    # Optional line colors
    lc_actual = (line_colors or {}).get("actual", None)
    lc_pred   = (line_colors or {}).get("counterfactual", None)
    lc_eop    = (line_colors or {}).get("eop", None)

    # ----------------- Figure 1: Actual vs Counterfactual (j→k) -----------------
    plt.figure(figsize=(10, 4.5))
    plt.plot(sub["month"], sub["flow_jk"], label="Actual j→k", color=lc_actual, linewidth=2)
    plt.plot(sub["month"], sub[pred_col], label="Counterfactual j→k", color=lc_pred, linestyle="--", linewidth=2)
    if yscale in {"linear", "log", "symlog"}:
        plt.yscale(yscale)

    if policy_list:
        ylim_top = plt.ylim()[1]
        for date, name, color in policy_list:
            plt.axvline(x=date, color=color, linestyle=":", linewidth=2)
            if name:
                plt.text(date, ylim_top * 0.95, name, color=color,
                         rotation=90, va="top", ha="right", fontsize=11)

    plt.title(f"Actual vs Counterfactual for {j}→{k}\n(attribution from {i}→{j})",
              fontsize=15, weight="bold")
    plt.xlabel("Month", fontsize=12)
    plt.ylabel("Monthly Flow", fontsize=12)
    plt.legend(frameon=False, fontsize=11)
    plt.tight_layout()
    plt.show()

    # ------------------------ Figure 2: EOP (moving average) --------------------
    y = sub.set_index("month")[eop_col].astype(float).replace([np.inf, -np.inf], np.nan).fillna(0.0)
    y_ma = y.rolling(ma, min_periods=1).mean()

    plt.figure(figsize=(10, 3.8))
    plt.plot(y_ma.index, y_ma.values, color=lc_eop, linewidth=2)
    plt.axhline(0, color="gray", linestyle="--", linewidth=1)

    if policy_list:
        ylim_top = plt.ylim()[1]
        for date, name, color in policy_list:
            plt.axvline(x=date, color=color, linestyle=":", linewidth=2)
            if name:
                plt.text(date, ylim_top * 0.95, name, color=color,
                         rotation=90, va="top", ha="right", fontsize=11)

    plt.title(f"EOP ({ma}-month MA) for {i}→{j}→{k}", fontsize=15, weight="bold")
    plt.xlabel("Month", fontsize=12)
    plt.ylabel("Index", fontsize=12)
    plt.tight_layout()
    plt.show()
