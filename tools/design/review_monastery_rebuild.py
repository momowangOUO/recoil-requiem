"""Pair untouched package captures with pixel-exact crops of the accepted source."""
import argparse, html, json, math, os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--evidence-dir', type=Path, default=ROOT/'dev-design/levels/rebuild/evidence-20261027')
args = parser.parse_args()
evidence = args.evidence_dir.resolve()
output = ROOT/'dev-design/levels/rebuild/review.html'
source_path = ROOT/'dev-design/levels/image-led/monastery-concept.png'
source = Image.open(source_path)
manifest = json.loads((evidence/'run-manifest.json').read_text(encoding='utf-8-sig'))
captured_date = manifest['date']
font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',24)
views = json.loads((evidence/'rebuild_views.json').read_text(encoding='utf8'))
replays = json.loads((evidence/'replay-results.json').read_text(encoding='utf-8-sig'))
assert len(replays) == 2 and all(r['exit'] == 0 and 'complete=true' in str(r['result']) for r in replays)

def link(path):
    return html.escape(os.path.relpath(path, output.parent).replace('\\', '/'), quote=True)

def movie_link(name):
    base = manifest.get('release_url', '')
    return html.escape(base+'/'+name, quote=True) if base else link(evidence/name)

def figure(path, caption):
    assert path.is_file(), path
    return f'<figure><a href="{link(path)}" target="_blank"><img src="{link(path)}" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

