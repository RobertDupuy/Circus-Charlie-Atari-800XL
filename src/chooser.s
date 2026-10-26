; Optional arcade chooser. No alternate selector is compiled when disabled.
; ROM bank 27: all menu rendering and input work is outside the gameplay loop.
.segment "CODE"
.proc chooser_load_entry
 lda #$3B
 sta $D500
 jmp chooser_load
.endproc
.proc chooser_render_entry
 lda #$3B
 sta $D500
 jmp chooser_render
.endproc
.proc chooser_tick_entry
 lda #$3B
 sta $D500
 jmp chooser_tick
.endproc

.segment "CHOOSER"
.proc chooser_load
 lda #0
 sta need_stage
 sta ready
 sta paused
 sta gfx_field
 sta gfx_logic_prepared
 sta tramp_font_adjust+1
 sta death_drop
 ldx #63
@pm:
 sta $0E00,x
 dex
 bpl @pm
 ldx #7
@pmold:
 sta pm_old_h,x
 dex
 bpl @pmold
 lda #$D0
 sta gfx_dli_entry::gfx_dma_branch
 ldx #8
@bands:
 txa
 clc
 adc #1
 sta gfx_dli_next,x
 lda #0
 sta gfx_bg,x
 lda $FD46
 sta gfx_pf0,x
 lda $FD0E
 sta gfx_pf1,x
 lda $FD2E
 cpx #5
 bcc :+
 lda $FD6A
:
 sta gfx_pf2,x
 lda $FD9C
 sta gfx_pf3,x
 dex
 bpl @bands
 lda #0
 sta gfx_pf2+8
 sta gfx_pf3+8
 ; Decode three fonts and a map, then publish identical initial buffers.
 lda #$88
 sta z_src+1
 lda #$40
 sta z_dst+1
 lda #0
 sta z_src
 sta z_dst
 jsr chooser_unpack
 lda #0
 sta z_src
 sta z_dst
 lda #$4C
 sta z_src+1
 lda #$34
 sta z_dst+1
 ldx #4
 jsr copy_pages
 lda #$40
 sta z_src+1
 lda #$4C
 sta z_dst+1
 ldx #12
 jsr copy_pages
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
 lda #<gfx_dli_entry
 sta nmi::display+1
 lda #>gfx_dli_entry
 sta nmi::display+2
 lda #0
 sta loading
 lda #$C0
 sta $D40E
 rts
.endproc

.proc chooser_unpack
@packet:
 jsr chooser_byte
 beq @done
 bmi @run
 sta z_counter
@literal:
 jsr chooser_byte
 jsr chooser_store
 dec z_counter
 bne @literal
 beq @packet
@run:
 and #127
 sta z_counter
 jsr chooser_byte
 sta z_value
@repeat:
 lda z_value
 jsr chooser_store
 dec z_counter
 bne @repeat
 beq @packet
@done:
 rts
.endproc
.proc chooser_byte
 ldy #0
 lda (z_src),y
 pha
 inc z_src
 bne :+
 inc z_src+1
:
 pla
 rts
.endproc
.proc chooser_store
 ldy #0
 sta (z_dst),y
 inc z_dst
 bne :+
 inc z_dst+1
:
 rts
.endproc

.proc chooser_tick
 lda z_fire
 beq @move
 ldx selected
 lda act_clears,x
 cmp #5
 jcs @done
 stx act
 lda #1
 sta mode
 sta need_stage
 ldx player
 sta player_started,x
 lda #0
 sta water
 sta choice_prev
 sta stage_hurt
 lda #$52
 jmp arcade_cue
@move:
 lda z_joy
 and #15
 cmp choice_prev
 beq @done
 sta choice_prev
 cmp #0
 beq @done
 ; Vertical movement stays in this column and never wraps rows.
 cmp #2
 beq @down
 cmp #1
 beq @up
 cmp #4
 beq @horizontal
 cmp #8
 bne @done
@horizontal:
 lda #1
 sta z_step
 lda choice_prev
 and #4
 beq @scan
 lda #255
 sta z_step
@scan:
 lda selected
 clc
 adc z_step
 bmi @last
 cmp #6
 bcc @test
 lda #0
 beq @test
@last:
 lda #5
@test:
 sta selected
 tax
 lda act_clears,x
 cmp #5
 bcs @scan
 lda #$52
 jmp arcade_cue
@down:
 lda selected
 cmp #3
 bcs @done
 clc
 adc #3
 bne @vertical
@up:
 lda selected
 cmp #3
 bcc @done
 sec
 sbc #3
@vertical:
 tax
 lda act_clears,x
 cmp #5
 bcs @done
 stx selected
 lda #$52
 jmp arcade_cue
@done:
 rts
.endproc

.proc chooser_render
 ldx back
 lda screen_high,x
 sta z_map+1
 sta z_dst+1
 lda #0
 sta z_map
 sta z_dst
 sta z_src
 lda #$34
 sta z_src+1
 ldx #4
 jsr copy_pages
 ; Each act owns five progress dots. Exhausted acts retain their icon and
 ; receive the original arcade's NO MORE caption.
 lda #0
 sta z_index
