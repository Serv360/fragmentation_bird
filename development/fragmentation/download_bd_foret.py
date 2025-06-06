import requests

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