"""Inspect this delivery's native Godot MJPEG recordings without rewriting them."""
from pathlib import Path
import hashlib, io, json, struct, sys
from PIL import Image, ImageDraw, ImageFont

root = Path(sys.argv[1]).resolve()
pack_sha = hashlib.sha256((Path(__file__).resolve().parents[2]/'builds/windows/RecoilRequiem.exe').read_bytes()).hexdigest()
out = root/('motion-review-'+pack_sha[:12])
out.mkdir(exist_ok=True)
font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf',14)
audit = {}
for name in ['replay_lift','replay_maintenance','camera-motion']:
    path = root/(name+'.avi')
    physical = path.stat().st_size
    frames, header = [], {}
    with path.open('rb') as stream:
        kind, length, format = struct.unpack('<4sI4s',stream.read(12))
        assert kind==b'RIFF' and format==b'AVI '
        delta = physical-(length+8)
        # Godot 4.7.2 writes a RIFF size 70 bytes short; keep original bytes.
        assert delta in [0,70], (name,delta)
        def scan(start,end):
            position = start
            while position+8<=end:
                stream.seek(position)
                tag,size = struct.unpack('<4sI',stream.read(8))
                data,finish = position+8,position+8+size
                assert finish<=end,(name,tag,position,size,end)
                if tag==b'LIST':
                    assert size>=4
                    scan(data+4,finish)
                elif tag==b'avih':
                    raw=stream.read(size)
                    header.update(frames=struct.unpack_from('<I',raw,16)[0],width=struct.unpack_from('<I',raw,32)[0],height=struct.unpack_from('<I',raw,36)[0])
                elif tag[:2].isdigit() and tag[2:] in [b'dc',b'db']:
                    stream.seek(data); assert stream.read(2)==b'\xff\xd8'
                    stream.seek(finish-2); assert stream.read(2)==b'\xff\xd9'
                    frames.append((data,size))
                position = finish+(size&1)
        scan(12,physical)
        assert len(frames)==header['frames'] and (header['width'],header['height'])==(1280,720)
        if name=='camera-motion':
            assert len(frames)>=1440
            samples=[min(len(frames)-1, slice*270+32+tick) for slice in range(6) for tick in [29,79,85,106,120,165,190,239]]
        else:
            rows=[json.loads(line) for line in (root/(name+'.jsonl')).read_text(encoding='utf-8-sig').splitlines()]
            assert max(row['frame'] for row in rows)<len(frames)
            groups={}
            for row in rows: groups.setdefault(row['phase'],[]).append(row)
            samples=sorted(set(min(len(frames)-1,group[int((len(group)-1)*t)]['frame']+2) for group in groups.values() for t in [.2,.8]))
            for previous,row in zip(rows,rows[1:]):
                if row['deaths']>previous['deaths']:
                    samples.extend(max(0,min(len(frames)-1,row['frame']+offset)) for offset in [-6,2,14])
            samples=sorted(set(samples))
        sheet=Image.new('RGB',(1280,204*((len(samples)+3)//4)),(20,24,36))
        draw=ImageDraw.Draw(sheet)
        for item,index in enumerate(samples):
            offset,size=frames[index]; stream.seek(offset); raw=stream.read(size)
            image=Image.open(io.BytesIO(raw)); image.load(); assert image.size==(1280,720)
            (out/f'{name}_{index:05}.jpg').write_bytes(raw)
            x,y=(item%4)*320,(item//4)*204
            draw.text((x+4,y+3),f'{name} f{index} {index/60:.2f}s',font=font,fill='#e0d5bd')
            sheet.paste(image.resize((320,180),Image.Resampling.NEAREST),(x,y+24))
        sheet.save(out/(name+'-contact.png'))
        audit[name]={**header,'fps':60,'seconds':len(frames)/60,'riff_length_delta':delta,'pack_sha256':pack_sha,'sample_directory':out.name,'all_jpeg_chunk_boundaries_checked':True,'sample_frames':samples,'samples':'Original JPEG payloads; contact sheets are labelled nearest previews.'}
(root/'movie-frame-audit.json').write_text(json.dumps(audit,indent=2),encoding='utf8')
print('All three recordings have complete JPEG chunks and correct frame counts; original payload samples saved.')
