.proc game_tick
 lda input
 sta z_joy
 lda fire_latch
 sta z_fire
 lda #0
 sta fire_latch
 lda pause_latch
 beq :+
 lda #0
 sta pause_latch
 lda mode
 bne @pausecheck
 lda #1
 sta demo
 jmp @newgame
@pausecheck:
 cmp #2
 bne :+
 lda paused
 eor #1
 sta paused
:
 lda demo
 beq @normal_input
 lda z_fire
 beq @demo_input
 lda #0
 sta demo
 sta mode
 jsr title_scene
 lda #1
 sta need_stage
 rts
@demo_input:
 lda mode
 cmp #2
 bne @normal_input
 jsr mech_demo_input
@normal_input:
 lda paused
 jne @done
 inc anim_clock
 bne :+
 inc anim_clock+1
:
 lda mode
 jeq @title
 cmp #5
 jeq @gameover
 .if ::ARCADE_CHOOSER
 cmp #7
 jeq chooser_tick_entry
 .endif
 cmp #6
 jeq continue_entry
 cmp #2
 jeq @play
 cmp #3
 bne :+
 jsr death_step
:
 lda mode
 cmp #4
 bne :+
 ldx #1
 jsr complete_entry
:
 dec mode_timer
 jne @done
 lda mode
 cmp #1
 beq @begin
 cmp #3
 beq @retry
 lda demo
 jeq arcade_after_act
 ; Demonstration runs all scenes in order.
 lda act
 cmp #2
 bne @advance_act
 lda water
 bne @leave_water
 inc tramp_clears
 lda demo
 bne @enter_water
 lda tramp_clears
 and #1
 bne @advance_act
@enter_water:
 lda #1
 sta water
 jmp @next
@leave_water:
 lda #0
 sta water
@advance_act:
 inc act
 lda act
 cmp #6
 bcc @next
 lda #0
 sta act
 lda round
 cmp #99
 bcs :+
 inc round
:
 inc clear_count
 lda demo
 beq @next
 lda #0
 sta demo
 sta mode
 jsr title_scene
 lda #1
 sta need_stage
 rts
@next:
 lda #0
 sta stage_hurt
 lda #1
 sta need_stage
 sta mode
 rts
@retry:
 jmp after_death_entry
@begin:
 lda #2
 sta mode
 lda #0
 sta missed
 sta missed+1
 sta max_interval
 sta max_dirty
 jsr perf_begin
 lda host_frames
 sta last_present_host
 rts
@title:
 jsr menu_entry
 lda start_latch
 ora z_fire
 jeq @done
 lda #0
 sta start_latch
 sta demo
@newgame:
 jmp newgame_entry
@gameover:
 ; Retire the old unbounded GAME OVER / FIRE TO PLAY AGAIN state.
 lda #$3F
 sta $D500
 jmp sys_title
@play:
 jsr complete_play
 jsr advance_hazards
 jsr mech_tick
 lda mode
 cmp #2
 jne @done
 inc scene_clock
 bne :+
 inc scene_clock+1
:
 jsr game_bonus_tick
 lda mode
 cmp #2
 bne @done
@actions:
 lda act
 bne :+
 jsr lion_arcade_step
 jmp @camera
:
 cmp #2
 bne :+
 lda water
 bne @water_course
 jsr fidelity_tramp_entry
 jmp @camera
:
 cmp #1
 beq @arcade_ground
 cmp #3
 beq @arcade_ground
 cmp #4
 beq @arcade_horse
 cmp #5
 beq @trapeze
@water_course:
 jsr water_step_entry
 jmp @camera
@arcade_horse:
 jsr fidelity_horse_step_entry
 jmp @camera
@arcade_ground:
 jsr fidelity_step_entry
 jmp @camera
@trapeze:
 jsr trapeze_tick
@camera:
 jsr update_camera
@done:
 rts
.endproc

.segment "XL"
.proc game_bonus_tick
 ; Trampoline counts after its landing/clear decision ($8C1F).
 lda act
 cmp #2
 bne :+
 lda water
 beq done
:
 lda act
 beq single
 cmp #1
 beq single
 cmp #2
 beq single
 cmp #3
 beq single
 lda water
 beq ordinary
single:
 lda #1
 sta z_tmp
 sta mech_timer_limit
 bne count
ordinary:
 inc timer_div
 lda #$10
 sta z_tmp
 lda #6
 ldx act
 cpx #4
 bcc :+
 lda #1
 sta z_tmp
 txa
 sec
 sbc #1
