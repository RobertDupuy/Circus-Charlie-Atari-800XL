/* Headless NMOS 6502 + XEGS/SIC mapping. Does not simulate ANTIC DMA. */
#define CHIPS_IMPL
#include "../vendor/m6502.h"
#include <stdio.h>
#include <string.h>
static m6502_t cpu;
static uint64_t pins,total;
static uint64_t pc_cycles[65536];
static unsigned traced_pc;
static uint8_t memory[65536],rom[1048576];
static unsigned bank,banks,cart_type,cart_control;
static unsigned video_lines;
static uint64_t forced_nmi;
static uint32_t profile[128][8192];
static uint16_t labels[128][8192],current_guest;
static uint64_t guest_cycles[32768];
static FILE *trace;
static FILE *write_trace;
static unsigned write_address;
static uint8_t read_byte(uint16_t a){
    if(video_lines && a==0xd40b)return (total%(video_lines*114))/228;
    if(video_lines && a==0xd40f)return 0x40;
    if(cart_type==56){
        if(a>=0xd500&&a<=0xd51f)return cart_control;
        if(a>=0x8000&&a<0xa000&&(cart_control&0x20))return rom[bank*16384+(a&8191)];
        if(a>=0xa000&&a<0xc000&&!(cart_control&0x40))return rom[bank*16384+8192+(a&8191)];
    }else{
        if(a>=0x8000 && a<0xa000)return rom[bank*8192+(a&8191)];
        if(a>=0xa000 && a<0xc000)return rom[(banks-1)*8192+(a&8191)];
    }
    return memory[a];
}
static void write_byte(uint16_t a,uint8_t v){
    if(write_trace && a==write_address)fprintf(write_trace,"%llu %u\n",(unsigned long long)total,v);
    /* GTIA $D014 reads PAL identity and writes COLPM2. Preserve the host-set
       read value; a sprite colour write must not change the television type. */
    if(a==0xd014)return;
    if(cart_type==56){
        if(a>=0xd500&&a<=0xd51f){cart_control=v;bank=v&31;return;}
        if(a>=0x8000&&a<0xa000&&(cart_control&0x20))return;
        if(a>=0xa000&&a<0xc000&&!(cart_control&0x40))return;
    }else{
        if(a==0xd500){bank=v&(banks-1);return;}
        if(a>=0x8000&&a<0xc000)return;
    }
    memory[a]=v;
}
void at_prefetch(uint16_t pc){
    pins=M6502_SYNC|M6502_RW;
    M6502_SET_ADDR(pins,pc);
    M6502_SET_DATA(pins,read_byte(pc));
    m6502_set_pc(&cpu,pc);
}
int at_init(const char *path,uint16_t pc){
    FILE*f=fopen(path,"rb");if(!f)return 0;
    fseek(f,0,SEEK_END);long size=ftell(f)-16;rewind(f);
    uint8_t header[16];if(fread(header,1,16,f)!=16){fclose(f);return 0;}
    cart_type=header[4]<<24|header[5]<<16|header[6]<<8|header[7];cart_control=0;
    if(size<=0 || size>sizeof rom){fclose(f);return 0;}
    if(fread(rom,1,size,f)!=(size_t)size){fclose(f);return 0;}fclose(f);banks=size/8192;bank=0;
    memset(memory,0,sizeof memory);memset(profile,0,sizeof profile);memset(labels,0xff,sizeof labels);memset(guest_cycles,0,sizeof guest_cycles);current_guest=0;total=0;video_lines=0;memory[0xd014]=15;
    forced_nmi=0;
    m6502_desc_t desc={0};pins=m6502_init(&cpu,&desc);at_prefetch(pc);return 1;
}
int64_t at_run(uint16_t stop,unsigned limit){
    uint64_t initial=total;
    for(unsigned n=0;n<limit;n++){
        if(pins&M6502_SYNC){
            unsigned a=M6502_GET_ADDR(pins);
            if(a==stop && n>0)return total-initial;
            traced_pc=a;
            if(a>=0x8000&&a<0xc000)profile[a>=0xa000?banks-1:bank][a&8191]++;
            if(a>=0x8000&&a<0xc000){uint16_t g=labels[a>=0xa000?banks-1:bank][a&8191];if(g!=65535)current_guest=g;}
            if(trace)fprintf(trace,"%u %04X %02X %02X %02X %02X %02X\n",bank,a,m6502_a(&cpu),m6502_x(&cpu),m6502_y(&cpu),m6502_p(&cpu),m6502_s(&cpu));
        }
        if(video_lines){
            unsigned phase=total%(video_lines*114);
            if((memory[0xd40e]&0x40) && phase>=248*114 && phase<248*114+4)pins|=M6502_NMI;
            else pins&=~M6502_NMI;
        }
        if(forced_nmi){
            if(total>=forced_nmi && total<forced_nmi+4)pins|=M6502_NMI;
            else if(total>=forced_nmi+4){pins&=~M6502_NMI;forced_nmi=0;}
        }
        pins=m6502_tick(&cpu,pins);total++;pc_cycles[traced_pc]++;if(current_guest<32768)guest_cycles[current_guest]++;
        unsigned a=M6502_GET_ADDR(pins);
        if(pins&M6502_RW){M6502_SET_DATA(pins,read_byte(a));}
        else write_byte(a,M6502_GET_DATA(pins));
    }
    return -(int64_t)(total-initial);
}
uint8_t *at_memory(void){return memory;}
uint32_t *at_profile(void){return &profile[0][0];}
unsigned at_bank(void){return bank;}
unsigned at_cart_control(void){return cart_control;}
unsigned at_pc(void){return M6502_GET_ADDR(pins);}
uint64_t at_cycles(void){return total;}
void at_trace(const char *path){if(trace)fclose(trace);trace=path?fopen(path,"w"):NULL;}
void at_write_trace(const char *path,unsigned address){if(write_trace)fclose(write_trace);write_trace=path?fopen(path,"w"):NULL;write_address=address;}
int64_t at_call(uint16_t address,uint8_t a,uint8_t x,uint8_t y){
    memory[0x1fe]=0xff;memory[0x1ff]=1;
    m6502_set_a(&cpu,a);m6502_set_x(&cpu,x);m6502_set_y(&cpu,y);
    m6502_set_s(&cpu,0xfd);m6502_set_p(&cpu,0x20);at_prefetch(address);
    return at_run(0x200,100000000);
}
unsigned at_a(void){return m6502_a(&cpu);}
void at_video_timing(unsigned lines){video_lines=lines;}
void at_force_nmi(unsigned after_cycles){forced_nmi=total+after_cycles;}
void at_label(unsigned b,unsigned addr,unsigned guest){labels[b][addr&8191]=guest;}
uint64_t *at_guest_cycles(void){return guest_cycles;}
/* Branching input search preserves complete machine RAM and cartridge mapping.
   Snapshots are only test infrastructure; no game state is edited during replay. */
typedef struct { uint8_t ram[65536]; unsigned bank,control; } test_state;
static test_state test_slots[1024];
void at_save_slot(unsigned n){memcpy(test_slots[n].ram,memory,65536);test_slots[n].bank=bank;test_slots[n].control=cart_control;}
void at_restore_slot(unsigned n){memcpy(memory,test_slots[n].ram,65536);bank=test_slots[n].bank;cart_control=test_slots[n].control;forced_nmi=0;}
void at_clone_slot(unsigned to,unsigned from){memcpy(&test_slots[to],&test_slots[from],sizeof(test_state));}
int at_game_steps(unsigned entry,unsigned joy,unsigned fire,unsigned count){
 unsigned n=0;
 for(;n<count;n++){
  memory[0x612]=joy;memory[0x615]=(n==0?fire:0);
  if(at_call(entry,0,0,0)<=0)return -1;
  if(memory[0x600]!=2)return n+1;
 }
 return n;
}

uint64_t *at_pc_cycles(void){return pc_cycles;}
void at_clear_pc_cycles(void){memset(pc_cycles,0,sizeof pc_cycles);}
