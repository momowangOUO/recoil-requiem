"""Check the review's local links, twelve images and recorded source hashes."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib
import json

root = Path(__file__).resolve().parent
beats = json.loads((root / 'beats.json').read_text(encoding='utf-8-sig'))
assert len(beats) == 12 and len({b['id'] for b in beats}) == 12
class Links(HTMLParser):
    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in ('src', 'href') and not value.startswith(('#', 'data:', 'http')):
                assert (root / value).exists(), value
Links().feed((root / 'flow.html').read_text(encoding='utf-8'))
manifest = json.loads((root / 'SOURCE_MANIFEST.json').read_text(encoding='utf-8'))
assert len(manifest['adopted']) == 12
for item in manifest['adopted']:
    assert hashlib.sha256((root / item['file']).read_bytes()).hexdigest() == item['sha256'], item['file']
assert (root / '反冲挽歌_完整流程设计.pdf').stat().st_size > 0
print('PASS: 12 unique flow beats, all local HTML references, 12 image SHA256 hashes, PDF present')