:
 sta mech_timer_limit
 jmp compare
count:
 inc timer_div
compare:
 lda timer_div
 cmp mech_timer_limit
 bcc done
 lda #0
 sta timer_div
 sed
 sec
 lda bonus
 sbc z_tmp
 sta bonus
 lda bonus+1
 sbc #0
 sta bonus+1
 cld
 ora bonus
 bne done
 jsr hurt
 rts
done:
 rts
.endproc
.proc game_tramp_bonus_tick
 lda mode
 cmp #4
 beq @done
 jmp game_bonus_tick::single
@done:
 rts
.endproc
.segment "XL"


.segment "CODE"




.proc trampoline_land
 jmp water_land_entry
.endproc

.proc ball_land
 jmp fidelity_ball_land_entry
.endproc

.proc update_camera
 lda #60
 ldx act
 cpx #2
 bcs :+
 lda #48
:
 sta z_tmp
 lda world
 sec
 sbc z_tmp
 sta camera
 lda world+1
 sbc #0
 sta camera+1
 bpl @done
 lda #0
 sta camera
 sta camera+1
@done:
 lda act
 cmp #2
 bcs @ground_limit
 lda #<1242
 sta z_pos
 lda #>1242
 sta z_pos+1
 lda act
 beq @limit
@ground_limit:
 lda act
 cmp #2
 bne :+
 lda water
 bne :+
 lda #<1344
 sta z_pos
 lda #>1344
 sta z_pos+1
 jmp @limit
:
 lda act
 cmp #4
 bcs @return
 lda #<1345
 sta z_pos
 lda #>1345
 sta z_pos+1
@limit:
 lda camera
 cmp z_pos
 lda camera+1
 sbc z_pos+1
 bcc @return
 lda z_pos
 sta camera
 lda z_pos+1
 sta camera+1
@return:
 rts
.endproc

.proc distance_to_player
 ; z_pos becomes absolute(world - z_pos). X preserved.
 lda world
 sec
 sbc z_pos
 sta z_pos
 lda world+1
 sbc z_pos+1
 sta z_pos+1
 bpl @done
 lda z_pos
 eor #255
 clc
 adc #1
 sta z_pos
 lda z_pos+1
 eor #255
 adc #0
 sta z_pos+1
@done:
 rts
.endproc

.proc get_hazard
 lda hazard_xlo,x
 sta z_pos
 lda hazard_xhi,x
 sta z_pos+1
 rts
.endproc
.proc monkey_height
 lda monkey_jump,x
 rts
.endproc

.proc check_hazards
 ; The original six acts have their own arcade collision routines.
 lda bounce_count
 cmp #3
 bne @water
 lda jump_pixels
 cmp #85
 bcc @water
 ldx tramp_index
 lda passed,x
 bne @water
 inc passed,x
 inc water_bags
 lda #0
 ldy #5
 jsr add_points
@water:
 jmp water_collision_entry
.endproc

.proc hurt
 lda mode
 cmp #2
 bne @done
 jsr checkpoint_entry
 lda #0
 sta spring_pending
 lda #3
 sta mode
 ; Let the original 2.32-second death cue finish before retry/continue.
 lda #150
 sta mode_timer
 dec lives
 lda #1
 sta stage_hurt
 lda #2
 sta sound_fx
 lda #0
 sta sound_age
 sta death_drop
 sta height
 sta height+1
 sta jumping
 sta jump_pixels
@done:
 rts
.endproc

.proc add_points
 pha
 lda #$3C
 sta $D500
 pla
 jmp score_add
.endproc

.proc finish_act
 jsr perf_end
 lda #4
 sta mode
 lda #224
 sta mode_timer
 inc finish_count
 lda bonus
 ldy bonus+1
 jsr add_points
 jsr mech_clear_checkpoint
 ldx #0
 jsr complete_entry
@done:
 lda #3
 sta sound_fx
 lda #0
 sta sound_age
 rts
.endproc

.proc rope_point
 jmp mech_rope_point
.endproc
.proc trapeze_tick
 jmp mech_trapeze_tick
.endproc

; ------------------------ Drawing the scene -----------------------------
.proc screen_position
 ; z_pos world coordinate -> sprite_x/xhi after camera subtraction.
 lda z_pos
 sec
 sbc camera
 sta sprite_x
 lda z_pos+1
 sbc camera+1
 sta sprite_xhi
 rts
.endproc

