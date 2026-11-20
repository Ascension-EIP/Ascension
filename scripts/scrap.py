#!/usr/bin/env python3
# @date 2026-10-01
# @file scrap.py
# @brief Scrapes YouTube Shorts of climbing content to build a local test dataset for the Ascension AI pose-analysis pipeline.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

DEFAULT_QUERIES = [
    "escalade bloc shorts",
    "bouldering shorts",
    "rock climbing shorts",
    "indoor climbing shorts",
    "lead climbing shorts",
    "sport climbing shorts",
    "climbing gym shorts",
    "escalade salle shorts",
    "climbing fail shorts",
    "climbing send shorts",
    "bouldering competition shorts",
    "grimpe bloc shorts",
]

# Specific, low-false-positive climbing terms only. Deliberately excludes
# generic words (route, wall, beta, send) that match tons of unrelated videos.
INCLUDE_KEYWORDS = [
    "climbing", "climber", "climbers", "rock climb",
    "bouldering", "boulderer",
    "escalade", "grimpeur", "grimpeuse", "grimpe",
    "crimp", "crimping",
    "via ferrata",
]

EXCLUDE_KEYWORDS = [
    "shop", "sponsor", "unboxing", "giveaway", "haul", "compilation fail",
    "minecraft", "roblox", "fortnite", "simulator",
]

DEFAULT_OUTPUT_DIR = Path("scraped_videos")


def build_match_filter(min_duration, max_duration):
    include = "|".join(rf"\b{kw}\b" for kw in INCLUDE_KEYWORDS)
    return (
        f"duration > {min_duration} & duration < {max_duration}"
        f" & title ~= '(?i){include}'"
    )


def check_yt_dlp():
    if shutil.which("yt-dlp") is None:
        print("Error: yt-dlp is not installed.", file=sys.stderr)
        print("Install it with: sudo apt install yt-dlp", file=sys.stderr)
        sys.exit(1)


def is_excluded(title):
    lowered = title.lower()
    return any(re.search(re.escape(keyword), lowered) for keyword in EXCLUDE_KEYWORDS)


def search_candidates(query, limit, match_filter):
    search_target = f"ytsearch{limit}:{query}"
    cmd = [
        "yt-dlp", search_target,
        "--match-filters", match_filter,
        "--no-playlist",
        "--no-update",
        "--skip-download",
        "--print", "%(id)s\t%(title)s\t%(uploader)s\t%(duration)s\t%(webpage_url)s",
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print(f"Warning: query {query!r} timed out after 120s, skipping.", file=sys.stderr)
        return []

    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)

    candidates = []
    for line in result.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) != 5:
            continue
        video_id, title, uploader, duration, url = parts
        if is_excluded(title):
            continue
        candidates.append({
            "id": video_id,
            "title": title,
            "uploader": uploader,
            "duration": duration,
            "url": url,
            "query": query,
        })
    return candidates


def download_candidates(candidates, output_dir, manifest_path):
    output_template = str(output_dir / "%(id)s.%(ext)s")

    for candidate in candidates:
        video_path = output_dir / f"{candidate['id']}.mp4"
        if video_path.exists():
            print(f"Skipping (already downloaded): {candidate['id']} - {candidate['title']}")
            continue

        cmd = [
            "yt-dlp", candidate["url"],
            "--no-update",
            "-f", "bv*[height<=720]+ba/b[height<=720]",
            "--merge-output-format", "mp4",
            "--output", output_template,
        ]
        print(f"Downloading: {candidate['id']} - {candidate['title']}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(result.stderr, file=sys.stderr)
            continue

        with open(manifest_path, "a", encoding="utf-8") as manifest:
            manifest.write(json.dumps(candidate) + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Scrape climbing YouTube Shorts into a local test dataset."
    )
    parser.add_argument("--query", action="append", help="Search query (repeatable). Defaults to a built-in climbing query set.")
    parser.add_argument("--limit", type=int, default=30, help="Max results to consider per query (default: 30)")
    parser.add_argument("--min-duration", type=int, default=5, help="Minimum duration in seconds (default: 5)")
    parser.add_argument("--max-duration", type=int, default=180, help="Maximum duration in seconds (default: 180, YouTube Shorts now go up to 3min)")
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR), help=f"Download directory (default: {DEFAULT_OUTPUT_DIR})")
    parser.add_argument("--dry-run", action="store_true", help="List matching candidates without downloading anything")
    args = parser.parse_args()

    check_yt_dlp()

    queries = args.query or DEFAULT_QUERIES
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = output_dir / "manifest.jsonl"

    match_filter = build_match_filter(args.min_duration, args.max_duration)

    all_candidates = []
    for query in queries:
        print(f"\n=== Query: {query!r} ===")
        candidates = search_candidates(query, args.limit, match_filter)
        for c in candidates:
            print(f"  {c['id']}\t{c['duration']}s\t{c['title']}")
        all_candidates.extend(candidates)

    if args.dry_run:
        print(f"\n{len(all_candidates)} candidate(s) matched (dry-run, nothing downloaded).")
        return

    download_candidates(all_candidates, output_dir, manifest_path)
    print(f"\nDone. Videos and manifest saved to: {output_dir}/")


if __name__ == "__main__":
    main()
