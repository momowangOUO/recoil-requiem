"""Export the actual image-led route segments for the illustrated M map."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "dev-design" / "levels" / "image-led" / "as-built.json"
TARGET = ROOT / "data" / "campaign" / "monastery_map_ui.json"

# These icons are illustrative landmarks, never extra traversal geometry.
LANDMARKS = [
    {"art": "map_gatehouse", "position": [2000, 1120], "space_id": "mon_02"},
    {"art": "map_crane", "position": [4080, 1408], "space_id": "mon_03"},
    {"art": "map_archive", "position": [5780, 688], "space_id": "mon_06"},
    {"art": "map_bell", "position": [8380, 1040], "space_id": "mon_08"},
    {"art": "map_pump", "position": [7400, 2632], "space_id": "mon_11"},
    {"art": "map_garden", "position": [10800, 1424], "space_id": "mon_14"},
    {"art": "map_chapel", "position": [14500, 1424], "space_id": "mon_15"},
]


def main() -> None:
    records = json.loads(SOURCE.read_text(encoding="utf-8"))
    segments = [
        {"id": item["id"], "kind": item["kind"], "start": item["start"], "end": item["end"], "one_way": item["one_way"]}
        for item in records if item["id"] != "RecoveryRoad"
    ]
    payload = {"world_bounds": [0, -2080, 16384, 6200], "segments": segments, "landmarks": LANDMARKS}
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


if __name__ == "__main__":
    main()
