; Arcade trapeze rules: physics retains original coordinates and update order.
.include "apparatus-tables.inc"

.proc apparatus_init
 lda #0
 sta r_clock_fraction
 sta r_clock_fraction+1
 sta r_clock_fraction+2
 jsr apparatus_clock_reset
 lda #0
 sta bonus
 lda #$60
 sta bonus+1
 lda #3
 sta timer_div
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
 sta r_depth_page
 sta r_arc_frac
 sta r_hist_index
 sta r_arc_joy
 sta r_catch_block
 sta r_launch_wait
 sta r_vertical
 sta r_vertical+1
 ldx #19
@histclear:
 sta r_hist_xfrac,x
 dex
 bpl @histclear
 ldx #31
@clear:
 sta r_active,x
 sta r_got,x
 sta r_fraction,x
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
 lda #112
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
 sta r_raw_pivot_lo,x
 lda z_pos+1
 sta r_raw_pivot_hi,x
 iny
 cpy #104
 bcc :+
 ldy #96
:
 lda r_lengths,y
 clc
 adc r_length,x
 clc
 adc #16
 clc
 adc z_pos
 sta z_pos
 bcc :+
 inc z_pos+1
:
 inx
 cpx #32
 bne @positions
 ldx #31
@displaypivots:
 lda r_raw_pivot_lo,x
 sta z_pos
 lda r_raw_pivot_hi,x
 sta z_pos+1
 jsr apparatus_scale_x
 lda z_pos
 sta r_pivot_lo,x
 lda z_pos+1
 sta r_pivot_hi,x
 dex
 bpl @displaypivots
 lda #$FF
 sta stage_end
 lda #$7F
 sta stage_end+1
 jsr apparatus_range
 jsr apparatus_clocks
 ldx #0
 jsr apparatus_point
 jsr apparatus_attach
 jsr apparatus_origin
 lda #7
 sta r_launch_wait
 jsr apparatus_display_position
 jsr apparatus_drum_init
 lda #0
 sta r_goal_screen
 sta r_goal_frac
 lda #$C0
 sta r_goal_screen+1
 lda #1
 sta r_got
 rts
.endproc

.proc apparatus_origin
 ; Every arcade course starts at scroll 0 and Charlie x=52. Shorter ropes
 ; therefore place the first pivot closer; this offset is not difficulty.
 lda #52
 sec
 sbc r_arc_x
 sta r_temp_x
 lda #0
 sbc r_arc_x+1
 sta r_temp_x+1
 ldx #31
@pivot:
 lda r_raw_pivot_lo,x
 clc
 adc r_temp_x
 sta r_raw_pivot_lo,x
 sta z_pos
 lda r_raw_pivot_hi,x
 adc r_temp_x+1
 sta r_raw_pivot_hi,x
 sta z_pos+1
 jsr apparatus_scale_x
 lda z_pos
 sta r_pivot_lo,x
 lda z_pos+1
 sta r_pivot_hi,x
 dex
 bpl @pivot
 lda #52
 sta r_arc_x
 lda #0
 sta r_arc_x+1
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
 txa
 pha
 clc
 adc r_start_index
 cmp #104
 bcc :+
 and #7
 ora #96
:
 tay
 lda r_initial_amplitude,y
 sta r_amplitude,x
 pla
 tax
 lda r_goal_ready
 beq :+
 cpx r_goal_rope
 bcc :+
 beq :+
 lda #60
 sta r_length,x
 lda #90
 sta r_amplitude,x
:
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
 lda r_goal_ready
 beq :+
 cpx r_goal_rope
 bcc :+
 beq :+
 jmp @next_rope
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
 lda r_age,x
 cmp #16
 bcc :+
 dec r_age,x
 lda flying
 bne :+
 jsr apparatus_release
:
 pla
@phase:
 sta r_phase,x
