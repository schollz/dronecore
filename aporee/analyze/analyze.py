#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#    "tqdm",
#    "plotly",
#    "duckdb",
#    "numpy",
#    "scikit-learn",
#    "pandas",
#    "tqdm"
# ]
# ///

import json
import re
import sys
import multiprocessing as mp
import plotly.express as px
import pandas as pd
import duckdb
import numpy as np
from tqdm import tqdm
from sklearn.metrics.pairwise import cosine_similarity

conn = duckdb.connect("word_embeddings.duckdb")


def get_vector_embedding(word):
    result = conn.execute(
        "SELECT embedding FROM word_embeddings WHERE word = ?", [word]
    ).fetchone()
    if result is None:
        return None
    return json.loads(result[0])


def word_distance(word1, word2):
    vec1 = get_vector_embedding(word1)
    vec2 = get_vector_embedding(word2)
    if vec1 is None or vec2 is None:
        return None
    return cosine_similarity([vec1], [vec2])[0][0]


def get_words(sentence):
    sentence = sentence.lower()
    # remove html tags
    sentence = re.sub(r"<[^>]*>", "", sentence)
    # remove urls
    sentence = re.sub(r"http\S+", "", sentence)
    # remove punctuation
    sentence = re.sub(r"[^\w\s]", "", sentence)
    # remove numbers
    sentence = re.sub(r"\d+", "", sentence)
    # remove newlines
    sentence = sentence.replace("\n", " ")
    return sentence.split()


def plot_latlon(latlon):
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


# Define your groupings
groupings = ["water", "forest", "birds", "city", "talking"]


# Function to process each data entry
def process_entry(dat):
    if (
        "latitude" not in dat
        or "longitude" not in dat
        or "description" not in dat
        or "identifier" not in dat
    ):
        return None  # Skip invalid entries

    w = {word: True for word in get_words(dat["description"])}
    w.update({word: True for word in get_words(dat["title"])})

    local_groupings_count = {group: 0 for group in groupings}

    for group in groupings:
        closest_similarity = -1
        closest_word = None
        for word in w:
            similarity = word_distance(word, group)
            if similarity is not None and similarity > closest_similarity:
                closest_similarity = similarity
                closest_word = word
        if closest_word is not None and closest_similarity > 0.84:
            local_groupings_count[group] += 1

    # create a string from the local_grouping_items that are >0
    local_grouping_items = [
        group for group in groupings if local_groupings_count[group] > 0
    ]
    # sort them
    local_grouping_items.sort()
    dat["groupings"] = local_grouping_items
    return dat


# Main function using multiprocessing
def main(data):
    latlon = []
    descriptions = []
    groupings_count = {group: 0 for group in groupings}

    with mp.Pool(mp.cpu_count()) as pool:
        results = list(
            tqdm(
                pool.imap(process_entry, data), desc="Processing data", total=len(data)
            )
        )
    # remove nulls
    results = [result for result in results if result is not None]

    # Aggregate results
    with open("results_aggregated.json", "w") as f:
        json.dump(results, f, indent=2)


# Example usage
if __name__ == "__main__":
    with open("results.json") as f:
        data = json.load(f)
    main(data)
