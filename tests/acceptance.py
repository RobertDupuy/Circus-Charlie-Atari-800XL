"""Run the current CPU/pixel acceptance suite against one assembled cartridge.

Hardware raster, UI and PAL/NTSC replay checks are separate because they need
Atari800 and an X server. Earlier C64-baseline tests are historical fixtures.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib,json,subprocess,sys

ROOT=Path(__file__).resolve().parents[1]
TESTS=('mechanics_regression','arcade_lion','lion_retry','hoop_depth','hoop_passage',
       'bold_render','hud_cache','arcade_rules','water_regression',
       'interrupt_audio','arcade_audio','spring_cache','monkey_cache',
       'rope_cache','hero_compositors','stamp_rows','ranked_playthrough',
       'complete_campaign','completion_rules','dma_windows','every_tick_render','dma_registers','pcm_payload','act3_arcade','act3_prize')
out=ROOT/'build/acceptance';out.mkdir(exist_ok=True)
car=ROOT/'build/Circus-Charlie-SIC512.car'
digest=hashlib.sha256(car.read_bytes()).hexdigest()
# Compile once before workers start, so a clean checkout cannot race two
# writes to the shared CPU-test library.
subprocess.run(['cc','-shared','-O2','-fPIC',str(ROOT/'tests/atari_cpu.c'),
                '-o',str(ROOT/'build/atari_cpu.so')],check=True)

def check(name):
    result=subprocess.run([sys.executable,str(ROOT/f'tests/{name}.py')],
                          cwd=ROOT,capture_output=True,text=True)
    log=result.stdout+result.stderr
    (out/f'{name}.log').write_text(log)
    print(name, 'PASS' if result.returncode==0 else 'FAIL',flush=True)
    return dict(test=name,passed=result.returncode==0,output=log)

with ThreadPoolExecutor(max_workers=2) as pool:
    results=list(pool.map(check,TESTS))
assert hashlib.sha256(car.read_bytes()).hexdigest()==digest,'Cartridge changed during tests'
report=dict(car_sha256=digest,tests=results,passed=all(r['passed'] for r in results))
(out/'result.json').write_text(json.dumps(report,indent=2))
assert report['passed'],'See build/acceptance/*.log for failures'
