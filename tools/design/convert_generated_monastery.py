"""Measured vector plan transcribed AFTER inspection of monastery-concept.png.
Does not edit the generated bitmap or modify gameplay geometry.
"""
from pathlib import Path
from html import escape
import json, math
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'dev-design/levels/image-led'
def world(p): return [p[0]*8,1120+(p[1]-430)*8]
# Image pixel endpoints, traced from visible floor breaks and stair silhouettes.
FLOORS=[('F01','站前街道',(16,430),(388,430)),('F02','装卸庭主地面',(460,466),(806,466)),('F03','钟庭地面',(878,502),(1160,502)),('F04','花园地面',(1228,468),(1470,468)),('F05','礼堂地面',(1470,468),(2020,468)),('F06','门楼阳台',(336,290),(416,290)),('F07','侧楼廊台',(556,376),(784,376)),('F08','货道地面',(420,575),(770,575)),('F09','泵房地面',(858,619),(998,619)),('F10','泵房东检修台',(1078,579),(1128,579)),('F11','礼堂后隧道',(1530,630),(2000,630))]
STAIRS=[('S01','补建门楼至装卸庭',(388,430),(460,466),True),('S02','门楼阳台梯',(208,354),(336,290),False),('S03','装卸庭至钟庭',(806,466),(878,502),False),('S04','钟庭至花园',(1160,502),(1228,468),False),('S05','侧楼长梯',(556,376),(740,468),False),('S06','货道至泵房',(770,575),(858,619),False),('S07','泵房东梯',(998,619),(1078,579),False),('S08','补建门楼低梯',(40,438),(208,354),True),('S09','补建货道入口梯',(570,475),(770,575),True),('S10','补建礼堂后隧道梯',(1684,468),(2008,630),True)]
for i in range(6):
    STAIRS.append((f'S{11+i:02}','钟楼侧梯', (1220 if i%2==0 else 1160,466-36*i),(1160 if i%2==0 else 1220,430-36*i),False))
