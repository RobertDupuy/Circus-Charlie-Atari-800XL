; Final-course rules and presentation. All entry points restore the caller bank.
.proc complete_dispatch
 cpx #0
 beq complete_begin
 cpx #1
 beq complete_tick
 cpx #2
 jeq complete_draw
 cpx #3
 jeq complete_reverse
 cpx #4
 jeq complete_reset
 cpx #5
 jeq complete_secrets
 cpx #6
 jeq complete_prize
 jmp complete_money
.endproc

.proc complete_begin
 lda #0
 sta clear_elapsed
 sta clear_reward
 sta clear_bird
 sta clear_prize
 sta finish_pony
 lda stage_hurt
 jne @done
 lda #1
 sta clear_reward
 lda act
 jne @done
 lda #1
 sta clear_bird
@done:
 rts
.endproc

.proc complete_tick
 inc clear_elapsed
 lda clear_bird
 beq @horse
 lda clear_elapsed
 cmp #64
 bcc @horse
 cmp #144
 bcs @horse
 and #7
 bne @horse
 inc clear_prize
 lda #$40
 ldy #0
 jsr score_add
@horse:
 lda act
 cmp #4
 jne @done
 lda finish_pony
 cmp #96
 jcs @done
 inc finish_pony
@done:
 rts
.endproc

.proc complete_reset
 lda #0
 sta clear_elapsed
 sta clear_reward
 sta clear_bird
 sta clear_prize
 sta finish_pony
 sta reward_chain
 sta secret_jumps
 sta secret_visible
 sta secret_paid
 sta secret_age
 sta money_chain
 lda #47
 sta sprite_cache_base+1
 lda #37
 sta sprite_cache_mid_adjust+1
 lda #87
 sta sprite_cache_bottom_limit+1
 lda act
 cmp #1
 bne @water
 lda #3
 sta sprite_cache_base+1
 lda #0
 sta sprite_cache_mid_adjust+1
@water:
 lda water
 beq @done
 lda #30
 sta sprite_cache_base+1
 lda #13
 sta sprite_cache_mid_adjust+1
 lda #83
 sta sprite_cache_bottom_limit+1
@done:
 rts
.endproc

.proc complete_prize
 lda reward_chain
 cmp #7
 bcs :+
 inc reward_chain
:
 lda reward_chain
 clc
 adc #2
 tay
 lda #0
 jmp score_add
.endproc

.proc complete_reverse
 lda lion_direction
 cmp #4
 jne @done
 lda secret_visible
 ora secret_paid
 jne @done
 inc secret_jumps
 lda secret_jumps
 cmp #3
 jcc @done
 lda #1
 sta secret_visible
 lda #0
 sta secret_age
 lda world
 clc
 adc #24
 sta secret_world
 lda world+1
 adc #0
 sta secret_world+1
 lda #0
 ldy #8
 jsr score_add
@done:
 rts
.endproc

.proc complete_secrets
 lda act
 jne @done
 lda secret_visible
 jeq @done
 inc secret_age
 lda secret_age
 cmp #180
 bcc :+
 lda #0
 sta secret_visible
 rts
:
 ; A rising prize must be reached, not awarded just for appearing.
 lsr
 cmp #40
 bcc :+
 lda #40
:
 sta secret_height
 lda secret_world
 sta z_pos
 lda secret_world+1
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 jne @done
 lda z_pos
 cmp #13
 jcs @done
 lda jump_pixels
 sec
 sbc secret_height
 clc
 adc #12
 cmp #24
 jcs @done
 lda #0
 sta secret_visible
 lda #1
 sta secret_paid
 lda #0
 ldy #$30
 jmp score_add
@done:
 rts
.endproc

.proc complete_draw
 lda mode
 cmp #4
 beq @clear
 lda act
 jne @done
 lda secret_visible
 jeq @done
 lda secret_world
 sta z_pos
 lda secret_world+1
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 jne @done
 lda #146
 sec
 sbc secret_height
 sta sprite_y
 lda #93
 sta sprite_pose
 jmp complete_stamp
@clear:
 lda act
 cmp #5
 jeq @kiss
 lda clear_bird
 jeq @done
 lda clear_elapsed
 lsr
 clc
 adc #16
 sta sprite_x
 lda #0
 sta sprite_xhi
 lda #80
 sta sprite_y
 lda clear_elapsed
 and #8
 lsr
 lsr
 lsr
 clc
 adc #9
 sta sprite_pose
 jsr complete_stamp
 lda clear_elapsed
 cmp #64
 jcc @done
 cmp #160
 jcs @done
 and #31
 asl
 clc
 adc #92
 sta sprite_y
 lda #86
 sta sprite_x
 lda #0
 sta sprite_xhi
 lda #8
 sta sprite_pose
 jmp complete_stamp
@kiss:
 ; Original partner and Charlie frames; alternate the kiss after approach.
 lda clear_elapsed
 cmp #48
 bcs @together
 lsr
 eor #255
 clc
 adc #112
 bne @partner
@together:
 lda #88
@partner:
 sta sprite_x
 lda #0
 sta sprite_xhi
 lda #32
 sta sprite_y
 lda clear_elapsed
 lsr
 lsr
 lsr
 lsr
 lsr
 and #1
 clc
 adc #14
 sta sprite_pose
 jsr complete_stamp
 lda #76
 sta sprite_x
 lda #0
 sta sprite_xhi
 lda #32
 sta sprite_y
 lda clear_elapsed
 lsr
 lsr
 lsr
 lsr
 lsr
 and #1
 clc
 adc #16
 sta sprite_pose
 jmp complete_stamp
@done:
 rts
.endproc

; Arcade $72F5: 1,000, 2,000, ... 5,000 for collected money hoops.
.proc complete_money
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
 jmp score_add
.endproc

