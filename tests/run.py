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

# 0.37.50 (REQUESTS 96): the two species use their pre-evolution's vanilla
# party icon (ICON_BIRD / ICON_GHOST); the unattributed icon PNGs must not ship.
for species in ('mismagius','honchkrow'):
    assert not (mod/'assets'/f'{species}_icon.png').exists(),f'{species}: icon PNG must stay removed'
print('Both species use vanilla party icons; no icon PNGs ship.')
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