@geometry:
 lda r_phase,x
 pha
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
 jsr apparatus_angle
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
 lda r_dxlo,x
 sta r_raw_dxlo,x
 lda r_dxhi,x
 sta r_raw_dxhi,x
 lsr
 sta z_tmp2
 lda r_dxlo,x
 ror
 sta z_tmp
 lsr z_tmp2
 ror z_tmp
 lda r_dxlo,x
 sec
 sbc z_tmp
 sta r_dxlo,x
 lda r_dxhi,x
 sbc z_tmp2
 sta r_dxhi,x
@next_rope:
 inx
 cpx r_limit
 jne @rope
 jmp apparatus_record
.endproc

.proc apparatus_point
 lda r_cycle,x
 and #1
 beq @positive
 lda #0
 sec
 sbc r_raw_dxlo,x
 sta z_off
 lda r_raw_pivot_lo,x
 sbc r_raw_dxhi,x
 sta z_pos
 lda r_raw_pivot_hi,x
 sbc #0
 sta z_pos+1
 jmp @vertical
@positive:
 lda r_raw_dxlo,x
 sta z_off
 lda r_raw_pivot_lo,x
 clc
 adc r_raw_dxhi,x
 sta z_pos
 lda r_raw_pivot_hi,x
 adc #0
 sta z_pos+1
@vertical:
 lda r_dyhi,x
 sta z_dy
 rts
.endproc

.proc apparatus_catch_point
 jsr apparatus_point
 txa
 and #3
 cmp #2
 bne @done
 ; Every fourth rope carries the performer. Arcade catch coordinates use
 ; its penultimate rope segment, four source pixels above the grip.
 ldy r_angle,x
 lda r_sine,y
 sta z_tempword
 lda #0
 sta z_tempword+1
 asl z_tempword
 rol z_tempword+1
 asl z_tempword
 rol z_tempword+1
 lda r_raw_dxlo,x
 sec
 sbc z_tempword
 sta z_off
 lda r_raw_dxhi,x
 sbc z_tempword+1
 sta z_tmp2
 lda r_cycle,x
 and #1
 beq @positive
 lda #0
 sec
 sbc z_off
 lda r_raw_pivot_lo,x
 sbc z_tmp2
 sta z_pos
 lda r_raw_pivot_hi,x
 sbc #0
 sta z_pos+1
 jmp @vertical
@positive:
 lda r_raw_pivot_lo,x
 clc
 adc z_tmp2
 sta z_pos
 lda r_raw_pivot_hi,x
 adc #0
 sta z_pos+1
@vertical:
 lda #90
 sec
 sbc r_angle,x
 tay
 lda r_sine,y
 sta z_tempword
 lda #0
 sta z_tempword+1
 asl z_tempword
 rol z_tempword+1
 asl z_tempword
 rol z_tempword+1
 lda r_dylo,x
 sec
 sbc z_tempword
 lda r_dyhi,x
 sbc z_tempword+1
 sta z_dy
@done:
 rts
.endproc

.proc apparatus_attach
 lda z_pos
 sta r_arc_x
 lda z_pos+1
 sta r_arc_x+1
 lda r_dyhi,x
 sta r_depth+1
 lda #0
 sta r_depth_page
 rts
.endproc

.proc apparatus_record
 ldx r_center
 lda r_goal_ready
 beq :+
 cpx r_goal_rope
 bcc :+
 beq :+
 rts
:
 jsr apparatus_point
 ; The arcade history is the signed grip offset, not scaled world position.
 lda z_pos
 sec
 sbc r_raw_pivot_lo,x
 sta z_tmp2
 lda r_dylo,x
 sta z_tmp
 lda r_dyhi,x
 sta z_dy
 ldx r_hist_index
 lda r_hist_xfrac,x
 sec
 sbc z_off
 sta r_next_vx
 lda r_hist_xlo,x
 sbc z_tmp2
 sta r_next_vx+1
 lda z_tmp
 sec
 sbc r_hist_yfrac,x
 sta r_next_vy
 lda z_dy
 sbc r_hist_yhi,x
 sta r_next_vy+1
 .repeat 2
 lda r_next_vx+1
 cmp #128
 ror r_next_vx+1
 ror r_next_vx
 lda r_next_vy+1
 cmp #128
 ror r_next_vy+1
 ror r_next_vy
 .endrepeat
 lda z_off
 sta r_hist_xfrac,x
 lda z_tmp2
 sta r_hist_xlo,x
 lda z_tmp
 sta r_hist_yfrac,x
 lda z_dy
 sta r_hist_yhi,x
 inx
 txa
 and #3
 sta r_hist_index
 rts
