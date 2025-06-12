import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
import os

#=====# Functions #=====#

def compute_cover_perc_point(clc_gdf, point, data_clc_path, clc_to_category_file, year, buffer_size):
    """
    Input: current_file, point, year
    Output: cover_percentages for a point and a year
    """
    buffer_geom = point.geometry.buffer(buffer_size)  # 5 km buffer

    # Intersect with land cover polygons
    intersected = clc_gdf[clc_gdf.geometry.intersects(buffer_geom)].copy()
    intersected['geometry'] = intersected.geometry.intersection(buffer_geom)
    intersected['area'] = intersected.geometry.area

    # Group by broad category and calculate area
    area_by_category = intersected.groupby('broad_category')['area'].sum()

    # Compute percentages
    total_area = area_by_category.sum()
    percentages = (area_by_category / total_area * 100)

    result_row = {
        'point_id': point['point_id'],
        'lon': point.geometry.x,
        'lat': point.geometry.y,
    }
    for cat in range(1, 5):
        result_row[f'perc{cat}'] = percentages.get(cat, 0.0)

    return result_row



def compute_cover_perc_all(points_df, data_clc_path, clc_to_category_file, year, buffer_size, output_file=None):
    """
    Input: a list of points, should be the unique sites, for which clc data was downloaded in batches of 100
        CLC data is downloaded by scripts in the fragmentation folder.
    Output: a csv with the following format: (site, year, perc1, perc2, perc3, perc4, surf_tot)
        With year in [2006, 2012, 2018] and for all sites (not only the ones available for those years)
        Surf_tot is used to control the quality of the download and merging of clc data.
    """
    clc_gdf = gpd.read_file(data_clc_path + "/merged/" + f"full_file_{year}.gpkg")

    # Load CLC code to broad category mapping
    clc_map_df = pd.read_csv(clc_to_category_file)
    clc_map = dict(zip(clc_map_df['Code_18'], clc_map_df['broad_category']))

    # Map CLC codes to broad categories
    clc_gdf['broad_category'] = clc_gdf['Code_18'].map(clc_map)

    # Drop unknown categories
    clc_gdf = clc_gdf.dropna(subset=['broad_category'])

    # Compute area of each polygon (in meters^2)
    clc_gdf = clc_gdf.to_crs("EPSG:3857")  # Use projected CRS for accurate area calculation
    clc_gdf['area'] = clc_gdf.geometry.area

    # Also project points to the same CRS
    points_gdf = points_gdf.to_crs("EPSG:3857")

    results = []


    for i in range(len(points_df)):
        point = (points_df.iloc[i]["longitude"], points_df.iloc[i]["latitude"])
        compute_cover_perc_point(clc_gdf,point, data_clc_path, clc_to_category_file, year, buffer_size)
    
    results_df = pd.DataFrame(results)

    if output_file:
        results_df.to_csv(output_file, index=False)

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


#points_df = get_bird_points(bird_path, 2008, all_years=True)

# df = compute_cover_perc_all(
#     points_df,
#     data_clc_path=data_path + path_clc,
#     clc_to_category_file="clc_to_broad_categories.csv",
#     year=2018,
#     output_file=habitat_path + "cover_percentages.csv"
# )

#clc_gdf = gpd.read_file(data_path + path_clc + "/merged/" + f"full_file_{year}.gpkg")
#print(clc_gdf)

clc_map_df = pd.read_csv(clc_to_category_file)
print(clc_map_df)