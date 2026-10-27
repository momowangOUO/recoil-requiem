"""Export current scene geometry and map UI coordinates, never rewrite the scene."""
import json,re,html
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
text=(ROOT/'scenes/rooms/image_monastery.tscn').read_text(encoding='utf8')
def vector(block,key='position'):
    m=re.search(r'^'+re.escape(key)+r' = Vector2\(([-\d.]+), ([-\d.]+)\)',block,re.M)
    return list(map(float,m.groups())) if m else [0.,0.]
segments=[];anchors={};landmarks=[]
for block in text.split('\n\n'):
    m=re.match(r'\[node name="([^"]+)"[^\n]*parent="Gameplay"\]',block)
    if not m:continue
    name=m[1]
    if name.startswith('Checkpoint_'):anchors['mon_'+name[-2:]]=vector(block)
    if 'metadata/route_surface = true' not in block:continue
    if 'metadata/gate_id' in block or name.startswith('Luggage'):continue
    at=vector(block)
    if 'script = ExtResource("5")' in block:
        d=vector(block,'end_offset');kind='stair'
    elif 'script = ExtResource("2")' in block:
        h=re.search(r'^collision_depth = ([\d.]+)',block,re.M)
        if not h:continue
        d=[float(re.search(r'^width = ([\d.]+)',block,re.M)[1]),0];kind='floor'
    else:continue
    segments.append(dict(id=name,kind=kind,start=at,end=[at[0]+d[0],at[1]+d[1]],one_way='one_way = true' in block))
m=re.search(r'metadata/world_bounds = Rect2\(([^)]+)\)',text)
bounds=list(map(float,m[1].split(',')))
for art,region in [('map_gatehouse','02'),('map_crane','03'),('map_archive','13'),('map_bell','08'),('map_pump','11'),('map_garden','14'),('map_chapel','15')]:
    landmarks.append(dict(art=art,position=anchors['mon_'+region],space_id='mon_'+region))
transitions={}
for s in segments:
    if s['id'].startswith('Maintenance') or s['id']=='F10':transitions[s['id']]=['mon_11','mon_08']
    elif s['id'].startswith('PumpEntry'):transitions[s['id']]=['mon_07','mon_10']
    elif s['id'] in ['HallLower','F11']:transitions[s['id']]=['mon_15','mon_16']
    elif s['id']=='GateBalconyUp':transitions[s['id']]=['mon_01','mon_04']
    elif s['id'] in ['S05','GalleryApproach']:transitions[s['id']]=['mon_06','mon_07']
    elif s['id']=='F08':transitions[s['id']]=['mon_10','mon_12']
payload=dict(world_bounds=[bounds[0],bounds[1],bounds[0]+bounds[2],bounds[1]+bounds[3]],segments=segments,landmarks=landmarks,label_anchors=anchors,transition_visibility=transitions)
(ROOT/'data/campaign/monastery_map_ui.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(ROOT/'dev-design/levels/image-led/as-built.json').write_text(json.dumps(segments,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="2140" height="950" viewBox="-40 -240 2140 950"><rect x="-40" y="-240" width="2140" height="950" fill="#171b28"/><image href="monastery-concept.png" x="0" y="-174" width="2048" height="768" opacity="0.4"/><g font-family="sans-serif" fill="#e8dfce"><text x="0" y="-205" font-size="26">实际场景导出：4096px / 16区域 / 2D碰撞与3D道路共用数据</text>']
for s in segments:
    a,b=s['start'],s['end'];color='#d8b778' if s['one_way'] else '#72c9c2'
    svg.append(f'<path d="M{a[0]/2},{a[1]/2} L{b[0]/2},{b[1]/2}" stroke="{color}" stroke-width="3"/><text x="{a[0]/2}" y="{a[1]/2-5}" font-size="9">{html.escape(s["id"])}</text>')
for id,at in anchors.items():svg.append(f'<circle cx="{at[0]/2}" cy="{at[1]/2}" r="4" fill="#e78b96"/><text x="{at[0]/2+5}" y="{at[1]/2+13}" font-size="10">{id}</text>')
svg.append('<text x="0" y="650" font-size="16">此图从 image_monastery.tscn 导出。完整主支路、门锁、遭遇和剧情站位见 ../rebuild/construction.svg 与 layout.json。</text></g></svg>')
(ROOT/'dev-design/levels/image-led/as-built.svg').write_text(''.join(svg),encoding='utf8')
layers=[]
for name,region,crop in [('station','01',[0,270,192,440]),('gatehouse','02',[192,0,220,710]),
 ('cargo','03',[412,100,190,610]),('workshop','05',[602,220,200,490]),('archive','13',[802,180,96,530]),
 ('bell','08',[898,0,352,712]),('pump','11',[850,520,340,192]),('garden','14',[1250,260,230,450]),('chapel','15',[1480,0,568,712])]:
    x,y,w,h=crop
    layers.append(dict(id=name,space_id='mon_'+region,source_rect=crop,world_rect=[x*2,y*2-348,w*2,h*2]))
art=dict(texture='res://assets/environments/crimson/monastery_architecture_v2.png',columns=1,rows=1,layers=layers)
(ROOT/'data/campaign/monastery_map_art.json').write_text(json.dumps(art,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
assert len(anchors)==16 and len({s['id'] for s in segments})==len(segments)
print(f'Exported {len(segments)} scene-owned routes, 16 checkpoint anchors and {len(layers)} architecture layers.')
