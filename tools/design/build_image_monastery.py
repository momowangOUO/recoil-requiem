"""Initial scene authoring from approved image-derived construction records.
The resulting .tscn remains editable; running this explicitly regenerates it.
"""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
records=json.loads((ROOT/'dev-design/levels/image-led/construction.json').read_text(encoding='utf8'))
def wp(x,y): return [x*8,1120+(y-430)*8]
def val(v):
    if isinstance(v,bool):return str(v).lower()
    return json.dumps(v,ensure_ascii=False)
def vec(p):return f'Vector2({p[0]}, {p[1]})'
out=['[gd_scene load_steps=6 format=3]',
 '[ext_resource type="Script" path="res://scripts/rooms/image_monastery.gd" id="1"]',
 '[ext_resource type="Script" path="res://scripts/rooms/paper_platform.gd" id="2"]',
 '[ext_resource type="Script" path="res://scripts/rooms/room_marker.gd" id="3"]',
 '[ext_resource type="Script" path="res://scripts/rooms/room_action.gd" id="4"]',
 '[ext_resource type="Script" path="res://scripts/rooms/paper_stair.gd" id="5"]',
 '[node name="ImageMonastery" type="Node2D"]\nscript = ExtResource("1")\nmetadata/world_bounds = Rect2(0, -2080, 16384, 6200)',
 '[node name="Gameplay" type="Node2D" parent="."]']
def node(name,script=None,position=None,parent='Gameplay',node_type='Node2D',**props):
    lines=[f'[node name="{name}" type="{node_type}" parent="{parent}"]']
    if position is not None:lines.append('position = '+vec(position))
    if script:lines.append(f'script = ExtResource("{script}")')
    lines += [k+' = '+str(v) for k,v in props.items()]
    out.append('\n'.join(lines))
def floor(id,x1,x2,y,oneway=False,depth=48):
    node(id,2,[x1,y],width=x2-x1,collision_depth=depth,one_way=val(oneway),**{'metadata/structural_id':val(id.split('_')[0])})
def source_floor(id,x1,x2,y,oneway=False):floor(id,x1*8,x2*8,wp(0,y)[1],oneway)
cuts={'F02':[(548,580)],'F07':[(556,602)],'F05':[(1684,1720)]}
for r in records:
    if r['kind']=='floor':
        a,b=r['source'];x1,x2=a[0],b[0];y=a[1]
        if r['id']=='F01':
            floor('F01',0,240,1120)
            floor('F01_east',896,3104,1120)
            continue
        if r['id']=='F11':x2=2020
        if r['id']=='F04':x1=1261
        if r['id']=='F02':
            for suffix,l,h,open_grid in [('west',x1,548,False),('Hatch',548,580,True),('middle',580,675,False),('east',800,x2,False)]:
                source_floor('F02_'+suffix,l,h,y,open_grid)
            continue
        for i,(l,h) in enumerate(cuts.get(r['id'],[])):
            if l>x1:source_floor(r['id']+f'_west{i}',x1,l,y)
            source_floor(r['id']+f'_Hatch{i}',l,h,y,True)
            x1=h
        source_floor(r['id'],x1,x2,y)
    elif r['kind'] in ('stair','ramp_join'):
        a,b=r['start'],r['end']
        if r['id']=='S08':a=wp(60,430) # Meet street directly, no buried ramp entrance.
        if r['id'] in ('J01','J03'):continue
        if r['id']=='S05':b=[5920,1408]
        if r['id']=='S04':b=[9600,1540]
        node(r['id'],5,a,end_offset=vec([b[0]-a[0],b[1]-a[1]]),stair_depth=48,**{'metadata/structural_id':val(r['id'])})
        if r['id'] in ['S09']+[f'S{i}' for i in range(11,17)]:out[-1]+='\none_way = true'
# Visible supplemental links resolve gaps in the concept's upper/gallery planes.
for id,a,b in [('C01',(416,290),(556,376)),('C02',(784,376),(832,400)),('D01',(675,466),(708,482.5)),('D02',(768,482.5),(800,466)),('D03',(1232,482.5),(1261,468))]:
    aa,bb=wp(*a),wp(*b)
    node(id,5,aa,end_offset=vec([bb[0]-aa[0],bb[1]-aa[1]]),**{'metadata/structural_id':val(id)})
