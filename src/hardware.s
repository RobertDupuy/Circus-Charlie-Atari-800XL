.proc start
 sei
 cld
 lda #0
 sta $D40E
 sta $D400
 sta $D20E
 sta $022F
 ldx #0
@clear:
 sta $0600,x
 sta $0700,x
 sta $0800,x
 sta $0900,x
 inx
 bne @clear
 lda #$0F
 sta console_prev
 lda #1
 sta fire_prev
 sta round
 lda #1
 sta players
 sta life_rule
 lda #2
 sta next_extra
 lda #3
 sta lives
 lda $D014
 and #15
 cmp #15
 beq @ntsc
 inc pal
@ntsc:
 lda #0
 sta $D01B
 sta $026F
 lda #2
 sta $D401
 lda #2
 sta $D01D
 sta $D20F
 lda #$55
 sta $D00C
 lda #<nmi
 sta $FFFA
 lda #>nmi
 sta $FFFB
 lda #<$BF00
 sta $FFFC
 lda #>$BF00
 sta $FFFD
 lda #<irq_return
 sta $FFFE
 lda #>irq_return
 sta $FFFF
 jsr mech_reset
 jsr audio_init
 jsr setup_lists
 lda #1
 sta need_stage
 sta request
 lda #$C0
 sta $D40E
 cli
@main:
 lda request
 beq @main
 lda ready
 bne @main
 lda #0
 sta request
 lda #1
 sta render_busy
 lda front
 eor #1
 sta back
 lda need_stage
 beq @tick
 jsr load_stage
@tick:
 jsr pcm_play
 lda gfx_logic_prepared
 bne @prepared
 jsr gfx_game_steps
@prepared:
 lda #0
 sta gfx_logic_prepared
 ; A scene transition can be requested by the final tick. Install its fonts
 ; before drawing, so the water platform codes never use the previous set.
 lda need_stage
 beq :+
 jsr load_stage
:
 jsr render_frame
 lda #0
 sta render_busy
 lda #1
 sta ready
 ; Use the idle part of the display interval for the next simulation batch.
 ; Rendering still waits for the atomic VBI flip before touching the buffer.
 lda mode
 cmp #2
 bne @main
 lda need_stage
 bne @main
 lda act
 beq @main
 jsr gfx_game_steps
 lda #1
 sta gfx_logic_prepared
 jmp @main
.endproc

.proc nmi
 pha
 lda $D40F
 sta $D40F
 bmi display
 txa
 pha
 tya
 pha
 jmp vbi
display:
 jmp gfx_dli_entry
.endproc
.segment "MECHANICS"
irq_return: rti
vbi_return:
 pla
 tay
 pla
 tax
 pla
 rti
.segment "CODE"

.proc vbi
 cld
 inc host_frames
 bne :+
 inc host_frames+1
:
 lda pcm_active
 jne pcm_vbi
 ldx player
 lda mode
 beq @port1
 cmp #5
 bne @port
@port1:
 ldx #0
@port:
 lda $D300
 cpx #0
 beq :+
 lsr
 lsr
 lsr
 lsr
:
 eor #$0F
 and #$0F
 sta input
 lda $D010,x
 eor #1
 and #1
 sta fire_held
 eor fire_prev
 and fire_held
 ora fire_latch
 sta fire_latch
 lda fire_held
 sta fire_prev
 lda $D01F
 and #7
 sta z_irq
 eor console_prev
 and console_prev
 tax
 and #2
 beq :+
 lda #1
 sta select_latch
:
 txa
 and #1
 beq :+
 lda mode
 bne :+
 lda #1
 sta start_latch
:
 txa
 and #4
 beq :+
 lda #1
 sta pause_latch
:
 lda z_irq
 sta console_prev
 jsr audio_control
 jsr audio_tick
 lda loading
 beq @normal
 lda #0
 sta $D400
 jmp vbi_return
@normal:
 lda phase
 eor #1
 sta phase
 bne display_frozen
 lda ready
 beq @late
 lda back
 sta front
 jsr gfx_font_table
 jsr pm_registers
 lda #0
 sta ready
 inc presented
 bne :+
 inc presented+1
