"""Crop the approved imagegen UI sheets without repainting their artwork."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2] / "assets" / "ui" / "v2"
SOURCE = ROOT / "source"
RUNTIME = ROOT / "runtime"

# Loose regions exclude neighbouring art. The actual crop is the alpha bounds
# inside each region, with a three-pixel transparent guard.
REGIONS = {
    "ui_panels_v1.png": {
        "journal_frame": (20, 45, 1080, 595),
        "tracker_frame": (1070, 150, 1660, 390),
        "dialogue_frame": (20, 635, 850, 870),
        "button_normal": (850, 685, 1010, 800),
        "button_hover": (1005, 685, 1170, 800),
        "button_pressed": (1165, 685, 1325, 800),
        "button_focus": (1320, 685, 1485, 800),
        "button_disabled": (1480, 685, 1665, 800),
    },
    "ui_combat_v1.png": {
        "weapon_frame": (0, 0, 485, 470),
        "slot_frame": (480, 45, 865, 450),
        "reload_track": (865, 40, 1280, 445),
        "reticle": (1300, 35, 1665, 445),
        "health_full": (35, 455, 195, 700),
        "health_empty": (865, 455, 1055, 700),
        "divider": (1045, 490, 1665, 675),
        "gun_revolver": (10, 690, 520, 935),
        "gun_shotgun": (520, 690, 1110, 935),
        "gun_smg": (1110, 690, 1665, 935),
    },
    "ui_map_landmarks_v1.png": {
        "map_gatehouse": (80, 0, 495, 475),
        "map_crane": (510, 0, 875, 475),
        "map_archive": (885, 0, 1315, 475),
        "map_bell": (1300, 0, 1770, 475),
        "map_pump": (65, 470, 550, 880),
        "map_garden": (620, 470, 1190, 880),
        "map_chapel": (1200, 470, 1770, 880),
    },
    "ui_map_marks_v1.png": {
        "map_player": (65, 90, 390, 490),
        "map_checkpoint": (395, 90, 790, 490),
        "map_lock": (795, 90, 1195, 490),
        "map_open": (1200, 90, 1665, 490),
        "map_unknown": (60, 510, 365, 875),
        "map_selection": (370, 510, 790, 880),
        "map_route": (785, 665, 1290, 810),
    },
}


def crop_art(source: Image.Image, bounds: tuple[int, int, int, int]) -> tuple[Image.Image, list[int]]:
    region = source.crop(bounds).convert("RGBA")
    mask = region.getchannel("A").point(lambda value: 255 if value > 12 else 0)
    box = mask.getbbox()
    if box is None:
        raise ValueError(f"No visible art in {bounds}")
    pad = 3
    box = (
        max(0, box[0] - pad),
        max(0, box[1] - pad),
        min(region.width, box[2] + pad),
        min(region.height, box[3] + pad),
    )
    return region.crop(box), [bounds[0] + box[0], bounds[1] + box[1], bounds[0] + box[2], bounds[1] + box[3]]


def main() -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict] = {}
    for filename, regions in REGIONS.items():
        source = Image.open(SOURCE / filename)
        for name, bounds in regions.items():
            image, exact = crop_art(source, bounds)
            image.save(RUNTIME / f"{name}.png", optimize=True)
            manifest[name] = {"source": filename, "crop": exact, "size": list(image.size)}

    # This quiet parchment was generated with the complete architectural map;
    # the concept's speculative corridors are deliberately excluded at runtime.
    map_source = Image.open(SOURCE / "ui_map_concept_v1.png")
    parchment = map_source.crop((35, 35, 185, 185)).convert("RGBA")
    parchment.save(RUNTIME / "map_parchment.png", optimize=True)
    manifest["map_parchment"] = {
        "source": "ui_map_concept_v1.png", "crop": [35, 35, 185, 185], "size": list(parchment.size)
    }
    wedge_source = Image.open(SOURCE / "ui_reload_wedge_v1.png")
    wedge, wedge_crop = crop_art(wedge_source, (520, 180, 1010, 820))
    wedge.save(RUNTIME / "reload_segment.png", optimize=True)
    manifest["reload_segment"] = {
        "source": "ui_reload_wedge_v1.png", "crop": wedge_crop, "size": list(wedge.size)
    }
    (ROOT / "SPLIT_MANIFEST.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
