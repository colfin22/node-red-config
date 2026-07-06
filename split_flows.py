#!/usr/bin/env python3
"""Split data/flows.json into one importable JSON per tab under flows/.

Each file contains the tab node, every node on it, and any config nodes it
references (credentials are never in flows.json, so nothing sensitive can
leak). Paste a file into Node-RED's Import dialog to get that flow.
"""
import json
import os
import re

SRC = "data/flows.json"
OUT = "flows"

flows = json.load(open(SRC))
tabs = [n for n in flows if n.get("type") == "tab"]
by_id = {n["id"]: n for n in flows}
non_tab = [n for n in flows if n.get("type") != "tab"]

os.makedirs(OUT, exist_ok=True)
expected = set()
for tab in tabs:
    nodes = [n for n in non_tab if n.get("z") == tab["id"]]
    # pull in referenced config nodes (server, broker, ui themes...)
    ids = {n["id"] for n in nodes}
    cfg_ids = set()
    for n in nodes:
        for v in n.values():
            if isinstance(v, str) and v in by_id and v not in ids and by_id[v].get("type") != "tab":
                cfg_ids.add(v)
    bundle = [tab] + nodes + [by_id[i] for i in sorted(cfg_ids)]
    slug = re.sub(r"[^a-z0-9]+", "-", tab["label"].lower()).strip("-")
    path = f"{OUT}/{slug}.json"
    json.dump(bundle, open(path, "w"), indent=1)
    expected.add(f"{slug}.json")
    print(f"{path}: {len(nodes)} nodes + {len(cfg_ids)} config nodes")

# remove exports for deleted/renamed tabs
for f in os.listdir(OUT):
    if f.endswith(".json") and f not in expected:
        os.remove(f"{OUT}/{f}")
        print(f"removed stale {OUT}/{f}")
