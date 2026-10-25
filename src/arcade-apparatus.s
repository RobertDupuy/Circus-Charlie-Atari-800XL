; Native translation of the arcade apparatus rules.
.include "apparatus-tables.inc"

.proc apparatus_init
 ; Two static PM columns form the finish legs over the animated audience.
 lda #$F0
 ldx #97
@legs:
 sta $5C6C,x
 sta $5D6C,x
 sta $646C,x
 sta $656C,x
 dex
 bpl @legs
 lda #0
 sta r_center
 sta r_pump
 sta f_rope_valid
 sta r_goal_ready
 sta flying
 sta jumping
 sta f_fraction
 sta r_depth
 sta r_vertical
 sta r_vertical+1
 ldx #31
@clear:
 sta r_active,x
 sta r_got,x
 dex
 bpl @clear
 lda rank
 clc
 adc #1
 asl
 asl
 asl
 asl
 sta r_start_index
 lda #84
 sta z_pos
 lda #0
 sta z_pos+1
 ldx #0
@positions:
 txa
 clc
 adc r_start_index
 cmp #104
 bcc :+
 and #7
 ora #96
:
 tay
 lda r_lengths,y
 sta r_length,x
 lda r_initial_amplitude,y
 sta r_amplitude,x
 lda z_pos
 sta r_pivot_lo,x
 lda z_pos+1
 sta r_pivot_hi,x
 iny
 lda r_lengths,y
 clc
 adc r_length,x
 clc
 adc #16
 sta z_tmp
 lsr
 lsr
 sta z_tmp2
 lda z_tmp
 sec
 sbc z_tmp2
 clc
 adc z_pos
 sta z_pos
 bcc :+
 inc z_pos+1
:
 inx
 cpx #32
 bne @positions
 lda #$FF
 sta stage_end
 lda #$7F
 sta stage_end+1
 jsr apparatus_range
 jsr apparatus_clocks
 ldx #0
 jsr apparatus_point
 jsr apparatus_attach
 lda #1
 sta r_got
 rts
.endproc
.proc apparatus_range
 lda r_center
 sec
 sbc #2
 bcs :+
 lda #0
:
 sta r_first
 lda r_center
 clc
 adc #3
 cmp #32
 bcc :+
 lda #32
:
 sta r_limit
 rts
.endproc
.proc apparatus_activate
 lda #1
 sta r_active,x
 sta r_cycle,x
 lda #90
 sta r_phase,x
 lda #255
 sta r_angle,x
 lda #0
 sta r_fraction,x
 lda #60
 sec
 sbc r_length,x
 lsr
 lsr
 sta r_age,x
 rts
.endproc
.proc apparatus_clocks
 ldx r_first
@rope:
 lda r_active,x
 bne :+
 jsr apparatus_activate
:
 lda r_freeze
 bne @geometry
 lda r_length,x
 sec
 sbc #32
 lsr
 lsr
 tay
 lda r_fraction,x
 clc
 adc r_step_lo,y
 sta r_fraction,x
 lda r_phase,x
 adc r_step_hi,y
 cmp #180
 bcc @phase
 sbc #180
 inc r_cycle,x
 pha
 lda r_cycle,x
 and #1
 bne :+
 cpx r_center
 bne :+
 inc r_age,x
:
 pla
@phase:
 sta r_phase,x
@geometry:
 lda r_phase,x
 pha
 lda r_pivot_lo,x
 clc
 adc #105
 sta z_tmp
 lda r_pivot_hi,x
 adc #0
 sta z_tmp2
 lda z_tmp
 sec
 sbc world
 sta z_tmp
 lda z_tmp2
 sbc world+1
 jne @far_geometry
 lda z_tmp
 cmp #255
 jcs @far_geometry
 pla
 cmp #90
 bcc :+
 sta z_tmp
 lda #180
 sec
 sbc z_tmp
:
 tay
 stx z_ropeindex
 lda r_amplitude,x
 tax
 lda r_angle_lo,x
 sta z_ptr
 lda r_angle_hi,x
 sta z_ptr+1
 lda (z_ptr),y
 ldx z_ropeindex
 cmp r_angle,x
 jeq @next_rope
 sta r_angle,x
 tay
 lda r_length,x
 sec
 sbc #32
 lsr
 lsr
 tax
 .repeat 4,I
 lda r_endpoint_0_lo+I*744,x
 sta z_ptr
 lda r_endpoint_0_hi+I*744,x
 sta z_ptr+1
 lda (z_ptr),y
 ldy z_ropeindex
 sta r_dxlo+I*32,y
 lda r_angle,y
 tay
 .endrepeat
 ldx z_ropeindex
@next_rope:
 inx
 cpx r_limit
 jne @rope
 rts
@far_geometry:
 pla
 jmp @next_rope
