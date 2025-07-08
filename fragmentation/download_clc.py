import requests
import geopandas as gpd
from shapely.geometry import Point, mapping, Polygon, MultiPolygon, shape
from shapely.ops import transform, unary_union
from pyproj import Transformer
import json
import copy
import os
import pandas as pd
from qgis.core import QgsProject, QgsVectorLayer, QgsApplication
import time
from shapely.strtree import STRtree
from shapely.geometry import GeometryCollection

def multiple_points_shape(points, buffer_radius, output=None):
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
    
    if output is not None:
        gdf = gpd.GeoDataFrame(geometry=[merged_buffer], crs="EPSG:3035")
        gdf.to_file(output, layer="multipolygon_layer", driver="GPKG")
    
    return merged_buffer


def to_esri_geometry(geometry):
    """Convert a Shapely Polygon or MultiPolygon to ESRI JSON geometry format."""
    # Force to MultiPolygon for consistency
    if isinstance(geometry, Polygon):
        geometry = MultiPolygon([geometry])
    
    # Get coordinates from all polygons and flatten to a list of rings
    rings = []
    for poly in geometry.geoms:
        coords = mapping(poly)["coordinates"]
        rings.extend(coords)  # coords is a list: [exterior, hole1, hole2, ...]

    # Build ESRI geometry
    esri_geom = {
        "rings": rings,
        "spatialReference": {"wkid": 3035}
    }

    return esri_geom


def multiple_points_request(merged_buffer, year=2018, clipping=True, add_to_project=False, project_path=""):
    # === Query CORINE Land Cover API ===
    api_url = "https://image.discomap.eea.europa.eu/arcgis/rest/services/Corine/CLC" + str(year) + "_WM/MapServer/0/query"
    esri_geom = to_esri_geometry(merged_buffer)
    params = {
        "where": "1=1",
        "geometry": json.dumps(esri_geom),
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
        clip_polygon = merged_buffer
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
        
        
    # === Save full final response (tmp) ===
    gdf = gpd.GeoDataFrame.from_features(to_add, crs="EPSG:3035")
    output_file = "clc_irregular_area.gpkg"
    gdf.to_file(output_file, driver="GPKG")

    print(f"CLC data successfully saved to {output_file}")

    # === Add to QGIS project ===
    if add_to_project:
        QGIS_PREFIX_PATH = "C:/Program Files/QGIS 3.34.14"
        QgsApplication.setPrefixPath(QGIS_PREFIX_PATH, True)
        qgs = QgsApplication([], False)
        qgs.initQgis()
        project = QgsProject.instance()
        project.read(project_path)
        print("Loaded project:", project.fileName())
        layer = QgsVectorLayer(output_file, "CLC2018_Buffered_Area", "ogr")
        if layer.isValid():
            project.addMapLayer(layer)
            project.write()
            print("Layer added to current QGIS project.")
            qgs.exitQgis()
        else:
            print("Layer is not valid and could not be added.")

    return response, gdf

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
    QGIS_PREFIX_PATH = "C:/Program Files/QGIS 3.34.14"
    QgsApplication.setPrefixPath(QGIS_PREFIX_PATH, True)
    qgs = QgsApplication([], False)
    qgs.initQgis()
    project = QgsProject.instance()
    project.read("C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/code/fragmentation_bird/development/qgis/fragmentation.qgz")
    print("Loaded project:", project.fileName())
    layer = QgsVectorLayer(temp_file, "Buffer Zone", "ogr")
    if layer.isValid():
        project.addMapLayer(layer)
        project.write()
        print("Layer added to current QGIS project.")
        qgs.exitQgis()
        print("Buffer layer added to QGIS.")
    else:
        print("Failed to load layer into QGIS.")

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
    write_clc_file(gdf, data_path + path_clc + "/" + str(year) + f"/batch_clc_{year}_{start}_{len(batch_df)}.gpkg")

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

def write_clc_file(clc_file, write_path):
    clc_file.to_file(write_path, driver="GPKG")


def merge_gpkg_files2(input_folder, output_file, input_layer=None):
    """
    Merges all GPKG files in a folder into one GPKG file.

    Parameters:
        input_folder (str): Path to folder containing GPKG files.
        output_file (str): Path to the output GPKG file.
        input_layer (str or None): Name of the input layer to read. If None, uses the first layer in each file.
    """
    gpkg_files = [os.path.join(input_folder, f) for f in os.listdir(input_folder) if f.endswith(".gpkg")]

    if not gpkg_files:
        raise FileNotFoundError("No .gpkg files found in the specified folder.")

    merged_gdfs = []

    for f in gpkg_files:
        gdf = gpd.read_file(f, layer=input_layer) if input_layer else gpd.read_file(f)
        merged_gdfs.append(gdf)

    merged_gdf = gpd.GeoDataFrame(pd.concat(merged_gdfs, ignore_index=True), crs=merged_gdfs[0].crs)
    
    merged_gdf.to_file(output_file, driver="GPKG")

    print(f"Merged {len(gpkg_files)} files into {output_file}")


def merge_gpkg_files(input_folder, output_file, input_layer=None):
    """
    Sequentially merges GPKG files from a folder, removing overlapping parts from later files.

    Parameters:
        input_folder (str): Folder with .gpkg files
        output_file (str): Output .gpkg path
        input_layer (str or None): Layer name to read; if None, first layer is used
    """
    gpkg_files = sorted([
        os.path.join(input_folder, f)
        for f in os.listdir(input_folder)
        if f.endswith(".gpkg")
    ])

    if not gpkg_files:
        raise FileNotFoundError("No .gpkg files found in the specified folder.")

    # Final result dataframe
    merged_gdf = gpd.GeoDataFrame(columns=["geometry"], geometry="geometry", crs=None)
    total_union = None  # cumulative geometry

    for idx, fpath in enumerate(gpkg_files):
        print(f"Processing file {idx+1}/{len(gpkg_files)}: {os.path.basename(fpath)}")
        gdf = gpd.read_file(fpath, layer=input_layer) if input_layer else gpd.read_file(fpath)

        # Set CRS if not yet set
        if merged_gdf.crs is None:
            merged_gdf.set_crs(gdf.crs, inplace=True)

        if total_union is not None:
            # Subtract already-merged geometries
            gdf["geometry"] = gdf.geometry.map(
                lambda geom: geom.difference(total_union) if geom is not None else None
            )

            # Drop empty geometries
            gdf = gdf[~gdf.geometry.is_empty & gdf.geometry.notna()]

        # Add non-overlapping geometries to result
        merged_gdf = pd.concat([merged_gdf, gdf], ignore_index=True)

        # Update the union of all merged geometries
        if total_union is None:
            total_union = gdf.unary_union
        else:
            total_union = total_union.union(gdf.unary_union)

    # Save final file
    merged_gdf.to_file(output_file, driver="GPKG")
    print(f"✅ Merged {len(gpkg_files)} files into '{output_file}' with {len(merged_gdf)} unique features.")