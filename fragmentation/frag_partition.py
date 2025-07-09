from shapely.geometry import Point
from shapely.ops import transform
from pyproj import Transformer, CRS
import networkx as nx
import numpy as np
import pandas as pd
import time
from collections import defaultdict, Counter

def balanced_greedy_color(G):
    coloring = {}
    color_groups = defaultdict(set)

    for node in sorted(G.nodes(), key=lambda x: G.degree[x], reverse=True):
        # Find colors used by neighbors
        neighbor_colors = {coloring[n] for n in G.neighbors(node) if n in coloring}

        # Try to assign to the least-populated valid color
        valid_colors = [c for c in color_groups if c not in neighbor_colors]
        if valid_colors:
            # Choose the color with the fewest nodes
            best_color = min(valid_colors, key=lambda c: len(color_groups[c]))
        else:
            # No valid color then create a new one
            best_color = len(color_groups)

        # Assign color
        coloring[node] = best_color
        color_groups[best_color].add(node)

    return coloring

def is_valid_coloring(G, coloring):
    for u, v in G.edges():
        if u != v and coloring.get(u) == coloring.get(v):
            print(f"Invalid coloring: nodes {u} and {v} are adjacent and both colored {coloring[u]}")
            return False
    return True

def buffers_intersect(lon1, lat1, lon2, lat2, buffer_radius_m, transformer):
    # Convert lon/lat to projected coordinates
    p1_proj = transform(transformer.transform, Point(lon1, lat1))
    p2_proj = transform(transformer.transform, Point(lon2, lat2))

    # Check if buffers intersect
    return p1_proj.distance(p2_proj) < 2*buffer_radius_m + 40

def assign_groups_from_adj_matrix(adj_matrix):
    """
    Given a 0-1 matrix indicating touching (intersection) between points,
    assign the minimum number of groups (colors) so that no touching points
    are in the same group.

    Returns:
        A list of group assignments (one per point).
    """
    n = len(adj_matrix)
    G = G = nx.from_numpy_array(adj_matrix)

    # Use greedy coloring (can use strategy='largest_first' or others)
    coloring = balanced_greedy_color(G)

    print(f"Coloring is correct: {is_valid_coloring(G, coloring)}")
    
    # Convert to list for return, indexed by node
    groups = [coloring[i] for i in range(n)]
    print(f"Number of groups: {max(groups) + 1}")
    print(dict(Counter(groups)))
    return groups

def partition(sites_to_keep, buffer_radius_m, verbose=True):
    """
    Partition the sites to keep in the least numbers of groups X so that no 3km buffer touches another one.
    This is necessary to run fragscape on them.
    Groups should be as even as possible. (There will be 4 of ~61 sites ?)
    Then fragscape will be applied X*3 times for each year in [2008(CLC2006), 2012, 2016]
    """
    sites_only = sites_to_keep[["site", "longitude", "latitude"]].drop_duplicates().reset_index()

    # Define coordinate systems
    wgs84 = CRS("EPSG:4326")       # Input coords in lon/lat
    laea = CRS("EPSG:3035")        # Output in ETRS89 / LAEA Europe (meters)
    # Set up transformer from WGS84 to LAEA Europe
    transformer = Transformer.from_crs(wgs84, laea, always_xy=True)

    if verbose:print("Constructing the adjacency matrix.")
    adj_matrix = np.zeros((len(sites_only), len(sites_only)))
    for index1, row1 in sites_only.iterrows():
        if verbose and index1 % (len(sites_only) // 10) == 0:print(f"{index1} / {len(sites_only)}")
        for index2, row2 in sites_only.iterrows():
            lon1 = row1["longitude"]
            lat1 = row1["latitude"]
            lon2 = row2["longitude"]
            lat2 = row2["latitude"]
            if buffers_intersect(lon1, lat1, lon2, lat2, buffer_radius_m, transformer):
                adj_matrix[index1, index2] = 1
                adj_matrix[index2, index1] = 1
                #print(row1, row2)

    if verbose:print("Constructing the partition.")
    groups = assign_groups_from_adj_matrix(adj_matrix)

    sites_only["group"] = groups

    return(sites_only)