.endproc
.proc apparatus_point
 lda r_cycle,x
 and #1
 beq @positive
 lda #0
 sec
 sbc r_dxlo,x
 sta z_off
 lda r_pivot_lo,x
 sbc r_dxhi,x
 sta z_pos
 lda r_pivot_hi,x
 sbc #0
 sta z_pos+1
 jmp @vertical
@positive:
 lda r_dxlo,x
 sta z_off
 lda r_pivot_lo,x
 clc
 adc r_dxhi,x
 sta z_pos
 lda r_pivot_hi,x
 adc #0
 sta z_pos+1
@vertical:
 lda r_dyhi,x
 sta z_dy
 rts
.endproc
.proc apparatus_attach
 lda z_pos
 sta world
 lda z_pos+1
 sta world+1
 lda z_off
 sta f_fraction
 lda r_dylo,x
 sta r_depth
 lda r_dyhi,x
 sta r_depth+1
 rts
.endproc
.proc apparatus_step
 jsr apparatus_range
 jsr apparatus_clocks
 lda flying
 jne @flight
 ldx held_rope
 jsr apparatus_point
 jsr apparatus_attach
 jsr apparatus_record
 jsr apparatus_pump
 lda r_goal_ready
 bne @release
 lda world
 sec
 sbc #<999
 lda world+1
 sbc #>999
 bmi @release
 lda r_center
 clc
 adc #2
 sta r_goal_rope
 tax
 lda r_length,x
 lsr
 lsr
 sta z_tmp
 lda r_length,x
 sec
 sbc z_tmp
 clc
 adc #14
 clc
 adc r_pivot_lo,x
 sta stage_end
 lda r_pivot_hi,x
 adc #0
 sta stage_end+1
 inc r_goal_ready
@release:
 lda f_rope_valid
 cmp #5
 jcc @position
 ldx held_rope
 lda r_age,x
 cmp #16
 bcs @letgo
 lda z_fire
 jeq @position
@letgo:
 lda #1
 sta flying
 sta jumping
 sta sound_fx
 lda #0
 sta sound_age
 lda #8
 sta release_guard
 jmp @position
@flight:
 lda r_depth+1
 sta r_old_depth
 lda f_fraction
 clc
 adc f_velocity
 sta f_fraction
 lda world
 adc f_velocity+1
 sta world
 lda #0
 ldx f_velocity+1
 bpl :+
 lda #255
:
 adc world+1
 sta world+1
 jmi hurt
 lda r_vertical
 clc
 adc #21
 sta r_vertical
 lda r_vertical+1
 adc #0
 sta r_vertical+1
 lda r_depth
 clc
 adc r_vertical
 sta r_depth
 lda r_depth+1
 adc r_vertical+1
 sta r_depth+1
 lda r_vertical+1
 bmi @catch
 lda r_goal_ready
 beq @ground
 lda r_old_depth
 cmp #26
 bcs @ground
 lda r_depth+1
 cmp #26
 bcc @ground
 lda world
 sec
 sbc stage_end
 sta z_tmp
 lda world+1
 sbc stage_end+1
 sta z_tmp2
 lda z_tmp
 clc
 adc #6
 sta z_tmp
 lda z_tmp2
 adc #0
 bne @ground
 lda z_tmp
 cmp #31
 bcs @ground
 lda #26
 sta r_depth+1
 lda #102
 sta jump_pixels
 jmp finish_act
@ground:
 lda r_depth+1
 cmp #124
 bcc @catch
 jsr apparatus_rescue
 lda mode
 cmp #2
 jne @return
@catch:
 lda release_guard
 beq @testcatch
 dec release_guard
 jmp @position
@testcatch:
 ldx r_first
@candidate:
 lda r_goal_ready
 beq :+
 cpx r_goal_rope
 beq :+
 jcs @position
:
 cpx held_rope
 bne @test
 lda flying
 cmp #2
 bne @next
@test:
 jsr apparatus_point
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda #5
 sta z_tmp
 txa
 and #3
 cmp #2
 bne :+
 lda #7
 sta z_tmp
:
 lda z_pos
 cmp z_tmp
 bcs @next
 lda r_dyhi,x
 sec
 sbc r_depth+1
 clc
 adc #11
 cmp #25
 bcs @next
 stx held_rope
 lda #0
 sta flying
 sta jumping
 sta f_rope_valid
 sta r_fraction,x
 lda r_angle,x
 sta r_amplitude,x
 lda #90
 sta r_phase,x
 lda r_got,x
 bne @position
 inc r_got,x
 lda #0
 ldy #5
 jsr apparatus_points_entry
 jmp @position
@next:
 inx
 cpx r_limit
 bne @candidate
@position:
 ; The working set follows Charlie, preserving the original five pendulums.
 ldx r_center
 lda r_length,x
 clc
 adc #8
 sta z_tmp
 lsr
 lsr
 sta z_tmp2
 lda z_tmp
 sec
 sbc z_tmp2
 sta z_tmp
 lda world
 sec
 sbc r_pivot_lo,x
 sta z_tempword
 lda world+1
 sbc r_pivot_hi,x
 bmi @left
 bne @right
 lda z_tempword
 cmp z_tmp
 bcc @height