.proc draw_scene
 lda #166
 ldx act
 cpx #1
 bne :+
 lda #96
:
 cpx #3
 bne :+
 lda #136
 ldy mode
 cpy #4
 bne :+
 lda #141
:
 cpx #4
 bne :+
 lda #152
:
 cpx #5
 bne :+
 lda #166
:
 sec
 sbc jump_pixels
 sta feet
 lda mode
 cmp #3
 beq @fallen_feet
 cmp #5
 beq @fallen_feet
 cmp #6
 bne @scene
@fallen_feet:
 lda feet
 clc
 adc death_drop
 sta feet
@scene:
 lda act
 cmp #5
 jeq @trapeze
 cmp #3
 jeq @balls
 cmp #1
 jeq @monkeys
 cmp #2
 jeq @tramp
 cmp #4
 jeq @horse
 lda mode
 cmp #4
 beq :+
 jsr gfx_lion_obstacles
:
 ; A prepared lion+rider composite removes all runtime overlap work.
 lda world
 sec
 sbc camera
 sec
 sbc #12
 sta sprite_x
 lda #0
 sbc #0
 sta sprite_xhi
 lda feet
 sec
 sbc #32
 sta sprite_y
 lda anim_clock
 lsr
 lsr
 lsr
 and #3
 cmp #3
 bne :+
 lda #1
:
 sta z_tmp
 asl
 clc
 adc z_tmp
 sta z_tmp
 lda anim_clock
 lsr
 lsr
 lsr
 and #1
 ldx jumping
 beq :+
 lda #2
:
 clc
 adc z_tmp
 adc #84
 sta sprite_pose
 lda jumping
 bne :+
 lda lion_goal
 bne @standlion
 lda lion_direction
 bne :+
@standlion:
 lda #84
 sta sprite_pose
:
 lda mode
 cmp #4
 bne :+
 lda clear_elapsed
 lsr
 lsr
 lsr
 and #3
 tax
 lda lion_dance_poses,x
 sta sprite_pose
 lda #97 ; Existing raised-foot Charlie on the lion; lion feet remain at Y=154.
 sta sprite_y
:
 jsr gfx_tag_hero
 jsr draw_stamp
 jmp lion_hoop_foreground
@monkeys:
 jsr gfx_monkeys
 jmp tramp_plain_char
@tramp:
 lda water
 beq :+
 jsr water_draw_entry
 lda #130
 sec
 sbc jump_pixels
 sta feet
 jmp tramp_plain_char
:
 jsr draw_flames
 jsr gfx_trampolines
 lda #130
 sec
 sbc jump_pixels
 clc
 adc death_drop
 sta feet
 jmp tramp_hero_entry
@horse:
 jsr gfx_springs
@pony:
 lda world
 sec
 sbc camera
 sec
 sbc #15
 sta sprite_x
 lda #0
 sbc #0
 sta sprite_xhi
 lda finish_pony
 and #252 ; Keep the departing pony on its prepared four-pixel drawing grid.
 clc
 adc sprite_x
 sta sprite_x
 lda #134
 sta sprite_y
 lda anim_clock
 lsr
 lsr
 and #3
 cmp #3
 bne :+
 lda #1
:
 clc
 adc #HORSE
 sta sprite_pose
 jsr gfx_horse
 jsr draw_finish
 jmp tramp_plain_char
@balls:
 jsr prepare_balls
 ; Arcade balls pass in front of the goal. A rider is still on the ball,
 ; not on the podium; only a successful dismount starts the celebration.
 jsr draw_finish
 lda #0
 sta z_hazard
@ball:
 ldx z_hazard
 lda f_active,x
 beq @ball_next
 lda ball_lo,x
 sec
 sbc #10
 sta z_pos
 lda ball_hi,x
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 beq @ballright
 cmp #255
 bne @ball_next
 lda sprite_x
 cmp #236
 bcc @ball_next
 jmp @ball_draw
@ballright:
 lda sprite_x
 cmp #160
 bcs @ball_next
@ball_draw:
 jsr draw_ball
@ball_next:
 inc z_hazard
 lda z_hazard
 cmp #5
 bcc @ball
 jmp tramp_plain_char
@trapeze:
 lda mode
 cmp #4
 bne :+
 rts
:
 jsr mech_rope_draw
tramp_plain_char:
@plainchar:
 lda mode
 cmp #4
 bne :+
 lda act
 cmp #5
 bne :+
 rts
:
 lda feet
 sec
 sbc #38
 sta sprite_y