.endproc

.proc apparatus_pump
 lda r_arc_joy
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

.proc apparatus_angle
 ; Identical product bytes, cached for the common 32..90 amplitudes.
 cmp #32
 bcc @multiply
 sbc #32
 stx z_ropeindex
 tax
 lda r_fast_angle_lo,x
 sta z_ptr
 lda r_fast_angle_hi,x
 sta z_ptr+1
 lda (z_ptr),y
 ldx z_ropeindex
 rts
@multiply:
 ; A * sine[Y] / 256. The original MUL truncates the low byte.
 sta z_tmp
 lda r_sine,y
 sta z_tmp2
 lda #0
 ldy #8
@bit:
 lsr z_tmp
 bcc :+
 clc
 adc z_tmp2
:
 ror
 dey
 bne @bit
 rts
.endproc

.proc apparatus_scale_x
 ; ceil(3*x/4), matching the existing Atari renderer. Physics stays unscaled.
 lda z_pos
 sta z_tempword
 lda z_pos+1
 sta z_tempword+1
 lsr z_tempword+1
 ror z_tempword
 lsr z_tempword+1
 ror z_tempword
 lda z_pos
 sec
 sbc z_tempword
 sta z_pos
 lda z_pos+1
 sbc z_tempword+1
 sta z_pos+1
 rts
.endproc

.proc apparatus_display_position
 lda r_arc_x
 sta z_pos
 lda r_arc_x+1
 sta z_pos+1
 jsr apparatus_scale_x
 lda z_pos
 sta world
 lda z_pos+1
 sta world+1
 lda #128
 sec
 sbc r_depth+1
 sta jump_pixels
 lda #0
 sec
 sbc r_vertical+1
 sta velocity
 rts
.endproc

.proc apparatus_release
 lda #1
 sta flying
 sta jumping
 sta r_catch_block
 sta sound_fx
 lda #0
 sta r_arc_frac
 sta r_goal_frac
 sta r_drum_frac
 sta r_drum_frac+1
 sta r_drum_frac+2
 sta r_depth
 sta sound_age
 lda r_next_vx
 sta f_velocity
 lda r_next_vx+1
 sta f_velocity+1
 lda r_next_vy
 sta r_vertical
 lda r_next_vy+1
 sta r_vertical+1
 rts
.endproc

.proc apparatus_step
 lda r_arc_x
 sta r_prev_x
 lda r_arc_x+1
 sta r_prev_x+1
 lda flying
 jne @airborne
 lda z_joy
 sta r_arc_joy
 lda z_fire
 jeq @clock
 lda r_launch_wait
 jne @clock
 jsr apparatus_release
 jmp @clock
@airborne:
 ; Arcade tests the existing position before the next gravity increment.
 lda r_goal_ready
 beq @drum
 lda r_depth_page
 bne @drum
 lda r_depth+1
 sec
 sbc #24
 cmp #3
 bcs @drum
 lda r_arc_goal
 sec
 sbc r_arc_x
 sta z_pos
 lda r_arc_goal+1
 sbc r_arc_x+1
 bne @drum
 lda z_pos
 sec
 sbc #8
 cmp #41
 bcs @drum
 jsr apparatus_display_position
 jmp finish_act
@drum:
 lda r_vertical+1
 bmi @catch
 lda r_depth_page
 bne @catch
 lda r_depth+1
 cmp #124
 bcc @catch
 jsr apparatus_rescue
 bcs @gravity
