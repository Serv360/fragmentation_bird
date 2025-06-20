import geopandas as gpd
from shapely.geometry import Point, mapping, Polygon, MultiPolygon, shape
from shapely.ops import transform, unary_union
from pyproj import Transformer

def multiple_points_features(points, buffer_radius, sites, features_output):
    # Define coordinate transformations
    transformer_to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True)
    # transformer_to_4326 = Transformer.from_crs("EPSG:3035", "EPSG:4326", always_xy=True)
    buffers = []
    for lon, lat in points:
        point = Point(lon, lat)
        point_3035 = transform(transformer_to_3035.transform, point)
        buffer_3035 = point_3035.buffer(buffer_radius)
        buffers.append(buffer_3035)
        #print(buffer_3035)
        
    gdf = gpd.GeoDataFrame(geometry=buffers, crs="EPSG:3035")
    gdf["site"] = sites.to_list()
    print(gdf)
    gdf.to_file(features_output, layer="buffer_features", driver="GPKG")
    
    return gdf