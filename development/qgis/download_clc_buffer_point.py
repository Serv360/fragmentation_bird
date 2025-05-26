import requests
import geopandas as gpd
from shapely.geometry import Point, mapping, Polygon, MultiPolygon, shape
from shapely.ops import transform, unary_union
from pyproj import Transformer
import json
import copy

# Define the point of interest (longitude, latitude)
lon, lat = 2.9256, 47.4125  # Example coordinates in ESPG:4326 !
buffer_radius = 5000  # in meters
points = [
    (2.556 + i, 47.4125 + j)
    for i in [k*0.2 for k in range(10)]
    for j in [k*0.2 for k in range(10)]
]

def single_point_shape(lon, lat, buffer_radius):
    # Create a point geometry
    # shapely does not assume any coordinate reference system
    point = Point(lon, lat)
    # Define coordinate transformations
    transformer_to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True)
    # Project the point to EPSG:3035
    # Now the point is in a reference system
    point_3035 = transform(transformer_to_3035.transform, point)
    # Create a buffer around the point
    buffer_3035 = point_3035.buffer(buffer_radius)
    # Get the bounding box of the buffer
    minx, miny, maxx, maxy = buffer_3035.bounds
    return minx, miny, maxx, maxy
    
def single_point_request():
    # Define the REST API endpoint
    api_url = "https://image.discomap.eea.europa.eu/arcgis/rest/services/Corine/CLC2018_WM/MapServer/0/query"
    # Define the parameters for the GET request
    params = {
        "where": "1=1",
        "geometry": f"{minx},{miny},{maxx},{maxy}",
        "geometryType": "esriGeometryEnvelope", #Use of envelope here for a single square shape
        "inSR": "3035",
        "spatialRel": "esriSpatialRelIntersects",
        "outFields": "*",
        "outSR": "3035",
        "f": "geojson"
    }
    # Send the GET request
    response = requests.get(api_url, params=params)
    # Check if the request was successful
    if response.status_code == 200:
        # Load the response into a GeoDataFrame
        data = response.json()
        gdf = gpd.GeoDataFrame.from_features(data["features"])
        
        # Save the data to a GeoPackage file
        output_file = "clc2018_5km_buffer.gpkg"
        gdf.to_file(output_file, driver="GPKG")
        
        print(f"Data successfully saved to {output_file}")
        
        # Optional: Add the layer to the current QGIS project
        try:
            from qgis.core import QgsProject, QgsVectorLayer
            layer = QgsVectorLayer(output_file, "CLC2018_5km_Buffer", "ogr")
            if layer.isValid():
                QgsProject.instance().addMapLayer(layer)
                print("Layer added to QGIS project.")
            else:
                print("Failed to load the layer into QGIS.")
        except ImportError:
            print("QGIS environment not detected. Skipping layer addition.")
    else:
        print(f"Request failed with status code {response.status_code}")


def multiple_points_shape(points, buffer_radius):
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
        
    # Merge all buffer zones into one geometry (MultiPolygon or Polygon)
    merged_buffer = unary_union(buffers)
    #print(merged_buffer)
    # === 4. Convert geometry to ESRI JSON ===
    esri_geom = {
        "rings": mapping(merged_buffer)["coordinates"],
        "spatialReference": {"wkid": 3035}
    }
    
    return esri_geom
    
def convert_to_lists(obj):
    if isinstance(obj, tuple):
        return [convert_to_lists(i) for i in obj]
    elif isinstance(obj, list):
        return [convert_to_lists(i) for i in obj]
    else:
        return obj
        
def convert_to_right_format(obj):
    obj = convert_to_lists(obj)
    if len(obj) > 1:
        return [el[0] for el in obj]
    else:
        return obj

def multiple_points_request_without_pagination(esri_geom, clipping=True, countOnly=False): #To use for count only!
    # === 5. Query CORINE Land Cover API ===
    api_url = "https://image.discomap.eea.europa.eu/arcgis/rest/services/Corine/CLC2018_WM/MapServer/0/query"
    esri_geom_copy = copy.deepcopy(esri_geom)
    esri_geom_copy["rings"] = convert_to_right_format(esri_geom_copy["rings"])
    params = {
        "where": "1=1",
        "geometry": json.dumps(esri_geom_copy),
        "geometryType": "esriGeometryPolygon", #Use of polygon for a more complex shape
        "inSR": "3035",
        "spatialRel": "esriSpatialRelIntersects",
        "outFields": "*",
        "outSR": "3035",
        "f": "geojson", #
        "returnCountOnly": str(countOnly),
        "resultRecordCount": 1000,
        "resultOffset": 0
    }
    
    response = requests.post(api_url, data=params)
    
    if countOnly:
        return response
    print(response.status_code)
    #print(response.json())
    # === 6. Handle response and save ===
    if response.status_code == 200:
        data = response.json()
        
        if clipping:
            rings = esri_geom["rings"]
            clip_polygon = Polygon(rings[0]) if len(rings) == 1 else MultiPolygon(rings)
            clipped_features = []

            for feat in data["features"]:
                geom = shape(feat['geometry'])  # GeoJSON to Shapely shape
                clipped_geom = geom.intersection(clip_polygon)  # clip geometry
                
                # Only keep features with non-empty intersection
                if not clipped_geom.is_empty:
                    # Update geometry with clipped geometry
                    feat['geometry'] = mapping(clipped_geom)
                    clipped_features.append(feat)
                to_add=clipped_features
        else:
            to_add=data["features"]
        
        
        gdf = gpd.GeoDataFrame.from_features(to_add, crs="EPSG:3035")
        
        
            
        
        output_file = "clc2018_irregular_area.gpkg"
        gdf.to_file(output_file, driver="GPKG")

        print(f"CLC data successfully saved to {output_file}")

        # === 7. Optional: Add to QGIS project ===
        try:
            from qgis.core import QgsProject, QgsVectorLayer
            layer = QgsVectorLayer(output_file, "CLC2018_Buffered_Area", "ogr")
            if layer.isValid():
                QgsProject.instance().addMapLayer(layer)
                print("Layer added to current QGIS project.")
            else:
                print("Layer is not valid and could not be added.")
        except ImportError:
            print("QGIS environment not detected. Skipping layer addition.")
    else:
        print(f"Request failed with status code {response.status_code}")
        print(response.text)
    return response

