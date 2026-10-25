-- Ordinary joystick/fire arcade replays. No gameplay RAM writes.
local m=manager.machine;local cpu=m.devices[':maincpu'];local ram=cpu.spaces.program
local out=assert(os.getenv('ARCADE_OUT'));local scenario=os.getenv('ARCADE_SCENARIO')
local act=tonumber(scenario:match('act(%d)')) or 0
local n=0;local p=m.ioport.ports;local screen=m.screens[':screen']
local f=assert(io.open(out..'/frames.bin','wb'));local csv=assert(io.open(out..'/frames.csv','w'));csv:setvbuf('no');csv:write('frame,right,left,fire,act,game_state,stage_state\n')
local function b(a) return ram:read_u8(a) end
local function u16(a) return b(a)*256+b(a+1) end
local lastjump=false;local lastclear=0;local started=false
local arc={0};local y=136;local v=0x420;local jumping=1
for i=1,64 do
 if jumping==1 then
  v=v-(math.floor(v/256)==0 and 64 or 32)
  if v<0 then v=0;jumping=2 end
 end
 if jumping==2 then v=v+(math.floor(v/256)==0 and 64 or 32);y=y+math.floor(v/256)
 else y=y-math.floor(v/256) end
 arc[#arc+1]=136-y
 if y>=136 and i>20 then break end
end
local function monkey_play()
 local right=true;local fire=false
 if b(0x2407)~=0 then return right,false end
 local x=b(0x2406);local monkeys={}
 for a=0x2440,0x25c0,0x40 do if b(a)==1 and b(a+2)~=2 and b(a+6)>10 then
  monkeys[#monkeys+1]={x=b(a+6),y=b(a+4),pink=b(a+0x30)~=0,jump=b(a+2)==8,v=u16(a+0x17),fall=b(a+7)~=0}
 end end
 local function safe(delay,run)
  for t=0,delay+#arc-1 do
   local h=t<delay and 0 or arc[math.min(#arc,t-delay+1)]
   for _,k in ipairs(monkeys) do
    local speed=k.pink and (run and 2.5 or 1.5) or (run and 1.25 or .75)
    local mx=k.x-speed*t;local my=136
    if k.jump then my=k.y end
    local dx=math.abs((mx+13)-(x+19));local dy=math.abs(my-(136-h))
    if dx<13 and dy<16 and dx+dy<20 then return false end
   end
  end
  return true
 end
 local danger=false
 for _,k in ipairs(monkeys) do if k.x>x and k.x-x<95 then danger=true end end
 if danger then
  local first=nil;local last=nil
  for d=0,70 do if safe(d,true) then first=first or d;last=d end end
  if first then fire=first==0 and last<=7
  else right=false;fire=safe(0,false) end
 end
 if b(0x2203)==0xf8 and x>=125 and x<160 then fire=true end
 return right,fire
end
local function ball_play()
 local x=b(0x2406);local fire=false;local right=true
 if b(0x2407)==0 then
  local nearest=999
  for a=0x2480,0x2540,0x40 do
   local dx=b(a+6)-x
   if b(a)==1 and dx>0 then nearest=math.min(nearest,dx) end
   if b(a)==1 and dx>=76 and dx<=108 then fire=true end
  end
  if b(0x2203)==0xf8 and x>=120 and x<150 then fire=true;right=true end
 end
 return right,fire
end
emu.register_frame_done(function()
 n=n+1
 p[':SYSTEM']:field(1):set_value(n>=420 and n<432 and 1 or 0)
 p[':SYSTEM']:field(8):set_value(n>=480 and n<492 and 1 or 0)
 local right=false;local left=false;local fire=n>=720 and n<728
 for i=0,act-1 do if n>=560+i*25 and n<568+i*25 then right=true end end
 if n>=800 and b(0x2003)==2 and b(0x2006)==3 then
  started=true
  if act==1 then right,fire=monkey_play()
  elseif act==3 then right,fire=ball_play()
  elseif act==2 then right=true
  elseif act==4 then right=true
  elseif act==5 then right=true;fire=n%120==0 end
 end
 p[':P1']:field(1):set_value(left and 1 or 0)
 p[':P1']:field(2):set_value(right and 1 or 0)
 p[':P1']:field(16):set_value(fire and 1 or 0)
 if n>=500 then
  local a={};for i=0x2000,0x3fff do a[#a+1]=string.char(b(i)) end;f:write(table.concat(a));csv:write(string.format('%d,%d,%d,%d,%d,%d,%d\n',n,right and 1 or 0,left and 1 or 0,fire and 1 or 0,b(0x2201),b(0x2006),b(0x2402)))
 end
 if n>=780 and n%30==0 then screen:snapshot(out..string.format('/screen-%05d.png',n)) end
 if started and b(0x2006)==4 and lastclear==0 then lastclear=n;print('CLEAR',n,b(0x2201));screen:snapshot(out..'/clear.png') end
 if lastclear>0 and n>=lastclear+500 or n>=6000 then f:close();m:exit() end
end)
