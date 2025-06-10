import geopandas as gpd
import pandas as pd
from shapely.geometry import Point

def compute_cover_percentages(points_file, clc_gpkg, clc_to_category_file, output_file=None):
    # Load points
    points_df = pd.read_csv(points_file) if points_file.endswith('.csv') else gpd.read_file(points_file)
    if not isinstance(points_df, gpd.GeoDataFrame):
        points_gdf = gpd.GeoDataFrame(points_df, geometry=gpd.points_from_xy(points_df.lon, points_df.lat), crs="EPSG:4326")
    else:
        points_gdf = points_df
        points_gdf = points_gdf.to_crs("EPSG:4326")

    # Load land cover buffer polygons
    clc_gdf = gpd.read_file(clc_gpkg)
    
    # Ensure common CRS
    clc_gdf = clc_gdf.to_crs("EPSG:4326")

    # Load CLC code to broad category mapping
    clc_map_df = pd.read_csv(clc_to_category_file)
    clc_map = dict(zip(clc_map_df['CLC_CODE'], clc_map_df['broad_category']))

    # Map CLC codes to broad categories
    clc_gdf['broad_category'] = clc_gdf['CLC_CODE'].map(clc_map)

    # Drop unknown categories
    clc_gdf = clc_gdf.dropna(subset=['broad_category'])

    # Compute area of each polygon (in meters^2)
    clc_gdf = clc_gdf.to_crs("EPSG:3857")  # Use projected CRS for accurate area calculation
    clc_gdf['area'] = clc_gdf.geometry.area

    # Also project points to the same CRS
    points_gdf = points_gdf.to_crs("EPSG:3857")

    results = []

    for _, point in points_gdf.iterrows():
        buffer_geom = point.geometry.buffer(5000)  # 5 km buffer

        # Intersect with land cover polygons
        intersected = clc_gdf[clc_gdf.geometry.intersects(buffer_geom)].copy()
        intersected['geometry'] = intersected.geometry.intersection(buffer_geom)
        intersected['area'] = intersected.geometry.area

        # Group by broad category and calculate area
        area_by_category = intersected.groupby('broad_category')['area'].sum()

        # Compute percentages
        total_area = area_by_category.sum()
        percentages = (area_by_category / total_area * 100).round(2)

        result_row = {
            'point_id': point['point_id'],
            'lon': point.geometry.x,
            'lat': point.geometry.y,
        }
        for cat in range(1, 5):
            result_row[f'perc{cat}'] = percentages.get(cat, 0.0)

        results.append(result_row)

    results_df = pd.DataFrame(results)

    if output_file:
        results_df.to_csv(output_file, index=False)

    return results_df

def load_bird_data(bird_path):
    

df = compute_cover_percentages(
    points_file="points.csv",
    clc_gpkg="clc_buffers.gpkg",
    clc_to_category_file="clc_to_broad_categories.csv",
    output_file="cover_percentages.csv"
)