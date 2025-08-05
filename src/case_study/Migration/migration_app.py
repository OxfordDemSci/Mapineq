import streamlit as st
import pydeck as pdk
import pandas as pd

# --- Replace this with your real data loading logic ---
# Example structure
country_data = {
    "UK": [(19, 7), (19, 10), (20, 7), (22, 10)],
}
import pandas as pd

data_frames = {
    ("UK", 1907): pd.read_csv("/Users/wenlanzhang/Downloads/PhD_UCL/Data/Oxford/Migration/Data4plot/UK1907_inflow.csv"),
    ("UK", 1910): pd.read_csv("/Users/wenlanzhang/Downloads/PhD_UCL/Data/Oxford/Migration/Data4plot/UK1910_inflow.csv"),
    ("UK", 2007): pd.read_csv("/Users/wenlanzhang/Downloads/PhD_UCL/Data/Oxford/Migration/Data4plot/UK2007_inflow.csv"),
    ("UK", 2210): pd.read_csv("/Users/wenlanzhang/Downloads/PhD_UCL/Data/Oxford/Migration/Data4plot/UK2210_inflow.csv"),

    ("DE", 1905): pd.read_csv("/Users/wenlanzhang/Downloads/PhD_UCL/Data/Oxford/Migration/Data4plot/DE1905_inflow.csv"),
    ("DE", 2007): pd.read_csv("/Users/wenlanzhang/Downloads/PhD_UCL/Data/Oxford/Migration/Data4plot/DE2007_inflow.csv"),
    ("DE", 2205): pd.read_csv("/Users/wenlanzhang/Downloads/PhD_UCL/Data/Oxford/Migration/Data4plot/DE2205_inflow.csv"),
}

# --- Layer toggle ---
colors = [[255, 0, 0, 100], [0, 128, 255, 100], [0, 255, 0, 100], [255, 165, 0, 100]]
layers = []

for i, (year, month) in enumerate(country_data["UK"]):
    key = ("UK", int(f"{year:02d}{month:02d}"))
    df = data_frames.get(key)
    label = f"UK {year}-{month:02d}"

    if st.checkbox(f"Show {label}", value=True) and df is not None:
        color = colors[i % len(colors)]
        layers.append(
            pdk.Layer(
                "ArcLayer",
                data=df,
                get_width="num_migrants / 500",
                get_source_position=["source_lon", "source_lat"],
                get_target_position=["target_lon", "target_lat"],
                get_source_color=color,
                get_target_color=color,
                pickable=True,
                auto_highlight=True,
            )
        )

view_state = pdk.ViewState(
    latitude=55.378051,
    longitude=-3.435973,
    zoom=1.5,
    pitch=40,
)

st.pydeck_chart(pdk.Deck(layers=layers, initial_view_state=view_state))
