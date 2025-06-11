import requests
import xml.etree.ElementTree as ET

wfs_url = "https://data.geopf.fr/wfs/ows"

params = {
    "service": "WFS",
    "version": "2.0.0",
    "request": "GetFeature",
    "typename": "LANDCOVER.FORESTINVENTORY.V2:formation_vegetale",
    "srsname": "EPSG:4326",
    "bbox": "2.9256,47.4125,2.9856,47.4625,EPSG:4326",  # Replace with your bbox coords
    "outputFormat": "application/json"
    #"count"
}

response = requests.get(wfs_url, params=params)
response.raise_for_status()

geojson = response.json()

# Save to file
with open("bd_foret_subset.geojson", "w") as f:
    import json
    json.dump(geojson, f)

def describe_wfs_feature_type(
    layer: str,
    wfs_url: str = "https://data.geopf.fr/wfs/ows",
    version: str = "2.0.0"
):
    """
    Fetches and prints the schema (properties and types) of a WFS feature type.
    
    Parameters:
        layer (str): Layer name (typename)
        wfs_url (str): Base WFS URL
        version (str): WFS version (default: 2.0.0)
    """
    params = {
        "service": "WFS",
        "version": version,
        "request": "DescribeFeatureType",
        "typename": layer
    }

    response = requests.get(wfs_url, params=params)
    response.raise_for_status()

    root = ET.fromstring(response.content)

    ns = {'xsd': 'http://www.w3.org/2001/XMLSchema'}

    # Extract all elements in the schema
    elements = root.findall(".//xsd:element", ns)
    print(f"Schema for layer: {layer}")
    for elem in elements:
        name = elem.attrib.get("name")
        type_ = elem.attrib.get("type")
        print(f" - {name}: {type_}")


describe_wfs_feature_type("LANDCOVER.FORESTINVENTORY.V2:formation_vegetale", )