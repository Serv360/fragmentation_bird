import geopandas as gpd
import pandas as pd

def results_to_csv(input_path, output_path, features_path, year, group):
    gpd_df = gpd.read_file(input_path)
    features = gpd.read_file(features_path)
    features.reset_index()
    gpd_df.reset_index()
    gpd_df = gpd_df.drop(columns=["geometry", "path", "layer"]).copy()
    gpd_df["site"] = features["site"]
    gpd_df["year"] = year
    gpd_df.to_csv(output_path, index=False)

def merge_results(input_folder, groups, version, year, file_output, verbose=True):
    dfs = []
    if verbose:print("Loading files...")
    for group in groups:
        df = gpd.read_file(input_folder + "/" + f"results_{version}_group{group}_{year}.csv")
        df["group"] = group
        dfs.append(df)
    if verbose:print(f"{len(dfs)} files loaded. Merging files...")
    combined_df = pd.concat(dfs, ignore_index=True)

    if verbose:print(f"Writing file...")
    combined_df.to_csv(file_output, index=False)


