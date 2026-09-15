"""Authoring drawings only; never rewrites the playable scene.
Coordinates and fixtures are proposals, IDs follow the existing campaign.
Run with bundled Python; outputs SVG, HTML and a precise object manifest.
"""
import json
from pathlib import Path
from html import escape

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'dev-design/levels'
# id, label, x, width, standing y, experience, encounter, landmark
SPACES = [
 ('01','运输站',0,1600,1120,'安全观察；看见外庭塔楼','无','候车棚'),
 ('02','装卸入口',1600,1600,1120,'正面路与地下货道分流','盾卫×1；独立示范','封闭货运门'),
 ('03','外庭',3200,2000,1120,'先交谈，再选择高廊或装卸场','盾卫×1＋女枪手×2','石塔基座'),
 ('04','西侧廊',1600,1900,400,'绕行观察；近路返回外庭','突进×1；独立示范','拱窗长廊'),
 ('05','装卸场',2400,2000,1840,'掩体交错；伊娜在西侧安全龛','盾卫×1＋女枪手×2','吊车轨梁'),
 ('06','上层走廊',3500,2300,400,'先看见投弹预警，再穿过高低火线','投弹×1；后段女枪手×2','断桥与下层接应路'),
 ('07','货梯间',4400,2000,1840,'维拉与工具现场；借货梯重返中层','突进×1＋女枪手×2','双轨货梯框'),
 ('08','中央庭院',5200,2800,1120,'两翼重汇；赛琳交谈与协战','盾卫×1＋女枪手×1＋支援×1','独立钟架'),
 ('09','钟台',5800,2200,400,'先观察下方落点，再绕到火力后侧','空追×1；后段女枪手×2','钟台支架'),
 ('10','地下货道',0,2400,1840,'低路有连续地基；回收失足玩家','盾卫×1＋突进×1＋女枪手×1','砖拱与货轨'),
 ('11','泵房',6400,2400,1840,'支路交付；设备分割射线','投弹×1＋女枪手×1＋支援×1','双泵罐'),
 ('12','维护道',8800,3200,1840,'带休息台的竖向绕行；回到内庭','空追×1＋突进×1＋女枪手×1','弯管与检修框'),
 ('13','档案走廊',8000,2000,400,'记录在可撤回侧室；短战后调查','盾卫×1＋女枪手×1＋支援×1','嵌墙档案柜'),
 ('14','内庭',8000,2000,1120,'收束路线；行李与出发点分开','女枪手×2＋突进×1；战后安全','装车雨棚'),
 ('15','装车礼堂',10000,2000,400,'入口观察；两段掩护后接近维拉','区域首领；不开普通杂兵组','高拱与货轨终点'),
 ('16','后门',10000,2000,1120,'赛琳封锁；战后走货运捷径回访','赛琳精英；不叠加普通巡逻','石门楼'),
]
BY = {r[0]: r for r in SPACES}
# Local x/height in logical px. A space gets only the objects its encounter uses.
COVERS = {'02':[(920,24)],'03':[(680,24),(1240,32)],'05':[(740,24),(1170,24),(1470,32)],'06':[(1160,24)],'08':[(1050,24),(1620,32)],'09':[(920,24)],'10':[(1180,24),(1540,24)],'11':[(960,32),(1360,24)],'12':[(1520,24)],'14':[(820,24),(1320,24)],'15':[(580,24),(1440,24)],'16':[(920,24)]}
PERCHES = {'03':(1050,128,192),'05':(980,96,256),'06':(1480,128,320),'08':(1400,128,288),'09':(1200,144,256),'11':(1230,96,192),'12':(1880,128,384),'15':(1080,128,256)}
# Connection drawings express desired adjacency, not proof of physical reachability.
LINKS = [('01','02','main'),('02','03','main'),('03','05','main'),('05','07','main'),('07','08','main'),('08','14','main'),('14','16','main'),('16','15','main'),('02','10','side'),('10','05','side'),('03','04','side'),('04','06','side'),('06','09','side'),('09','08','side'),('09','13','side'),('13','14','side'),('07','11','side'),('11','12','side'),('12','14','side'),('16','01','return')]
COL = {'main':'#b63d38','side':'#207e83','return':'#86622d'}
SHAFTS=[('S1','03↔05',3360,1840),('S2','03↔04',2880,1120),('S3','07↔08',5680,1840),('S4','08↔09',7040,1120),('S5','12↔14',8880,1840),('S6','16↔15',11120,1120)]
def text(x,y,s,size=18,fill='#292a2d'):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}">{escape(str(s))}</text>'
def rect(x,y,w,h,fill,stroke='#afa895',extra=''):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" {extra}/>'
def line(x1,y1,x2,y2,color='#777',width=2,extra=''):
    return f'<path d="M{x1},{y1} L{x2},{y2}" fill="none" stroke="{color}" stroke-width="{width}" {extra}/>'