:
 lda host_frames
 sec
 sbc last_present_host
 cmp max_interval
 bcc :+
 sta max_interval
:
 lda host_frames
 sta last_present_host
 jmp @request
@late:
 lda mode
 cmp #2
 bne @request
 lda render_busy
 beq @request
 lda missed
 ora missed+1
 bne :+
 jsr scene_id
 asl
 tax
 lda scene_clock
 sta $0780,x
 lda scene_clock+1
 sta $0781,x
:
 inc missed
 bne @request
 inc missed+1
@request:
 lda #1
 sta request
display_frozen:
@display:
 ldx front
 lda dl_high,x
 sta $D403
 lda #0
 sta $D402
 sta dli_index
 lda font_high,x
 sta active_font
 lda #$30
 sta $D409
 lda gfx_pf0+4
 sta $D016
 lda #$0E
 sta $D017
 lda #0
 sta $D018
 sta $D01A
 lda #$AA
 sta $D019
 lda #$3A
 ldy act
 cpy #1
 beq @no_top_players
 cpy #4
 beq @no_top_players
 cpy #5
 beq @no_top_players
 cpy #2
 bne @dma
 ldy water
 bne @dma
@no_top_players:
 lda #0
 sta $D01D
 sta $D00D
 sta $D00E
 sta $D00F
 sta $D010
 lda #$32
@dma:
 sta $D400
 lsr
 lsr
 and #2
 sta $D01D
 jmp vbi_return
pm_registers:
 lda pm_high,x
 sta $D407
 ; PM registers are staged per buffer with the same atomic flip as DMA.
 txa
 asl
 asl
 asl
 asl
 asl
 tax
 ldy #0
@pm:
 lda $0E00,x
 sta $D000,y
 lda $0E04,x
 sta $D004,y
 lda $0E08,x
 sta $D008,y
 lda $0E0C,x
 sta $D012,y
 inx
 iny
 cpy #4
 bne @pm
 rts
.endproc

.proc setup_lists
 ; 16 blank lines, two hires HUD rows, 22 ANTIC-4 rows, two footer rows.
 ldx #0
@copy:
 lda dl_template,x
 sta $6800,x
 sta $6900,x
 inx
 cpx #(dl_template_end-dl_template)
 bne @copy
 lda #$A0
 sta $6903
 lda #$3C
 sta $6908
 lda #$F0
 sta $691F
 lda #$69
 sta $6924
 rts
.endproc

.proc load_stage
 jsr setup_lists
 jsr apparatus_restore_common
 lda #1
 sta loading
 lda #1
 ldx act
 bne :+
 lda #4
:
 sta $D01B
 lda #0
 sta $D400
 ldx #2
 stx $D01D
 sta need_stage
 sta ready
 sta dirty_count
 sta dirty_count+1
 sta $DCA0
 sta $DCB0
 sta gfx_rect_count
 sta gfx_rect_count+1
 sta gfx_logic_prepared
 sta pal_acc
 sta height
 sta height+1
 sta jumping
 sta velocity
 sta jump_pixels
 sta scene_clock
 sta scene_clock+1
 sta camera
 sta camera+1
 sta world+1
 sta held_rope
 sta flying
 sta last_rope
 sta bounce_count
 sta tramp_index
 sta paused
 sta current_ball
 sta spring_hit
 sta pm_missile_min
 sta pm_missile_max
 sta water_pm_peak
 sta water_pm_overflow
 sta water_hits
 sta water_bags
 sta timer_div
 lda #60
 sta world
 lda #$00
 sta bonus
 lda #$50
 sta bonus+1
 lda #0
 ldx #15
@reset:
 sta passed,x
 dex
 bpl @reset
 ldx #7