@charlie:
 lda world
 sec
 sbc camera
 sec
 sbc #8
 sta sprite_x
 lda #0
 sbc #0
 sta sprite_xhi
 lda mode
 cmp #3
 beq @fallen
 cmp #5
 beq @fallen
 cmp #6
 bne @normal
@fallen:
 lda #CHAR_FALL
 sta sprite_pose
 jmp @draw
@normal:
 lda mode
 cmp #4
 bne :+
 jsr tightrope_clear_pose
 sta sprite_pose
 jmp @draw
:
 lda jumping
 beq @walk
 lda #CHAR_JUMP
 sta sprite_pose
 jmp @draw
@walk:
 lda act
 cmp #5
 bne @walking
 lda #CHAR_SWING1
 sta sprite_pose
 jmp @draw
@walking:
 lda anim_clock
 lsr
 lsr
 lsr
 and #1
 clc
 adc #CHAR_WALK1
 sta sprite_pose
@draw:
 jsr gfx_tag_hero
 jsr draw_stamp
 rts
.endproc

.proc draw_flames
 lda #$3A
 sta $D500
 jmp tramp_draw
.endproc
.proc tramp_hero_entry
 lda #$3A
 sta $D500
 jmp tramp_hero_draw
.endproc
.proc tramp_prepare_entry
 lda #$3A
 sta $D500
 jmp tramp_prepare
.endproc
.proc tramp_init_entry
 lda #$3A
 sta $D500
 jmp tramp_init
.endproc
.proc tramp_stamp
 jsr gfx_native_cached
 lda #$3A
 sta $D500
 rts
.endproc
.proc tramp_points
 jsr add_points
 lda #$3A
 sta $D500
 rts
.endproc
.proc tramp_resume_entry
 lda #$3A
 sta $D500
 jsr tramp_resume
 lda #$3F
 sta $D500
 rts
.endproc

draw_finish=gfx_finish

.if ::ARCADE_CHOOSER
.proc ground_finish_goal_entry
 ; Switch banks from resident RAM, after leaving the bank-0 dispatcher.
 sta $D500
 jmp ground_finish_goal_cached
.endproc
.endif


.proc perf_begin
 jsr scene_id
 asl
 asl
 asl
 asl
 tax
 lda host_frames
 sta $0700,x
 lda host_frames+1
 sta $0701,x
 lda presented
 sta $0702,x
 lda presented+1
 sta $0703,x
 rts
.endproc
.proc perf_end
 jsr scene_id
 asl
 asl
 asl
 asl
 tax
 lda host_frames
 sta $0704,x
 lda host_frames+1
 sta $0705,x
 lda presented
 sta $0706,x
 lda presented+1
 sta $0707,x
 lda missed
 sta $0708,x
 lda missed+1
 sta $0709,x
 lda max_interval
 sta $070A,x
 lda fault
 sta $070B,x
 lda max_dirty
 sta $070C,x
 lda lives
 sta $070D,x
 lda #$A5
 sta $070F,x
 rts
.endproc

.proc scene_id
 lda water
 beq :+
 lda #6
 rts
:
 lda act
 rts
.endproc

.proc title_scene
 lda #0
 sta water
 sta act
 rts
.endproc

; Banked routines run only with bank zero selected. VBI/DLI use RAM exclusively.
.proc water_collision_entry
 lda #$FD
 sta $D500
 jsr water_collision
 lda #$3C
 sta $D500
 rts
.endproc
.proc water_draw_entry
 lda #$3C
 sta $D500
 jmp water_draw
.endproc
.proc water_stamp
 lda sprite_pose
 cmp #95
 bne @ordinary
 lda #10
 sta gfx_cached_kind
 jsr gfx_cached_select
 jmp @restore
@ordinary:
 jsr draw_stamp
@restore:
 lda #$3C
 sta $D500
 rts
.endproc

.proc advance_hazards
 inc hazard_clock
 bne :+
 inc hazard_clock+1
:
 lda grace
 beq :+
 dec grace
:
 ; Legacy hazard clock remains for diagnostics; apparatus owns its clocks.
 lda water
 bne @done
 ldx rank
 beq @done
 lda scene_clock
 and speed_masks,x
 bne @done
 inc hazard_clock
 bne @done
 inc hazard_clock+1
@done:
 rts
.endproc
speed_masks: .byte 255,7,3,1,1,1

.proc newgame_entry
 lda #$3F
 sta $D500
 jmp sys_newgame
