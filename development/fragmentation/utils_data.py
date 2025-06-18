import os
import geopandas as gpd
import time

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
    





#=====# Global variables #=====#

base_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/roads_rails"
road_elements = ["CHEMIN.SHP", "ROUTE_NOMMEE.SHP", "ROUTE_PRIMAIRE.SHP", "ROUTE_SECONDAIRE.SHP"]
rail_elements = ["TRONCON_VOIE_FERREE.SHP"]

# CREATE FOLDERS
#create_dep_folder(base_folder + "/2018")

# CLIP ROAD AND RAIL DATA
