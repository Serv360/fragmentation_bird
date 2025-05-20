import requests
import geopandas as gpd
from shapely.geometry import Point
from shapely.ops import transform
from pyproj import Transformer
import json

# Define the point of interest (longitude, latitude)
lon, lat = 2.9256, 47.4125  # Example coordinates
buffer_radius = 5000  # in meters

# Create a point geometry
# shapely does not assume any coordinate reference system
point = Point(lon, lat)

# Define coordinate transformations
# transformer_to_3035 = Transformer.from_crs("EPSG:4326", "EPSG:3035", always_xy=True)
# transformer_to_4326 = Transformer.from_crs("EPSG:3035", "EPSG:4326", always_xy=True)

# Project the point to EPSG:3035
# Now the point is in a reference system
point_3035 = transform(transformer_to_3035.transform, point)

# Create a buffer around the point
buffer_3035 = point_3035.buffer(buffer_radius)

# Project the buffer back to EPSG:4326
# buffer_4326 = transform(transformer_to_4326.transform, buffer_3035)

# Get the bounding box of the buffer
minx, miny, maxx, maxy = buffer_3035.bounds

# Define the REST API endpoint
api_url = "https://image.discomap.eea.europa.eu/arcgis/rest/services/Corine/CLC2018_WM/MapServer/0/query"

# Define the parameters for the GET request
params = {
    "where": "1=1",
    "geometry": f"{minx},{miny},{maxx},{maxy}",
    "geometryType": "esriGeometryEnvelope",
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