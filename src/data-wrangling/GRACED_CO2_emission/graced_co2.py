import pandas as pd
import re, calendar

# 1. Load --------------------------------------------------
df = pd.read_csv("./GRACED_final.csv")

# 2. Parse obsTime ----------------------------------------
pat = re.compile(r'^(?:(\d{2})_(\d{4})|(\d{4}))$')

def split_obs_time(val):
    m = pat.match(str(val))
    if not m:
        return pd.Series([pd.NA, pd.NA])
    
    month, year_m, year_y = m.groups()
    if month is not None:
        year  = int(year_m)
        m_int = int(month)
        m_txt = calendar.month_name[m_int]
        return pd.Series([year, m_txt])
    else:
        return pd.Series([int(year_y), "all"])

df[["year", "month"]] = df["obsTime"].apply(split_obs_time)

df["obsTime"] = df["year"]


col_to_move   = "month"
new_position  = df.columns.get_loc("obsTime") + 5  # index *after* "year"

# Remove the column, remember its contents …
month_series = df.pop(col_to_move)

# … then insert it at the desired location.
df.insert(new_position, col_to_move, month_series)

df = df.drop(columns=['year'])

df.tail()

df.to_csv('./GRACED_final_v2.csv', index=False)