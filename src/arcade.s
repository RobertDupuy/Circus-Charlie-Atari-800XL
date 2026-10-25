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
 rts
.endproc
.proc arcade_rank
 ldx act
 lda act_clears,x
 clc
 adc #1
 sta round
 sec
 sbc #1
 clc
 ldy difficulty
 beq :+
 adc #2
:

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
 lda #7
 sta mode
 lda #1
 sta need_stage
 ; Default to the next unfinished act; the stick can select any available act.
 ldx #6
@next:
 inc act
 lda act
 cmp #6
 bcc :+
 lda #0
 sta act
:
 txa
 pha
 ldx act
 lda act_clears,x
 cmp #6
 pla
 tax
 bcc @done
 dex
 bne @next
 lda #8
 sta mode
 lda #0
 sta lives
 lda #$3F
 sta $D500
 jsr save_player
@done:
 rts
.endproc

.proc arcade_choose
 lda z_fire
 beq @move
 lda #1
 sta mode
 sta need_stage
 lda #90
 sta mode_timer
 lda #0
 sta choice_prev
 lda #$52
 jsr arcade_cue
 rts
@move:
 lda z_joy
 and #12
 cmp choice_prev
 beq @done
 sta choice_prev
 cmp #0
 beq @done
 cmp #12
 beq @done
 lda #1
 sta z_step
 lda choice_prev
 and #4
 beq @scan
 lda #255
 sta z_step
@scan:
 lda act
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
 sta act
 tax
 lda act_clears,x
 cmp #6
 bcs @scan
 lda #1
 sta need_stage
 lda #$52
 jsr arcade_cue
@done:
 rts
.endproc

.proc arcade_complete
 lda z_fire
 beq @done
 lda players
 cmp #2
 bne @new
 lda player
 eor #1
 sta player
 lda #$3F
 sta $D500
 jsr player_offset
 lda player_records+3,x
 beq @new
 jsr restore_player
 lda #7
 sta mode
 lda #1
 sta need_stage
 rts
@new:
 jmp newgame_entry
@done:
 rts
.endproc

; Main code queues original commands atomically. IRQ owns all playback state.
.proc arcade_cue
 sta audio_request
 rts
.endproc

.proc arcade_hud
 lda mode
 cmp #7
 beq @counts
 cmp #8
 beq @counts
 rts
@counts:
 lda #<completion_text
 sta z_src
 lda #>completion_text
 sta z_src+1
 ldy #120
 jsr hud_text
 ldx #0
 ldy #122
@each:
 lda act_clears,x
 clc
 adc #'0'
 sta (z_hud),y
 tya
 clc
 adc #6
 tay
 inx
 cpx #6
 bne @each
 rts
.endproc
completion_text: .asciiz "1:0/6 2:0/6 3:0/6 4:0/6 5:0/6 6:0/6   "
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
