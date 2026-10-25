; Bank zero gameplay additions. Callers in RAM restore/choose their own banks.
.proc score_add
 pha
 lda #5
 sta sound_fx
 pla
 sed
 clc
 adc score
 sta score
 tya
 adc score+1
 sta score+1
 lda score+2
 adc #0
 sta score+2
 cld
 bcs @cap
 cmp #$99
 bne @lives
 lda score+1
 cmp #$99
 bne @lives
 lda score
 cmp #$91
 bcc @lives
@cap:
 lda #$99
 sta score+2
 sta score+1
 lda #$90
 sta score
@lives:
 lda next_extra
 beq @compare_init
 cmp #$FF
 beq @compare_init
 cmp score+2
 bcc @extra
 bne @compare_init
@extra:
 lda lives
 cmp #99
 bcs :+
 inc lives
:
 inc extra_awards
 lda #4
 sta sound_fx
 lda #0
 sta sound_age
 sed
 clc
 jsr arcade_next_life
 cld
 bcc @lives
 lda #$FF
 sta next_extra
@compare_init:
 ldx #2
@compare:
 lda score,x
 cmp highscore,x
 bcc @done
 bne @copy
 dex
 bpl @compare
 rts
@copy:
 ldx #2
@digit:
 lda score,x
 sta highscore,x
 dex
 bpl @digit
@done:
 rts
.endproc

.proc reward_pot
 lda pot_passed,x
 bne @done
 inc pot_passed,x
 txa
 pha
 lda #0
 ldy #1
 jsr score_add
 pla
 tax
@done:
 rts
.endproc
.proc reward_monkey
 lda monkey_type,x
 beq @brown
 lda #2
 bne @save
@brown:
 lda #1
@save:
 ora monkey_seen
 sta monkey_seen
 rts
.endproc
.proc reward_land
 lda act
 cmp #1
 bne @done
 lda monkey_seen
 beq @done
 ldy #2
 cmp #1
 beq @pay
 ldy #3
 cmp #2
 beq @pay
 ldy #10
 inc combo_awards
@pay:
 lda #0
 sta monkey_seen
 sta monkey_points
 jmp score_add
@done:
 rts
.endproc
.proc reward_ball
 txa
 pha
 sec
 sbc current_ball
 beq @done
 bpl :+
 eor #255
 clc
 adc #1
:
 ldy #2
 cmp #2
 bcc @score
 inc skip_awards
 ldy #5
@score:
 lda #0
 jsr score_add
@done:
 pla
 tax
 rts
.endproc

.proc lion_bag_collision
 lda jump_pixels
 cmp #36
 bcc @done
 lda world
 clc
 adc #8
 sta z_tempword
 lda world+1
 adc #0
 sta z_tempword+1
 ldx #0
@bag:
 lda bag_taken,x
 bne @next
 lda z_tempword
 sec
 sbc hazard_xlo,x
 sta z_tmp
 lda z_tempword+1
 sbc hazard_xhi,x
 bmi @done
 bne @next
 lda z_tmp
 cmp #17
 bcs @next
 inc bag_taken,x
 inc bag_awards
 txa
 pha
 lda #0
 ldy #2
 jsr score_add
 pla
 tax
@next:
 inx
 cpx #6
 bcc @bag
@done:
 rts
.endproc
.proc lion_bag_draw
 ldx #0
@bag:
 lda bag_taken,x
 bne @next
 jsr get_hazard
 jsr screen_position
 lda sprite_xhi
 bne @next
 lda sprite_x
 ; Prioritize bags close to or ahead of Charlie, never a passed off-left bag.
 cmp #44
 bcc @next
 cmp #160
 bcs @next
 sec
 sbc #4
 sta pm_x+3
 lda #105
 sta pm_y+3
 lda #13
 sta pm_id+3
 lda #$2C
 sta pm_color+3
 rts
@next:
 inx
 cpx #6
 bcc @bag
 rts
.endproc
