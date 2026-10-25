local m=manager.machine;local r=m.devices[':maincpu'].spaces.program;local p=m.ioport.ports;local screen=m.screens[':screen'];local out=assert(os.getenv('ARCADE_OUT'));local file=assert(os.getenv('ARCADE_INPUT_FILE'));local seq={};for line in io.lines(file)do seq[#seq+1]=tonumber(line)end
local n=0;local f=assert(io.open(out..'/frames.bin','wb'));local csv=assert(io.open(out..'/frames.csv','w'));csv:write('frame,act,state,hero_state\n')
local function b(a)return r:read_u8(a)end
emu.register_frame_done(function()
 n=n+1;p[':SYSTEM']:field(1):set_value(n>=420 and n<432 and 1 or 0);p[':SYSTEM']:field(8):set_value(n>=480 and n<492 and 1 or 0)
 local v=seq[n] or 0;p[':P1']:field(1):set_value(v%2);p[':P1']:field(2):set_value(math.floor(v/2)%2);p[':P1']:field(16):set_value(math.floor(v/16)%2)
 if n>=780 then local a={};for i=0x2000,0x3fff do a[#a+1]=string.char(b(i))end;f:write(table.concat(a));csv:write(string.format('%d,%d,%d,%d\n',n,b(0x2201),b(0x2006),b(0x2402)))end
 if n>=780 and n%6==0 then screen:snapshot(out..string.format('/screen-%05d.png',n))end
 if n==#seq then print('END INPUT',n,'world',((65536-(b(0x2203)*256+b(0x2204)))%65536)+b(0x2406),'state',b(0x2402));m:save(out..'/verified.sta')end
 if n>=#seq+400 then f:close();csv:close();m:exit()end
end)
