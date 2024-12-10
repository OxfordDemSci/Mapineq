import requests
import pandas as pd
import json

# API base URL
url = "https://api.mapineq.org"


# ---- get sources by NUTS level ----#

# API endpoint
endpoint = "functions/postgisftw.get_source_by_nuts_level/items.json"

# Endpoint parameters
params = {"_level": 2, "limit": 500}

# Construct the full URL
full_url = f"{url}/{endpoint}"

# Make the GET request to the API
response = requests.get(full_url, params=params)

# Check the response status
if response.status_code != 200:
    print(f"Error: {response.status_code}")
else:
    # Parse the API response as JSON
    json_data = response.json()

    # Convert the JSON data to a pandas DataFrame
    df_content = pd.DataFrame(json_data)


# ---- get years and NUTS levels from source ----#

# API endpoint
endpoint = "functions/postgisftw.get_year_nuts_level_from_source/items.json"

# Endpoint parameters
params = {"_resource": "TGS00103", "limit": 500}

# Construct the full URL
full_url = f"{url}/{endpoint}"

# Make the GET request to the API
response = requests.get(full_url, params=params)

# Check the response status
if response.status_code != 200:
    print(f"Error: {response.status_code}")
else:
    # Parse the API response as a pandas DataFrame
    json_data = response.json()
    df_content = pd.DataFrame(json_data)


# ---- get column values from source ----#

# API endpoint
endpoint = "functions/postgisftw.get_column_values_source_json/items.json"

# API parameters
params = {
    "_resource": "TGS00103",
    "source_selections": '{"year":"2018","level":"2","selected":[]}',
    "limit": 40,
}

# Construct the full URL
full_url = f"{url}/{endpoint}"

# Make the GET request to the API
response = requests.get(full_url, params=params)

# Check the response status
if response.status_code != 200:
    print(f"Error: {response.status_code}")
else:
    # Parse the API response as JSON
    json_content = response.json()

    # Flatten the JSON into a DataFrame
    df_content = pd.json_normalize(
        json_content, record_path=["field_values"], meta=["field", "field_label"]
    )


# ---- get X data ----#

# API endpoint
endpoint = "functions/postgisftw.get_x_data/items.json"

# API parameters
params = {
    "_level": 2,
    "_year": 2018,
    "X_JSON": '{"source":"TGS00103", "conditions":[{"field":"unit","value":"PC_POP"}, {"field":"freq","value":"A"}]}',
    "limit": 1500,
}

# Construct the full URL
full_url = f"{url}/{endpoint}"

# Make the GET request to the API
response = requests.get(full_url, params=params)

# Check the response status
if response.status_code != 200:
    print(f"Error: {response.status_code}")
else:
    # Parse the API response as JSON
    json_content = response.json()

    # Convert the JSON response to a pandas DataFrame
    df_content = pd.DataFrame(json_content)


# ---- get X and Y data ----#

# API endpoint
endpoint = "functions/postgisftw.get_xy_data/items.json"

# Endpoint parameters
params = {
    "_level": 2,
    "_year": 2018,
    "X_JSON": json.dumps(
        {
            "source": "TGS00103",
            "conditions": [
                {"field": "unit", "value": "PC_POP"},
                {"field": "freq", "value": "A"},
            ],
        }
    ),
    "Y_JSON": json.dumps(
        {
            "source": "DEMO_R_MLIFEXP",
            "conditions": [
                {"field": "unit", "value": "YR"},
                {"field": "age", "value": "Y_LT1"},
                {"field": "sex", "value": "T"},
                {"field": "freq", "value": "A"},
            ],
        }
    ),
    "limit": 1500,
}

# Construct the full URL
full_url = f"{url}/{endpoint}"

# Make the GET request to the API
response = requests.get(full_url, params=params)

# Check the response status
if response.status_code != 200:
    print(f"Error: {response.status_code}")
else:
    # Parse the API response as JSON
    json_content = response.json()

    # Convert the JSON response to a pandas DataFrame
    df_content = pd.DataFrame(json_content)
