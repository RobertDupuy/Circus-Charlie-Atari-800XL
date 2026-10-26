.proc fidelity_tramp_step
 lda #0
 sta z_dx
 lda f_direction
 beq @height
 cmp #4
 beq @left
 lda f_fraction
 clc
 adc #128
 sta f_fraction
 lda world
 adc #1
 sta world
 lda world+1
 adc #0
 sta world+1
 jmp @height
@left:
 lda f_fraction
 sec
 sbc #128
 sta f_fraction
 lda world
 sbc #1
 sta world
 lda world+1
 sbc #0
 sta world+1
 bpl @height
 lda #60
 sta world
 lda #0
 sta world+1
@height:
 inc f_phase
 ldx f_tramp_arc
 lda trampoline_arc_lo,x
 sta z_ptr
 lda trampoline_arc_hi,x
 sta z_ptr+1
 ldy f_phase
 lda (z_ptr),y
 sta jump_pixels
 lda trampoline_arc_length,x
 cmp f_phase
 beq @land
 lsr
 cmp f_phase
 lda #1
 bcs :+
 lda #255
:
 sta velocity
 jmp @hazards
@land:
 lda world
 cmp stage_end
 lda world+1
 sbc stage_end+1
 bcc @apparatus
 lda stage_end
 clc
 adc #32
 sta z_pos
 lda stage_end+1
 adc #0
 sta z_pos+1
 lda world
 cmp z_pos
 lda world+1
 sbc z_pos+1
 jcs @miss
 jmp finish_act
@apparatus:
 ldx #0
@platform:
 lda arcade_tramp_lo,x
 clc
 adc #8
 sta z_pos
 lda arcade_tramp_hi,x
 adc #0
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #13
 bcc @bounce
@next:
 inx
 cpx #25
 bne @platform
 jmp @miss
@bounce:
 stx tramp_index
 lda z_joy
 and #12
 cmp #12
 bne :+
 lda #0
:
 sta f_direction
 cmp #0
 beq @stationary
 lda #0
 sta bounce_count
 sta f_tramp_arc
 txa
@mod:
 cmp #3
 bcc @short
 sbc #3
 bcs @mod
@short:
 cmp #2
 bne @reset
 lda #1
 sta f_tramp_arc
 bne @reset
@stationary:
 inc bounce_count
 lda bounce_count
 clc
 adc #1
 sta f_tramp_arc
@reset:
 lda #0
 sta f_phase
 sta jump_pixels
 sta sound_age
 lda #1
 sta sound_fx
@hazards:
 lda bounce_count
 cmp #3
 bne @flame
 lda jump_pixels
 cmp #74
 bcc @flame
 ldx tramp_index
 lda passed,x
 bne @flame
 inc passed,x
 jsr complete_tramp_prize
@flame:
 lda f_tramp_arc
 cmp #5
 bne @attacks
 lda jump_pixels
 cmp #92
 bcc @attacks
 lda #4
 sta tramp_death_reason
 jmp detail_hurt
@attacks:
 jmp tramp_attacks_entry
@miss:
 lda #1
 sta tramp_death_reason
 jmp detail_hurt
.endproc
trampoline_arc_0: .byte 0,4,7,10,13,16,19,22,24,26,28,30,32,33,34,35,36,37,37,37,37,37,37,37,37,37,37,37,37,36,35,34,33,32,30,28,26,24,22,19,16,13,10,7,0
trampoline_arc_1: .byte 0,3,6,9,12,15,17,19,21,23,25,26,27,28,29,30,30,30,30,30,30,30,30,30,30,30,30,29,28,27,26,25,23,21,19,17,15,12,9,6,0
trampoline_arc_2: .byte 0,4,8,11,14,17,20,23,26,28,30,32,34,36,37,38,39,40,41,41,41,41,41,41,41,41,41,41,41,41,40,39,38,37,36,34,32,30,28,26,23,20,17,14,11,8,0
trampoline_arc_3: .byte 0,5,9,13,17,21,25,28,31,34,37,40,43,45,47,49,51,53,54,55,56,57,58,58,58,58,58,58,58,58,58,58,58,58,57,56,55,54,53,51,49,47,45,43,40,37,34,31,28,25,21,17,13,9,0
trampoline_arc_4: .byte 0,6,12,17,22,27,32,37,41,45,49,53,57,60,63,66,69,72,75,77,79,81,83,85,86,87,88,89,90,90,90,90,90,90,90,90,90,90,90,90,89,88,87,86,85,83,81,79,77,75,72,69,66,63,60,57,53,49,45,41,37,32,27,22,17,12,0
trampoline_arc_5: .byte 0,7,14,21,28,35,42,49,56,63,70,77,84,91,92
trampoline_arc_lo: .byte <trampoline_arc_0,<trampoline_arc_1,<trampoline_arc_2,<trampoline_arc_3,<trampoline_arc_4,<trampoline_arc_5
trampoline_arc_hi: .byte >trampoline_arc_0,>trampoline_arc_1,>trampoline_arc_2,>trampoline_arc_3,>trampoline_arc_4,>trampoline_arc_5
trampoline_arc_length: .byte 44,40,46,54,66,255

