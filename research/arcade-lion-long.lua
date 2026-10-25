local m=manager.machine
local cpu=m.devices[":maincpu"]
local ram=cpu.spaces.program
local out=assert(os.getenv('ARCADE_OUT'))
local scenario=os.getenv('ARCADE_SCENARIO') or 'right'
local n,scroll,bank=0,0,0
arcade_taps={}
arcade_taps[1]=ram:install_write_tap(0x1c00,0x1fff,'scroll',function(a,d) scroll=d end)
arcade_taps[2]=ram:install_write_tap(5,5,'spritebank',function(a,d) bank=d&1 end)
local data=assert(io.open(out..'/frames.bin','wb'))
data:setvbuf('no')
local events=assert(io.open(out..'/events.csv','w'));events:setvbuf('no');events:write('frame,scroll,bank,pc\n')
local inputs=assert(io.open(out..'/inputs.txt','w'));inputs:setvbuf('no')
local function dump()
 local t={};for a=0x2000,0x3fff do t[#t+1]=string.char(ram:read_u8(a)) end
 data:write(table.concat(t));events:write(string.format('%d,%d,%d,%04x\n',n,scroll,bank,cpu.state.PC.value))
end
emu.register_frame_done(function()
 n=n+1
 local p=m.ioport.ports
 p[':SYSTEM']:field(1):set_value(n>=420 and n<432 and 1 or 0)
 p[':SYSTEM']:field(8):set_value(n>=480 and n<492 and 1 or 0)
 local fire=(n>=690 and n<698)
 local right=n>=800 and scenario~='neutral' and scenario~='jump' and scenario~='held'
 if scenario=='play' and n>=800 then
  local rings,pots={},{}
  for a=0x26d0,0x2760,0x30 do if ram:read_u8(a)~=0 then rings[#rings+1]={x=ram:read_u8(a+6)+ram:read_u8(a+7)/256,low=a==0x2760} end end
  for a=0x24b0,0x2530,0x40 do if ram:read_u8(a)==2 then pots[#pots+1]=ram:read_u8(a+6)+ram:read_u8(a+7)/256 end end
  local world=ram:read_u8(0x2203)*256-ram:read_u8(0x2204)-ram:read_u8(0x2205)/256
  local function safe(t,h,speed)
   for _,r in ipairs(rings) do local x=math.floor(r.x-(speed+0.5)*t);local d=math.abs(x-64);local v=208-h+(r.low and 16 or 0)-182;if d<14 and v>=0 and v+d<=28 then return false end end
   for _,x0 in ipairs(pots) do local x=math.floor(x0-speed*t);if x>=41 and x<87 and h<=10 then return false end end
   return true
  end
  if ram:read_u8(0x20b0)==0 then
   local danger=false;for t=0,85 do if not safe(t,0,1.5) then danger=true;break end end
   if world>=1680 then fire=true
   elseif danger then
    local choice=nil;local first=nil
    for delay=0,65 do
     local ok=true
     for t=0,delay+64 do
      local k=t-delay-2;local h=(k>0 and k<63) and math.ceil(3.5*k-28/512*k*(k+1)) or 0
      if not safe(math.max(0,t-1),math.max(0,h-1),1.5) then ok=false;break end
     end
     if ok then choice=delay;first=first or delay end
    end
    if choice then fire=first==0 and choice<=8
    else
     local ok=true;for t=0,64 do local h=t<63 and math.ceil(3.5*t-28/512*t*(t+1)) or 0;if not safe(t,h,0) then ok=false;break end end
     right=false;fire=ok
    end
   end
  end
 end
 if scenario=='jump' then fire=fire or (n>=820 and n<821)
 elseif scenario=='held' then fire=fire or n>=820
 elseif scenario=='runjump' then fire=fire or (n>=820 and n<821)
 end
 p[':P1']:field(16):set_value(fire and 1 or 0)
 p[':P1']:field(2):set_value(right and 1 or 0)
 inputs:write(((right and 2 or 0)+(fire and 16 or 0))..'\n')
 if n==700 then
  print('DASM',pcall(function() m.debugger:command('dasm '..out..'/program.asm,0x6000,0xa000') end))
  print('PERIOD',m.screens[':screen'].frame_period)
 end
 if n==810 and scenario~='play' then m.debugger:command('trace '..out..'/trace.txt,0,noloop') end
 if n==825 and scenario~='play' then m.debugger:command('trace off,0') end
 if n>=500 then dump() end
 if scenario=='sweep' and n>=800 and ram:read_u8(0x2800)==1 then
  ram:write_u8(0x2644,153);ram:write_u8(0x20b7,161)
 end
 if n>=600 and n%30==0 then m.screens[':screen']:snapshot(out..string.format('/screen-%04d.png',n)) end
 if n==1498 then data:flush();events:flush() end
 if n==((scenario=='play' or scenario=='sweep') and 4000 or 1500) then m:exit() end
end)
