#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#    "openai",
#    "pandas",
#    "tqdm",
#   "duckdb",
# ]
# ///
import json
import re
import sys
import duckdb


import openai
from tqdm import tqdm

results = json.load(open("results.json"))
word_embeddings = json.load(open("word_embeddings.json"))

# convert word_embeddings to duckdb
conn = duckdb.connect("word_embeddings.duckdb")
conn.execute("CREATE TABLE word_embeddings (word STRING, embedding STRING)")
for word, embedding in tqdm(word_embeddings.items(), desc="Inserting into duckdb"):
    conn.execute(
        "INSERT INTO word_embeddings VALUES (?, ?)", (word, json.dumps(embedding))
    )
conn.close()
sys.exit()


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


words = {}
for result in tqdm(results):
    things = ["description", "title"]
    for thing in things:
        if thing in result:
            sentence = result[thing]
            for word in get_words(sentence):
                if word not in word_embeddings:
                    words[word] = True


print(len(words))
if len(words) == 0:
    sys.exit(0)
sys.exit(0)
# Set your OpenAI API key
client = openai.OpenAI()

# do batches of 500
words = list(words.keys())
for i in tqdm(range(0, len(words), 500), desc="Processing batches"):
    batch = words[i : i + 500]
    response = client.embeddings.create(model="text-embedding-ada-002", input=batch)
    embeddings = [item.embedding for item in response.data]
    word_embeddings_new = dict(zip(batch, embeddings))
    word_embeddings.update(word_embeddings_new)
    json.dump(word_embeddings, open("word_embeddings.json", "w"), indent=2)