def multiple_points_request(esri_geom, clipping=True):
    # === Query CORINE Land Cover API ===
    api_url = "https://image.discomap.eea.europa.eu/arcgis/rest/services/Corine/CLC2018_WM/MapServer/0/query"
    esri_geom_copy = copy.deepcopy(esri_geom)
    esri_geom_copy["rings"] = convert_to_right_format(esri_geom_copy["rings"])
    params = {
        "where": "1=1",
        "geometry": json.dumps(esri_geom_copy),
        "geometryType": "esriGeometryPolygon", #Use of polygon for a more complex shape
        "inSR": "3035",
        "spatialRel": "esriSpatialRelIntersects",
        "outFields": "*",
        "outSR": "3035",
        "f": "geojson", #
        "returnCountOnly": "False",
        "resultRecordCount": 1000,
        "resultOffset": 0
    }
    
    features = []
    offset = 0
    page_size = 1000

    while True:
        params["resultOffset"] = offset
        response = requests.post(api_url, data=params)
        if response.status_code == 200:
            data = response.json()
        else:
            print(f"Request failed with status code {response.status_code}")
            print(response.text)
            raise ValueError("Status code is wrong")
        
        if "features" not in data or not data["features"]:
            break  # No more data

        features.extend(data["features"])
        offset += page_size

    # === Clip if true ===
    if clipping:
        rings = esri_geom["rings"]
        clip_polygon = Polygon(rings[0]) if len(rings) == 1 else MultiPolygon(rings)
        clipped_features = []

        for feat in features:
            geom = shape(feat['geometry'])  # GeoJSON to Shapely shape
            clipped_geom = geom.intersection(clip_polygon)  # clip geometry
            
            # Only keep features with non-empty intersection
            if not clipped_geom.is_empty:
                # Update geometry with clipped geometry
                feat['geometry'] = mapping(clipped_geom)
                clipped_features.append(feat)
            to_add=clipped_features
    else:
        to_add=features
        
        
    # === Save full final response ===
    gdf = gpd.GeoDataFrame.from_features(to_add, crs="EPSG:3035")
    output_file = "clc2018_irregular_area.gpkg"
    gdf.to_file(output_file, driver="GPKG")

    print(f"CLC data successfully saved to {output_file}")

    # === Add to QGIS project ===
    try:
        from qgis.core import QgsProject, QgsVectorLayer
        layer = QgsVectorLayer(output_file, "CLC2018_Buffered_Area", "ogr")
        if layer.isValid():
            QgsProject.instance().addMapLayer(layer)
            print("Layer added to current QGIS project.")
        else:
            print("Layer is not valid and could not be added.")
    except ImportError:
        print("QGIS environment not detected. Skipping layer addition.")

    return response

def create_layer(given_shape, esri_format=True):
    if esri_format:
        rings = given_shape["rings"]
        # If it's just one polygon:
        geometry = Polygon(rings[0]) if len(rings) == 1 else MultiPolygon(rings)
    else:
        geometry=given_shape
    # 2. Create GeoDataFrame with EPSG:3035
    gdf = gpd.GeoDataFrame(geometry=[geometry], crs="EPSG:3035")
    # 3. Save to file
    temp_file = "temp_buffer_layer.gpkg"  # Adjust this path
    gdf.to_file(temp_file, layer="buffer_zone", driver="GPKG")
    # 4. Load into QGIS (only works if run inside QGIS Python environment)
    layer = QgsVectorLayer(temp_file, "Buffer Zone", "ogr")
    if layer.isValid():
        QgsProject.instance().addMapLayer(layer)
        print("Buffer layer added to QGIS.")
    else:
        print("Failed to load layer into QGIS.")

esri_geom = multiple_points_shape(points, buffer_radius)
response = multiple_points_request(esri_geom, clipping=True)