from download_clc import multiple_points_shape, multiple_points_request, multiple_points_request_without_pagination

# Define the point of interest (longitude, latitude)
lon, lat = 2.9256, 47.4125  # Example coordinates in ESPG:4326 !
buffer_radius = 5000  # in meters
points2 = [
    (2.556 + i, 47.4125 + j)
    for i in [k*0.2 for k in range(10)]
    for j in [k*0.2 for k in range(10)]
]
points = [(2.556, 47.4125)]

esri_geom = multiple_points_shape(points, buffer_radius)
response = multiple_points_request(esri_geom, clipping=True)