from shapely.geometry import Point
from shapely.ops import transform
from pyproj import Transformer, CRS
import networkx as nx
import numpy as np
import pandas as pd

def buffers_intersect(lon1, lat1, lon2, lat2, buffer_radius_m=3000):
    # Define coordinate systems
    wgs84 = CRS("EPSG:4326")       # Input coords in lon/lat
    laea = CRS("EPSG:3035")        # Output in ETRS89 / LAEA Europe (meters)

    # Set up transformer from WGS84 to LAEA Europe
    transformer = Transformer.from_crs(wgs84, laea, always_xy=True)

    # Convert lon/lat to projected coordinates
    p1_proj = transform(transformer.transform, Point(lon1, lat1))
    p2_proj = transform(transformer.transform, Point(lon2, lat2))

    # Create buffers
    buffer1 = p1_proj.buffer(buffer_radius_m)
    buffer2 = p2_proj.buffer(buffer_radius_m)

    # Check if buffers intersect
    return buffer1.intersects(buffer2)

def assign_groups_from_adj_matrix(adj_matrix):
    """
    Given a 0-1 matrix indicating touching (intersection) between points,
    assign the minimum number of groups (colors) so that no touching points
    are in the same group.

    Returns:
        A list of group assignments (one per point).
    """
    n = len(adj_matrix)
    G = nx.Graph()

    # Add edges for touching pairs
    for i in range(n):
        for j in range(i + 1, n):
            if adj_matrix[i][j]:
                G.add_edge(i, j)

    # Use greedy coloring (can use strategy='largest_first' or others)
    coloring = nx.coloring.greedy_color(G, strategy='largest_first')

    # Convert to list for return, indexed by node
    groups = [coloring[i] for i in range(n)]
    return groups

def partition(sites_to_keep, verbose=True):
    """
    Partition the sites to keep in the least numbers of groups X so that no 3km buffer touches another one.
    This is necessary to run fragscape on them.
    Groups should be as even as possible. (There will be 4 of ~61 sites ?)
    Then fragscape will be applied X*3 times for each year in [2008(CLC2006), 2012, 2016]
    """
    sites_only = sites_to_keep[["site", "lon", "lat"]].drop_duplicates()
    if verbose:print("Constructing the adjacency matrix")
    matrix = 
    for index, row in sites_only.iterrows():
        if verbose and index % (len(sites_only) // 10):print(f"{index} / {len(sites_only)}")
