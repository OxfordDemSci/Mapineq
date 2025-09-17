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
