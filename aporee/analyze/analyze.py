#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#    "tqdm",
#    "plotly",
#    "pandas"
# ]
# ///

import json
import plotly.express as px
import pandas as pd

# Load data
with open("results.json") as f:
    data = json.load(f)

# Extract latitude and longitude points
latlon = []
descriptions = []
for dat in data:
    if "latitude" not in dat or "longitude" not in dat or "description" not in dat:
        continue
    descriptions.append(dat["description"])
    lon = dat["longitude"]  # Fixed key lookup
    lat = dat["latitude"]
    latlon.append({"latitude": lat, "longitude": lon})

# write descriptios to file
with open("descriptions.txt", "w") as f:
    f.write("\n".join(descriptions))
print(len(latlon))
# Create DataFrame
df = pd.DataFrame(latlon)

# Plot using Plotly
fig = px.scatter_geo(
    df,
    lat="latitude",
    lon="longitude",
    projection="natural earth",
    title="Geographical Locations",
)

fig.show()