@catch:
 lda r_catch_block
 bne @gravity
 ldx r_center
 lda r_goal_ready
 beq :+
 cpx r_goal_rope
 beq :+
 bcs @gravity
:
 jsr apparatus_catch_point
 lda r_arc_x
 sec
 sbc z_pos
 clc
 adc #9
 cmp #19
 bcs @gravity
 sta z_tmp
 txa
 and #3
 cmp #2
 beq @vertical
 lda z_tmp
 sec
 sbc #3
 cmp #13
 bcs @gravity
@vertical:
 lda r_depth_page
 beq :+
 lda r_depth+1
 cmp #243
 bcc @gravity
:
 lda z_dy
 sec
 sbc r_depth+1
 clc
 adc #11
 cmp #25
 bcs @gravity
 stx held_rope
 lda r_angle,x
 sta r_amplitude,x
 lda #90
 sta r_phase,x
 lda #0
 sta r_fraction,x
 sta flying
 sta jumping
 lda #7
 sta r_launch_wait
 inc r_got,x
 lda #0
 ldy #5
 jsr apparatus_points_entry
 jmp @clock
@gravity:
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
 ldx #0
 bit r_vertical+1
 bpl :+
 dex
:
 txa
 adc r_depth_page
 sta r_depth_page
 bpl @below_roof
 lda r_depth+1
 cmp #176
 bcs @clock
 jsr apparatus_display_position
 jmp apparatus_hurt_entry
@below_roof:
 lda r_depth+1
 cmp #137
 bcc @clock
 jsr apparatus_display_position
 jmp apparatus_hurt_entry
@clock:
 jsr apparatus_clocks
 lda flying
 bne @move
 ldx r_center
 jsr apparatus_point
 jsr apparatus_attach
 jsr apparatus_pump
 jsr apparatus_goal
 jsr apparatus_scroll_attached
 lda r_launch_wait
 beq @position
 dec r_launch_wait
 jmp @position
@move:
 ; Arcade scroll velocity has the opposite sign to world travel.
 lda r_arc_frac
 clc
 adc f_velocity
 sta r_arc_frac
 lda f_velocity+1
 adc #0
 sta z_tmp
 lda #0
 bit f_velocity+1
 bpl :+
 lda #255
:
 adc #0
 sta z_tmp2
 lda r_arc_x
 sec
 sbc z_tmp
 sta r_arc_x
 lda r_arc_x+1
 sbc z_tmp2
 sta r_arc_x+1
 bmi @lostleft
 jsr apparatus_recenter
 jsr apparatus_scroll_air
@position:
 jmp apparatus_display_position
@lostleft:
 jmp apparatus_hurt_entry
.endproc

.proc apparatus_recenter
 ldx r_center
 lda r_length,x
 clc
 adc #8
 sta z_tmp
 lda r_arc_x
 sec
 sbc r_raw_pivot_lo,x
 sta z_pos
 lda r_arc_x+1
 sbc r_raw_pivot_hi,x
 bmi @left
 bne @right
 lda z_pos
 cmp z_tmp
 bcc @done
 beq @done
@right:
 cpx #29
 bcs @done
 inc r_center
 lda #0
 sta r_catch_block
 txa
 clc
 adc #3
 tax
 lda #0
 cpx #5
 bcc @new
 lda r_fraction-5,x
 pha
 lda #0
 sta r_active-5,x
 pla
@new:
 sta r_fraction,x
 jsr apparatus_activate
 jsr apparatus_range
 jmp apparatus_drum_create
@left:
 lda r_raw_pivot_lo,x
 sec
 sbc r_arc_x
 sta z_pos
 lda r_raw_pivot_hi,x
 sbc r_arc_x+1
 bne @goleft
 lda z_pos
 cmp z_tmp
 bcc @done
@goleft:
 cpx #0
 beq @done
 dec r_center
 lda #0
 sta r_catch_block
 txa
 sec
 sbc #3
 bmi @range
 tax
 lda r_fraction+5,x
 sta r_fraction,x
 lda #0
 sta r_active+5,x
 jsr apparatus_activate