@panel:
 ldx z_index
 lda chooser_panel_lo,x
 sta z_cell
 lda chooser_panel_hi,x
 ora z_map+1
 sta z_cell+1
 lda act_clears,x
 cmp #5
 bcc @dots
 ldy #41
 ldx #0
@locked:
 lda z_index
 cmp #3
 bcs @lower
 lda chooser_lock_top,x
 bcc @letter
@lower:
 lda chooser_lock_bottom,x
@letter:
 sta (z_cell),y
 inx
 iny
 cpx #11
 bne @locked
@dots:
 lda z_cell
 clc
 adc #<364
 sta z_ptr
 lda z_cell+1
 adc #>364
 sta z_ptr+1
 ldy #0
 ldx z_index
@dot:
 tya
 cmp act_clears,x
 lda #121
 bcs :+
 lda #120
:
 sta (z_ptr),y
 iny
 cpy #5
 bne @dot
 inc z_index
 lda z_index
 cmp #6
 bne @panel
 ; A stable white frame identifies the selected tile without obscuring it.
 ldx selected
 lda chooser_panel_lo,x
 sta z_cell
 lda chooser_panel_hi,x
 ora z_map+1
 sta z_cell+1
 ldy #0
 lda #116
 sta (z_cell),y
 ldy #12
 lda #117
 sta (z_cell),y
 ldy #11
 lda #112
@top:
 sta (z_cell),y
 dey
 bne @top
 lda #9
 sta z_counter
@side:
 jsr chooser_next_row
 ldy #0
 lda #114
 sta (z_cell),y
 ldy #12
 lda #115
 sta (z_cell),y
 dec z_counter
 bne @side
 jsr chooser_next_row
 ldy #0
 lda #118
 sta (z_cell),y
 ldy #12
 lda #119
 sta (z_cell),y
 ldy #11
 lda #113
@bottom:
 sta (z_cell),y
 dey
 bne @bottom
 ; Native hires HUD: score, full instructions, current act and show cycle.
 ldx back
 lda hud_lo,x
 sta z_hud
 lda hud_hi,x
 sta z_hud+1
 ldy #159
@hud_high:
 lda chooser_hud,y
 sta (z_hud),y
 dey
 cpy #127
 bne @hud_high
 ldy #127
@hud_low:
 lda chooser_hud,y
 sta (z_hud),y
 dey
 bpl @hud_low
 ldy #4
 ldx #2
@score:
 lda score,x
 jsr hud_bcd
 dex
 bpl @score
 ldy #17
 ldx #2
@high:
 lda highscore,x
 jsr hud_bcd
 dex
 bpl @high
 lda player
 clc
 adc #'1'
 ldy #26
 sta (z_hud),y
 lda lives
 ldy #35
 jsr chooser_decimal_pair
 lda selected
 clc
 adc #'1'
 ldy #84
 sta (z_hud),y
 lda selected
 asl
 tax
 lda chooser_names,x
 sta z_src
 lda chooser_names+1,x
 sta z_src+1
 ldy #86
 jsr hud_text
 ldx selected
 lda act_clears,x
 clc
 adc #'1'
 ldy #108
 sta (z_hud),y
 lda show_cycle
 clc
 adc #1
 cmp #100
 bcc :+
 lda #99
:
 ldy #117
 jmp chooser_decimal_pair
.endproc
.proc chooser_decimal_pair
 ldx #0
@tens:
 cmp #10
 bcc @digits
 sbc #10
 inx
 bne @tens
@digits:
 pha
 txa
 clc
 adc #48
 sta (z_hud),y
 iny
 pla
 clc
 adc #48
 sta (z_hud),y
 rts
.endproc
.proc chooser_next_row
 lda z_cell
 clc
 adc #40
 sta z_cell
 bcc :+
 inc z_cell+1
:
 rts
.endproc
chooser_panel_lo: .byte <0,<13,<26,<440,<453,<466
chooser_panel_hi: .byte >0,>13,>26,>440,>453,>466
.include "chooser-data.inc"
chooser_names: .word chooser_lion,chooser_rope,chooser_tramp,chooser_ball,chooser_horse,chooser_trap
chooser_lion: .asciiz "FIRE HOOPS"
chooser_rope: .asciiz "TIGHTROPE"
chooser_tramp: .asciiz "TRAMPOLINES"
chooser_ball: .asciiz "ROLLING BALLS"
chooser_horse: .asciiz "HORSE RIDING"
chooser_trap: .asciiz "TRAPEZE"
chooser_hud:
 .byte "PTS 000000   TOP 000000  P1  LIVES 00   "
 .byte "CHOOSE THE SCREEN USING STICK AND FIRE  "
 .byte "ACT 1                  NEXT 1/5 SHOW 01 "
 .byte "STICK: CHOOSE        FIRE: PERFORM      "
 .assert *-chooser_hud = 160, error, "Chooser HUD must be four rows"
.segment "CODE"
