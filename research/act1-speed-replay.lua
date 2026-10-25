-- Ordinary input only, fresh boot. No gameplay RAM writes or state loads.
local m=manager.machine;local r=m.devices[':maincpu'].spaces.program;local p=m.ioport.ports;local screen=m.screens[':screen']
local out=assert(os.getenv('ARCADE_OUT'));local seq={};for line in io.lines(assert(os.getenv('ARCADE_INPUT_FILE')))do seq[#seq+1]=tonumber(line)end
local force=os.getenv('FORCE_RIGHT')=='1';local interval=tonumber(os.getenv('SHOT_INTERVAL') or '1');local n=0
local f=assert(io.open(out..'/frames.bin','wb'));local csv=assert(io.open(out..'/frames.csv','w'))
csv:write('frame,input,game_state,act_state,jumping,hero_y,foot_y,world,frame_period\n')
local function b(a)return r:read_u8(a)end
emu.register_frame_done(function()
 n=n+1
 p[':SYSTEM']:field(1):set_value(n>=420 and n<432 and 1 or 0);p[':SYSTEM']:field(8):set_value(n>=480 and n<492 and 1 or 0)
 local v=seq[n] or 0;if force and n>=800 then v=(v&16)|2 end
 p[':P1']:field(1):set_value(v&1);p[':P1']:field(2):set_value((v>>1)&1);p[':P1']:field(16):set_value((v>>4)&1)
 if n==780 then print('PERIOD',tostring(screen.frame_period))end
 if n>=780 then
  local a={};for i=0x2000,0x3fff do a[#a+1]=string.char(b(i))end;f:write(table.concat(a))
  local w=b(0x2203)*256-b(0x2204)-b(0x2205)/256
  csv:write(string.format('%d,%d,%d,%d,%d,%d,%d,%.6f,%s\n',n,v,b(0x2006),b(0x2800),b(0x20b0),b(0x20b7),b(0x2644),w,tostring(screen.frame_period)))
 end
 if n>=780 and n%interval==0 then screen:snapshot(out..string.format('/screen-%05d.png',n))end
 if force and b(0x2800)==3 or n>=#seq+50 then f:close();csv:close();print('END',n,'actstate',b(0x2800),'game',b(0x2006));m:exit()end
end)
