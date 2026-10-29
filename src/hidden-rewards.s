; Original Lion reward choreography ($7289..$7B77), in a spare cartridge bank.
; All movement/collision inputs are ordinary live state, never route counters.
.segment "XL"
.proc hidden_entry
 sta hidden_command
 lda $D500
 pha
 txa
 pha
 tya
 pha
 lda #242
 sta $D500
 jsr hidden_dispatch
 pla
 tay
 pla
 tax
 pla
 sta $D500
 rts
.endproc
.proc hidden_points
 jsr add_points
 lda #242
 sta $D500
 rts
.endproc
.proc hidden_contact_bridge
 lda #$31
 sta $D500
 jsr hidden_contact
 lda #242
 sta $D500
 rts
.endproc
.proc hidden_stamp
 jsr hidden_stamp_pixels
 lda #242
 sta $D500
 rts
.endproc
.proc hidden_stamp_pixels
 txa
 pha
 tya
 pha
 jsr hidden_art_setup
 lda #255
 sta z_band
 lda z_bank
 sta $D500
 jmp (z_rom)
.endproc

.segment "HIDDEN"
.proc hidden_distance
 sec
 sbc lion_frac
 sta z_tempword
 lda z_pos
 sbc world
 sta z_tempword+1
 lda z_pos+1
 sbc world+1
 sta z_pos+1
 sta z_flag
 bpl @positive
 ; Distant pots behind the hero need no absolute-value conversion. Keep
 ; the original rounding path for every coordinate near either boundary.
 cmp #255
 bne @far
 lda z_tempword+1
 cmp #$EE
 bcc @far
 lda #0
 sec
 sbc z_tempword
 sta z_tempword
 lda #0
 sbc z_tempword+1
 sta z_tempword+1
 lda #0
 sbc z_pos+1
 sta z_pos+1
 ; Round a negative delta away from zero before taking its absolute value.
 lda z_tempword
 clc
 adc #191
 sta z_tempword
 bcc @positive
 inc z_tempword+1
 bne @positive
 inc z_pos+1
@positive:
 lda z_pos+1
 bne @done
 lda z_tempword+1
 cmp #18
 bcc :+
 inc z_pos+1
 rts
:
 ; floor((integer*256+fraction)/192) = floor((integer*4+
 ; floor(fraction/64))/3). The collision range guard bounds this index to 0..71.
 ; Use the exact quotient table to leave more display time near several pots.
 lda z_tempword
 asl
 rol z_tempword+1
 asl
 rol z_tempword+1
 ldy z_tempword+1
 lda hidden_distance_thirds,y
 sta z_pos
@done:
 rts
@far:
 lda #1
 sta z_pos+1
 rts
.endproc
hidden_distance_thirds:
 .repeat 96,I
  .byte I/3
 .endrepeat

.proc hidden_dispatch
 lda hidden_command
 asl
 tay
 lda hidden_jumps,y
 sta z_tempword
 lda hidden_jumps+1,y
 sta z_tempword+1
 jmp (z_tempword)
.endproc
hidden_jumps:
 .word hidden_stage,hidden_takeoff,hidden_land,hidden_spawn
 .word hidden_retire_left,hidden_retire_right,hidden_lion_collision,hidden_contact_bridge
 .word hidden_motion,hidden_hoop_draw,hidden_doll_draw,hidden_finish,hidden_checkpoint,hidden_clear_tick

.proc hidden_stage
 lda #0
 ldx #31
@clear:
 sta hidden_state,x
 dex
 bpl @clear
 lda act
 bne @done
 lda stage_hurt
 beq @done
 lda player
 .repeat 5
 asl
 .endrepeat
 tax
 ldy #0
@restore:
 lda hidden_records,x
 sta hidden_state,y
 inx
 iny
 cpy #32
 bne @restore
 lda #0
 sta hidden_doll_active
 sta hidden_pot_jump
 lda hidden_pot_live
 cmp #1
 bne :+
 inc hidden_pot_live
:
 lda #0
 ldx #3
@hoops:
 sta hidden_sides,x
 ldy hoop_type,x
 cpy #3
 bcc :+
 sta hoop_type,x
 sta passed,x
:
 dex
 bpl @hoops
@done:
 rts
.endproc

; Native 16.8 displacement from Charlie to the hoop, without taking abs().
.proc hidden_ring_delta
 lda lion_ringfrac,x
 sec
 sbc lion_frac
 sta hidden_delta
 lda hazard_xlo,x
 sbc world
 sta hidden_delta+1
 lda hazard_xhi,x
 sbc world+1
 sta hidden_delta+2
 rts
.endproc
.proc hidden_pot_delta
 ldx hidden_pot
 lda lion_potfrac,x
 sec
 sbc lion_frac
 sta hidden_delta
 lda lion_potlo,x
 sbc world
 sta hidden_delta+1
 lda lion_pothi,x
 sbc world+1
 sta hidden_delta+2
 rts