@range:
 jsr apparatus_range
@done:
 rts
.endproc

.proc apparatus_drum_init
 ldx #0
 ; apparatus_origin adjusts the first pivot for each course's rope length
 ; and amplitude. The arcade's drum placement uses that adjusted pivot.
 lda r_raw_pivot_lo
 sec
 sbc r_arc_x
 clc
 adc #52
 clc
 adc r_length
 clc
 adc #44
 sta z_pos
 lda #0
 sta z_pos+1
@slot:
 lda z_pos
 and #248
 sta r_drum_xlo,x
 lda z_pos+1
 sta r_drum_xhi,x
 lda #0
 sta r_drum_frac,x
 cpx #2
 beq @done
 inx
 lda r_length,x
 asl
 clc
 adc #16
 clc
 adc z_pos
 sta z_pos
 bcc @slot
 inc z_pos+1
 jmp @slot
@done:
 lda #$C0
 sta r_drum_xhi+1
 rts
.endproc

.proc apparatus_drum_create
 ldx r_center
 txa
 and #1
 bne @done
 lda r_raw_pivot_lo,x
 sec
 sbc r_arc_x
 clc
 adc #52
 clc
 adc r_length,x
 clc
 adc #76
 sta z_tmp
 lda r_length+2,x
 asl
 sta z_tmp2
 lda r_length+1,x
 asl
 clc
 adc z_tmp2
 clc
 adc #4
 clc
 adc z_tmp
 sta z_pos
 lda #0
 adc #0
 sta z_pos+1
 lda z_pos
 and #248
 sta z_pos
 ; No new drum is created beyond the arcade's six-page course.
 lda #52
 sec
 sbc r_arc_x
 sta z_tempword
 lda #0
 sbc r_arc_x+1
 sta z_tempword+1
 lda z_tempword
 sec
 sbc z_pos
 lda z_tempword+1
 sbc z_pos+1
 cmp #$FA
 bcc @done
 ldy #0
 ldx #1
@lowest:
 lda r_drum_xlo,x
 cmp r_drum_xlo,y
 lda r_drum_xhi,x
 sbc r_drum_xhi,y
 bvc :+
 eor #128
:
 bpl :+
 txa
 tay
:
 inx
 cpx #3
 bne @lowest
 lda z_pos
 sta r_drum_xlo,y
 lda z_pos+1
 sta r_drum_xhi,y
@done:
 rts
.endproc

.proc apparatus_scroll_air
 ldx #2
@drum:
 lda r_drum_frac,x
 clc
 adc f_velocity
 sta r_drum_frac,x
 lda r_drum_xlo,x
 adc f_velocity+1
 sta r_drum_xlo,x
 lda #0
 bit f_velocity+1
 bpl :+
 lda #255
:
 adc r_drum_xhi,x
 sta r_drum_xhi,x
 dex
 bpl @drum
 lda r_goal_frac
 clc
 adc f_velocity
 sta r_goal_frac
 lda r_goal_screen
 adc f_velocity+1
 sta r_goal_screen
 lda #0
 bit f_velocity+1
 bpl :+
 lda #255
:
 adc r_goal_screen+1
 sta r_goal_screen+1
 jmp apparatus_goal_position
.endproc

.proc apparatus_scroll_attached
 lda r_prev_x
 sec
 sbc r_arc_x
 sta z_tmp
 lda r_prev_x+1
 sbc r_arc_x+1
 sta z_tmp2
 ldx #2
@drum:
 lda r_drum_xlo,x
 clc
 adc z_tmp
 sta r_drum_xlo,x
 lda r_drum_xhi,x
 adc z_tmp2
 sta r_drum_xhi,x
 dex
 bpl @drum
 lda r_goal_screen
 clc
 adc z_tmp
 sta r_goal_screen
 lda r_goal_screen+1
 adc z_tmp2
 sta r_goal_screen+1
 jmp apparatus_goal_position
.endproc

