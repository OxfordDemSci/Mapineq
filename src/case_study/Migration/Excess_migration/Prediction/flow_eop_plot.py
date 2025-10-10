import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.dates import DateFormatter

def plot_flow_and_eop(
    df,
    i,
    j,
    k,
    eop_metric="EOP_pct",
    smooth=False,
    smooth_window=3,
    grid=False,
    colors=None,
    markers=None,
    figsize=(12, 5),
    xrotation=30,
    flow_ylim=None,
    eop_ylim=None,
    policies=None,           # NEW: list of tuples (date_str_or_dt, label, color)
    policy_line_kwargs=None,    # NEW: dict override for axvline kwargs (linestyle, linewidth, alpha, zorder)
    policy_text_kwargs=None,    # NEW: dict override for text kwargs (fontsize, rotation, va, ha, backgroundcolor)
):
    """
    Pretty + flexible plotting of flow (observed/predicted) vs EOP metric.
    Added optional vertical policy lines (policies).
    policies : list of tuples
        Each tuple: (date (str or pd.Timestamp), label (str), color (str))
        Example: [("2021-04-01", "Ley 21325\nApril 2021", "red")]
    """

    if eop_metric not in {"EOP_pct", "EOP_z"}:
        raise ValueError("eop_metric must be one of {'EOP_pct', 'EOP_z'}")

    sub = df[(df["i"] == i) & (df["j"] == j) & (df["k"] == k)].copy()
    if sub.empty:
        print(f"No data found for {i} → {j} → {k}")
        return

    sub["month"] = pd.to_datetime(sub["month"])
    sub = sub.sort_values("month").reset_index(drop=True)

    # --- Defaults ---
    default_colors = {
        "obs": "#1f77b4",   # blue
        "pred": "#ff7f0e",  # orange
        "eop": "#2ca02c" if eop_metric == "EOP_pct" else "#d62728",
    }
    default_markers = {
        "obs": "o",
        "pred": "s",
        "eop": "D",
    }

    colors = {**default_colors, **(colors or {})}
    markers = {**default_markers, **(markers or {})}

    sns.set_theme(style="whitegrid" if grid else "white")
    fig, ax1 = plt.subplots(figsize=figsize)

    lw = 2.2

    # --- Left axis: observed + predicted flow ---
    sns.lineplot(
        x="month",
        y="flow_jk",
        data=sub,
        ax=ax1,
        label="Flow (observed)",
        marker=markers.get("obs"),
        linewidth=lw,
        color=colors["obs"],
        legend=False,
    )
    sns.lineplot(
        x="month",
        y="mu_hat_jk",
        data=sub,
        ax=ax1,
        label=r"Flow ($\hat{\mu}$ predicted)",
        marker=markers.get("pred"),
        linewidth=lw,
        linestyle="--",
        color=colors["pred"],
        legend=False,
    )

    if smooth:
        sub["_smooth"] = sub["flow_jk"].rolling(smooth_window, center=True, min_periods=1).mean()
        sns.lineplot(
            x="month",
            y="_smooth",
            data=sub,
            ax=ax1,
            label=f"Flow (smoothed, w={smooth_window})",
            linewidth=1.6,
            linestyle=":",
            color=colors["obs"],
            legend=False,
        )

    ax1.set_xlabel("Month", fontsize=11)
    ax1.set_ylabel("Flow (observed / predicted)", fontsize=11)
    ax1.grid(alpha=0.3 if grid else 0)
    ax1.xaxis.set_major_formatter(DateFormatter("%Y-%m"))

    if flow_ylim:
        ax1.set_ylim(flow_ylim)

    # --- Right axis: EOP metric ---
    ax2 = ax1.twinx()
    sns.lineplot(
        x="month",
        y=eop_metric,
        data=sub,
        ax=ax2,
        label=eop_metric.replace("_", " "),
        marker=markers.get("eop"),
        linewidth=2,
        color=colors["eop"],
        legend=False,
    )
    ax2.set_ylabel(eop_metric.replace("_", " "), fontsize=11)
    if eop_ylim:
        ax2.set_ylim(eop_ylim)

    if policies:
        # --- compute stacking offsets (same as before) ---
        policy_dates = [pd.to_datetime(pl[0]) for pl in policies]
        from collections import defaultdict
        date_buckets = defaultdict(list)
        for idx, dt in enumerate(policy_dates):
            key = dt.normalize()
            date_buckets[key].append(idx)
        stack_y = {}
        for key, idxs in date_buckets.items():
            n = len(idxs)
            base = 0.92
            spacing = 0.04
            if n == 1:
                positions = [base]
            else:
                start = base + (spacing * (n - 1) / 2)
                positions = [start - spacing * r for r in range(n)]
            for ii, pos in zip(idxs, positions):
                stack_y[ii] = pos
    
        # --- visible x-limits (data coords) for clamping label x-position ---
        xmin = sub["month"].min()
        xmax = sub["month"].max()
        # small padding so label doesn't sit exactly on edge (use days)
        pad = pd.Timedelta(days=1)
    
        default_line_kw = {"linestyle": "--", "linewidth": 1.2, "alpha": 0.9, "zorder": 2}
        for idx, pl in enumerate(policies):
            date_raw, label, color = pl
            date_dt = pd.to_datetime(date_raw)
    
            # draw vertical line at the exact policy date
            ax1.axvline(x=date_dt, color=color, **default_line_kw)
    
            # SHIFT LABEL LEFT by 15 days (or adjust as needed)
            shift = pd.Timedelta(days=15)
            label_x = date_dt - shift
    
            # clamp label_x to be within [xmin+pad, xmax-pad]
            if label_x < (xmin + pad):
                label_x = xmin + pad
            if label_x > (xmax - pad):
                label_x = xmax - pad
    
            ypos = stack_y.get(idx, 0.92)
            ax1.text(
                label_x,                     # shifted x in data coords
                ypos,                        # y in axis fraction (0..1)
                label,
                color=color,
                transform=ax1.get_xaxis_transform(),  # x = data coords, y = axes fraction
                rotation=90,
                va="top",
                ha="center",
                fontsize=9,
                clip_on=True,
                bbox=dict(facecolor=(1, 1, 1, 0.75), edgecolor="none", boxstyle="round,pad=0.2"),
            )
    
    # --- Title & legend ---
    fig.suptitle(
        f"Flow and {eop_metric.replace('_', ' ')} for {i} → {j} → {k}",
        fontsize=14,
        fontweight="bold",
        y=0.9,  # move closer
    )
    handles1, labels1 = ax1.get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()

    handles, labels = [], []
    for h, l in zip(handles1 + handles2, labels1 + labels2):
        if l not in labels:
            handles.append(h)
            labels.append(l)

    ax1.legend(handles, labels, loc="upper left", fontsize=10, frameon=True, framealpha=0.9)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.show()


