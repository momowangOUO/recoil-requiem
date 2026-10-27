"""Compact chapter authoring. Default writes the plan; --write-scene is explicit."""
import json, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'dev-design/levels/rebuild'
OUT.mkdir(parents=True,exist_ok=True)
out=['[gd_scene load_steps=6 format=3]']
for i,s in enumerate(['image_monastery','paper_platform','room_marker','room_action','paper_stair'],1):
    out.append(f'[ext_resource type="Script" path="res://scripts/rooms/{s}.gd" id="{i}"]')
def val(v):
    return v if isinstance(v,str) and v.startswith(('Vector2(','Rect2(')) else json.dumps(v,ensure_ascii=False)
def vec(p):return f'Vector2({p[0]}, {p[1]})'
def node(name,script=None,at=None,parent='Gameplay',**props):
    kind='Marker2D' if script in (3,4) else 'Node2D'
    b=[f'[node name="{name}" type="{kind}" parent="{parent}"]']
    if at is not None:b.append('position = '+vec(at))
    if script:b.append(f'script = ExtResource("{script}")')
    b.extend(f'{k} = {val(v)}' for k,v in props.items());out.append('\n'.join(b))
out.append('[node name="ImageMonastery" type="Node2D"]\nscript = ExtResource("1")\nmetadata/world_bounds = Rect2(0, -416, 4096, 1536)\nmetadata/layout_revision = 2')
node('Gameplay',parent='.')
geometry=[]
def floor(name,a,b,y,open=False,depth=16):
    node(name,2,[a,y],width=b-a,collision_depth=depth,one_way=open,**{'metadata/structural_id':name,'metadata/route_surface':True})
    geometry.append(dict(id=name,kind='floor',start=[a,y],end=[b,y],one_way=open))
def stair(name,a,b,open=False):
    assert abs(b[0]-a[0])<=512 and abs(b[1]-a[1])/abs(b[0]-a[0])<=.7
    node(name,5,a,end_offset=vec([b[0]-a[0],b[1]-a[1]]),stair_depth=12,visual_tread=8,one_way=open,**{'metadata/structural_id':name,'metadata/route_surface':True})
    geometry.append(dict(id=name,kind='stair',start=a,end=b,one_way=open))
# The standing lines below are traced from visible source decks, not laid over
# a separate invented road network. Local headroom adaptations are explicit.
for args in [('F01',0,384,512),('F01_east',384,776,512),('F02_west',920,1088,584),
 ('F02_Hatch',1088,1280,584,True,12),('F14_Underpass',1424,1488,656),
 ('F03',1756,2208,656),('F03_PumpHatch',2208,2320,656,True,12),
 ('F04_Hatch',2456,2640,588,True,12),('F04',2640,2940,588),
 ('F05_west',2940,3464,588),('F05',3464,3880,588),('F05_EastHatch',3880,4000,588,True,12),('F05_East',4000,4096,588)]:floor(*args)
for args in [('S01',[776,512],[920,584]),('S03',[1612,584],[1756,656]),
 ('S04',[2320,656],[2440,588]),('CargoUnderpassDown',[1280,584],[1424,656]),
 ('CargoUnderpassUp',[1488,656],[1612,584])]:stair(*args)
# Original gate balcony and cargo/archival gallery, with visible short access.
for args in [('F07',1112,1568,404,True,12),('F12_Archive',1664,1792,452),('F06',672,832,280),('GateLowerLanding',144,416,360,True,12)]:floor(*args)
for args in [('S05',[1112,404],[1480,584]),('ArchiveEntry',[1568,404],[1664,452]),
 ('S02',[416,360],[672,280]),('GateBalconyUp',[448,512],[144,360],True)]:stair(*args)
floor('GalleryApproach',1480,1612,584,True,8)
# Original lower cargo floor, pump tanks and short eastern maintenance landing.
for args in [('F08',772,1540,802),
 ('F09',1716,1996,890),('F10',2156,2256,810,False,24),('MaintenanceLanding',2464,2496,656,True,12)]:floor(*args)
for args in [('PumpEntryUpper',[1240,584],[804,802],True),
 ('S06',[1540,802],[1716,890]),('S07',[1996,890],[2156,810]),
 ('MaintenanceAscent',[2156,810],[2464,656],True),('MaintenanceExit',[2496,656],[2632,588],True)]:stair(*args)
