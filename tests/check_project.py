"""Dependency-free checks for references and the generated pixel art assets."""
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
paths = [ROOT / 'project.godot', *ROOT.glob('scenes/survival_*.tscn'),
         *ROOT.glob('scripts/survival/*.gd'), ROOT / 'scripts/pixel_ui.gd',
         ROOT / 'assets/fonts/game_theme.tres', ROOT / 'tests/survival_smoke.gd']
for source in paths:
    for resource in re.findall(r'res://([^"\s]+)', source.read_text(encoding='utf-8')):
        assert (ROOT / resource).is_file(), f'{source}: missing {resource}'
for name in ['grass', 'dirt', 'stone', 'wood', 'leaves', 'berry', 'plank', 'brick']:
    image = (ROOT / 'assets/fantasy' / (name + '.png')).read_bytes()
    assert image[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II', image[16:24]) == (16, 16), name
print(f'Checked resource paths in {len(paths)} files and eight 16×16 terrain sprites.')
