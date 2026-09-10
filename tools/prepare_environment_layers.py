"""Deterministic atlas extraction/chroma key; artwork is authored by imagegen."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets/environments/crimson'

def keyed(image):
    image = image.convert('RGBA')
    image.putdata([(r, g, b, 0 if min(r, b) - g > 18 else a)
                   for r, g, b, a in image.getdata()])
    return image

source = Image.open(ROOT / 'night_layers_source_v1.png')
w, h = source.size
source.crop((0, 0, w, h // 2)).save(ROOT / 'sky_v3.png')
keyed(source.crop((0, h // 2, w, h))).save(ROOT / 'castle_v3.png')
keyed(Image.open(ROOT / 'moon_source_v1.png')).save(ROOT / 'moon_v1.png')

atlas_path = ROOT / 'materials_source_v1.png'
if atlas_path.exists():
    atlas = Image.open(atlas_path)
    # Authored grid boundaries measured on the selected 1254px source.
    xs, ys = [0, 418, 838, 1254], [0, 415, 811, 1254]
    for index, name in enumerate(['iron', 'brass', 'wood', 'leather', 'parchment',
                                  'rope', 'leaf', 'petal', 'glass']):
        x, y = index % 3, index // 3
        # Small inset avoids picking up the adjacent authored swatch.
        atlas.crop((xs[x]+4, ys[y]+4, xs[x+1]-4, ys[y+1]-4)).save(ROOT / f'{name}_v1.png')