source_floor('F12_Archive',832,884,400)
source_floor('F13_BellLanding',1220,1248,250)
floor('F14_Underpass',5664,6144,1540)
out[-1]+='\nmetadata/interior_backwall = true'
floor('F15_MetalLandingBridge',5920,6400,1408,True)
floor('F16_BellUnderpass',9600,9856,1540)
out[-1]+='\nmetadata/interior_backwall = true'
floor('F17_TowerMetalLanding',9760,10088,1424,True)
# Gatehouse approach separates the solid stair foot from the street below.
node('D04',5,[240,1120],end_offset=vec([240,128]),**{'metadata/structural_id':val('D04')})
node('D05',5,[640,1248],end_offset=vec([256,-128]),**{'metadata/structural_id':val('D05')})
floor('F18_GateUnderpass',480,640,1248)
out[-1]+='\nmetadata/interior_backwall = true'
floor('F19_GateEntryBridge',240,480,1120,True)
# Broad open landings make tower reversal and deliberate drop selection readable.
for level in range(5):
    x=9088 if level%2==0 else 9760
    floor(f'F20_TowerLanding{level+1}',x,x+192,1120-level*288,True)
# Catch floor is a physical underground service road, rendered with solid foundation.
floor('RecoveryRoad',0,16384,3840,False,200)
out[-1]+='\ngrounded = true\nmetadata/recovery_road = true'
# Main gate closes the entire chapel boundary including its underground approach.
for id,y,h in [('gate_departure',-2080,3504),('gate_departure_back',1472,2648)]:
    node(id,2,[13160,y],width=48,collision_depth=h,**{'metadata/gate_id':val(id)})
# Freight controls have a small visible anchored door plate, no wall across the main route.
shortcuts=[('gate_entry',[(340,430,'02'),(500,575,'10')]),('gate_west',[(370,290,'04'),(1010,502,'08')]),('gate_east',[(1232,250,'09'),(1340,468,'14')]),('gate_return',[(2015,630,'16'),(125,430,'01')])]
for id,points in shortcuts:
    x,y,space=points[0]
    node(id,2,wp(x,y),width=16,collision_depth=16,**{'metadata/gate_id':val(id),'metadata/freight_plate':'true'})
    for i,(x,y,space) in enumerate(points):
        node(id+f'_travel{i}',4,wp(x,y),node_type='Marker2D',action_id=val(id+'_travel'),title='""',**{'metadata/space_id':val('mon_'+space),'metadata/shortcut_gate':val(id)})
for id,x,y,space in [('mara',490,466,'03'),('ina',610,466,'05'),('vira',802,466,'07'),('celine',1000,502,'08'),('ruka',900,619,'11')]:
    node('NPC_'+id,3,wp(x,y),node_type='Marker2D',**{'kind':0,'metadata/npc_id':val(id),'metadata/space_id':val('mon_'+space)})
for id,x,y,space in [('tools',758,482.5,'07'),('records',862,400,'13'),('luggage',1374,468,'14'),('departure',1434,468,'14'),('exit',2000,468,'15')]:
    node('Action_'+id,4,wp(x,y),node_type='Marker2D',action_id=val(id),title='""',**{'metadata/space_id':val('mon_'+space)})
# Rects describe distinct rooms; specific upper spaces come before broad lower halls.
spaces=[('01',0,370,192,96,120,430),('02',192,370,218,96,340,430),('04',180,230,240,140,370,290),('06',420,270,380,116,680,376),('13',800,250,84,174,858,400),('09',1138,190,112,278,1232,250),('03',410,386,160,109,510,466),('05',570,386,120,109,630,466),('07',690,386,115,109,750,482.5),('08',805,400,355,126,1030,502),('10',400,495,190,115,500,575),('12',590,495,215,125,720,575),('11',805,526,333,140,920,619),('14',1230,340,240,160,1320,468),('15',1660,100,388,420,1840,468),('16',1470,320,578,360,1570,468)]
for id,x,y,w,h,cx,cy in spaces:
    node('Checkpoint_'+id,3,wp(cx,cy),node_type='Marker2D',**{'kind':0,'metadata/checkpoint_id':val('cp_mon_'+id),'metadata/space_id':val('mon_'+id)})