floor('MaintenanceCatch',2400,2640,832)
stair('MaintenanceCatchReturn',[2256,810],[2400,832])
floor('TowerApproach',2440,2456,588,True,8)
for i in range(6):
    x0,x1=(2440,2320) if i%2==0 else (2320,2440);y=588-i*72
    stair(f'S{11+i}',[x0,y],[x1,y-72],True)
    floor(f'F20_TowerLanding{i+1}',2288 if x1==2320 else 2440,2320 if x1==2320 else 2496,y-72,True,8)
floor('F13_BellLanding',2288,2496,156,True,8)
# The raised altar and lateral stairs occupy the illustrated stage, not a painted dead end.
floor('HallAltar',3440,3676,488,False,100)
stair('HallAltarWest',[3240,588],[3440,488])
stair('HallAltarEast',[3676,488],[3876,588])
stair('HallEastDescent',[3980,588],[3692,750],True)
floor('HallLanding',3692,3788,750,True,12)
stair('HallLower',[3692,750],[3368,912],True)
floor('F11',2940,4096,912)
edge_barriers=[('PumpWestStop',756,754),('MaintenanceStop',2640,784),('HallLowerWestStop',2924,864)]
for name,x,y in edge_barriers:
    node(name,2,[x,y],width=16,collision_depth=48,**{'metadata/edge_barrier':True,'metadata/structural_id':name})
gate_specs=[('gate_lift',1744,478,24,180),('gate_maintenance',2208,698,24,112),
 ('gate_departure',3040,428,32,160),('gate_departure_back',3040,620,32,500)]
for name,x,y,w,h in gate_specs:
    node(name,2,[x,y],width=w,collision_depth=h,**{'metadata/gate_id':name})
for name,x,y,w,h in [('LiftHeadwall',1744,120,24,358),('MaintenanceHeadwall',2208,688,24,10),
 ('DepartureHeadwall',3040,80,32,348)]:node(name,2,[x,y],width=w,collision_depth=h,**{'metadata/structural_id':name})
def marker(name,at,**props):node(name,3,at,kind=0,**props)
def action(name,at,region):node('Action_'+name,4,at,action_id=name,title='',**{'metadata/space_id':'mon_'+region})
npcs={'mara':([1000,584],'03'),'ina':([1168,584],'05'),'vira':([1800,656],'08'),
 'celine':([1936,656],'08'),'ruka':([1824,890],'11')}
for name,(at,region) in npcs.items():marker('NPC_'+name,at,**{'metadata/npc_id':name,'metadata/space_id':'mon_'+region})
actions={'tools':([1456,656],'07'),'records':([1704,452],'13'),'lift_repair':([1672,614],'07'),
 'maintenance_isolate':([2176,800],'11'),'luggage':([2768,552],'14'),'departure':([2944,588],'15'),'exit':([4032,588],'16')}
for name,(at,region) in actions.items():action(name,at,region)
for site,x in [('Home',2608),('Cart',2768)]:
    floor('Luggage'+site+'Cover',x-28,x+28,552,False,36)
    stair('Luggage'+site+'Up',[x-100,588],[x-28,552]);stair('Luggage'+site+'Down',[x+28,552],[x+100,588])
shortcuts=[('gate_entry',([728,512],'02'),([1000,802],'10')),('gate_west',([744,280],'04'),([1840,656],'08')),
 ('gate_east',([2376,156],'09'),([2480,656],'14')),('gate_return',([4000,912],'16'),([160,512],'01'))]
for gate,*ends in shortcuts:
    node(gate,2,ends[0][0],width=12,collision_depth=12,**{'metadata/gate_id':gate,'metadata/freight_plate':True})
    for i,(at,region) in enumerate(ends):node(gate+f'_travel{i}',4,at,action_id=gate+'_travel',title='',**{'metadata/space_id':'mon_'+region,'metadata/shortcut_gate':gate})
spaces=[('04',[128,144,768,272],[744,280]),('06',[1088,320,512,208],[1144,404]),
 ('13',[1600,320,208,208],[1640,440]),('09',[2288,80,208,496],[2320,156]),
 ('01',[0,416,384,160],[160,512]),('02',[384,416,536,224],[728,512]),
 ('03',[920,528,232,184],[1040,584]),('05',[1152,528,256,208],[1208,584]),
 ('07',[1408,528,348,208],[1584,584]),('08',[1756,576,564,176],[1888,656]),
 ('10',[756,720,444,160],[1000,802]),('12',[1200,720,480,160],[1312,802]),
 ('11',[1680,784,584,240],[1784,890]),('14',[2320,520,620,232],[2912,588]),
 ('15',[2940,480,100,576],[2944,588]),('16',[3040,480,1056,576],[3232,588])]