def svg(body,w,h):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><style>text{{font-family:Microsoft YaHei,Arial,sans-serif}} a:hover rect{{stroke:#b63d38;stroke-width:3}}</style><rect width="100%" height="100%" fill="#f4efdf"/>'+''.join(body)+'</svg>'

def overview():
    b=[text(52,55,'猩红修道院 / 动线设计总图',32),text(52,88,'LD-01 · 2026-09-15 · 待审施工设计；未写入游戏 · 横轴按世界坐标，纵向分层示意',17)]
    b += [text(52,120,'红：主路　青：可选路线　赭：战后回访　虚框：安全交谈／观察区',18)]
    yy={400:210,1120:450,1840:690}
    for y in yy:
        b.append(text(20,yy[y]-20,f'y={y}',15))
    for n in range(0,12001,1000):
        x=80+n*.14
        b.extend([line(x,150,x,890,'#ded7c4',1),text(x,925,n,14)])
    for a,z,k in LINKS:
        ra,rz=BY[a],BY[z]
        x1=80+(ra[2]+ra[3]*.5)*.14; x2=80+(rz[2]+rz[3]*.5)*.14
        y1=yy[ra[4]]+68; y2=yy[rz[4]]+68
        if k=='return':
            b.append(f'<path d="M{x1},{y1} V970 H{x2} V{y2}" fill="none" stroke="{COL[k]}" stroke-width="3" stroke-dasharray="8 6"/>')
        else: b.append(line(x1,y1,x2,y2,COL[k],5))
    for id,name,x,w,y,beat,enemy,landmark in SPACES:
        xx=80+x*.14; top=yy[y]; ww=w*.14-8
        b.append(f'<a href="#space-{id}">')
        b.append(rect(xx,top,ww,132,'#fffaf0'))
        b.extend([text(xx+10,top+28,f'{id}  {name}',20),text(xx+10,top+52,f'x {x}–{x+w} / 站立面 {y}',13)])
        for j,part in enumerate([beat[:14],beat[14:]]):
            if part:b.append(text(xx+10,top+77+j*20,part,14))
        b.append(text(xx+10,top+121,landmark,14,'#785b35')); b.append('</a>')
    b.extend([text(52,1018,'主要顺序：运输站 → 外庭 → 装卸場／货梯 → 中央庭院 → 内庭 → 赛琳 → 维拉 → 后门回访',20),
      text(52,1052,'四条既有货运捷径保留：02↔10、04↔08、09↔14、16↔01；开放条件沿用任务事实，不能充当新的剧情锁。',17),
      text(52,1085,'空间间连线表示设计通路。施工须补齐实际楼梯、门洞与支承；不能把图上的连通当成玩家已经走得通。',17)])
    return svg(b,1820,1120)

def detail(row):
    id,name,x,w,y,beat,enemy,landmark=row
    # Local drawing unit = logical pixel; viewport intentionally wider than one camera.
    b=[text(40,45,f'LD-{int(id)+1:02d} / {id} {name}',27),text(40,78,f'世界范围 x={x}…{x+w}；站立面 y={y}。{beat}',17)]
    b += [text(40,110,'这是单空间施工剖面：实际物件位置见下方清单。红实线为无需开枪的通路，青虚线为反冲可选高点。',16)]
    base=450; sx=40; scale=1120/w
    b.append(rect(sx,base,1120,68,'#a69b85'))
    b.append(text(48,base+40,'有下一层：梁与后墙承托；最底层：连续实体地基。桥洞只在下层路线处保留。',18))
    # Safe bays never become enemy spawns. Fixed length, not percentage of camera.
    for a,z in [(0,320),(w-280,w)]:
        b.append(rect(sx+a*scale,base-180,(z-a)*scale,180,'#e1e4d2','#8d9779','stroke-dasharray="6 5"'))
    b.extend([text(48,base-195,'观察／交谈 320px',15),text(980,base-195,'出口缓冲 280px',15)])
    combat = id not in ('01','04','07','13')
    if combat:
        for c,h in COVERS.get(id,[]):
            b.append(rect(sx+c*scale,base-h,48*scale,h,'#6c7673'))
            b.append(text(sx+c*scale-18,base+95,f'48×{h}石基座',13))
        b.append(line(sx+320*scale,base-8,sx+(w-280)*scale,base-8,COL['main'],4))
        if id in PERCHES:
            px,ph,pw=PERCHES[id]
            b.append(rect(sx+px*scale,base-ph,pw*scale,12,'#567a7a'))
            b.append(line(sx+(px-200)*scale,base-18,sx+px*scale,base-ph-12,COL['side'],3,'stroke-dasharray="6 5"'))
            b.append(text(sx+px*scale,base-ph-24,f'{ph}px高 / {pw}px宽检修台',14))
        b.append(text(40,570,'高点下面可通行；通往高点的反冲支路不计入主路验收。基座24px高，可正常跳越。',16))
    else:
        b.append(line(sx+20,base-8,sx+1100,base-8,COL['main'],4))
        b.append(text(40,570,'本空间留出连续安全通道；调查点与敌人活动边界至少隔开320px，并用墙角挡住射线。',16))
    b.extend([text(40,610,'遭遇：'+enemy,18),text(40,644,'地标：'+landmark+'；放在人物平面后方。花纹、枝叶和书架不占用行走截面。',17),text(40,682,'强制净空≥112px；主路台阶≤24px；换弹落脚面≥192px；新跨度仍须实控复测。',17)])
    return svg(b,1200,720)

def objects():
    data=[]
    def add(id,kind,x,y,z,w,h,d,representation,collision,material,reason):
        data.append(dict(id=id,kind=kind,x=round(x),y=y,z=z,width=w,height=h,depth=d,representation=representation,collision=collision,material=material,purpose=reason,status='proposed'))
    for id,name,x,w,y,beat,enemy,landmark in SPACES:
        prefix='mon_'+id
        # All floor coordinates identify the top; visual pieces grow upward.
        add(prefix+'_backwall','后墙',x,y,-64,w,320,24,'3D',False,'现有素石材区域','遮挡室内天空与跨层漏景；门窗逐个开洞，不用透明遮罩')
        add(prefix+'_beam','连续承重梁',x,y+24,-24,w,36,48,'3D',False,'iron_v1.png','上中层连到塔基；底层与地基接合')
        for i,xx in enumerate([x+64,x+w-128]):
            add(prefix+f'_pier{i}','后侧壁柱',xx,y,-48,64,288,32,'3D',False,'现有素石材区域','柱脚到站立面；正面不穿平台')
        add(prefix+'_landmark',landmark,x+w*.55,y,-96,240,256,64,'3D',False,'iron_v1.png + wood_v1.png + 现有素石材','具体组合见施工说明；远近镜头都检查侧面')
        add(prefix+'_lamp_in','入口壁灯',x+96,y-112,-42,20,48,12,'3D',False,'brass_v1.png','暖光照向入口，不在屏幕上画箭头')
        add(prefix+'_lamp_out','出口壁灯',x+w-112,y-112,-42,20,48,12,'3D',False,'同入口壁灯','墙上安装，不悬在空中')
        for i,(xx,h) in enumerate(COVERS.get(id,[])):
            add(prefix+f'_cover{i}','低石基座',x+xx,y,0,48,h,48,'3D',True,'现有素石材区域','跳越、急停和分割低位火线；不得穿出地板')
        if id in PERCHES:
            px,ph,pw=PERCHES[id]
            add(prefix+'_perch','检修格栅台',x+px,y-ph,0,pw,12,64,'3D',True,'iron_v1.png','可辨识单向格栅；高点可选，不影响主路')
        if y==1840:
            add(prefix+'_foundation','连续地基',x,y+24,-16,w,800,144,'3D',False,'现有素石材区域','实际底部须超出最远低俯镜头，不让背景露出水平底边')
    return data

def shaft_drawing(s):
    id,label,x,base=s
    b=[text(40,42,f'{id} / {label} / 三段折返检修梯',25),text(40,75,f'范围 x={x}…{x+816}；y={base-720}…{base}。每级24高、96宽、水平错开48；不依赖反冲。',16)]
    nodes=[]
    for flight in range(3):
        for j in range(10):
            xx=96+48*j if flight%2==0 else 576-48*j
            yy=base-240*flight-24*(j+1)
            nodes.append(dict(id=f'{id}_step_{flight*10+j+1:02}',x=x+xx,y=yy,width=96,depth=6,one_way=True))
    for n,(xx,rise) in enumerate([(0,0),(528,240),(96,480),(528,720)]):
        nodes.append(dict(id=f'{id}_rest_{n}',x=x+xx,y=base-rise,width=192,depth=8,one_way=True))
    for n in nodes:
        xx=60+(n['x']-x)*.9; yy=140+(n['y']-(base-720))*.9
        b.append(rect(xx,yy,n['width']*.9,6,'#528384'))
        if 'rest' in n['id']: b.append(text(xx,yy-12,f"{n['id']} / y={n['y']}",14))
    for xx in [16,768]: b.append(rect(60+xx*.9,120,12,684,'#c4bcb0'))
    b.extend([text(40,860,'实线：格栅台面；浅灰：后侧铁框(z=-40)。框脚接底层地基，不能作为不可见碰撞柱。',16),text(40,892,'4个192px休息台；相邻梯段垂直差240px。最终施工仍须实控上/下行及镜头侧面检查。',16)])
    return svg(b,860,930),nodes

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    data=objects()
    (OUT/'monastery-layout.svg').write_text(overview(),encoding='utf-8')
    articles=[]
    for row in SPACES:
        id=row[0]; name=f'monastery-{id}.svg'
        (OUT/name).write_text(detail(row),encoding='utf-8')
        lines=[o for o in data if o['id'].startswith('mon_'+id+'_')]
        trs=''.join('<tr>'+''.join(f'<td>{escape(str(o[k]))}</td>' for k in ['id','kind','x','y','z','width','height','depth','collision'])+'</tr>' for o in lines)
        articles.append(f'<section id="space-{id}"><h2>{id} {row[1]}</h2>{detail(row)}<table><tr>'+''.join(f'<th>{k}</th>' for k in ['物件ID','物件','x','y','z','宽','高','厚','碰撞'])+f'</tr>{trs}</table><a href="#top">返回总图</a></section>')
    stairs=[]
    for s in SHAFTS:
        drawing,nodes=shaft_drawing(s); stairs+=nodes
        (OUT/f'monastery-{s[0]}.svg').write_text(drawing,encoding='utf-8')
        articles.append(f'<section id="{s[0]}"><h2>{s[0]} 跨层节点</h2>{drawing}</section>')
    (OUT/'monastery-stairs.json').write_text(json.dumps(stairs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'monastery-objects.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>猩红修道院关卡设计图</title><style>body{margin:0;background:#ebe5d6;color:#292a2d;font:16px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1820px;margin:auto;padding:30px}h1{font-size:34px}section{background:#f8f3e7;padding:24px;margin:36px 0;scroll-margin-top:16px}svg{width:100%;height:auto}table{width:100%;border-collapse:collapse;font-size:14px}td,th{padding:7px;border:1px solid #bfb5a0;text-align:left}a{color:#a33838}nav{display:flex;gap:16px;flex-wrap:wrap}.note{padding:18px;border-left:4px solid #a33838;background:#fff8e9}@media print{section{break-before:page}nav{display:none}}</style><main id="top"><h1>猩红修道院 · 先图后施工</h1><p class="note">待审设计，尚未改动游戏。红线为主路，青线为可选路线。点击空间进入剖面与物件表。图与 JSON 由同一份数据生成，所有坐标为逻辑像素，z 为相对玩法平面的深度。</p>'''
    html+='<nav>'+''.join(f'<a href="#space-{r[0]}">{r[0]} {r[1]}</a>' for r in SPACES)+'</nav>'+overview()+''.join(articles)+'</main></html>'
    (OUT/'monastery-plan.html').write_text(html,encoding='utf-8')
    assert len({o['id'] for o in data})==len(data)
    assert len(BY)==16 and all(a in BY and z in BY for a,z,k in LINKS)
    print(f'16 space drawings, 1 overview, 6 stair drawings / {len(stairs)} nodes, {len(data)} explicit objects; design only.')
if __name__=='__main__':main()
