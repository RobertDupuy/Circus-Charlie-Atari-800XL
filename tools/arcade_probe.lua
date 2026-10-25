-- Record actual arcade game sound commands and matching chip writes.
local m=manager.machine
local main=m.devices[":maincpu"].spaces["program"]
local sound=m.devices[":audiocpu"].spaces["program"]
local out=os.getenv("CIRCUS_PROBE_OUT")
local f=assert(io.open(out.."/mame-sound.csv","w"))
local frame=0
local chosen=tonumber(os.getenv("CIRCUS_PROBE_ACT") or "0")
local bus=0
local taps={}
_G.circus_taps=taps
taps[1]=main:install_write_tap(0x0800,0x0bff,"commands",function(a,v)
 f:write(string.format("%.9f,command,%02X,%04X\n",m.time:as_double(),v,m.devices[":maincpu"].state["PC"].value))
end)
taps[2]=sound:install_write_tap(0xa000,0xbfff,"psg",function(a,v)
 local r=a&7
 if r==0 then bus=v
 elseif r==1 or r==2 then f:write(string.format("%.9f,sn%d,%02X\n",m.time:as_double(),r,bus))
 elseif r==3 then f:write(string.format("%.9f,dac,%02X\n",m.time:as_double(),v)) end
end)
for tag,p in pairs(m.ioport.ports) do for name,field in pairs(p.fields) do print("INPUT",tag,name,field.mask) end end
emu.register_frame_done(function()
 frame=frame+1
 local p=m.ioport.ports
 p[":SYSTEM"]:field(1):set_value(frame>=420 and frame<432 and 1 or 0)
 p[":SYSTEM"]:field(8):set_value(frame>=480 and frame<492 and 1 or 0)
 local cursor=frame>=600 and frame<600+chosen*12 and frame%12<4
 p[":P1"]:field(2):set_value((cursor or frame>780) and 1 or 0)
 p[":P1"]:field(16):set_value((frame>=690 and frame<698 or frame>780 and frame%80<2) and 1 or 0)
 if frame%120==0 then m.screens[":screen"]:snapshot(out..string.format("/frame-%04d.png",frame)) end
 if frame==1200 then f:close();m:exit() end
end)
