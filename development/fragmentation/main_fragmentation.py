from download_clc import multiple_points_shape, multiple_points_request
from download_clc import write_clc_file, create_layer
from download_clc import download_clc_year
from download_clc import merge_gpkg_files

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
year = 2012
data_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data"
path_clc = "/land_cover/corine_land_cover"

# SINGLE IMPORT
# This was used to test single import for a list of points
# esri_geom = multiple_points_shape(list_points, buffer_radius)
# response, gdf = multiple_points_request(esri_geom, 
#                                    year=year,
#                                    clipping=True,
#                                    add_to_project=False, 
#                                    project_path=project_path)
# write_clc_file(gdf, data_path + path_clc + "/" + str(year) + "/test.gpkg")

# FULL IMPORT
# This has to be done for years 2006, 2012 and 2018
# batch_size of 100 may be too big and may need to be reduce to 50.
# download_clc_year(df_points, batch_size, buffer_radius, year, project_path, 
#                     data_path, path_clc, starting_point=0, verbose=True)


# MERGING
# This has to be done for years 2006, 2012 and 2018
input_folder = data_path + path_clc + "/" + str(year)
output_file = data_path + path_clc + "/" + "merged" + f"/full_file_{year}.gpkg"

merge_gpkg_files(input_folder, output_file, input_layer=None)
