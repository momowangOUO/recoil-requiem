"""Pack authored RGBA poses without cutting overlapping horizontal bounds.

This is asset separation only: preserve source colors, no painted anatomy.
"""
from collections import deque
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/ui/v2/source/title_hero_poses_v1.png'
OUTPUT = ROOT / 'assets/ui/v2/runtime/title_hero_poses_v1.png'
image = Image.open(SOURCE).convert('RGBA')
w, h = image.size
alpha = image.getchannel('A').tobytes()
seen = bytearray(w * h)
components = []
for p in range(w * h):
    if seen[p] or alpha[p] < 16:
        continue
    queue = deque([p])
    seen[p] = 1
    pixels = []
    while queue:
        k = queue.popleft()
        pixels.append(k)
        y, x = divmod(k, w)
        neighbors = [k-w, k+w]
        if x: neighbors.append(k-1)
        if x < w-1: neighbors.append(k+1)
        for j in neighbors:
            if 0 <= j < w*h and not seen[j] and alpha[j] >= 16:
                seen[j] = 1
                queue.append(j)
    if len(pixels) > 1000:
        components.append(pixels)
assert len(components) == 5, f'Review source components: {[(len(c), min(p%w for p in c), max(p%w for p in c)) for c in components]}'
components.sort(key=lambda points: min(p % w for p in points))
atlas = Image.new('RGBA', (500 * 5, h))
source_pixels = image.load()
target = atlas.load()
regions = []
for index, (pose, pixels) in enumerate(zip(['ready','cylinder','cuff','notebook','lookback'], components)):
    x0 = min(p % w for p in pixels)
    x1 = max(p % w for p in pixels) + 1
    left = (500 - (x1 - x0)) // 2
    for p in pixels:
        y, x = divmod(p, w)
        rgba = source_pixels[x,y]
        # Generator left isolated saturated key-color specks around the alpha
        # silhouette. Remove that narrow color class; burgundy cloth is retained.
        r, g, b, a = rgba
        fringe = any(alpha[ny*w+nx] == 0 for nx,ny in [(max(0,x-2),y),(min(w-1,x+2),y),(x,max(0,y-2)),(x,min(h-1,y+2))])
        if fringe and ((r > 150 and b > 150 and g < 100) or (r > 220 and g > 170 and b < 80) or (r > 230 and g < 60 and b < 70)):
            continue
        target[index*500 + left + x-x0, y] = rgba
    # The load-bearing boot pair, not the windblown coat, defines registration.
    foot_x = [245, 675, 1080, 1510, 1990][index]
    regions.append({'id': pose, 'rect': [index*500,0,500,h], 'anchor': [left+foot_x-x0,701]})
atlas.save(OUTPUT)
manifest = {'texture':'res://assets/ui/v2/runtime/title_hero_poses_v1.png',
            'reference_height':680, 'display_height':640, 'foot_position':[0.36,0.95],
            'regions':regions}
(ROOT / 'data/campaign/title_hero_poses.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Packed five authored poses:', atlas.size)