node('PlayerSpawn',3,wp(120,430),node_type='Marker2D',**{'kind':0})
node('WorldExit',3,wp(2010,468),node_type='Marker2D',**{'kind':1})
# Each authored encounter occupies a specific piece of the level; no safe-room spawns.
encounters=[('03',[(540,466,'shield'),(556,466,'rifle'),(562,466,'rifle')]),('05',[(650,466,'shield'),(668,466,'rifle'),(680,468.5,'charger')]),('06',[(646,376,'grenadier'),(690,376,'rifle'),(726,376,'rifle')]),('07',[(712,482.5,'charger'),(720,482.5,'rifle'),(735,482.5,'shield')]),('08',[(1072,502,'shield'),(1090,502,'rifle'),(1120,502,'support')]),('09',[(1190,240,'flyer'),(1238,250,'rifle'),(1200,330,'flyer')]),('10',[(430,575,'shield'),(450,575,'rifle'),(464,575,'charger')]),('11',[(1000,580,'flyer'),(962,619,'rifle'),(980,619,'support')]),('12',[(650,575,'grenadier'),(674,575,'rifle'),(704,575,'charger')]),('13',[(846,400,'shield'),(874,400,'rifle'),(880,400,'support')]),('14',[(1390,468,'charger'),(1404,468,'rifle'),(1414,468,'rifle')]),('16',[(1590,630,'shield'),(1612,630,'rifle'),(1632,630,'support')]),('04',[(392,290,'charger')]),('06',[(588,376,'shield'),(604,376,'rifle')]),('11',[(1082,579,'rifle'),(1100,579,'support')]),('12',[(730,575,'shield'),(750,575,'charger')])]
for i,(space,actors) in enumerate(encounters,1):
    for j,(x,y,typ) in enumerate(actors):
        node(f'Encounter{i}_{j}',3,wp(x,y),node_type='Marker2D',**{'kind':2 if typ=='shield' else 3,'metadata/encounter_id':i,'metadata/space_id':val('mon_'+space),'metadata/room_id':val('mon_'+space),'metadata/enemy_archetype':val(typ)})
node('Sections',parent='.')
for id,x,y,w,h,cx,cy in spaces:
    p=wp(x,y)
    node('mon_'+id,parent='Sections',**{'metadata/space_id':val('mon_'+id),'metadata/space_bounds':f'Rect2({p[0]}, {p[1]}, {w*8}, {h*8})'})
node('Connections',parent='.')
links=[('01','02',''),('02','03',''),('02','04',''),('04','06',''),('06','13',''),('06','03',''),('03','05',''),('05','07',''),('05','10',''),('10','12',''),('12','11',''),('07','08',''),('08','09',''),('08','14',''),('14','16',''),('16','15','gate_departure'),('02','10','gate_entry'),('04','08','gate_west'),('09','14','gate_east'),('16','01','gate_return')]
for i,(a,b,g) in enumerate(links):
    node('Link'+str(i),parent='Connections',**{'metadata/from':val('mon_'+a),'metadata/to':val('mon_'+b),'metadata/gate_id':val(g)})
node('VisualSections',parent='.')
node('StructureRecords',parent='.')
for r in records:
    if 'source_bounds' in r:node(r['id'],parent='StructureRecords',position=r['position'],**{'metadata/record':val(r)})
node('StoryPositions',parent='.')
for id,p in {'elite':[12400,1424],'boss':[14800,1424],'celine_after':[12320,1424],'celine_return':[3920,1408]}.items():
    node(id,parent='StoryPositions',position=p,node_type='Marker2D')
(ROOT/'scenes/rooms/image_monastery.tscn').write_text('\n\n'.join(out)+'\n',encoding='utf8')
print('Authored image_monastery.tscn from approved image construction; scene remains editable.')