def pair_png(reference, runtime_path, destination, title, overview=False):
    runtime = Image.open(runtime_path).convert('RGBA')
    width,height = runtime.size
    if overview:
        assert reference.width*height == reference.height*width, 'Overview preview must preserve aspect ratio'
        shown = reference.resize(runtime.size,Image.Resampling.NEAREST)
        scale = '等比1/2预览；原始2048×768另存'
    else:
        factor = max(1,min(width//reference.width,height//reference.height))
        shown = reference.resize((reference.width*factor,reference.height*factor),Image.Resampling.NEAREST)
        scale = f'原图裁区等比放大{factor}倍，nearest；无变形'
    assert shown.width<=width and shown.height<=height, 'Reference preview must remain fully visible'
    canvas = Image.new('RGBA',(width*2+24,height+64),(23,27,40,255))
    draw = ImageDraw.Draw(canvas)
    draw.text((12,16),title+' · '+scale,font=font,fill='#eee5d4')
    draw.text((width+36,16),'运行包实景 · 原尺寸，未修图',font=font,fill='#eee5d4')
    canvas.paste(shown,((width-shown.width)//2,64+(height-shown.height)//2))
    canvas.paste(runtime,(width+24,64))
    assert canvas.crop((width+24,64,width*2+24,height+64)).tobytes()==runtime.tobytes()
    canvas.save(destination)

names = {'gatehouse':'门楼','cargo':'装卸庭','bell':'钟楼庭院','garden':'花棚','hall':'礼堂'}
differences = {
    'gatehouse':'门楼尖拱已单独重绘；上层服务通道和拱口按角色尺度调整，石块线条比原图更粗。',
    'cargo':'主路和下穿沿原图货场组织。门、货箱补绘清晰正面；箱体与侧面是真实3D，后墙沿实际楼梯收边。此处相对旧版避开了NPC重叠站位。',
    'bell':'巨钟与两侧塔楼关系保留。钟梯为六段短金属梯；接台、栏杆和托座来自实际节点，雕像、凹龛及档案书架继续拆分。',
    'garden':'玻璃顶、框架、枝干、树冠、前后攀藤、花丛、灯具和室内分别分层。树根与花丛落在真实花槽上，槽面沿用原画；暖光源与可见灯具同位，恢复原图的绿植密度和冷暖围合。新后墙和格栅背梁补齐接缝。树冠像素簇较原图简化。',
    'hall':'祭台高于主路100px，两侧短阶及地下室入口可走。重绘彩窗、雕像和背饰，玻璃凹进墙内，雕像配真实凹龛与基座。纹样较原图简化，未宣称逐像素复刻。',
}
parts = ['''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>修道院：原图与运行包对照</title><link rel="icon" href="data:,"><style>
body{margin:0;background:#171b28;color:#eee5d4;font:16px/1.65 system-ui,"Microsoft YaHei",sans-serif}main{max-width:1500px;margin:auto;padding:32px}h1{font-size:30px}h2{margin-top:42px;color:#e3bc80}a{color:#8fd3d0}p{max-width:1100px}figure{margin:0;background:#10131e;padding:12px;min-width:0}img{display:block;width:100%;height:auto;image-rendering:pixelated}figcaption{padding-top:9px;color:#c4beb8;font-size:14px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:14px;align-items:start}.six{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}code{color:#c7d7e5}summary{cursor:pointer;padding:12px 0}table{border-collapse:collapse;width:100%}td,th{border:1px solid #45495a;text-align:left;padding:9px}.note{border-left:3px solid #d19e65;padding-left:14px}video{width:100%}@media(max-width:850px){main{padding:18px}.pair,.six{grid-template-columns:1fr}}</style><main>
<h1>修道院：原图与运行包对照</h1>
<p>本页使用CAPTURE_DATE修订后Windows内嵌包的实际渲染。原图裁区保持原始像素，截图未经修图、非等比拉伸或锐化处理；点图可打开原尺寸文件。正常视角固定为左轮近镜头，另列三枪近远图。</p>
<p class="note">正常镜头图和三枪远近图为受控站位，不计作通关。两条连续路线由正常键鼠输入脚本完成，未设置无敌、任务完成状态或用传送替代路线。截图与回放读取Windows EXE内嵌资源包，由同版Godot引擎驱动；EXE直接启动的原始帧另列。没有真人试玩。</p>
<p><a href="construction.svg">完整施工图</a> · <a href="layout.json">尺度、区域、门锁和站位数据</a> · <a href="NAVIGATION_REVIEW_2026-10-27.md">本轮动线、文字与验收记录</a></p>
<h2>全景</h2><p>右图为审阅用远镜头，1024×384；隐藏跟随镜头的前景遮挡，用于核对五组建筑的轮廓、高低关系和裸露结构断面，不是正常游玩视野。正常镜头图保留实际前景。</p><div class="pair">''']
parts += [figure(source_path,'已确认原图 · 2048×768'),figure(evidence/'rebuild_overview.png','Windows内嵌包 · 审阅专用全景'),'</div>']
pair_png(source,evidence/'rebuild_overview.png',evidence/'comparison-overview.png','全景',True)
parts.append(f'<p><a href="{link(evidence/"comparison-overview.png")}">打开全景并排图</a></p>')
for id, title in names.items():
    x, y, w, h = views[id]['world_rect']
    box = (max(0,math.floor(x/2)), max(0,math.floor((y+348)/2)), min(source.width,math.ceil((x+w)/2)), min(source.height,math.ceil((y+h+348)/2)))
    assert box[2]>box[0] and box[3]>box[1], (id,box)
    crop = evidence/f'source_{id}.png'
    source.crop(box).save(crop)
    pair_png(source.crop(box),evidence/f'rebuild_{id}.png',evidence/f'comparison-{id}.png',title)
    views[id]['reference_crop'] = list(box)
    parts += [f'<h2>{title}</h2><p>{differences[id]}</p><div class="pair">',
              figure(crop,f'原图裁区 {box}；按游玩平面投影定位，保留原图比例'),
              figure(evidence/f'rebuild_{id}.png','正常游玩镜头 · 受控站位 · 1280×720'),'</div>']
    parts.append(f'<p><a href="{link(evidence/f"comparison-{id}.png")}">打开本区并排图</a></p>')
    parts.append('<details><summary>三枪近远镜头（同一运行包）</summary><div class="six">')
    for gun, label in [('revolver','左轮'),('shotgun','霰弹枪'),('smg','冲锋枪')]:
        for extent, name in [('near','近镜头'),('far','远镜头')]:
            parts.append(figure(evidence/f'{id}_{gun}_{extent}.png',label+' · '+name))
    parts.append('</div></details>')

parts.append('<details><summary>运输站、档案室与泵房补充视角</summary><div class="six">')
for id,label in [('station','运输站棚梁、立柱与车体'),('archive','档案室书架、雕像和短梯'),('pump','泵房与维护下路')]:
    parts.append(figure(evidence/f'rebuild_{id}.png',label+' · 正常左轮近镜头 · 受控站位'))
parts.append('</div></details>')

parts.append('<h2>连续自动通关与真实游玩画面</h2><p>录像保留实际输入、战斗、交谈、上下楼和回程。AVI为引擎直接录制；JSONL为位置与输入状态诊断日志，不能替代录像。</p><table><tr><th>路线</th><th>结果</th><th>证据</th></tr>')
for row in replays:
    route = row['route']; label = '货梯维修上路' if route=='lift' else '泵房维护下路'
    parts.append(f'<tr><td>{label}</td><td>{html.escape(str(row["result"][0]))}</td><td><a href="{movie_link("replay_"+route+".avi")}">连续录像</a> · <a href="{link(evidence/("replay_"+route+".jsonl"))}">诊断日志</a></td></tr>')
parts.append('</table><div class="six">')
for id,title in names.items():
    filename = 'gate' if id=='gatehouse' else id
    parts.append(figure(evidence/f'play_lift_{filename}.png','连续上路回放中的'+title+'；包含实际HUD和战斗状态'))
parts.append(f'</div><h2>连续镜头检查</h2><p><a href="{movie_link("camera-motion.avi")}">三枪、近远镜头、横移、跳跃和下落的连续检查录像</a>。各切片之间设置测试起点，切片内保持连续物理输入；此录像不计作通关。</p><h2>EXE直接启动核对</h2><p>下图来自EXE自行运行的原始帧序列，不通过外部场景脚本启动。</p>')
parts.append(figure(evidence/'direct-exe.png','RecoilRequiem.exe 直接运行 · 第30帧；完整60帧另存于本地原始证据'))
parts.append('<details><summary>实际对白、发车确认与地图</summary><div class="six">')
for filename, caption in [('modal_lift_01_dialogue.png','玛拉：一次完整发言'),('modal_lift_04_dialogue.png','隔着货梯门初见维拉'),('modal_lift_05_departure.png','实际未交接物品与发车确认'),('play_lift_map.png','货梯路线通关后，按M打开的已探索地图'),('play_maintenance_map.png','泵房路线通关后的已探索地图')]:
    parts.append(figure(evidence/filename,caption+'；连续回放中的原始画面'))
parts.append('</div></details>')
parts.append(f'<p><a href="{link(evidence/"package-check.log")}">内嵌资源核对</a> · <a href="{link(evidence/"direct-exe.log")}">EXE直接启动记录</a> · <a href="{link(evidence/"checks.log")}">完整回归结果</a> · <a href="{link(evidence/"rebuild_details.json")}">实际画片登记</a> · <a href="{link(evidence/"run-manifest.json")}">构建指纹与证据类型</a></p></main></html>')
output.write_text(''.join(parts).replace('CAPTURE_DATE',html.escape(captured_date)),encoding='utf8')
(evidence/'comparison-crops.json').write_text(json.dumps(views,ensure_ascii=False,indent=2),encoding='utf8')
print('Comparison written:',output)
print('Five source crops, five normal views, thirty weapon views, five continuous-play views and direct EXE frame; no screenshot resizing or retouching.')