import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.dates import DateFormatter

def plot_flow_ijk_and_eop(
    df,
    i,
    j,
    k,
    eop_metric="EOP_pct",
    smooth=False,
    smooth_window=3,
    grid=False,
    colors=None,
    markers=None,
    figsize=(12, 5),
    xrotation=30,
    flow_ylim=None,
    eop_ylim=None,
    policies=None,
    policy_line_kwargs=None,
    policy_text_kwargs=None,
):
    """
    Plot observed + predicted flow_jk, flow_ij, and EOP metric with optional policy lines.
    The i→j flow (pair flow) is included by default, computed from flow_jk where j==i & k==j.
    """

    # --- Copy input df to avoid accidental mutation and ensure datetime consistency ---
    df = df.copy()
    df["month"] = pd.to_datetime(df["month"], errors="coerce")   # coerce invalid -> NaT

    # --- Filter triple subset ---
    sub = df[(df["i"] == i) & (df["j"] == j) & (df["k"] == k)].copy()
    if sub.empty:
        print(f"No data found for {i} → {j} → {k}")
        return

    sub["month"] = pd.to_datetime(sub["month"], errors="coerce")
    sub = sub.sort_values("month").reset_index(drop=True)

    # --- Compute i→j flow automatically: ensure df.month and temp.month are both datetime ---
    mask_pair = (df["j"] == i) & (df["k"] == j)
    if mask_pair.any():
        temp = df.loc[mask_pair, ["month", "flow_jk"]].copy()
        temp["month"] = pd.to_datetime(temp["month"], errors="coerce")
        # drop NaT months if any (can't aggregate them reliably)
        temp = temp.dropna(subset=["month"])
        if not temp.empty:
            pair = (
                temp.groupby("month", as_index=False)["flow_jk"]
                .sum()
                .rename(columns={"flow_jk": "flow_ij"})
            )
            # ensure pair.month dtype matches sub.month dtype (both datetime now)
            pair["month"] = pd.to_datetime(pair["month"], errors="coerce")
            sub = sub.merge(pair, on="month", how="left")
        else:
            # nothing to merge after dropping NaT months
            pass

    # --- Defaults ---
    default_colors = {
        "obs": "navy",
        "pred": "goldenrod",
        "eop": "green",
        "pair": "purple",
    }
    default_markers = {
        "obs": None,
        "pred": None,
        "eop": "o",
        "pair": "D",
    }

    colors = {**default_colors, **(colors or {})}
    markers = {**default_markers, **(markers or {})}

    sns.set_theme(style="whitegrid" if grid else "white")
    fig, ax1 = plt.subplots(figsize=figsize)
    lw = 2.2

    # --- Left axis: flows ---
    if "flow_ij" in sub.columns:
        sns.lineplot(
            x="month",
            y="flow_ij",
            data=sub,
            ax=ax1,
            label=f"Flow {i}→{j}",
            marker=markers["pair"],
            linewidth=lw,
            linestyle="-.",
            color=colors["pair"],
            legend=False,
        )

    if "flow_jk" in sub.columns:
        sns.lineplot(
            x="month",
            y="flow_jk",
            data=sub,
            ax=ax1,
            label=f"Flow {j}→{k} (observed)",
            marker=markers["obs"],
            linewidth=lw,
            color=colors["obs"],
            legend=False,
        )

    if "mu_hat_jk" in sub.columns:
        sns.lineplot(
            x="month",
            y="mu_hat_jk",
            data=sub,
            ax=ax1,
            label=f"Flow {j}→{k} (predicted)",
            marker=markers["pred"],
            linewidth=lw,
            linestyle="--",
            color=colors["pred"],
            legend=False,
        )

    if smooth and "flow_jk" in sub.columns:
        sub["_smooth"] = sub["flow_jk"].rolling(smooth_window, center=True, min_periods=1).mean()
        sns.lineplot(
            x="month",
            y="_smooth",
            data=sub,
            ax=ax1,
            label=f"{j}→{k} (smoothed, w={smooth_window})",
            linewidth=1.6,
            linestyle=":",
            color=colors["obs"],
            legend=False,
        )

    ax1.set_xlabel("Month", fontsize=11)
    ax1.set_ylabel("Flows", fontsize=11)
    ax1.grid(alpha=0.3 if grid else 0)
    ax1.xaxis.set_major_formatter(DateFormatter("%Y-%m"))
    plt.setp(ax1.get_xticklabels(), rotation=xrotation)
    if flow_ylim:
        ax1.set_ylim(flow_ylim)

    # --- Right axis: EOP metric ---
    ax2 = ax1.twinx()
    if eop_metric in sub.columns:
        sns.lineplot(
            x="month",
            y=eop_metric,
            data=sub,
            ax=ax2,
            label=eop_metric.replace("_", " "),
            marker=markers["eop"],
            linewidth=2,
            color=colors["eop"],
            legend=False,
        )
    ax2.set_ylabel(eop_metric.replace("_", " "), fontsize=11)
    if eop_ylim:
        ax2.set_ylim(eop_ylim)

    # --- Policy lines ---
    if policies:
        policy_line_kw = {"linestyle": "--", "linewidth": 1.2, "alpha": 0.9, "zorder": 2}
        if policy_line_kwargs:
            policy_line_kw.update(policy_line_kwargs)

        policy_dates = [pd.to_datetime(pl[0], errors="coerce") for pl in policies]
        from collections import defaultdict
        date_buckets = defaultdict(list)
        for idx, dt in enumerate(policy_dates):
            if pd.isna(dt):
                continue
            date_buckets[dt.normalize()].append(idx)

        stack_y = {}
        for key, idxs in date_buckets.items():
            n = len(idxs)
            base, spacing = 0.92, 0.04
            if n == 1:
                positions = [base]
            else:
                start = base + (spacing * (n - 1) / 2)
                positions = [start - spacing * r for r in range(n)]
            for ii, pos in zip(idxs, positions):
                stack_y[ii] = pos

        xmin = sub["month"].min()
        xmax = sub["month"].max()
        pad = pd.Timedelta(days=1)

        for idx, pl in enumerate(policies):
            date_raw, label, color = pl
            date_dt = pd.to_datetime(date_raw, errors="coerce")
            if pd.isna(date_dt):
                continue
            ax1.axvline(x=date_dt, color=color, **policy_line_kw)
            shift = pd.Timedelta(days=15)
            label_x = date_dt - shift
            if label_x < (xmin + pad):
                label_x = xmin + pad
            if label_x > (xmax - pad):
                label_x = xmax - pad
            ypos = stack_y.get(idx, 0.92)
            text_kw = dict(
                color=color,
                transform=ax1.get_xaxis_transform(),
                rotation=90,
                va="top",
                ha="center",
                fontsize=9,
                clip_on=True,
                bbox=dict(facecolor=(1, 1, 1, 0.75), edgecolor="none", boxstyle="round,pad=0.2"),
            )
            if policy_text_kwargs:
                text_kw.update(policy_text_kwargs)
            ax1.text(label_x, ypos, label, **text_kw)

    # --- Title & legend ---
    fig.suptitle(
        f"Flows and {eop_metric.replace('_', ' ')} for {i} → {j} → {k}",
        fontsize=14,
        fontweight="bold",
        y=0.95,
    )

    handles1, labels1 = ax1.get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()
    handles, labels = [], []
    for h, l in zip(handles1 + handles2, labels1 + labels2):
        if l not in labels:
            handles.append(h)
            labels.append(l)
    if handles:
        ax1.legend(handles, labels, loc="upper left", fontsize=10, frameon=True, framealpha=0.9)

    plt.tight_layout(rect=[0, 0, 1, 0.93])
    plt.show()