.endproc
.proc hidden_side
 ; CMP #$40 / BMI in the original selects source screen X=64..191.
 jsr hidden_ring_delta
 lda hidden_delta+2
 bne @no
 lda hidden_delta+1
 cmp #96
 bcs @no
 lda #1
 rts
@no:
 lda #0
 rts
.endproc
.proc hidden_takeoff
 ldx #3
@hoop:
 jsr hidden_side
 and lion_active,x
 sta hidden_sides,x
 dex
 bpl @hoop
 lda #0
 sta hidden_pot_jump
 lda hidden_pot_live
 cmp #1
 bne @done
 jsr hidden_pot_delta
 lda hidden_delta+2
 beq @right
 cmp #255
 bne @done
 lda hidden_delta+1
 cmp #$D6
 bcc @done
 bne @yes
 lda hidden_delta
 cmp #$C0 ; Source coin X >= 1, hence pot X >= 9 (-41.25 native).
 bcc @done
 bcs @yes
@right:
 lda hidden_delta+1
 cmp #6
 bcc @yes
 bne @done
 lda hidden_delta
 cmp #192 ; Source coin X <= 64, hence pot X < 73 (+6.75 native).
 bcs @done
@yes:
 inc hidden_pot_jump
@done:
 rts
.endproc
.proc hidden_land
 lda lion_direction
 cmp #4
 bne @done
 lda hidden_life
 bne @doll
 ldx #3
@hoop:
 lda hidden_sides,x
 bne @next
 lda lion_active,x
 beq @next
 jsr hidden_side
 beq @next
 inc hidden_life
 bne @doll
@next:
 dex
 bpl @hoop
@doll:
 lda hidden_doll
 bne @done
 lda hidden_pot_jump
 beq @done
 inc hidden_doll
 lda #1
 sta secret_visible
 sta hidden_doll_active
 lda #0
 sta hidden_doll_y
 sta hidden_doll_frame
 sta secret_age
 lda #210
 sta hidden_doll_y+1
 lda #$A0
 sta hidden_doll_v
 lda #$FB
 sta hidden_doll_v+1
 lda #0
 ldy #8
 jsr hidden_points
@done:
 rts
.endproc
.proc hidden_spawn
 cpx #3
 beq @done
 lda hidden_life
 cmp #1
 bne @done
 inc hidden_life
 lda #3
 sta hoop_type,x
@done:
 rts
.endproc
.proc hidden_retire_left
 lda hoop_type,x
 cmp #2
 bne @done
 lda passed,x
 bne @done
 inc hidden_failed
@done:
 rts
.endproc
.proc hidden_retire_right
 lda hoop_type,x
 cmp #3
 bne @done
 lda hidden_life
 cmp #2
 bne @done
 dec hidden_life
 lda #0
 sta hoop_type,x
@done:
 rts
.endproc
.proc hidden_extra_life
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
 rts
.endproc
.proc hidden_money
 lda money_chain
 cmp #5
 bcs :+
 inc money_chain
:
 lda money_chain
 asl
 asl
 asl
 asl
 tay
 lda #0
 jmp hidden_points
.endproc
.segment "DETAILS"
.proc hidden_contact
 lda hidden_doll
 cmp #1
 bne @done
 lda secret_visible
 beq @done
 ; The original coin's X is eight source pixels left of its selected pot.
 ; $7294 tests X=38..69, equivalent to pot X=46..77.
 ; hidden_motion caches this delta after movement. Contact precedes the
 ; next movement, and rendering leaves this displacement intact.
 lda hidden_delta+2
 beq @positive
 cmp #255
 bne @done
 lda hidden_delta+1
 cmp #$F2 ; -18 source pixels = -13.5 native pixels.
 bcc @done
 bne @vertical
 lda hidden_delta
 cmp #128
 bcc @done
 bcs @vertical
@positive:
 lda hidden_delta+1
 cmp #10
 bcc @vertical
 bne @done
 lda hidden_delta
 cmp #128
 bcs @done
@vertical:
 lda hidden_doll_y+1
 clc
 adc #12
 sec
 sbc #216
 clc
 adc jump_pixels
 cmp #20
 bcs @done
 inc hidden_doll
 lda #0
 sta secret_visible
 sta hidden_doll_active
 lda #1
 sta secret_paid
 lda #0
 ldy #$30
 jmp detail_points
@done:
 rts
.endproc
.segment "HIDDEN"
.proc hidden_motion
 jsr hidden_pot_delta
 ; The tracked pot is retired at source X < 2 or on a reverse wrap.
 lda hidden_delta+2
 beq @ahead
 cmp #255
 bne @retire
 lda hidden_delta+1
 cmp #$D1
 bcc @retire
 bne @position
 lda hidden_delta
 cmp #128
 bcc @retire
 bcs @position
