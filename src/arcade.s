; Transition-only arcade features. No new collision or per-object work.
act_clears=$06D3
choice_prev=$06D9

.proc arcade_reset
 lda #0
 ldx #5
@clear:
 sta act_clears,x
 dex
 bpl @clear
 sta choice_prev
 sta show_cycle
 sta player_cycles
 sta player_cycles+1
 sta player_started
 sta player_started+1
 rts
.endproc
.proc arcade_save
 ; X points to record+3 on entry, as in save_player.
 ldy #0
@copy:
 lda act_clears,y
 sta player_records+7,x
 inx
 iny
 cpy #6
 bne @copy
 ldx player
 lda show_cycle
 sta player_cycles,x
 rts
.endproc
.proc arcade_restore
 ldy #0
@copy:
 lda player_records+7,x
 sta act_clears,y
 inx
 iny
 cpy #6
 bne @copy
 ldx player
 lda player_cycles,x
 sta show_cycle
 rts
.endproc
.proc arcade_rank
 ldx act
 lda act_clears,x
 ldy show_cycle
 beq :+
 ; The next show starts at the sixth, hardest source schedule. Arcade
 ; schedules saturate; difficulty never wraps back to the easy course.
 lda #5
:
 pha
 clc
 adc #1
 sta round
 pla
 rts
.endproc

.proc arcade_next_available
 ldx #6
@next:
 inc selected
 lda selected
 cmp #6
 bcc :+
 lda #0
 sta selected
:
 tay
 lda act_clears,y
 cmp #5
 bcc @done
 dex
 bne @next
@done:
 rts
.endproc

.proc arcade_after_act
 lda #0
 sta stage_hurt
 lda water
 bne @choose
 ldx act
 inc act_clears,x
 cpx #2
 bne @choose
 inc tramp_clears
 lda tramp_clears
 and #1
 bne @choose
 lda #1
 sta water
 sta mode
 sta need_stage
 rts
@choose:
 lda #0
 sta water
 sta choice_prev
 ; A show is thirty main performances. Keep score/lives, clear the six
 ; availability counters, and enter the harder show without a game ending.
 ldx #5
@all:
 lda act_clears,x
 cmp #5
 bcc @select
 dex
 bpl @all
 lda show_cycle
 cmp #98
 bcs :+
 inc show_cycle
:
 lda #0
 ldx #5
@reset:
 sta act_clears,x
 dex
 bpl @reset
@select:
 lda act
 sta selected
 jsr arcade_next_available
.if ::ARCADE_CHOOSER
 lda #7
.else
 lda selected
 sta act
 lda #1
.endif
 sta mode
 lda #1
 sta need_stage
 rts
.endproc

; Main code queues original commands atomically. IRQ owns all playback state.
.proc arcade_cue
 sta audio_request
 rts
.endproc

audio_request=$06DA

start_latch=$06E1
life_rule=$06E2
.proc arcade_settings
 lda start_latch
 beq @done
 lda #0
 sta start_latch
 inc life_rule
 lda life_rule
 cmp #3
 bcc :+
 lda #1
 sta life_rule
:
 lda #255
 sta hud_menu_cache
 sta hud_menu_cache+1
 lda #$52
 sta audio_request
@done:
 rts
.endproc
.proc arcade_first_life
 lda #2
 ldx life_rule
 cpx #2
 bne :+
 lda #3
:
 sta next_extra
 rts
.endproc
.proc arcade_next_life
 ; Called in decimal mode from score_add. X and Y are disposable there.
 ldx life_rule
 lda next_extra
 clc
 adc life_increment,x
 sta next_extra
 rts
.endproc
life_increment: .byte 2,7,8
.proc arcade_settings_hud
 lda mode
 bne @done
 lda #<life_text
 sta z_src
 lda #>life_text
 sta z_src+1
 ldy #111
 jsr hud_text
 ldx life_rule
 lda life_letter,x
 ldy #117
 sta (z_hud),y
 lda life_digit,x
 iny
 sta (z_hud),y
 lda life_tail,x
 iny
 sta (z_hud),y
@done:
 rts
.endproc
life_text: .asciiz "LIVES:A1 "
life_letter: .byte 'C','A','A'
life_digit: .byte '6','1','2'
life_tail: .byte '4',' ',' '

; A missed ball or the horse's final gap drops Charlie to the arena floor.
; Continue/game-over retain this landing instead of drawing him upright again.
.proc death_step
 jmp detail_death_entry
.endproc

; Fast opaque copy on the empty sky behind a high trampoline bag.
.proc detail_bag_blank
 ldy #0
@pixel:
 lda detail_bag_pixels,x
 sta (z_glyph),y
 inx
 iny
 cpy #8
 bne @pixel
 rts
.endproc
