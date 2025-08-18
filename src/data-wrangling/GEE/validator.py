
import re
import pandas as pd
from typing import Iterable
from datetime import date
from pandas.api.types import is_integer_dtype
from pandas.api.types import is_numeric_dtype
from pandas.api.types import is_float_dtype
from pandas.api.types import is_string_dtype
from pandas.api.types import infer_dtype


MIN_YEAR = 1600
MAX_YEAR = date.today().year + 1000
_NUTS_REGEX = re.compile(r"^[A-Z]{2}[A-Z0-9]{0,3}$")


class MixedDtypeError(TypeError):
    pass


def assert_no_mixed_dtypes(df: pd.DataFrame) -> None:
    for col in df.columns:
        kind = infer_dtype(df[col], skipna=True)
        if "mixed" in kind:
            sample_types = {
                type(x).__name__ for x in df[col].dropna().unique()[:10]
            }
            raise MixedDtypeError(
                f"Column '{col}' has mixed dtypes: "
                f"{', '.join(sorted(sample_types))}. "
                "Clean or cast before continuing."
            )


def is_well_formed_nuts(code: str | None) -> bool:
    if code is None:
        return False
    return bool(_NUTS_REGEX.fullmatch(str(code)))


def filter_malformed(codes: Iterable[str | None]) -> list[str]:
    return [c for c in codes if not is_well_formed_nuts(c)]


def assert_all_well_formed(codes: Iterable[str | None]) -> None:
    bad = filter_malformed(codes)
    if bad:
        sample = ", ".join(map(str, bad[:10]))
        raise ValueError(f"{len(bad)} malformed NUTS codes (e.g. {sample})")


def assert_year_column(
        col: pd.Series,
        min_year: int = MIN_YEAR,
        max_year: int = MAX_YEAR
        ) -> None:
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


def validate(data: pd.DataFrame, outfile_name: str=None) -> pd.DataFrame:
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
    assert_no_mixed_dtypes(data)
    clean_data = data.fillna('').copy()
    if outfile_name is not None:
        clean_data.to_csv(outfile_name, index=False)
        return 0
    return clean_data