
import pandas as pd
from pandas.api.types import is_integer_dtype
from pandas.api.types import is_numeric_dtype
from pandas.api.types import is_float_dtype
from pandas.api.types import is_string_dtype
from datetime import date


MIN_YEAR = 1600
MAX_YEAR = date.today().year + 1000


import re
from typing import Iterable

# ---------------------------------------------------------------------
# Compile once at import time
#   ^[A-Z]{2}        → exactly two upper-case letters  (ISO-3166 country)
#   [A-Z0-9]{0,3}$   → zero to three alphanumerics    (NUTS levels 1-3)
#   total length     → 2..5 characters
# ---------------------------------------------------------------------
_NUTS_REGEX = re.compile(r"^[A-Z]{2}[A-Z0-9]{0,3}$")

def is_well_formed_nuts(code: str | None) -> bool:
    """
    Return True if *code* is a syntactically valid NUTS identifier.

    This is *shape-only* validation:
      - Accepts levels 0, 1, 2, 3 (length 2-5).
      - Ignores whether the code is actually in the current Eurostat list.
    """
    if code is None:
        return False
    return bool(_NUTS_REGEX.fullmatch(str(code)))


def filter_malformed(codes: Iterable[str | None]) -> list[str]:
    """Return a list of the entries that are *not* well-formed."""
    return [c for c in codes if not is_well_formed_nuts(c)]


def assert_all_well_formed(codes: Iterable[str | None]) -> None:
    """Raise ValueError if any element is malformed (shows up to 10)."""
    bad = filter_malformed(codes)
    if bad:
        sample = ", ".join(map(str, bad[:10]))
        raise ValueError(f"{len(bad)} malformed NUTS codes (e.g. {sample})")


def assert_year_column(
        col: pd.Series,
        min_year: int = MIN_YEAR,
        max_year: int = MAX_YEAR
        ) -> None:
    """
    Raise ValueError if *col* is not numeric, or
    contains any value outside [min_year, max_year].

    Works with classic int64, nullable Int64, and floats that
    are all whole numbers (e.g. 1990.0).  If the column is
    object dtype, attempt a safe numeric cast first.
    """
    s = col.copy()
    
    if is_integer_dtype(s.dtype):
        series_int = s
    elif is_float_dtype(s.dtype):
        if not (s.dropna() % 1 == 0).all():
            raise ValueError(f"Column '{col.name}' contains non-integer floats")
        series_int = s.astype("Int64")
    else:
        raise ValueError(
            f"Column '{col.name}' must be of integer or float type, "
            f"not {s.dtype}"
        )
    outside = series_int.dropna().loc[
        (series_int < min_year) | (series_int > max_year)
    ]

    if not outside.empty:
        bad = outside.unique()[:5]
        raise ValueError(
            f"Column '{col.name}' has year(s) outside "
            f"[{min_year}, {max_year}]: {bad.tolist()}"
        )


def validate(data: pd.DataFrame) -> pd.DataFrame:
    """
    Validates the input DataFrame to ensure it contains the required columns.
    Args:
        data (pd.DataFrame): The DataFrame to validate.
    Returns:
        pd.DataFrame: A cleaned DataFrame with NaN values replaced by empty strings.
    Raises:
        ValueError: If the DataFrame does not contain the required columns.
    """
    if not isinstance(data, pd.DataFrame):
        raise TypeError("Input must be a pandas DataFrame")
    required_columns = [
        'id', 
        'geo', 
        'obsValue', 
        'obsTime',
        'geo_source'
        ]
    if not all(col in data.columns for col in required_columns):
        raise ValueError(f"Data must contain the following columns: {', '.join(required_columns)}")
    if not is_integer_dtype(data['id']):
        raise ValueError("Column 'id' must be of integer type")
    if not is_numeric_dtype(data['obsValue']):
        raise ValueError("Column 'obsValue' must be of numeric type")
    assert_year_column(data['obsTime'])
    assert_all_well_formed(data["geo"])
    if not is_string_dtype(data['geo_source']):
        raise ValueError("Column 'geo_source' must be of string type")
    clean_data = data.fillna('').copy()
    return clean_data