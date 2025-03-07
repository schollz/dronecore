import internetarchive
import os
import subprocess

# Define collection name and output folder
collection = "radio-aporee-maps"
output_folder = "radio_aporee_single_audio"

# Create output directory if it doesn't exist
os.makedirs(output_folder, exist_ok=True)

# Search for all items in the collection
search_results = internetarchive.search_items(f"collection:{collection}")

for item in search_results:
    identifier = item["identifier"]
    files = internetarchive.get_item(identifier).files

    if files:
        # Find the first audio file (MP3 or WAV)
        first_audio = next(
            (f["name"] for f in files if f["name"].endswith((".mp3", ".wav",".flac"))), None
        )

        if first_audio:
            print(f"Downloading {first_audio} from {identifier}...")

            # Run the downloader command
            cmd = [
                "python3",
                "ia_downloader.py",
                "download",
                "-i",
                identifier,
                "-o",
                output_folder,
                "-f",
                first_audio,
            ]
            subprocess.run(cmd)

print("Download complete!")
