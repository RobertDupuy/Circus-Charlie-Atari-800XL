local m=manager.machine;local s=m.screens[':screen'];local out=assert(os.getenv('ARCADE_OUT'));local n=0
emu.register_frame_done(function()
 n=n+1
 if n%20==0 then s:snapshot(out..string.format('/screen-%05d.png',n))end
 if n>=1800 then m:exit()end
end)
