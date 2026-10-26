"""Actual Atari800 ANTIC/GTIA/DMA capture and timing probe, 64K Atari 800XL."""
import os,subprocess,time,sys,secrets,shutil
from pathlib import Path
from PIL import Image
from Xlib import X,XK,display,error
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
 def visible_window(self):
  for w in self.d.screen().root.query_tree().children:
   try:
    if 'Atari' in (w.get_wm_name() or '') and w.get_attributes().map_state==X.IsViewable:return w
   except error.BadWindow:continue
  return None
 def key(self,n,down):
  # SDL can replace its X window when leaving the monitor or changing mode.
  # Xvfb has no window manager to restore keyboard focus to the replacement.
  w=self.visible_window()
  if w is not None:
   try:self.w=w;w.set_input_focus(X.RevertToParent,X.CurrentTime)
   except error.BadWindow:pass
  xtest.fake_input(self.d,X.KeyPress if down else X.KeyRelease,self.d.keysym_to_keycode(XK.string_to_keysym(n)));self.d.sync()
 def tap(self,n):self.key(n,True);time.sleep(.06);self.key(n,False)
 def record(self):
  self.key('Alt_L',True);self.tap('v');self.key('Alt_L',False);time.sleep(.15);self.tap('Return');time.sleep(.1)
 def shot(self,path=None):
  for attempt in range(20):
   try:
    w=self.visible_window()
    if w is None:time.sleep(.02);continue
    self.w=w;g=w.get_geometry();r=w.get_image(0,0,g.width,g.height,X.ZPixmap,0xffffffff);break
   except error.BadWindow:time.sleep(.02)
  else:raise AssertionError(('Atari800 screenshot window unavailable',self.out))
  im=Image.frombytes('RGB',(g.width,g.height),r.data,'raw','BGRX')
  if path:im.save(self.out/path)
  return im
 def monitor(self,cmd,resume=True):
  # A fixed host delay can read an empty/stale dump under parallel test load.
  # Wait for the monitor's prompt both when entering and after the commands.
  path=Path(self.log.name)
  def wait_prompt(offset,seconds=5):
   until=time.monotonic()+seconds
   while ' PC=' not in path.read_bytes()[offset:].decode(errors='replace'):
    assert time.monotonic()<until,('Atari800 monitor did not respond',self.out)
    time.sleep(.01)
  offset=path.stat().st_size
  self.tap('F8')
  try:wait_prompt(offset,.5)
  except AssertionError:
   # SDL occasionally drops the entry key while replacing its window.
   # Retry only if the emulator is alive and still showing that window;
   # a process failure or an already-entered monitor must not be hidden.
   if ' PC=' not in path.read_bytes()[offset:].decode(errors='replace'):
    assert self.p.poll() is None,('Atari800 process stopped',self.out)
    if self.visible_window() is not None:self.tap('F8')
   wait_prompt(offset)
  offset=path.stat().st_size
  self.p.stdin.write(('\n'.join(cmd+['show'])+'\n').encode());self.p.stdin.flush()
  wait_prompt(offset)
  if resume:
   self.p.stdin.write(b'cont\n');self.p.stdin.flush();time.sleep(.15)
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
