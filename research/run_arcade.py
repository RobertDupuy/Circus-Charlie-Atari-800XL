import os,sys,subprocess,shutil
from pathlib import Path
R=Path(__file__).resolve().parents[1]
name=sys.argv[1] if len(sys.argv)>1 else 'inspect'
out=R/'build'/'arcade'/name;out.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env.update(LD_LIBRARY_PATH=os.environ.get('MAME_LIBRARY_PATH',os.environ.get('LD_LIBRARY_PATH','/workspace/scratch/a6f3c9ff8fd9/qa-tools/usr/lib/x86_64-linux-gnu:/workspace/scratch/a6f3c9ff8fd9/toolchain/root/usr/lib/x86_64-linux-gnu')),SDL_VIDEODRIVER='dummy',SDL_AUDIODRIVER='dummy',ARCADE_OUT=str(out),ARCADE_SCENARIO=os.environ.get('ARCADE_SCENARIO',name))
args=[os.environ.get('MAME_BIN',shutil.which('mame') or '/workspace/scratch/a6f3c9ff8fd9/qa-tools/mame'),'circusc','-rompath',os.environ.get('MAME_ROM_DIR','/workspace/scratch/e2bf033955e3/circus-study/inputs/arcade'),'-video','none','-sound','none','-nothrottle','-skip_gameinfo','-autoboot_delay','0','-autoboot_script',str(R/'research'/os.environ.get('ARCADE_SCRIPT','arcade-replay.lua')),'-cfg_directory',str(out/'cfg'),'-nvram_directory',str(out/'nvram'),'-state_directory',str(out/'sta'),'-seconds_to_run',os.environ.get('ARCADE_SECONDS','400')]
with (out/'mame.log').open('w') as f: p=subprocess.run(args,env=env,stdout=f,stderr=f)
print(name,p.returncode,(out/'mame.log').read_text()[-4000:])
