import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
from shapely.ops import transform
from pyproj import Transformer
import os
from math import ceil

#=====# Functions #=====#

def compute_cover_perc_point(clc_gdf, point, data_clc_path, clc_to_category_file, year, buffer_size):
    """
    Input: current_file, point, year
    Output: cover_percentages for a point and a year
    """
    transformer = Transformer.from_crs("EPSG:4326", "EPSG:3857", always_xy=True)

    point = Point(point)
    point = transform(transformer.transform, point)
    buffer_geom = point.buffer(buffer_size)  # 5 km buffer

    # Intersect with land cover polygons
    intersected = clc_gdf[clc_gdf.geometry.intersects(buffer_geom)].copy()
    intersected['geometry'] = intersected.geometry.intersection(buffer_geom)
    intersected['area'] = intersected.geometry.area

    # Group by broad category and calculate area
    area_by_category = intersected.groupby('broad_category')['area'].sum()

    # Compute percentages
    total_area = area_by_category.sum()
    percentages = (area_by_category / total_area * 100)

    result_row = {}
    for cat in range(1, 5):
        result_row[f'perc{cat}'] = percentages.get(cat, 0.0) # handles missing values and assign 0
    result_row['surf_tot'] = total_area

    return result_row



def compute_cover_perc_all(points_df, data_clc_path, clc_to_category_file, year, buffer_size, output_folder=None, verbose=False):
    """
    Input: a list of points, should be the unique sites, for which clc data was downloaded in batches of 100
        CLC data is downloaded by scripts in the fragmentation folder.
    Output: a csv with the following format: (site, year, perc1, perc2, perc3, perc4, surf_tot)
        With year in [2006, 2012, 2018] and for all sites (not only the ones available for those years)
        Surf_tot is used to control the quality of the download and merging of clc data.
    """
    clc_gdf = gpd.read_file(data_clc_path + "/merged/" + f"full_file_{year}.gpkg")

    # Load CLC code to broad category mapping
    clc_map_df = pd.read_csv(clc_to_category_file, sep=";")
    clc_map_df = clc_map_df.apply(pd.to_numeric)
    clc_map = dict(zip(clc_map_df['Code_18'], clc_map_df['broad_category']))

    # Make sure Code_18 is numeric for clc_gdf 
    clc_gdf["Code_18"] = pd.to_numeric(clc_gdf["Code_18"], errors='coerce')

    # Map CLC codes to broad categories
    clc_gdf['broad_category'] = clc_gdf['Code_18'].map(clc_map)

    # Drop unknown categories
    clc_gdf = clc_gdf.dropna(subset=['broad_category'])

    clc_gdf = clc_gdf.to_crs("EPSG:3857")  # Use projected CRS for accurate area calculation

    results = []

    if (verbose):print("Start computing percentages")

    for i in range(len(points_df)):
        if (verbose) and i%(ceil(len(points_df)//10)) == 0:print(f"Computing {i}/{len(points_df)}.")
        point = (points_df.iloc[i]["longitude"], points_df.iloc[i]["latitude"])
        result_row = compute_cover_perc_point(clc_gdf, point, data_clc_path, clc_to_category_file, year, buffer_size)
        result_row["site"] = points_df.iloc[i]["site"]
        results.append(result_row)

    results_df = pd.DataFrame.from_dict(results)

    if output_folder:
        results_df.to_csv(output_folder + f"/habitat_control_{year}_{buffer_size}.csv", index=False)

    return results_df

def get_bird_points(file_path, year, all_years=False):
    df = pd.read_csv(file_path)
    if (not all_years):df = df[df["annee"]==year]
    df = df[['site', 'longitude', 'latitude']].drop_duplicates()
    return df

#=====# Global variables #=====#

bird_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/countingdata_2007_2023.csv"
data_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data"
path_clc = "/land_cover/corine_land_cover"
habitat_path = "/control_variables/habitat"
clc_to_category_file = data_path + "/land_cover/corres_clc_cat.csv"
buffer_size = 5000
year=2018


points_df = get_bird_points(bird_path, 2008, all_years=True)

output = compute_cover_perc_all(points_df, 
                       data_path + path_clc, 
                       clc_to_category_file, 
                       year, 
                       buffer_size, 
                       output_folder=data_path + habitat_path, 
                       verbose=True)

print(output)