"""Build the illustrated review from text/data; no game assets or images are edited."""
from pathlib import Path
import html
import json
import re

ROOT = Path(__file__).resolve().parent
beats = json.loads((ROOT / 'beats.json').read_text(encoding='utf-8-sig'))
esc = html.escape

def inline(s):
    s = esc(s)
    s = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', s)
    return re.sub(r'`([^`]+)`', r'<code>\1</code>', s)

def markdown(source):
    out, para, table = [], [], []
    def flush():
        if para:
            out.append('<p>' + inline(' '.join(para)) + '</p>')
            para.clear()
        if table:
            rows = [[c.strip() for c in r.strip('|').split('|')] for r in table]
            out.append('<table><thead><tr>' + ''.join('<th>'+inline(c)+'</th>' for c in rows[0]) + '</tr></thead><tbody>')
            for r in rows[2:]:
                out.append('<tr>' + ''.join('<td>'+inline(c)+'</td>' for c in r) + '</tr>')
            out.append('</tbody></table>')
            table.clear()
    for line in source.splitlines():
        if line.startswith('|'):
            if para: flush()
            table.append(line)
        elif line.startswith('#'):
            flush()
            n = min(len(line)-len(line.lstrip('#')), 4)
            out.append(f'<h{n}>{inline(line[n:].strip())}</h{n}>')
        elif not line.strip(): flush()
        else:
            if table: flush()
            para.append(line)
    flush()
    return '\n'.join(out)

ui = '../../assets/ui/v2/runtime/'
parts = []
for b in beats:
    shotgun = b['id'] in ('06','07')
    ammo = ('01' if b['id'] == '06' else '02') if shotgun else ('04' if b['id'] in ('03','10','11') else '06')
    capacity = '2' if shotgun else '6'
    gun = 'gun_shotgun.png' if shotgun else 'gun_revolver.png'
    dots = ''.join(f'<img src="{ui}health_full.png" alt="生命">' for _ in range(5))
    marks = ''.join(f'<span class="mark" style="left:{x}%;top:{y}%" title="{esc(t)}">{i+1}</span>' for i,(x,y,t) in enumerate(b['annotations']))
    labels = ''.join(f'<li><b>{i+1}</b> {esc(t)}</li>' for i,(_,_,t) in enumerate(b['annotations']))
    dialogue = f'<div class="dialogue">{esc(b["subtitle"])}</div>' if b['subtitle'] else ''
    confirm = '<div class="confirmation"><h3>继续追猎？</h3><p>继续后，尚未完成的物品交接将结束。<br>已读记录和已开通路会保留。</p><p>工具箱尚未交还。<br>维修记录尚未交给任何人。</p><div><span>再等等</span><span>继续追猎</span></div></div>' if b['id'] == '09' else ''
    fields = ''.join(f'<p><strong>{title}</strong>{esc(b[key])}</p>' for key,title in [('action','玩家行动　'),('entry','开始条件　'),('exit','结束条件　'),('feedback','场景回应　'),('build','施工重点　'),('check','验证问题　')])
    parts.append(f'''<section class="beat" id="beat-{b['id']}">
      <header class="beat-head"><span class="number">{b['id']}</span><div><small>{esc(b['time'])} · {esc(b['region'])}</small><h2>{esc(b['title'])}</h2></div><span class="status">设计提案</span></header>
      <figure><div class="screen">
        <img class="scene" src="images/{b['id']}.png" alt="图{b['id']} {esc(b['title'])} 生成流程示意">
        <div class="screen-ui"><div class="tracker"><small>当前目标</small><span>{esc(b['objective'])}</span></div>
        <div class="hud"><div class="life">{dots}</div><div class="ammo"><img src="{ui}{gun}" alt="当前武器"><span>{ammo}<small> / {capacity}</small></span></div><div class="slots">1 左轮　2 霰弹枪　3 冲锋枪　4— 5— 6—</div></div>
        {dialogue}{confirm}<div class="hint">{esc(b['hint'])}</div></div><div class="annotations">{marks}</div>
      </div><figcaption>图 {b['id']}　生成场景＋中文界面排布示意　非实机截图　·　{esc(b['quest'])}</figcaption></figure>
      <ol class="legend">{labels}</ol><div class="details">{fields}</div>
    </section>''')

