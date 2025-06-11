from download_clc import multiple_points_shape, multiple_points_request
from download_clc import write_clc_file, create_layer
from get_points import get_bird_points
import time

# Define the point of interest (longitude, latitude)
lon, lat = 2.9256, 47.4125  # Example coordinates in ESPG:4326 !
buffer_radius = 5000  # in meters
points2 = [
    (2.556 + i, 47.4125 + j)
    for i in [k*0.2 for k in range(10)]
    for j in [k*0.2 for k in range(10)]
]
points = [(2.556, 47.4125)]
bird_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/countingdata_2007_2023.csv"

batch_size = 100
df_points = get_bird_points(bird_path, 2008, all_years=True)
# print(df_points)
list_points = list(zip(df_points['longitude'], df_points['latitude']))[:batch_size]
project_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/code/fragmentation_bird/development/qgis/fragmentation.qgz"
year = 2018
data_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data"
path_clc = "/land_cover/corine_land_cover"

# esri_geom = multiple_points_shape(list_points, buffer_radius)
# response, gdf = multiple_points_request(esri_geom, 
#                                    year=year,
#                                    clipping=True,
#                                    add_to_project=False, 
#                                    project_path=project_path)
# write_clc_file(gdf, data_path + path_clc + "/" + str(year) + "/test.gpkg")

def download_clc_batch(batch_df, start, buffer_radius, year, project_path, data_path, path_clc, verbose=True):
    list_batch_points = list(zip(batch_df['longitude'], batch_df['latitude']))
    if (verbose):print("Constructing shape.")
    merged_buffer = multiple_points_shape(list_batch_points, buffer_radius)
    if (verbose):print("Recovering CLC data.")
    start_timer = time.time()
    response, gdf = multiple_points_request(merged_buffer,
                                       year=year,
                                       clipping=True,
                                       add_to_project=False, 
                                       project_path=project_path)
    end_timer = time.time()
    diff_timer = end_timer - start_timer
    if (verbose):print(f"Done. Execution time = {diff_timer}")
    if (verbose):print("Writing CLC data.")
    write_clc_file(gdf, data_path + path_clc + "/" + str(year) + f"/batch_clc_{year}_{start}.gpkg")

def download_clc_year(df_points, batch_size, buffer_radius, year, project_path, 
                    data_path, path_clc, starting_point=0, verbose=True):
    total_rows = len(df_points)
    for start in range(0, total_rows, batch_size):
        if start >= starting_point:
            if (verbose):print(f"{start}/{total_rows}")
            end = min(start + batch_size, total_rows)
            batch_df = df_points.iloc[start:end]
            download_clc_batch(batch_df, start,
                        buffer_radius, 
                        year, 
                        project_path, 
                        data_path, 
                        path_clc,
                        verbose=True)
        else:
            if (verbose):print(f"{start}/{total_rows}")
            if (verbose):print(f"Already downloaded. Starting point = {starting_point}")

download_clc_year(df_points, batch_size, buffer_radius, year, project_path, 
                    data_path, path_clc, starting_point=100, verbose=True)