@ahead:
 lda hidden_delta+1
 cmp #144
 bcs @retire
@position:
 lda hidden_pot_live
 cmp #2
 beq @retired
 lda #1
 sta hidden_pot_live
 lda hidden_doll_active
 beq @done
 lda lion_potlo,x
 sec
 sbc #6
 sta secret_world
 lda lion_pothi,x
 sbc #0
 sta secret_world+1
 lda hidden_doll_y+1
 cmp #215
 bcs @hide
 lda hidden_doll_v
 clc
 adc #28
 sta hidden_doll_v
 lda hidden_doll_v+1
 adc #0
 sta hidden_doll_v+1
 lda hidden_doll_y
 clc
 adc hidden_doll_v
 sta hidden_doll_y
 lda hidden_doll_y+1
 adc hidden_doll_v+1
 sta hidden_doll_y+1
 lda #210
 sec
 sbc hidden_doll_y+1
 sta secret_height
 inc hidden_doll_frame
 lda hidden_doll_frame
 cmp #24
 bcc @done
 lda #0
 sta hidden_doll_frame
@done:
 rts
@retire:
 lda hidden_delta+2
 bmi @left
 lda #0
 sta hidden_pot_live
 beq @retired
@left:
 lda #2
 sta hidden_pot_live
@retired:
 lda #0
 sta hidden_doll_active
@hide:
 lda #0
 sta secret_visible
 rts
.endproc
.proc hidden_checkpoint
 lda act
 bne @done
 inc hidden_failed
 lda hidden_life
 cmp #2
 bne :+
 dec hidden_life
:
 lda player
 .repeat 5
 asl
 .endrepeat
 tax
 ldy #0
@copy:
 lda hidden_state,y
 sta hidden_records,x
 inx
 iny
 cpy #32
 bne @copy
@done:
 rts
.endproc
.proc hidden_finish
 lda #0
 sta hidden_clear_hi
 lda hidden_failed
 ora stage_hurt
 beq @yes
 lda #0
 sta clear_reward
 sta clear_bird
 rts
@yes:
 lda #1
 sta clear_reward
 sta clear_bird
 rts
.endproc
.proc hidden_clear_tick
 lda clear_bird
 beq @done
 lda clear_elapsed
 bne :+
 inc hidden_clear_hi
:
 lda hidden_clear_hi
 bne @second_page
 lda clear_elapsed
 cmp #224
 bne :+
 ; Original $CA starts at $80 and runs for 384 updates. Extend only this
 ; eligible celebration; the other acts retain their existing countdown.
 lda #161
 sta mode_timer
:
 lda clear_elapsed
 cmp #203
 bcc @done
 bcs @cadence
@second_page:
 lda clear_elapsed
 cmp #128
 bcs @done
@cadence:
 and #3
 cmp #3
 bne @done
 inc clear_prize
 lda #$40
 ldy #0
 jmp hidden_points
@done:
 rts
.endproc
.proc hidden_hoop_draw
 jsr get_hazard
 lda z_pos
 sec
 sbc #12
 sta z_pos
 bcs :+
 dec z_pos+1
:
 jsr screen_position
 lda #24
 jsr gfx_visible_width
 bcs @done
 lda #70
 sta sprite_y
 lda #0
 sta hidden_art
 jmp hidden_stamp
@done:
 rts
.endproc
.proc hidden_doll_draw
 lda secret_world
 sta z_pos
 lda secret_world+1
 sta z_pos+1
 jsr screen_position
 lda #12
 jsr gfx_visible_width
 bcs @done
 lda hidden_doll_y+1
 sec
 sbc #64
 sta sprite_y
 lda hidden_doll_frame
 lsr
 clc
 adc #1
 sta hidden_art
 jmp hidden_stamp
@done:
 rts
.endproc
.proc hidden_art_setup
 lda sprite_y
 and #7
 asl
 asl
 sta z_tmp
 lda sprite_x
 and #3
 .repeat 5
 asl
 .endrepeat
 ora z_tmp
 sta z_ptr
 lda hidden_art
 lsr
 php
 clc
 adc #$B0
 sta z_ptr+1
 plp
 bcc :+
 lda z_ptr
 ora #128
 sta z_ptr
:
 ldy #0
 lda (z_ptr),y
 sta z_bank
 iny
 lda (z_ptr),y
 sta z_rom
 iny
 lda (z_ptr),y
 sta z_rom+1
 iny
 lda (z_ptr),y
 sta z_cells
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 sta z_col
 lda sprite_y
 lsr
 lsr
 lsr
 sta z_row
 rts
.endproc