@pmstate:
 sta pm_old_y,x
 sta pm_old_h,x
 dex
 bpl @pmstate
 lda #255
 sta hud_cached_act
 sta hud_cached_act+1
 sta ball_cached_phase
 sta ball_cached_phase+1
 ; Copy stage fonts into both RAM sets.
 lda act
 clc
 adc #$21
 sta $D500
 lda #$80
 sta z_src+1
 lda #0
 sta z_src
 sta z_dst
 lda #$40
 sta z_dst+1
 ldx #12
 jsr copy_pages
 lda #$80
 sta z_src+1
 lda #$4C
 sta z_dst+1
 ldx #12
 jsr copy_pages
 ; A full 1K includes unused trailing map bytes, never displayed.
 lda #$8C
 sta z_src+1
 lda #$34
 sta z_dst+1
 ldx #4
 jsr copy_pages
 lda water
 beq :+
 jsr load_water_background
:
 lda #$34
 sta z_src+1
 lda #$38
 sta z_dst+1
 ldx #4
 jsr copy_pages
 lda #$34
 sta z_src+1
 lda #$3C
 sta z_dst+1
 ldx #4
 jsr copy_pages
 ; PM graphics never retain data across a stage change.
 lda #$58
 sta z_dst+1
 ldx #16
 lda #0
 ldy #0
@clearpm:
 sta (z_dst),y
 iny
 bne @clearpm
 inc z_dst+1
 dex
 bne @clearpm
 ; Counts are prepared separately for each vertical character bank.
 lda act
 asl
 clc
 adc act
 tax
 ldy #0
@counts:
 lda $7DC0,x
 sta bg_count,y
 inx
 iny
 cpy #3
 bne @counts
 lda water
 beq :+
 ldx #2
@water_counts:
 lda $7DE0,x
 sta bg_count,x
 dex
 bpl @water_counts
:
 lda act
 cmp #3
 bne :+
 lda #98
 sta bg_count+2
 ; Four immutable ball fonts: no animation-font copy during gameplay.
 lda #$3F
 sta $D500
 lda #0
 sta z_src
 sta z_dst
 lda #$80
 sta z_src+1
 lda #$48
 sta z_dst+1
 ldx #4
 jsr copy_pages
 lda #$54
 sta z_dst+1
 ldx #4
 jsr copy_pages
 lda #$6C
 sta z_dst+1
 ldx #4
 jsr copy_pages
 lda #$70
 sta z_dst+1
 ldx #4
 jsr copy_pages
:
 ; Ball positions and other geometry are mutable game state.
 ldx #0
@balls:
 lda initial_ball_lo,x
 sta ball_lo,x
 lda initial_ball_hi,x
 sta ball_hi,x
 inx
 cpx #16
 bne @balls
 lda #<$0360
 sta stage_end
 lda #>$0360
 sta stage_end+1
 lda act
 cmp #3
 bne :+
 lda #$E0
 sta stage_end
 lda #2
 sta stage_end+1
:
 cmp #5
 bne :+
 lda #80
 sta world
:
 jsr gfx_stage_setup
 jsr stage_rules_entry
 lda mode
 beq @title
 cmp #7
 beq @title
 cmp #8
 beq @title
 lda #1
 sta mode
 lda #90
 sta mode_timer
@title:
 lda #<gfx_dli_entry
 ldx #>gfx_dli_entry
 ldy mode
 bne :+
 jsr title_init
 lda #<title_dli
 ldx #>title_dli
:
 sta nmi::display+1
 stx nmi::display+2
 lda #0
 sta loading
 rts
.endproc

.proc load_water_background
 lda #$23
 sta $D500
 lda #0
 sta z_src
 sta z_dst
 lda #$B0
 sta z_src+1
 lda #$44
 sta z_dst+1
 ldx #8
 jsr copy_pages
 lda #$B0
 sta z_src+1
 lda #$50
 sta z_dst+1
 ldx #8
 jsr copy_pages
 ; The complete water map is at B800; crowd glyph numbers are identical.
 lda #$34
 sta z_dst+1
 ldx #4
 jmp copy_pages
.endproc

.proc copy_pages
 ldy #0
@byte:
 lda (z_src),y
 sta (z_dst),y
 iny
 bne @byte
 inc z_src+1
 inc z_dst+1
 dex
 bne @byte
 rts
.endproc