for region,bounds,at in spaces:marker('Checkpoint_'+region,at,**{'metadata/checkpoint_id':'cp_mon_'+region,'metadata/space_id':'mon_'+region})
marker('PlayerSpawn',[160,512]);node('WorldExit',3,[4032,588],kind=1)
encounters=[(1,'02','shield',[656,512],[560,432,216,144],150),(5,'08','shield',[2096,656],[2016,576,264,160],180),
 (5,'08','rifle',[2264,656],[2016,576,264,160],150),(6,'06','rifle',[1280,404],[1112,320,456,112],140),
 (10,'10','shield',[1120,802],[1008,736,400,128],150),(12,'12','charger',[1456,802],[1320,736,216,128],140),
 (9,'09','rifle',[2424,156],[2288,80,208,480],140),(13,'13','rifle',[1712,452],[1600,320,208,208],100),
 (16,'16','rifle',[3888,912],[3488,824,600,192],160)]
for i,(group,region,kind,at,patrol,wake) in enumerate(encounters):
    node(f'Encounter{group}_{i}',3,at,kind=2 if kind=='shield' else 3,**{'metadata/encounter_id':group,
      'metadata/space_id':'mon_'+region,'metadata/room_id':'mon_'+region,'metadata/enemy_archetype':kind,
      'metadata/wake_radius':wake,'metadata/patrol_bounds':f'Rect2({", ".join(map(str,patrol))})'})
node('Sections',parent='.')
for region,bounds,at in spaces:node('mon_'+region,parent='Sections',**{'metadata/space_id':'mon_'+region,'metadata/space_bounds':f'Rect2({", ".join(map(str,bounds))})'})
node('Connections',parent='.')
links=[('01','02',''),('02','04',''),('02','03',''),('03','05',''),('05','07',''),('05','06',''),('06','13',''),
 ('13','07',''),('07','08','gate_lift'),('07','10',''),('10','12',''),('12','11',''),('11','08','gate_maintenance'),
 ('08','09',''),('08','14',''),('14','15',''),('15','16','gate_departure'),('02','10','gate_entry'),
 ('04','08','gate_west'),('09','14','gate_east'),('16','01','gate_return')]
for i,(a,b,g) in enumerate(links):node('Link'+str(i),parent='Connections',**{'metadata/from':'mon_'+a,'metadata/to':'mon_'+b,'metadata/gate_id':g})
node('VisualSections',parent='.')
node('StructureRecords',parent='.')
landmarks=[('StationGate',[0,0,400,712]),('CargoCourt',[400,0,400,712]),('BellCourt',[800,0,430,712]),
 ('Garden',[1230,0,250,712]),('GreatHall',[1480,0,568,712])]
for name,(x,y,w,h) in landmarks:
    r={'id':name,'source_bounds':[x,y,w,h],'position':[x*2,y*2-348],'size':[w*2,h*2],'kind':'painted_architecture','depth':48}
    node(name,parent='StructureRecords',at=r['position'],**{'metadata/record':r})
roof={'id':'ChapelRoof','kind':'roof','position':[0,0],'size':[4096,1120],
 'polygon':[[2940,80],[3120,80],[3120,-38],[3620,-278],[3968,-38],[4096,80],
            [4096,96],[3968,-22],[3620,-262],[3136,-14],[3136,96],[2940,96]]}
node('ChapelRoof',parent='StructureRecords',at=[0,0],**{'metadata/record':roof})
node('StoryPositions',parent='.')
story={'elite':[3016,588],'boss':[3968,588],'celine_after':[2984,588],'celine_return':[1080,584],
 'vira_after':[2880,588],'vira_departure_mid':[1816,656],'vira_departure_end':[1856,656],
 'vira_path_01':[1888,656],'vira_path_02':[2160,656],'vira_path_03':[2320,656],'vira_path_04':[2440,588],
 'vira_path_05':[2668,588],'vira_path_06':[2740,552],'vira_path_07':[2796,552],'vira_path_08':[2868,588],
 'luggage_home':[2608,588],'luggage_cart':[2768,588],
 'tutorial_jump':[256,512],'tutorial_shoot':[480,512],'arrival_stairs':[776,512]}
