import os
import geopandas as gpd
import time
import pandas as pd

#=====# Functions #=====#

def create_dep_folder(base_folder):
    # List of all French départements (metropolitan + Corse A/B)
    departements = (
        [str(i) for i in range(1, 96) if i != 20] +  # 1 to 95, skipping 20
        ['2A', '2B']  # Special Corsican codes
    )

    # Optional: format numbers with leading zeros (e.g. '01', '02', ..., '09')
    departements = [d.zfill(2) if d.isdigit() else d for d in departements]

    # Create each folder
    for dept in departements:
        folder_path = os.path.join(base_folder, dept)
        os.makedirs(folder_path, exist_ok=True)

    print("Folders created successfully.")

def clip_roads_rails(base_folder, merged_buffer):
    path_shp = base_folder + "/2018/01/A_RESEAU_ROUTIER/CHEMIN.SHP"
    path_gpkg = base_folder + "/2018/01/A_RESEAU_ROUTIER/CHEMIN.gpkg"
    a = time.time()
    target_crs = "EPSG:3035"
    shapefile_gdf = gpd.read_file(path_shp).to_crs(target_crs)
    
    # Create GeoDataFrame from the merged buffer and assign the same CRS
    buffer_gdf = gpd.GeoDataFrame(geometry=[merged_buffer], crs=target_crs)

    # Intersect
    result = gpd.overlay(shapefile_gdf, buffer_gdf, how="intersection")
    b = time.time()
    print(b - a)
    # Save to GeoPackage
    result.to_file(path_gpkg, layer="chemin", driver="GPKG")
    


def merge_roads_rails(base_folder, year, output_path, file_path, layer_name="france_roads_rails", verbose=True):
    # List of all French départements (metropolitan + Corse A/B)
    departements = (
        [str(i) for i in range(1, 96) if i != 20] +  # 1 to 95, skipping 20
        ['2A', '2B']  # Special Corsican codes
    )

    # Optional: format numbers with leading zeros (e.g. '01', '02', ..., '09')
    departements = [d.zfill(2) if d.isdigit() else d for d in departements]

    all_gdfs = []

    if verbose:print("Loading shp files.")
    for dep in departements:
        print(dep)
        chemin_path = os.path.join(base_folder, str(year), dep, file_path)

        if not os.path.isfile(chemin_path):
            print(f"Shapefile not found for {dep}: {chemin_path}")
            continue

        # Load and reproject
        try:
            gdf = gpd.read_file(chemin_path)
            gdf = gdf.to_crs("EPSG:3035")
            all_gdfs.append(gdf)
        except Exception as e:
            print(f"Failed to load {chemin_path}: {e}")

    if verbose:print("Merging dataframes.")
    # Merge all GeoDataFrames
    if len(all_gdfs) == 0:
        print("No shapefiles were loaded.")
        return

    merged = gpd.GeoDataFrame(pd.concat(all_gdfs, ignore_index=True), crs="EPSG:3035")

    if verbose:print("Writing gpkg file.")
    # Save to GPKG
    merged.to_file(output_path, layer=layer_name, driver="GPKG")
    print(f"✅ Merged shapefiles saved to {output_path}, layer: {layer_name}")


#=====# Global variables #=====#

base_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/roads_rails"
road_elements = ["CHEMIN.SHP", "ROUTE_NOMMEE.SHP", "ROUTE_PRIMAIRE.SHP", "ROUTE_SECONDAIRE.SHP"]
rail_elements = ["TRONCON_VOIE_FERREE.SHP"]
output_merged = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/roads_rails/merged"

# CREATE FOLDERS
#create_dep_folder(base_folder + "/2018")

# MERGE ROAD AND RAIL DATA
file_path = "A_RESEAU_ROUTIER/CHEMIN.SHP"
merge_roads_rails(base_folder, 2008, output_merged + "/chemin_2008_70.gpkg", file_path, layer_name="france_roads_rails")