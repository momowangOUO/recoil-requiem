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

# Room numbers sit beside an actual authored walking surface, never at the
# centre of a tall/overlapping Section rectangle. Coordinates are world space.
LABEL_ANCHORS = {
    "mon_01": [960, 1120], "mon_02": [2200, 1120],
    "mon_03": [4080, 1408], "mon_04": [2960, 0],
    "mon_05": [4880, 1408], "mon_06": [5300, 688],
    "mon_07": [6080, 1408], "mon_08": [8000, 1696],
    "mon_09": [9760, 256], "mon_10": [4000, 2280],
    "mon_11": [7440, 2632], "mon_12": [8840, 2312],
    "mon_13": [10320, 1424], "mon_14": [10800, 1424],
    "mon_15": [12400, 1424], "mon_16": [14800, 1424],
}

# A few genuine transition pieces lie just outside the non-overlapping Section
# rectangles. Reveal the complete authored piece only after both sides are seen.
TRANSITION_VISIBILITY = {
    "S04": ["mon_08", "mon_14"],
    "S08": ["mon_01", "mon_04"],
    "F16_BellUnderpass": ["mon_08", "mon_14"],
    "F20_TowerLanding3": ["mon_09"],
    "F20_TowerLanding5": ["mon_09"],
    "RecoveryAscent": ["mon_01", "mon_10"],
}


def main() -> None:
    records = json.loads(SOURCE.read_text(encoding="utf-8"))
    segments = [
        {"id": item["id"], "kind": item["kind"], "start": item["start"], "end": item["end"], "one_way": item["one_way"]}
        for item in records if item["id"] != "RecoveryRoad" and not item["id"].startswith("Luggage")
    ]
    payload = {"world_bounds": [0, -2080, 16384, 4120], "segments": segments, "landmarks": LANDMARKS, "label_anchors": LABEL_ANCHORS, "transition_visibility": TRANSITION_VISIBILITY}
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


if __name__ == "__main__":
    main()