nav = ''.join(f'<a href="#beat-{b["id"]}">{b["id"]} {esc(b["title"])}</a>' for b in beats)
design = markdown((ROOT / 'DESIGN.md').read_text(encoding='utf-8'))
copy = markdown((ROOT.parent.parent / 'game-text/monastery-flow-review.md').read_text(encoding='utf-8'))
css = '''
@font-face{font-family:GamePixel;src:url('../../assets/fonts/unifont-18.0.01.otf')}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#ece8df;color:#24232a;font-family:'Microsoft YaHei','Noto Sans CJK SC',sans-serif;line-height:1.75}a{color:#792f42;text-decoration:none}button{font:inherit;cursor:pointer;border:1px solid #afa391;border-radius:4px;background:#faf7f0;padding:7px 14px;color:#36292b}button:focus-visible,a:focus-visible{outline:3px solid #ba833a;outline-offset:4px}.toolbar{position:sticky;top:0;background:#eee9dfed;backdrop-filter:blur(8px);z-index:5;border-bottom:1px solid #c9c0b3;padding:10px 4vw;display:flex;gap:12px;align-items:center}.toolbar span{margin-right:auto;font-weight:600}.cover,main,.appendix{max-width:1160px;margin:auto;padding:36px 36px}.cover{padding-top:62px}.eyebrow{color:#873b4e;letter-spacing:.18em;font-size:13px}.cover h1{font-size:42px;line-height:1.35;letter-spacing:.03em;margin:15px 0}.cover .lead{max-width:860px;font-size:19px;color:#4c4547}.scope{font-size:14px;color:#6c6462}.overview{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin:28px 0}.overview span{padding:8px 12px;border-bottom:3px solid #97455a;font-weight:600}.overview i{font-style:normal;color:#a39486}.index{display:grid;grid-template-columns:repeat(3,1fr);gap:8px 24px;margin:28px 0}.index a{border-bottom:1px solid #cfc5b8;padding:7px 0;font-size:14px}.beat{margin:0 0 70px;scroll-margin-top:85px}.beat-head{display:flex;gap:18px;align-items:center;margin:0 0 20px}.beat-head .number{font-family:Georgia,serif;font-size:52px;line-height:1;color:#944258}.beat-head small{font-size:12px;color:#6a6163}.beat-head h2{font-size:28px;margin:2px 0;line-height:1.4}.status{margin-left:auto;font-size:12px;border:1px solid #ad9298;padding:3px 9px;color:#7b4250}.screen{position:relative;container-type:inline-size;background:#17141c;line-height:1}.scene{width:100%;height:auto;display:block}.screen-ui,.annotations{position:absolute;inset:0;pointer-events:none}.tracker{position:absolute;right:2%;top:3%;width:34%;aspect-ratio:3;background:url('../../assets/ui/v2/runtime/tracker_frame.png') center/contain no-repeat;padding:3% 3% 2% 4%;font-family:GamePixel,monospace;color:#f2e5cc;display:flex;flex-direction:column;justify-content:center;gap:.6cqw}.tracker small{font-size:1.15cqw;color:#c5a47b}.tracker span{font-size:1.7cqw;line-height:1.2;overflow-wrap:anywhere}.hud{position:absolute;left:3%;bottom:4%;color:#fff0cd;font-family:GamePixel,monospace;text-shadow:2px 2px #171018}.life{display:flex;gap:.45cqw;margin-bottom:.5cqw}.life img{width:1.25cqw;height:1.9cqw;object-fit:contain}.ammo{display:flex;gap:1cqw;align-items:center}.ammo img{width:4cqw;height:3cqw;object-fit:contain}.ammo span{font-size:3.5cqw}.ammo small{font-size:1.6cqw}.slots{font-size:1cqw;margin-top:.4cqw}.dialogue{position:absolute;left:28%;bottom:9%;width:47%;font-family:GamePixel,monospace;font-size:1.65cqw;color:#fff0d4;text-shadow:2px 2px #161019,-1px -1px #161019;line-height:1.35;text-align:center}.hint{position:absolute;left:29%;bottom:3%;width:46%;font-family:GamePixel,monospace;color:#ded6cb;text-align:center;font-size:1.2cqw;text-shadow:1px 1px #111}.mark{position:absolute;border-radius:50%;width:2.35cqw;height:2.35cqw;display:grid;place-items:center;background:#eadac0;color:#752f45;border:.16cqw solid #80364b;box-shadow:0 1px 5px #0008;font:bold 1.35cqw Arial;transform:translate(-50%,-50%)}figure{margin:0}figcaption{font-size:12px;color:#6f6560;padding:9px 0}.legend{display:flex;list-style:none;padding:0;margin:8px 0 18px;gap:12px;flex-wrap:wrap;font-size:13px;color:#65534f}.legend li{flex:1;min-width:200px}.legend b{color:#8b3d51;margin-right:5px}.details{columns:2;column-gap:34px;border-top:1px solid #c8bbac;padding-top:14px;font-size:14px}.details p{margin:0 0 9px;break-inside:avoid}.details strong{display:block;color:#79394b;font-size:13px}.appendix{border-top:2px solid #8e4455}.appendix h1{font-size:30px}.appendix h2{font-size:23px;margin-top:32px}.appendix h3{font-size:18px;margin-top:24px}.appendix p{font-size:15px}.appendix table{width:100%;border-collapse:collapse;font-size:13px;margin:18px 0}.appendix th,.appendix td{border:1px solid #c9c0b3;padding:8px;vertical-align:top}.appendix th{background:#ded6c9;text-align:left}.appendix tr:nth-child(even){background:#f4f0e7}.appendix code{font-size:.9em}.notes-off .annotations,.notes-off .legend{display:none}.ui-off .screen-ui{display:none}.review-ref{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin:24px 0}.review-ref img{width:100%;image-rendering:pixelated}.review-ref p{font-size:13px;margin:4px 0}.footer{margin:40px auto;text-align:center;font-size:12px;color:#776963}.print-only{display:none}
@media(max-width:700px){.cover,main,.appendix{padding:24px 16px}.cover h1{font-size:30px}.index{grid-template-columns:1fr 1fr}.details{columns:1}.toolbar{flex-wrap:wrap}.toolbar span{width:100%;font-size:14px}.beat-head h2{font-size:23px}.status{display:none}.review-ref{grid-template-columns:1fr}}
@media print{@page{size:A4 landscape;margin:12mm}html{scroll-behavior:auto}body{background:#fff;color:#222;-webkit-print-color-adjust:exact;print-color-adjust:exact}.toolbar,.index,.no-print{display:none}.cover{padding:5mm 0;break-after:page}.cover h1{font-size:32pt}.cover .lead{font-size:13pt}.overview{margin:8mm 0}.review-ref{max-width:190mm}.cover,main,.appendix{max-width:none;margin:0;padding:0}.beat{break-before:page;break-inside:avoid;margin:0;page-break-after:always}.beat-head{margin:0 0 3mm;gap:4mm}.beat-head .number{font-size:24pt}.beat-head h2{font-size:17pt}.beat-head small{font-size:8pt}.status{font-size:8pt}figure{width:205mm;margin:0 auto}.screen{width:205mm}.legend{font-size:8pt;margin:1mm 0 2mm;gap:4mm}.legend li{min-width:0}.details{font-size:8pt;columns:3;column-gap:5mm;padding-top:2mm;line-height:1.5}.details p{margin:0 0 1.5mm}.details strong{font-size:8pt}figcaption{font-size:7pt;padding:1mm 0}.appendix{break-before:page;border:0}.appendix h1{font-size:21pt}.appendix h2{font-size:16pt;break-after:avoid}.appendix h3{font-size:12pt;break-after:avoid}.appendix p{font-size:10pt;line-height:1.65;orphans:3;widows:3}.appendix table{font-size:8pt}.appendix tr{break-inside:avoid}.appendix th,.appendix td{padding:2mm}.footer{font-size:8pt}.print-only{display:block}}
'''
css += '''.tracker{padding-left:5.3%}.confirmation{position:absolute;left:34%;top:25%;width:45%;padding:2% 3%;border:15px solid transparent;border-image:url('../../assets/ui/v2/runtime/dialogue_frame.png') 35 fill stretch;color:#f4e6ce;font-family:GamePixel,monospace;font-size:1.35cqw;line-height:1.45}.confirmation h3{font-size:2cqw;font-weight:normal;margin:0 0 .8cqw}.confirmation p{margin:.6cqw 0}.confirmation div{display:flex;gap:1.5cqw;margin-top:1cqw}.confirmation span{flex:1;padding:.8cqw;text-align:center;background:url('../../assets/ui/v2/runtime/button_normal.png') center/100% 100% no-repeat}.confirmation+.hint{bottom:2%}'''
css += '''@media print{.cover{padding:0;line-height:1.5}.cover h1{font-size:28pt;line-height:1.15;margin:4mm 0}.cover .lead{font-size:11pt}.cover p{font-size:10pt}.cover .scope{font-size:9pt}.cover .overview{margin:4mm 0}.cover .review-ref{max-width:155mm;margin:4mm 0}.cover .review-ref p{font-size:8pt}}'''
page = f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="data:,"><title>反冲挽歌 猩红修道院完整流程设计</title><style>{css}</style></head><body>
<nav class="toolbar"><span>反冲挽歌 · 完整流程审阅</span><button onclick="document.body.classList.toggle('notes-off')">显示／隐藏标注</button><button onclick="document.body.classList.toggle('ui-off')">显示／隐藏界面</button><button onclick="window.print()">打印／保存 PDF</button><a href="#spec">完整规则</a></nav>
<header class="cover"><div class="eyebrow">反冲挽歌 · 流程设计审阅 · 2026 年 9 月 22 日</div><h1>猩红修道院<br>完整游玩流程</h1><p class="lead">从运输站抵达，到猩红修道院事件结束。前十五分钟把操作、目的和人物逐一接起来；后半章给路线选择、关系变化和战后回访留出空间。</p><p class="scope">12 幅生成伪游戏截图 · 首次体验目标 40–50 分钟 · 新增安排待审，未接入运行</p>
<div class="overview"><span>抵达</span><i>→</i><span>学会换位</span><i>→</i><span>见到目标</span><i>→</i><span>合作与选路</span><i>→</i><span>确认追猎</span><i>→</i><span>战后回访</span></div>
<p>白发莉芙、三枪与六槽、已确认的事件线继续保留。维拉死亡固定，支线改变通路、现场和人物回应；没有隐藏发车倒计时，也不提供虚假的饶命选项。</p>
<div class="review-ref"><div><img src="references/actual-camera-5.2.png" alt="实机中距离人物与透视参考"><p>实机比例参考：距离 5.2，人物约占画高 17–18%。</p></div><div><img src="references/actual-camera-7.2.png" alt="实机远镜头人物比例参考"><p>实机远镜头参考：距离 7.2；人物不会为了交谈单独放大。</p></div></div>
<p class="scope">示意要遵守实机镜头，实机施工要对照示意的分层、顶面、厚度和光影。生成图是场景目标，不是人物素材或已经通过验收的施工图。</p><div class="index">{nav}</div></header>
<main>{''.join(parts)}</main><article class="appendix" id="spec">{design}</article><article class="appendix">{copy}</article><footer class="footer">场景使用内置图像生成工具；中文覆盖层为文档排布示意。原图、提示词、节点与检查记录均保存在 dev-design/flow-review。</footer></body></html>'''
(ROOT / 'flow.html').write_text(page, encoding='utf-8')
print(f'Built flow.html with {len(beats)} illustrated beats and full design appendix')
