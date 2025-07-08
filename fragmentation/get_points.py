import pandas as pd
import requests
import elevation
import rasterio
import time
from math import ceil

def add_altitude(df, lon_col='longitude', lat_col='latitude', verbose=True):
    altitudes = []
    base_url = "https://data.geopf.fr/altimetrie/1.0/calcul/alti/rest/elevation.json"
    parameters_template = "&resource=ign_rge_alti_wld&delimiter=|&indent=false&measures=false&zonly=true"
    headers = {"User-Agent": "Mozilla/5.0"}
    i = 0
    for lon, lat in zip(df[lon_col], df[lat_col]):
        if verbose and i%(ceil(len(df[lon_col])//50)) == 0:print(f"{i}/{len(df[lon_col])}")
        i += 1
        url = f"{base_url}?lon={lon}&lat={lat}{parameters_template}"
        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            data = response.json()
            alt = data.get("elevations", [None])[0]  # Get elevation or None if missing
            altitudes.append(alt)
        except requests.RequestException as e:
            print(f"Request failed for lon={lon}, lat={lat}: {e}")
            altitudes.append(None)
        time.sleep(0.02)  # polite delay to avoid rate limits

    df = df.copy()
    df['alt'] = altitudes
    return df

def write_df(df, output_path):
    df.to_csv(output_path, index=False)

def get_bird_points(file_path, year, all_years=False):
    df = pd.read_csv(file_path)
    df['annee'] = df['annee'].astype(int)
    if (not all_years):df = df[df["annee"]==year]
    df = df[['site', 'longitude', 'latitude']].drop_duplicates()
    return df

def create_sites_to_keep(bird_path, altitude_path, version="all_three"):
    bird_data = pd.read_csv(bird_path)
    bird_data['annee'] = bird_data['annee'].astype(int)
    alt_data = pd.read_csv(altitude_path)
    df = bird_data.merge(right=alt_data[["site", "alt"]], how="left", on="site")
    df = df[df['alt'] < 800]
    df = df[df["passage"]=="OK_1_and_2"] # Ensure that two surveys were conducted
    df = df[df["annee"].isin([2008, 2012, 2018])]

    if version == "all_three":
        required_years = {2008, 2012, 2018}
        # Group by 'site' and collect all years observed per site
        sites_with_required_years = (
            df.groupby('site')['annee']
            .apply(set)
            .loc[lambda x: x.apply(lambda years: required_years.issubset(years))]
            .index
        )
        # Step 2: Filter the dataframe to keep only those sites
        filtered_df = df[df['site'].isin(sites_with_required_years)]

    else:
        if version == "two_out_of_three":
            required_years = {2008, 2012, 2018}
            # Group by 'site' and collect all years observed per site
            sites_with_required_years = (
                df.groupby('site')['annee']
                .apply(set)
                .loc[lambda x: x.apply(lambda years: len(years.intersection(required_years)) >= 2)]
                .index
            )
            # Step 2: Filter the dataframe to keep only those sites
            filtered_df = df[df['site'].isin(sites_with_required_years)]
        else:
            print(f"Version is incorrect: {version} given. Should be in ['all_three', 'two_out_of_three']")

    return filtered_df

def get_points_to_keep(sites_to_keep_path, group=None):
    sites_to_keep = pd.read_csv(sites_to_keep_path)
    if group is not None:sites_to_keep = sites_to_keep[sites_to_keep["group"]==group]
    sites_to_keep = sites_to_keep[["site", "longitude", "latitude"]].drop_duplicates()
    sites = sites_to_keep["site"].copy()
    points_to_keep = list(zip(sites_to_keep['longitude'], sites_to_keep['latitude']))
    return points_to_keep, sites

def get_sites_to_keep(sites_to_keep_path):
    sites_to_keep = pd.read_csv(sites_to_keep_path)
    sites_to_keep = sites_to_keep[["site", "annee", "longitude", "latitude"]].drop_duplicates()
    return sites_to_keep