@right:
 cpx #29
 bcs @height
 inc r_center
 jsr apparatus_range
 jmp @height
@left:
 cpx #0
 beq @height
 lda r_pivot_lo,x
 sec
 sbc world
 sta z_tempword
 lda r_pivot_hi,x
 sbc world+1
 bne @goleft
 lda z_tempword
 cmp z_tmp
 bcc @height
@goleft:
 dec r_center
 jsr apparatus_range
@height:
 lda #128
 sec
 sbc r_depth+1
 sta jump_pixels
 lda #0
 sec
 sbc r_vertical+1
 sta velocity
@return:
 rts
.endproc
.proc apparatus_record
 lda scene_clock
 and #3
 tax
 lda f_rope_valid
 cmp #5
 bcs :+
 inc f_rope_valid
:
 lda f_fraction
 sec
 sbc r_hist_xfrac,x
 sta f_velocity
 lda world
 sbc r_hist_xlo,x
 sta f_velocity+1
 lda r_depth
 sec
 sbc r_hist_yfrac,x
 sta r_vertical
 lda r_depth+1
 sbc r_hist_yhi,x
 sta r_vertical+1
 .repeat 2
 lda f_velocity+1
 cmp #128
 ror f_velocity+1
 ror f_velocity
 lda r_vertical+1
 cmp #128
 ror r_vertical+1
 ror r_vertical
 .endrepeat
 lda f_fraction
 sta r_hist_xfrac,x
 lda world
 sta r_hist_xlo,x
 lda r_depth
 sta r_hist_yfrac,x
 lda r_depth+1
 sta r_hist_yhi,x
 rts
.endproc
.proc apparatus_pump
 lda z_joy
 and #12
 beq @done
 cmp #12
 beq @done
 sta z_tmp
 lda r_pump
 clc
 adc #24
 sta r_pump
 bcc @done
 ldx held_rope
 lda r_cycle,x
 and #1
 sta z_tmp2
 lda r_phase,x
 cmp #90
 bcs :+
 lda z_tmp2
 eor #1
 sta z_tmp2
:
 lda z_tmp
 cmp #8
 lda #0
 rol
 cmp z_tmp2
 bne @shrink
 lda r_amplitude,x
 cmp #90
 bcs @done
 inc r_amplitude,x
 rts
@shrink:
 lda r_amplitude,x
 beq @done
 dec r_amplitude,x
@done:
 rts
.endproc
.proc apparatus_rescue
 lda r_old_depth
 cmp #124
 jcs apparatus_hurt_entry
 ldx r_first
@support:
 txa
 and #1
 jne @next
 lda r_length,x
 lsr
 lsr
 sta z_tmp
 lda r_length,x
 sec
 sbc z_tmp
 clc
 adc #12
 clc
 adc r_pivot_lo,x
 sta z_pos
 lda r_pivot_hi,x
 adc #0
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #13
 bcs @next
 lda #124
 sta r_depth+1
 lda #0
 sta r_depth
 lda #2
 sta flying
 lda #0
 sta release_guard
 lda z_joy
 and #12
 beq @stationary
 lda #0
 sta bounce_count
 jmp @jump
@stationary:
 lda bounce_count
 cmp #3
 bcs @jump
 inc bounce_count
@jump:
 ldy bounce_count
 lda r_rescue_lo,y
 sta r_vertical
 lda r_rescue_hi,y
 sta r_vertical+1
 lda #0
 sta f_velocity
 sta f_velocity+1
 lda z_joy
 and #12
 cmp #8
 beq @right
 cmp #4
 bne @done
 lda #172
 sta f_velocity
 lda #255
 sta f_velocity+1
 bne @done
@right:
 lda #84
 sta f_velocity
@done:
 inc rescue_events
 rts
@next:
 inx
 cpx r_limit
 jne @support
 jmp apparatus_hurt_entry
.endproc
r_rescue_lo: .byte $E0,$70,$00,$80
r_rescue_hi: .byte $FB,$FB,$FB,$F9

.proc apparatus_resume
 lda #0
 sta flying
 sta jumping
 sta f_rope_valid
 sta release_guard
 jsr apparatus_range
 lda #1
 sta r_freeze
 jsr apparatus_clocks
 lda #0
 sta r_freeze
 ldx held_rope
 jsr apparatus_point
 jsr apparatus_attach
 lda #128
 sec
 sbc r_depth+1
 sta jump_pixels
 lda r_goal_ready
 beq @done
 ldx r_goal_rope
 lda r_length,x
 lsr
 lsr
 sta z_tmp
 lda r_length,x
 sec
 sbc z_tmp
 clc
 adc #14
 clc
 adc r_pivot_lo,x
 sta stage_end
 lda r_pivot_hi,x
 adc #0
 sta stage_end+1
@done:
 rts
.endproc
