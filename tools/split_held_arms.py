"""Deterministic crops only; artwork is the saved imagegen source, never redrawn."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1] / 'assets/characters/requiem'
source = Image.open(root / 'held_arms_v3_handed.png')
assert source.size == (1536, 1024), 'Review source anchors before accepting a new atlas.'
for name, top, bottom in [('revolver', 0, 385), ('shotgun', 385, 670), ('smg', 670, 1024)]:
    source.crop((0, top, 850, bottom)).save(root / f'{name}_right_trigger_v3.png')
    # The isolated LEFT-hand source includes a registration grip; exclude its ends.
    support_bottom = 865 if name == 'smg' else bottom
    part = source.crop((850, top, 1536, support_bottom))
    if name == 'smg':
        from PIL import ImageDraw
        ImageDraw.Draw(part).rectangle((331, 100, 376, 115), fill=(255, 0, 255))
    part.save(root / f'{name}_left_support_v3.png')
