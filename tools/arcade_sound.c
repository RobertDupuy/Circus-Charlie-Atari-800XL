/* Offline Circus Charlie audio-CPU oracle. Never runs on the Atari.
 * The map and clock follow MAME's BSD-licensed circusc.cpp driver.
 * z80.h carries its own retained zlib/libpng license. */
#define CHIPS_IMPL
#include "../vendor/z80.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static z80_t cpu;
static uint64_t pins,cycles;
static uint8_t rom[16384],ram[1024],command,sn_bus,irq;
static uint16_t regs[16];
static uint8_t latched[2],dac;
static FILE *logfile;
static void sn_write(unsigned chip,uint8_t v){
 unsigned r;
 if(v&128){r=latched[chip]=(v>>4)&7;regs[chip*8+r]=(regs[chip*8+r]&0x3f0)|(v&15);}
 else {r=latched[chip];if(r&1)regs[chip*8+r]=v&15;
  else if(r==6)regs[chip*8+r]=v&7;
  else regs[chip*8+r]=(regs[chip*8+r]&15)|((v&63)<<4);}
 if(logfile)fprintf(logfile,"%llu,%u,%u\n",(unsigned long long)cycles,chip,v);
}
void as_init(const char *path){
 FILE*f=fopen(path,"rb");if(!f)abort();if(fread(rom,1,sizeof rom,f)!=sizeof rom)abort();fclose(f);
 memset(ram,0,sizeof ram);memset(regs,0,sizeof regs);memset(latched,0,sizeof latched);
 for(int i=1;i<16;i+=2)regs[i]=15;
 cycles=0;command=sn_bus=irq=dac=0;pins=z80_init(&cpu);
}
void as_command(uint8_t v){command=v;irq=1;}
void as_step(unsigned count){
 for(unsigned i=0;i<count;i++){
  if(irq)pins|=Z80_INT;else pins&=~Z80_INT;
  pins=z80_tick(&cpu,pins);cycles++;
  if((pins&(Z80_IORQ|Z80_M1))==(Z80_IORQ|Z80_M1)){irq=0;Z80_SET_DATA(pins,255);}
  if(pins&Z80_MREQ){
   unsigned a=Z80_GET_ADDR(pins);uint8_t v=Z80_GET_DATA(pins);
   if(pins&Z80_RD){
    v=a<0x4000?rom[a]:a<0x6000?ram[a&1023]:a<0x8000?command:a<0xa000?(cycles>>9)&0x1e:255;
    Z80_SET_DATA(pins,v);
   }else if(pins&Z80_WR){
    if(a>=0x4000&&a<0x6000)ram[a&1023]=v;
    else if(a>=0xa000&&a<0xc000){
     switch(a&7){case 0:sn_bus=v;break;case 1:sn_write(0,sn_bus);break;
      case 2:sn_write(1,sn_bus);break;case 3:dac=v;if(logfile)fprintf(logfile,"%llu,2,%u\n",(unsigned long long)cycles,v);break;}
    }
   }
  }
 }
}
unsigned as_frame(void){
 uint64_t before=cycles;
 do{as_step(1);}while(!((pins&(Z80_MREQ|Z80_RD|Z80_M1))==(Z80_MREQ|Z80_RD|Z80_M1)&&Z80_GET_ADDR(pins)==0x135)&&cycles-before<10000000);
 return (unsigned)(cycles-before);
}
uint16_t *as_registers(void){return regs;}
uint8_t *as_ram(void){return ram;}
unsigned as_pc(void){return cpu.pc;}
unsigned as_dac(void){return dac;}
uint64_t as_cycles(void){return cycles;}
void as_log(const char *path){if(logfile)fclose(logfile);logfile=path?fopen(path,"w"):NULL;}
