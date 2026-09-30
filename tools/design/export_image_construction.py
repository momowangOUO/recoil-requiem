"""Export the editable scene's actual geometry; never regenerate the scene here."""
from pathlib import Path
import re,json,html
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'dev-design/levels/image-led'
source=(ROOT/'scenes/rooms/image_monastery.tscn').read_text(encoding='utf8')
records=[]
def vector(block,key):
    m=re.search(r'^'+re.escape(key)+r' = Vector2\(([-\d.]+), ([-\d.]+)\)',block,re.M)
    return [float(v) for v in m.groups()] if m else [0.,0.]
for block in source.split('\n\n'):
    m=re.match(r'\[node name="([^"]+)"[^\n]*parent="Gameplay"\]',block)
    if not m:continue
    stair='script = ExtResource("5")' in block
    floor='script = ExtResource("2")' in block
    if not(stair or floor) or 'metadata/gate_id' in block:continue
    if floor and float(re.search(r'^collision_depth = ([\d.]+)',block,re.M)[1]) > 80 and 'RecoveryRoad' not in block:continue
    at=vector(block,'position')
    delta=vector(block,'end_offset') if stair else [float(re.search(r'^width = ([\d.]+)',block,re.M)[1]),0]
    records.append(dict(id=m[1],kind='stair' if stair else 'floor',start=at,end=[at[i]+delta[i] for i in range(2)],one_way='one_way = true' in block))
(OUT/'as-built.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def pt(p):return [p[0]/8+60,(p[1]-1120)/8+430+100]
b=['<svg xmlns="http://www.w3.org/2000/svg" width="2180" height="1050" viewBox="0 0 2180 1050"><rect width="2180" height="1050" fill="#f1eddf"/><g font-family="Microsoft YaHei,Arial" fill="#292b32"><text x="60" y="45" font-size="28">猩红修道院 · 实际施工剖面</text><text x="60" y="76" font-size="18">红色：实体地面　蓝色：独立石阶　金色虚线：开放金属梯／格栅　标记与场景节点同名</text>']
for r in records:
    a,z=pt(r['start']),pt(r['end']);color='#a47525' if r['one_way'] else ('#176e82' if r['kind']=='stair' else '#a12f31')
    dash=' stroke-dasharray="5 4"' if r['one_way'] else ''
    b.append(f'<path d="M{a[0]},{a[1]} L{z[0]},{z[1]}" stroke="{color}" stroke-width="4"{dash}/><text x="{(a[0]+z[0])/2}" y="{(a[1]+z[1])/2-9}" font-size="10" fill="{color}">{html.escape(r["id"])}</text>')
b.append('<text x="60" y="990" font-size="18">F14/F16为两处下穿通道；F15/F17为上方金属接台。石阶不允许从下方穿过。</text><text x="60" y="1020" font-size="18">此图由image_monastery.tscn导出；编辑地图后重新运行export_image_construction.py更新。</text></g></svg>')
(OUT/'as-built.svg').write_text(''.join(b),encoding='utf8')
print(f'Exported {len(records)} actual floor/stair modules.')