JOINS=[('J01','门楼低梯接街道',(28,430),(40,438)),('J02','货道梯入口接庭院',(552,466),(570,475)),('J03','侧楼梯脚接庭院',(736,466),(740,468)),('J04','钟楼梯脚接花园',(1220,466),(1228,468))]
# Explicit structural pieces: x,y,w,h are IMAGE bounds. Depth is logical px.
STRUCTURES=[('B01','门楼石墙',[192,120,218,580],192,'3D'),('B02','吊车房后墙',[410,242,155,334],128,'3D'),('B03','装卸庭基础',[412,476,391,230],192,'3D'),('B04','钟楼西墩',[884,70,59,570],256,'3D'),('B05','钟楼东墩',[1118,65,42,590],256,'3D'),('B06','钟架梁',[916,111,241,30],128,'3D'),('B07','铜钟',[983,132,84,87],96,'3D'),('B08','泵房后墙',[842,525,298,99],128,'3D'),('B09','花园基础',[1232,480,237,232],192,'3D'),('B10','花园棚',[1250,306,229,32],96,'3D'),('B11','门框',[1470,291,111,180],128,'3D'),('B12','礼堂后墙',[1618,99,359,369],192,'3D'),('B13','礼堂基础',[1590,478,458,230],192,'3D'),('B14','高窗玻璃',[1716,155,82,165],8,'2D贴片'),('B15','档案柜',[804,321,92,73],48,'3D柜体+2D书脊'),('B16','左泵罐',[875,546,53,71],64,'3D'),('B17','右泵罐',[945,546,53,71],64,'3D')]
COL={'floor':'#a12f31','stairs':'#176e82','add':'#873f90'}
def main():
    b=['<svg xmlns="http://www.w3.org/2000/svg" width="2200" height="1150" viewBox="0 0 2200 1150"><style>text{font-family:Microsoft YaHei,Arial,sans-serif}</style><rect width="2200" height="1150" fill="#f1eddf"/>']
    b+=['<text x="70" y="48" font-size="30">猩红修道院 / 生成图转施工剖面</text>','<text x="70" y="83" font-size="18">红：连续路面　蓝：独立步行楼梯　紫虚线：原图缺失的补建连接　灰：建筑体块（不是整块碰撞）</text>']
    def pt(p):return (p[0]+70,p[1]+140)
    for i in range(0,2049,128):
        b.append(f'<path d="M{i+70},130 V940" stroke="#ddd5c4"/><text x="{i+70}" y="965" font-size="13">{i*8}</text>')
    for id,name,(x,y,w,h),depth,kind in STRUCTURES:
        b.append(f'<rect x="{x+70}" y="{y+140}" width="{w}" height="{h}" fill="#d1cab9" stroke="#b2a893"/>')
        b.append(f'<text x="{x+74}" y="{y+156}" font-size="13">{id}</text>')
    records=[]
    for id,name,a,z in FLOORS:
        x,y=pt(a);xx,yy=pt(z)
        b.append(f'<path d="M{x},{y} L{xx},{yy}" stroke="{COL["floor"]}" stroke-width="6"/><text x="{(x+xx)/2-20}" y="{y-12}" font-size="15" fill="{COL["floor"]}">{id}</text>')
        records.append(dict(id=id,name=name,kind='floor',source=[a,z],start=world(a),end=world(z),depth=48,status='proposed'))
    for id,name,a,z,added in STAIRS:
        x,y=pt(a);xx,yy=pt(z);color=COL['add' if added else 'stairs'];dash='stroke-dasharray="8 5"' if added else ''
        slope=abs((z[1]-a[1])/(z[0]-a[0])); angle=math.degrees(math.atan(slope))
        assert angle<=35
        b.append(f'<path d="M{x},{y} L{xx},{yy}" stroke="{color}" stroke-width="7" {dash}/><text x="{(x+xx)/2+8}" y="{(y+yy)/2-8}" font-size="15" fill="{color}">{id}</text>')
        records.append(dict(id=id,name=name,kind='stair',source=[a,z],start=world(a),end=world(z),width=abs(z[0]-a[0])*8,rise=abs(z[1]-a[1])*8,angle=round(angle,2),visual_tread=12,visual_riser=6,landing=96,depth=96,body='closed_ramp',added_to_concept=added,status='proposed'))
    for id,name,a,z in JOINS:
        records.append(dict(id=id,name=name,kind='ramp_join',source=[a,z],start=world(a),end=world(z),body='continuous_solid_join',status='proposed'))
        x,y=pt(a);xx,yy=pt(z)
        b.append(f'<path d="M{x},{y} L{xx},{yy}" stroke="{COL["add"]}" stroke-width="7"/>')
    for id,name,bounds,depth,kind in STRUCTURES:
        x,y,w,h=bounds
        records.append(dict(id=id,name=name,kind=kind,source_bounds=bounds,position=world([x,y]),size=[w*8,h*8],depth=depth,collision='author_openings_first',status='proposed'))
    notes=['J01…J04为楼梯和平地间的实体坡面接段，消除源图高差；S09入口须开洞并补96px前室。',
           'F06与F07之间有未连通建筑：保持可选观察台，不能将其算作已连通上层主路。',
           'S10补建于礼堂侧墙内；隧道尽端接既有返程货运门。没有宣称画出一条贯通全图的步行地下路。',
           '主线：F01→S01→F02→S03→F03→S04→F04→任务门→F05。跳跃、开火、V均不是主路必要输入。']
    for j,n in enumerate(notes):b.append(f'<text x="70" y="{1005+j*30}" font-size="18">{escape(n)}</text>')
    b.append('</svg>'); (OUT/'construction.svg').write_text(''.join(b),encoding='utf-8')
    (OUT/'construction.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    rows=''.join('<tr>'+''.join('<td>'+escape(str(r.get(k,'')))+'</td>' for k in ['id','name','kind','start','end','angle','added_to_concept'])+'</tr>' for r in records)
    html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>生成图与施工图对照</title><style>body{margin:24px;background:#f1eddf;color:#27282a;font:17px/1.7 "Microsoft YaHei",sans-serif}img{width:100%;height:auto}section{margin:32px 0}td,th{padding:8px;border:1px solid #aaa}table{border-collapse:collapse;width:100%}a{color:#963c35}</style><h1>猩红修道院：先生成，再转施工</h1><p>待审方案。生成图体现建筑构图，施工图区分源图结构与必须补建的连接。游戏地图尚未更新。</p><a href="README.md">施工规则与转换边界</a><section><h2>01 / imagegen生成图</h2><img src="monastery-concept.png"></section><section><h2>02 / 按源图坐标提取的施工图</h2><img src="construction.svg"></section><h2>03 / 构件清单</h2><table><tr><th>ID</th><th>对象</th><th>类型</th><th>起点</th><th>终点</th><th>角度</th><th>补建</th></tr>'''+rows+'</table></html>'
    (OUT/'construction.html').write_text(html,encoding='utf-8')
    print(f'{len(FLOORS)} floor segments, {len(STAIRS)} separate stairs, {len(STRUCTURES)} architectural masses; all stairs <=35 degrees. Not a reachability test.')
if __name__=='__main__':main()
