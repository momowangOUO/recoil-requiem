"""Uniform nearest normalization only; anatomy is authored in the saved source."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1] / "assets/characters/requiem"
source = Image.open(root / "smg_support_source_v5.png")
assert source.size == (1746, 901), "Review joint and crop anchors if source changes"
source.resize((round(source.width * .45), round(source.height * .45)),
              Image.Resampling.NEAREST).save(root / "smg_left_support_v5.png")