.endproc

.proc after_death_entry
 lda #$3F
 sta $D500
 jmp sys_after_death
.endproc

.proc continue_entry
 lda #$3F
 sta $D500
 jmp sys_continue
.endproc

.proc menu_entry
 lda #$3F
 sta $D500
 jmp sys_menu
.endproc

.proc checkpoint_entry
 lda #$3F
 sta $D500
 jmp sys_checkpoint
.endproc

.proc stage_rules_entry
 lda #$3F
 sta $D500
 jmp sys_stage
.endproc

.proc hud_rules_entry
 lda #$3F
 sta $D500
 jmp sys_hud
.endproc

.proc pot_reward_entry
 lda #$3C
 sta $D500
 jmp reward_pot
.endproc

.proc monkey_reward_entry
 lda #$3C
 sta $D500
 jmp reward_monkey
.endproc

.proc land_reward_entry
 lda #$3C
 sta $D500
 jmp reward_land
.endproc

.proc ball_reward_entry
 lda #$3C
 sta $D500
 jmp reward_ball
.endproc

.proc bag_collision_entry
 lda #$3C
 sta $D500
 jmp lion_bag_collision
.endproc

.proc bag_draw_entry
 lda #$3C
 sta $D500
 jmp lion_bag_draw
.endproc

.segment "MECHANICS"
.proc fidelity_init_entry
 lda #$3E
 sta $D500
 jsr fidelity_init
 lda #$3F
 sta $D500
 rts
.endproc
.proc fidelity_step_entry
 lda #$3E
 sta $D500
 jmp fidelity_step
.endproc
.proc fidelity_ball_land_entry
 lda #$3E
 sta $D500
 jmp fidelity_ball_land
.endproc
.proc fidelity_clear_text_entry
 lda mode
 cmp #4
 bne @done
 lda #$3E
 sta $D500
 jmp fidelity_clear_text
@done:
 rts
.endproc
.proc fidelity_tramp_entry
 lda #$31
 sta $D500
 jsr fidelity_tramp_step
 jmp game_tramp_bonus_tick
.endproc
.proc fidelity_resume_entry
 lda #$3E
 sta $D500
 jsr fidelity_resume
 lda #$3F
 sta $D500
 rts
.endproc
.proc fidelity_horse_gravity_entry
 lda #$3D
 sta $D500
 jmp fidelity_horse_gravity
.endproc
.proc fidelity_horse_launch_entry
 lda #$3D
 sta $D500
 jmp fidelity_horse_launch
.endproc
.proc fidelity_horse_init_entry
 lda #$3D
 sta $D500
 jsr fidelity_horse_init
 lda #$3F
 sta $D500
 rts
.endproc
.proc fidelity_horse_step_entry
 lda #$3D
 sta $D500
 jmp fidelity_horse_step
.endproc
.proc fidelity_points
 jsr add_points
 lda #$3E
 sta $D500
 rts
.endproc
.proc fidelity_reward
 jsr land_reward_entry
 lda #$3E
 sta $D500
 rts
.endproc

.segment "CODE"

.segment "CODE"

.segment "AUX"
.proc tramp_bag
 lda #$A0
 ldx #$3A
 ldy water
 beq :+
 lda #$90
 ldx #$3C
:
 sta @lo+2
 sta @hi+2
 stx $D500
 lda tramp_index
 asl
 asl
 sta z_tmp
 lda sprite_x
 and #3
 ora z_tmp
 asl
 tay
@lo:
 lda $A000,y
 sta z_rom
@hi:
 lda $A001,y
 sta z_rom+1
 ldy #0
 lda (z_rom),y
 sta z_cells
 inc z_rom
 bne :+
 inc z_rom+1
:
 lda bg_count
 clc
 adc gfx_reserve
 sta z_new
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 sta z_col
@cell:
 ldy #0
 lda (z_rom),y
 sta z_colorflag
 and #127
 clc
 adc z_col
 cmp #40
 bcs @next
 sta z_left
 iny
 lda (z_rom),y
 tax
 lda row_lo,x
 clc
 adc z_left
 sta z_cell
 lda row_hi,x
 adc z_map+1
 sta z_cell+1
 lda z_colorflag
 and #128
 ora z_new
 ldy #0
 sta (z_cell),y
 ldx z_new
 lda glyph_lo,x
 sec
 sbc #2
 sta z_glyph
 lda glyph_hi,x
 ora band_font
 sbc #0
 sta z_glyph+1
 .repeat 8,I
 ldy #I+2
 lda (z_rom),y
 sta (z_glyph),y
 .endrepeat
 inc z_new
