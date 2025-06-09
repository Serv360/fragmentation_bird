from download_clc import multiple_points_shape, multiple_points_request, multiple_points_request_without_pagination
from get_points import get_bird_points

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


df_points = get_bird_points(bird_path, 2009)
print(df_points)
list_points = list(zip(df_points['longitude'], df_points['latitude']))

esri_geom = multiple_points_shape(list_points, buffer_radius)
response = multiple_points_request(esri_geom, clipping=True)