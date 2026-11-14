"""Dependency-free resource, audio and scene checks for the island prototype."""
from pathlib import Path
import re
import wave
ROOT = Path(__file__).resolve().parents[1]
files = [ROOT / 'project.godot', *ROOT.glob('scenes/island*.tscn'),
         *ROOT.glob('scripts/island/*.gd'), ROOT / 'tests/island_smoke.gd',
         ROOT / 'assets/fonts/game_theme.tres']
for source in files:
    text = source.read_text(encoding='utf-8')
    for resource in re.findall(r'res://([^"\s]+)', text):
        assert (ROOT / resource).is_file(), f'{source}: missing {resource}'
for path in (ROOT / 'assets/island/audio').glob('*.wav'):
    with wave.open(str(path), 'rb') as audio:
        assert audio.getnchannels() == 1 and audio.getsampwidth() == 2
        assert audio.getnframes() > 0
assert 'run/main_scene="res://scenes/island_menu.tscn"' in (ROOT / 'project.godot').read_text()
print(f'Checked references in {len(files)} files and synthesized audio.')