@next:
 lda z_rom
 clc
 adc #10
 sta z_rom
 bcc :+
 inc z_rom+1
:
 dec z_cells
 jne @cell
 rts
.endproc
.segment "CODE"

.segment "CODE"
.proc water_step_entry
 lda #$3C
 sta $D500
 jmp water_step
.endproc
.proc water_land_entry
 lda #$3C
 sta $D500
 jmp water_land
.endproc
.proc water_init_entry
 lda #$3C
 sta $D500
 jsr water_init
 lda #$3F
 sta $D500
 rts
.endproc
.proc water_resume_entry
 lda #$3C
 sta $D500
 jsr water_resume
 lda #$3F
 sta $D500
 rts
.endproc
.proc complete_entry
 ; X selects a bounded bank-17 routine. Preserve the caller's mapped bank.
 lda $D500
 pha
 lda #$31
 sta $D500
 jsr complete_dispatch
 pla
 sta $D500
 rts
.endproc
.proc complete_stamp
 jsr draw_stamp
 lda #$31
 sta $D500
 rts
.endproc
.proc complete_cached
 jsr gfx_cached_select
 lda #$3C
 sta $D500
 rts
.endproc

.proc complete_lion_land
 ldx #3
 jmp complete_entry
.endproc
.proc complete_stage
 ldx #4
 jmp complete_entry
.endproc
.proc complete_play
 lda act
 bne @done
 lda secret_visible
 beq @done
 ldx #5
 jmp complete_entry
@done:
 rts
.endproc
.proc complete_draw_entry
 lda #$31
 sta $D500
 jmp detail_draw
.endproc

.proc complete_tramp_prize
 ldx #6
 jmp complete_entry
.endproc

.segment "CODE"
.proc complete_lion_bag
 ldx #7
 jmp complete_entry
.endproc


.proc horse_resume_entry
 lda #$3D
 sta $D500
 jsr fidelity_horse_resume
 lda #$3F
 sta $D500
 rts
.endproc

.proc rope_bar_entry
 lda #$3C
 sta $D500
 jmp complete_rope_bar_endpoint
.endproc

; Non-top endpoint cells have a single contiguous run of visible scanlines.
; Clip once per cell instead of rechecking the rope's Y bound on every byte.
.proc rope_partial_fast
 lda #7
 ldx r_draw_row
 cpx r_draw_bottomrow
 bcc :+
 lda r_draw_lastline
:
 sta z_body
 ldy #0
 lda r_draw_sign
 bne @mirror
@plain:
 lda (z_data),y
 and r_draw_mask
 sta (z_glyph),y
 cpy z_body
 beq @tail
 iny
 bne @plain
@mirror:
 lda (z_data),y
 tax
 lda $7A00,x
 and r_draw_mask
 sta (z_glyph),y
 cpy z_body
 beq @tail
 iny
 bne @mirror
@tail:
 iny
 cpy #8
 beq @done
 lda #0
@clear:
 sta (z_glyph),y
 iny
 cpy #8
 bne @clear
@done:
 rts
.endproc

.segment "CODE"
.proc detail_entry
 ldx #8
 jmp complete_entry
.endproc
.proc detail_hud_entry
 ldx #9
 jmp complete_entry
.endproc
.proc detail_hurt_entry
 sta tramp_death_reason
 ldx #10
 jmp complete_entry
.endproc
.proc detail_death_entry
 ldx #11
 jmp complete_entry
.endproc
.proc detail_tramp_entry
 lda #$31
 sta $D500
 jmp detail_trampolines
.endproc
.proc detail_cached
 jsr gfx_native_cached
 lda #$31
 sta $D500
 rts
.endproc
.proc tramp_attacks_entry
 lda #$3A
 sta $D500
 jmp tramp_attacks
.endproc

lion_dance_poses: .byte 0,5,0,5
.proc detail_hurt_call
 jsr hurt
 lda #$31
 sta $D500
 rts
.endproc

.proc detail_points
 jsr add_points
 lda #$31
 sta $D500
 rts
.endproc

.proc detail_track_signs
 lda act
 cmp #4
 bne @done
 lda #$31
 sta $D500
 jmp detail_signs
@done:
 rts
.endproc

.segment "CODE"
.proc fidelity_hurt
 jsr hurt
 lda #$3E
 sta $D500
 rts
.endproc
