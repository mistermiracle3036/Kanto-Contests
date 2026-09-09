"""Run: python tests/run.py --engine PATH --lua PATH [--cache PATH]."""
from pathlib import Path
import argparse, subprocess, sys, tempfile, time
from PIL import Image
p=argparse.ArgumentParser()
p.add_argument('--engine',required=True,type=Path)
p.add_argument('--lua',default='luajit')
p.add_argument('--cache',type=Path)
p.add_argument('--game',default='crystal')
a=p.parse_args()
mod=Path(__file__).resolve().parents[1]
engine=a.engine.resolve()

# PartyMenu loads icon PNGs directly: native OBJ shade zero must be transparent.
for species in ('mismagius','honchkrow'):
    icon=Image.open(mod/'assets'/f'{species}_icon.png').convert('RGBA')
    assert icon.size==(16,32),f'{species}: preserve both native icon frames'
    for red,green,blue,alpha in icon.getdata():
        assert red==green==blue and red in (0,85,170,255),f'{species}: invalid icon shade'
        assert alpha==(0 if red==255 else 255),f'{species}: incorrect icon transparency'
print('Both species icons use native transparent shade zero.')
def run(args,cwd=engine,retry=False):
    try:
        subprocess.run([str(x) for x in args],cwd=cwd,check=True)
    except subprocess.CalledProcessError:
        # The loader harness is flaky when suites run back-to-back (it has
        # failed and then passed the same suite seconds apart, repeatedly).
        # One paused retry tells a flake from a failure.
        if not retry: raise
        print('...retrying once after a pause'); time.sleep(3)
        subprocess.run([str(x) for x in args],cwd=cwd,check=True)
with tempfile.TemporaryDirectory() as td:
    for f in mod.glob('*.lua'):
        run([a.lua,'-b',f,Path(td)/'check.luac'])
run([sys.executable,engine/'tools/modkit.py','lint',mod])
run([sys.executable,mod/'tools/check_sprites.py',mod/'assets'])
run([sys.executable,mod/'tests/check_dialogue.py',mod/'main.lua',mod/'contest_screen.lua',mod/'dusk_challenge.lua',mod/'cast_lines.lua'])
for name in ['engine_test.lua','contest_screen_test.lua','gen_gate_test.lua']:
    run([a.lua,mod/'tests'/name,mod],retry=True)
if a.cache:
    for name,extra in [('release_behavior_test.lua',[]),('species_off_test.lua',['off'])]:
        run([a.lua,mod/'tests'/name,mod,a.cache.resolve(),a.game,*extra],retry=True)
else:
    print('ROM-backed integration tests not run: pass --cache for imported game data.')
print('Requested release checks passed.')