for name,at in story.items():node(name,parent='StoryPositions',at=at)
sheet={'world_bounds':[0,-416,4096,1536],'reference':'../image-led/monastery-concept.png','reference_transform':{'scale':2,'offset':[0,-348]},'player_height':42,'geometry':geometry,'spaces':spaces,'connections':links,'gates':gate_specs,'edge_barriers':edge_barriers,'encounters':encounters,'shortcuts':shortcuts,'npcs':npcs,'actions':actions,'story':story,'roof':roof}
(OUT/'layout.json').write_text(json.dumps(sheet,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="2200" height="1000" viewBox="-60 -240 2200 1000"><rect x="-60" y="-240" width="2200" height="1000" fill="#171b28"/><g font-family="sans-serif" fill="#e8dfce"><text x="20" y="-190" font-size="32">修道院 / 4096px 紧凑互通施工图</text>']
svg.append('<image href="../image-led/monastery-concept.png" x="0" y="-174" width="2048" height="768" opacity="0.45"/>')
for name,(x,y,w,h) in landmarks:svg.append(f'<rect x="{x}" y="{y-174}" width="{w}" height="{h}" fill="none" stroke="#535468"/><text x="{x+8}" y="{y-150}" font-size="16">{name}</text>')
for g in geometry:
    a,b=g['start'],g['end'];c='#cfa264' if g['one_way'] else '#72c9c2'
    svg.append(f'<path d="M{a[0]/2},{a[1]/2} L{b[0]/2},{b[1]/2}" stroke="{c}" stroke-width="4"/><text x="{a[0]/2}" y="{a[1]/2-5}" font-size="9">{g["id"]}</text>')
for name,(at,region) in npcs.items():svg.append(f'<circle cx="{at[0]/2}" cy="{at[1]/2-12}" r="6" fill="#d96e7a"/><text x="{at[0]/2}" y="{at[1]/2-24}" font-size="14">{name}</text>')
for region,bounds,at in spaces:svg.append(f'<circle cx="{at[0]/2}" cy="{at[1]/2}" r="5" fill="#78bdf2"/><text x="{at[0]/2+6}" y="{at[1]/2+16}" font-size="11">CP{region}</text>')
for name,x,y,w,h in gate_specs:svg.append(f'<rect x="{x/2}" y="{y/2}" width="{max(3,w/2)}" height="{h/2}" fill="#ed6666" opacity="0.8"/><text x="{x/2+6}" y="{y/2}" font-size="11">{name}</text>')
for name,x,y in edge_barriers:svg.append(f'<rect x="{x/2}" y="{y/2}" width="8" height="24" fill="#c6ab70"/><text x="{x/2+10}" y="{y/2}" font-size="10">{name}</text>')
for group,region,kind,at,patrol,wake in encounters:svg.append(f'<path d="M{at[0]/2},{at[1]/2-15} l-5,10 h10 z" fill="#ff9a60"/><text x="{at[0]/2+7}" y="{at[1]/2-6}" font-size="10">E{group}:{kind}</text>')
for name,(at,region) in actions.items():svg.append(f'<rect x="{at[0]/2-3}" y="{at[1]/2-6}" width="6" height="6" fill="#d8bf82"/><text x="{at[0]/2+4}" y="{at[1]/2-9}" font-size="10">{name}</text>')
svg.append('<path d="M30,565 h100 M30,561 v8 M130,561 v8" stroke="#fff"/><text x="30" y="585" font-size="12">200 逻辑像素</text><path d="M160,565 v-21" stroke="#fff" stroke-width="3"/><text x="167" y="550" font-size="12">人物 42px</text>')
svg.append('<text x="20" y="650" font-size="16">青色：实体石路/楼梯　金色：开放格栅　红点：会面　蓝点：检查点　橙三角：敌人　红条：任务门锁</text><text x="20" y="680" font-size="14">主路：门楼→装卸庭→货梯维修 / 泵房隔离→钟庭→花棚→礼堂。支路回到已知道路；下层为建筑内局部回路。</text></g></svg>')
(OUT/'construction.svg').write_text(''.join(svg),encoding='utf8')
if '--write-scene' in sys.argv:
    (ROOT/'scenes/rooms/image_monastery.tscn').write_text('\n\n'.join(out)+'\n',encoding='utf8')
    print(f'Authored 4096px chapter: 16 stable regions, {len(geometry)} local route pieces.')
else:print('Construction sheet updated; scene untouched. Use --write-scene to explicitly regenerate.')
