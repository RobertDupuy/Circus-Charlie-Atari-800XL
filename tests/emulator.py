"""Actual Atari800 ANTIC/GTIA/DMA capture and timing probe, 64K Atari 800XL."""
import os,subprocess,time,sys,secrets,shutil
from pathlib import Path
from PIL import Image
from Xlib import X,XK,display
from Xlib.ext import xtest
R=Path(__file__).resolve().parents[1]
T=Path(os.environ.get('ATARI800_ROOT','/usr'))
class Atari:
 def __init__(self,standard='ntsc',name='probe',sound=False,cart=None):
  self.out=R/'build'/name;self.out.mkdir(exist_ok=True)
  (self.out/'capture.avi').unlink(missing_ok=True)
  self.env=os.environ.copy();n=1000+secrets.randbelow(4000)
  while Path(f'/tmp/.X{n}-lock').exists():n=1000+secrets.randbelow(4000)
  self.env.update(LD_LIBRARY_PATH=str(T/'lib/x86_64-linux-gnu'),DISPLAY=f'127.0.0.1:{n}',SDL_VIDEODRIVER='x11',SDL_AUDIODRIVER=os.environ.get('CIRCUS_AUDIO_DRIVER','dummy'),SDL_DISKAUDIOFILE='/dev/null')
  self.xlog=(self.out/'xvfb.log').open('w');self.log=(self.out/f'{standard}.log').open('w')
  self.xv=subprocess.Popen([str(T/'bin/Xvfb'),f':{n}','-screen','0','900x700x24','-ac','-nolisten','unix','-nolisten','local','-listen','tcp'],env=self.env,stdout=self.xlog,stderr=self.xlog)
  time.sleep(.6);self.d=display.Display(self.env['DISPLAY'])
  # Flush monitor lines immediately so live assertions never read stale dumps.
  line_buffer=['stdbuf','-oL'] if shutil.which('stdbuf') else []
  self.p=subprocess.Popen(line_buffer+[str(T/'bin/atari800'),'-config',str(R/'tools/atari800.cfg'),'-xl','-xl-rev','altirra','-nobasic','-'+standard,('-sound' if sound else '-nosound'),'-aname',str(self.out/'audio.wav'),'-vcodec','zmbv','-acodec','pcm','-vname',str(self.out/'capture.avi'),'-no-showstats','-windowed','-no-video-accel','-stretch','2','-cart',str(cart or R/'build/Circus-Charlie-SIC512.car')],env=self.env,stdin=subprocess.PIPE,stdout=self.log,stderr=self.log)
  time.sleep(2)
  self.w=next(w for w in self.d.screen().root.query_tree().children if 'Atari' in (w.get_wm_name() or ''))
  self.w.set_input_focus(X.RevertToParent,X.CurrentTime);self.d.sync()
 def key(self,n,down):xtest.fake_input(self.d,X.KeyPress if down else X.KeyRelease,self.d.keysym_to_keycode(XK.string_to_keysym(n)));self.d.sync()
 def tap(self,n):self.key(n,True);time.sleep(.06);self.key(n,False)
 def record(self):
  self.key('Alt_L',True);self.tap('v');self.key('Alt_L',False);time.sleep(.15);self.tap('Return');time.sleep(.1)
 def shot(self,path=None):
  self.w=next(w for w in self.d.screen().root.query_tree().children if 'Atari' in (w.get_wm_name() or ''))
  g=self.w.get_geometry();r=self.w.get_image(0,0,g.width,g.height,X.ZPixmap,0xffffffff)
  im=Image.frombytes('RGB',(g.width,g.height),r.data,'raw','BGRX')
  if path:im.save(self.out/path)
  return im
 def monitor(self,cmd,resume=True):
  self.tap('F8');time.sleep(.08)
  self.p.stdin.write(('\n'.join(cmd+(['cont'] if resume else []))+'\n').encode());self.p.stdin.flush();time.sleep(.08)
 def close(self):
  if self.p.poll() is None:
   self.p.terminate()
   try:self.p.wait(timeout=1)
   except subprocess.TimeoutExpired:self.p.kill();self.p.wait(timeout=3)
  self.d.close();self.xv.terminate();self.xv.wait(timeout=5);self.log.close();self.xlog.close()
if __name__=='__main__':
 for standard in ['ntsc','pal']:
  a=Atari(standard)
  try:
   a.shot(f'{standard}-title.png');a.monitor(['m 0600','m 0680'])
   for act in range(6):
    a.monitor([f'c 0600 00 {act:02x}','c 0639 01']);time.sleep(.5)
    a.monitor(['c 0600 02','c 0608 00 00','c 068c 00']);time.sleep(1.4)
    a.shot(f'{standard}-act-{act+1}.png')
    a.monitor(['m 0600','m 0620','m 0680'])
  finally:a.close()
