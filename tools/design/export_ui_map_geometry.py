"""Export scene-owned compact chapter data without rebuilding its geometry."""
import runpy
from pathlib import Path
runpy.run_path(str(Path(__file__).with_name("export_compact_monastery.py")),run_name="__main__")
