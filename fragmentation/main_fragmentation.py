from download_clc import multiple_points_shape, multiple_points_request
from download_clc import write_clc_file, create_layer
from download_clc import download_clc_year
from download_clc import merge_gpkg_files

from get_points import get_bird_points, write_df, add_altitude, get_points_to_keep, create_sites_to_keep, get_sites_to_keep
import time
from frag_partition import partition
from utils_fragscape import multiple_points_features
from recover_frag_index import results_to_csv, merge_results

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
# df_points = get_bird_points(bird_path, 2008, all_years=True)
# list_points = list(zip(df_points['longitude'], df_points['latitude']))[:batch_size]
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
# input_folder = data_path + path_clc + "/" + str(year)
# output_file = data_path + path_clc + "/" + "merged" + f"/full_file_{year}.gpkg"
# merge_gpkg_files(input_folder, output_file, input_layer=None)

# COMPUTE ALTITUDE DATA
# output_path_alt = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/countingdata_2007_2023_alt.csv"
# bird_data = get_bird_points(bird_path, 2008, all_years=True)
# bird_data = add_altitude(bird_data)
# write_df(bird_data, output_path_alt)

# COMPUTE SITES TO KEEP ALL THREE
# output_path_sites_to_keep_all_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_to_keep_all_three.csv"
# alt_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/countingdata_2007_2023_alt.csv"
# df = create_sites_to_keep(bird_path, alt_path, version="all_three")
# write_df(df, output_path_sites_to_keep_all_three)

# COMPUTE SITES TO KEEP TWO OUT OF THREE
# output_path_sites_to_keep_two_out_of_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_to_keep_two_out_of_three.csv"
# alt_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/countingdata_2007_2023_alt.csv"
# df = create_sites_to_keep(bird_path, alt_path, version="two_out_of_three")
# write_df(df, output_path_sites_to_keep_two_out_of_three)

# OBSERVE SITES TO KEEP
sites_to_keep_all_three_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_to_keep_all_three.csv"
sites_to_keep_two_out_of_three_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_to_keep_two_out_of_three.csv"
# points_to_keep = get_points_to_keep(sites_to_keep_two_out_of_three_path)
# print(len(points_to_keep))
# merged_buffer = multiple_points_shape(points_to_keep, 3000)
# create_layer(merged_buffer, esri_format=False)

# ASSIGN GROUPS TWO OUT OF THREE
# output_path_sites_with_group_two_out_of_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_with_group_two_out_of_three_5000.csv"
# sites_to_keep = get_sites_to_keep(sites_to_keep_two_out_of_three_path)
# print(len(sites_to_keep))
# sites_with_group = partition(sites_to_keep, 5000)
# write_df(sites_with_group, output_path_sites_with_group_two_out_of_three)

# ASSIGN GROUPS ALL THREE
# output_path_sites_with_group_all_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_with_group_all_three_5000.csv"
# sites_to_keep = get_sites_to_keep(sites_to_keep_all_three_path)
# print(len(sites_to_keep))
# sites_with_group = partition(sites_to_keep, 5000)
# write_df(sites_with_group, output_path_sites_with_group_all_three)

# CREATE LAYER WITH FEATURES ALL THREE
# features_output_all_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/computation/features_all_three_group0.gpkg"
# sites_with_group_all_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_with_group_all_three_5000.csv"
# base_output_all_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/computation/base_all_three_group2.gpkg"
# points, sites = get_points_to_keep(sites_with_group_all_three, group=2)
# # multiple_points_features(points, 3000, sites, features_output_all_three)
# multiple_points_shape(points, 5000, output=base_output_all_three)

# CREATE LAYER WITH FEATURES TWO OUT OF THREE
# features_output_two_out_of_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/computation/features_two_out_of_three_group4.gpkg"
# sites_with_group_two_out_of_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_with_group_two_out_of_three_5000.csv" # 5000 here is because I constructed groups with a 5000 buffer separation
# base_output_two_out_of_three = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/computation/base_two_out_of_three_group4.gpkg"
# points, sites = get_points_to_keep(sites_with_group_two_out_of_three, group=4)
# # multiple_points_features(points, 3000, sites, features_output_two_out_of_three)
# multiple_points_shape(points, 5000, output=base_output_two_out_of_three)

# RECOVER FRAGMENTATION DATA
# frag_working_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/computation"
# year = 2018
# version = "all_three" # two_out_of_three
# group = 2
# file_features = f"features_{version}_group{group}.gpkg" 
# output_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/results"
# file_output = f"results_{version}_group{group}_{year}.csv"
# input_path = f"C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/code/qgis/fragscape_{version}_group{group}_{year}/outputs/reportingResultsCBC.gpkg"
# features_path = frag_working_folder + "/" + file_features
# output_path = output_folder + "/" + file_output
# results_to_csv(input_path, output_path, features_path, year, group=None) # 

# MERGE FRAGMENTATION DATA
# input_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/results"
# groups = [0, 1, 2]
# version = "all_three"
# year = 2018
# output_folder = input_folder
# file_output = f"results_{version}_{year}.csv"
# output_path = output_folder + "/" + file_output

# merge_results(input_folder, groups, version, year, output_path)
