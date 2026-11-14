"""Static resource and audio validation; does not replace Godot runtime tests."""
from pathlib import Path
import re
import wave
import struct
root = Path(__file__).resolve().parents[2]
files = [root / 'project.godot', *root.glob('scripts/affinix/*.gd'),
         *root.glob('scenes/affinix/*.tscn'), root / 'assets/fonts/game_theme.tres',
         root / 'tests/affinix/smoke.gd', root / 'tests/affinix/visual_smoke.gd']
for source in files:
    text = source.read_text(encoding='utf-8')
    for path in re.findall(r'res://([^"\s]+)', text):
        assert (root / path).is_file(), f'{source.relative_to(root)}: missing {path}'
for path in (root / 'assets/affinix').glob('*.wav'):
    with wave.open(str(path), 'rb') as audio:
        assert audio.getnchannels() == 1
        assert audio.getframerate() > 0 and audio.getnframes() > 0
for name, size in {'terrain_v2.png': (320, 144), 'lake_edges_v2.png': (80, 8),
                   'chill_boy_states.png': (192, 896)}.items():
    data = (root / 'assets/affinix' / name).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II', data[16:24]) == size, f'{name}: unexpected atlas dimensions'
assert 'run/main_scene="res://scenes/affinix/menu.tscn"' in (root / 'project.godot').read_text()
print(f'{len(files)} source files: resource references and WAV headers are valid.')