.proc apparatus_goal_position
 lda r_goal_ready
 beq @done
 lda r_goal_screen
 clc
 adc r_arc_x
 sta z_pos
 lda r_goal_screen+1
 adc r_arc_x+1
 sta z_pos+1
 lda z_pos
 sec
 sbc #52
 sta r_arc_goal
 lda z_pos+1
 sbc #0
 sta r_arc_goal+1
 lda r_arc_goal
 sec
 sbc #48
 sta z_pos
 lda r_arc_goal+1
 sbc #0
 sta z_pos+1
 jsr apparatus_scale_x
 lda z_pos
 sta stage_end
 lda z_pos+1
 sta stage_end+1
@done:
 rts
.endproc

.proc apparatus_goal
 lda r_goal_ready
 bne @done
 lda r_arc_x
 sec
 sbc #<1333
 lda r_arc_x+1
 sbc #>1333
 bmi @done
 ldx r_center
 txa
 clc
 adc #2
 sta r_goal_rope
 inc r_goal_ready
 lda r_raw_pivot_lo,x
 sec
 sbc r_arc_x
 clc
 adc #52
 clc
 adc r_length,x
 sta z_tmp
 lda r_length+2,x
 asl
 clc
 adc r_length+1,x
 clc
 adc r_length+1,x
 clc
 adc z_tmp
 sta z_pos
 lda #0
 adc #0
 sta z_pos+1
 lda z_pos
 clc
 adc #104
 and #248
 sta r_goal_screen
 lda z_pos+1
 adc #0
 sta r_goal_screen+1
@done:
 rts
.endproc

.proc apparatus_rescue
 ; Test the original three scrolling drum anchors, inclusive 64..96.
 ldx #0
@candidate:
 lda r_drum_xhi,x
 bne @next
 lda r_drum_xlo,x
 sec
 sbc #64
 cmp #33
 bcs @next
 lda #0
 sta r_catch_block
 sta f_velocity
 sta f_velocity+1
 ldy #0
 lda z_joy
 and #12
 bne @moving
 lda flying
 sec
 sbc #1
 cmp #3
 bcc :+
 lda #3
:
 tay
 inc flying
 jmp @launch
@moving:
 cmp #8
 beq @right
 lda #112
 sta f_velocity
 jmp @launch
@right:
 lda #144
 sta f_velocity
 lda #255
 sta f_velocity+1
@launch:
 lda r_rescue_lo,y
 sta r_vertical
 lda r_rescue_hi,y
 sta r_vertical+1
 inc rescue_events
 sec
 rts
@next:
 inx
 cpx #3
 bcc @candidate
 clc
 rts
.endproc
r_rescue_lo: .byte $E0,$70,$00,$80
r_rescue_hi: .byte $FB,$FB,$FB,$F9


.proc apparatus_resume
 lda r_arc_x
 sta r_prev_x
 lda r_arc_x+1
 sta r_prev_x+1
 lda held_rope
 sta r_center
 lda #0
 sta flying
 sta jumping
 sta f_rope_valid
 sta release_guard
 jsr apparatus_range
 lda #1
 sta r_freeze
 jsr apparatus_clocks
 ; A new life gets fresh ropes, retaining their visible swing positions.
 ldx r_first
@fresh:
 lda #60
 sec
 sbc r_length,x
 lsr
 lsr
 sta r_age,x
 inx
 cpx r_limit
 bcc @fresh
 lda #0
 sta r_freeze
 ldx held_rope
 jsr apparatus_point
 jsr apparatus_attach
 lda #0
 sta r_arc_frac
 sta r_goal_frac
 sta r_drum_frac
 sta r_drum_frac+1
 sta r_drum_frac+2
 sta r_catch_block
 sta r_depth
 sta r_arc_joy
 jsr apparatus_scroll_attached
 lda #7
 sta r_launch_wait
 jsr apparatus_display_position
 lda #128
 sec
 sbc r_depth+1
 sta jump_pixels
 rts
.endproc
