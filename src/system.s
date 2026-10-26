; Bank 31, $B400-$BEFF: menus, alternating players, continue, level preparation.
; These routines never switch banks or call an asset renderer.

; Player DMA is unnecessary outside the actual PM vertical span. Staged
; values flip atomically with the screen. Three guard scanlines keep the
; last GTIA graphics latch zero whenever a subsequent band disables DMA.
.proc sys_dma_prepare
 lda back
 asl
 asl
 asl
 asl
 asl
 sta z_tmp
 tax
 lda act
 cmp #2
 jeq @trampolines
 cmp #1
 jeq @monkeys
 cmp #4
 beq @horse
 cmp #5
 beq @trapeze
 lda $0E19,x
 beq :+
 rts
:
 lda #1
 sta $0E19,x
 lda #$3A
 jmp @fill
@trampolines:
 lda #0
 sta $0E19,x
 sta z_cells
 lda #255
 sta z_left
 lda back
 asl
 asl
 tax
 ldy #4
@tramp_bounds:
 lda pm_old_h,x
 beq @tramp_next
 lda pm_old_y,x
 sec
 sbc #3
 cmp z_left
 bcs :+
 sta z_left
:
 lda pm_old_y,x
 clc
 adc pm_old_h,x
 adc #3
 cmp z_cells
 bcc @tramp_next
 sta z_cells
@tramp_next:
 inx
 dey
 bne @tramp_bounds
 ldx z_tmp
 jmp @bands
@horse:
 lda $0E03,x
 bne @horse_goal
 lda $0E19,x
 cmp #2
 bne :+
 rts
:
 lda #2
 sta $0E19,x
 jmp @empty
@horse_goal:
 lda #0
 sta $0E19,x
 lda #188
 sta z_left
 lda #216
 sta z_cells
 bne @bands
@trapeze:
 lda #0
 sta $0E19,x
 lda #255
 sta z_left
 lda #0
 sta z_cells
 lda $0E03,x
 beq @goal
 lda back
 asl
 asl
 ora #3
 tay
 lda pm_old_y,y
 sec
 sbc #3
 sta z_left
 lda pm_old_y,y
 clc
 adc pm_old_h,y
 adc #3
 sta z_cells
@goal:
 lda $0E00,x
 ora $0E01,x
 beq @bands
 lda z_left
 cmp #105
 bcc :+
 lda #105
 sta z_left
:
 lda z_cells
 cmp #209
 bcs @bands
 lda #209
 sta z_cells
@bands:
 lda #$32
 sta $0E10,x
 lda #64
 cmp z_left
 bcc :+
 lda z_cells
 cmp #40
 bcc :+
 lda #$3A
 sta $0E10,x
:
 lda #$32
 sta $0E11,x
 lda #104
 cmp z_left
 bcc :+
 lda z_cells
 cmp #64
 bcc :+
 lda #$3A
 sta $0E11,x
:
 lda #$32
 sta $0E12,x
 lda #104
 cmp z_left
 bcc :+
 lda z_cells
 cmp #96
 bcc :+
 lda #$3A
 sta $0E12,x
:
 lda #$32
 sta $0E13,x
 lda #144
 cmp z_left
 bcc :+
 lda z_cells
 cmp #104
 bcc :+
 lda #$3A
 sta $0E13,x
:
 lda #$32
 sta $0E14,x
 lda #144
 cmp z_left
 bcc :+
 lda z_cells
 cmp #112
 bcc :+
 lda #$3A
 sta $0E14,x
:
 lda #$32
 sta $0E15,x
 lda #176
 cmp z_left
 bcc :+
 lda z_cells
 cmp #144
 bcc :+
 lda #$3A
 sta $0E15,x
:
 lda #$32
 sta $0E16,x
 lda #200
 cmp z_left
 bcc :+
 lda z_cells
 cmp #176
 bcc :+
 lda #$3A
 sta $0E16,x
:
 lda #$32
 sta $0E17,x
 lda #216
 cmp z_left
 bcc :+
 lda z_cells
 cmp #200
 bcc :+
 lda #$3A
 sta $0E17,x
:
 lda #$32
 sta $0E18,x
 lda #255
 cmp z_left
 bcc :+
 lda z_cells
 cmp #216
 bcc :+
 lda #$3A
 sta $0E18,x
:
 lda act
 cmp #2
 bne :+
 lda water
 bne :+
 lda $0E15,x
 ora $0E14,x
 sta $0E14,x ; Act 3 skips the redundant 104-line palette interrupt.
:
 rts
@empty:
 lda #$32
@fill:
 ldy #9
@full:
 sta $0E10,x
 inx
 dey
 bne @full
 rts
@monkeys:
 lda #0
 sta $0E19,x
 sta z_cells
 lda #255
 sta z_left
 lda back
 asl
 asl
 tay
 lda #4
 sta z_counter2
@monkey_player:
 lda $0E00,x
 beq @monkey_next
 lda pm_old_h,y
 beq @monkey_next
 lda pm_old_y,y
 sec
 sbc #3
 cmp z_left
 bcs :+
 sta z_left
:
 lda pm_old_y,y
 clc
 adc pm_old_h,y
 adc #3
 cmp z_cells
 bcc @monkey_next
 sta z_cells
@monkey_next:
 inx
 iny
 dec z_counter2
 bne @monkey_player
 ldx z_tmp
 jmp @bands
.endproc

.proc sys_newgame
 jsr mech_reset
 jsr arcade_reset
 lda #0
 sta player
 sta score
 sta score+1
 sta score+2
 sta stage_hurt
 sta finish_count
 sta clear_count
 sta tramp_clears
 sta resume_pending
 sta paused
 sta extra_awards
 sta bag_awards
 sta combo_awards
 sta skip_awards
 lda #3
 sta lives
 jsr arcade_first_life
 lda #1
 sta round
 sta mode
 sta need_stage
 lda #0
 sta act
 sta water
 sta selected
.if ::ARCADE_CHOOSER
 lda demo
 bne :+
 lda #7
 sta mode
:
.endif
 jsr save_player
 inc player
 jsr save_player
 dec player
 lda #0
 sta fire_latch
 rts
.endproc

; Records: score[3], lives, act, round, water, trampoline clears, hurt, next life.
.proc player_offset
 lda player
 asl
 asl
 asl
 asl
 tax
 rts
.endproc
.proc save_player
 jsr player_offset
 ldy #0
@score:
 lda score,y
 sta player_records,x
 inx
 iny
 cpy #3
 bne @score
 lda lives
 sta player_records,x
 lda act
 sta player_records+1,x
 lda round
 sta player_records+2,x
 lda water
 sta player_records+3,x
 lda tramp_clears
 sta player_records+4,x
 lda stage_hurt
 sta player_records+5,x
 lda next_extra
 sta player_records+6,x
 jmp arcade_save
.endproc
.proc restore_player
 jsr player_offset
 ldy #0
@score:
 lda player_records,x
 sta score,y
 inx
 iny
 cpy #3
 bne @score
 lda player_records,x
 sta lives
 lda player_records+1,x
 sta act
 lda player_records+2,x
 sta round
 lda player_records+3,x
 sta water
 lda player_records+4,x
 sta tramp_clears
 lda player_records+5,x
 sta stage_hurt
 lda player_records+6,x
 sta next_extra
 jsr arcade_restore
 lda #0
 sta fire_latch
 sta fire_prev
 rts
.endproc

.proc sys_after_death
 lda lives
 bne switch_turn
 ; Five television seconds, independent of the act's simulation cadence.
 lda #<300
 ldx #>300
 ldy pal
 beq :+
 lda #<250
 ldx #>250
:
 sta continue_ticks
 stx continue_ticks+1
 jsr continue_read_clock
 lda z_value
 clc
 adc continue_ticks
 sta continue_deadline
 lda z_step
 adc continue_ticks+1
 sta continue_deadline+1
 lda #5
 sta continue_secs
 lda #0
 sta select_latch
 lda #6
 sta mode
 rts
.endproc
.proc switch_turn
 jsr save_player
 lda players
 cmp #2
 bne @same
 lda demo
 bne @same
 lda player
 eor #1
 sta player
 jsr player_offset
 lda player_records+3,x
 bne @other
 lda player
 eor #1
 sta player
 jmp @same
@other:
 jsr restore_player
@same:
.if ::ARCADE_CHOOSER
 ldx player
 lda player_started,x
 bne :+
 lda demo
 bne :+
 lda lives
 beq @over
 lda act
 sta selected
 lda #7
 sta mode
 lda #1
 sta need_stage
 rts
:
.endif
 lda lives
 beq @over
 lda #1
 sta need_stage
 sta mode
 rts
@over:
 jmp sys_title
.endproc

.proc sys_title
 lda #0
 sta mode
 sta demo
 sta paused
 sta resume_pending
 sta player
 sta fire_latch
 sta start_latch
 sta select_latch
 sta continue_ticks
 sta continue_ticks+1
 sta continue_secs
 jsr title_scene
 lda #1
 sta need_stage
 rts
.endproc

.proc continue_read_clock
 ; VBI can roll the low byte while the foreground reads it. Retry on carry.
@read:
 lda host_frames+1
 sta z_step
 lda host_frames
 sta z_value
 lda host_frames+1
 cmp z_step
 bne @read
 rts
.endproc

.proc sys_continue
 jsr continue_read_clock
 lda continue_deadline
 sec
 sbc z_value
 sta continue_ticks
 lda continue_deadline+1
 sbc z_step
 sta continue_ticks+1
 bmi @expired
 ora continue_ticks
 beq @expired
 lda z_fire
 beq @count
 lda #3
 sta lives
 lda #1
 sta resume_pending
 sta mode
 sta need_stage
 lda #0
 sta select_latch
 rts
@count:
 lda select_latch
 beq :+
 lda #0
 sta select_latch
 jmp switch_turn
:
 lda #60
 ldx pal
 beq :+
 lda #50
:
 sta z_step
 lda continue_ticks
 sta z_value
 lda continue_ticks+1
 sta z_tmp2
 ldx #0
@seconds:
 inx
 lda z_value
 sec
 sbc z_step
 sta z_value
 lda z_tmp2
 sbc #0
 sta z_tmp2
 bmi @shown
 ora z_value
 bne @seconds
@shown:
 stx continue_secs
 rts
@expired:
 jmp switch_turn
.endproc

.proc sys_menu
 lda select_latch
 beq @stick
 lda #0
 sta select_latch
 lda players
 eor #3
 sta players
@stick:
 lda z_joy
 and #12
 cmp #4
 bne :+
 lda #1
 sta players
:
 lda z_joy
 and #12
 cmp #8
 bne @done
 lda #2
 sta players
@done:
 rts
.endproc

.proc sys_checkpoint
 jmp mech_save_checkpoint
.endproc

.proc sys_stage
 lda #0
 sta hazard_clock
 sta hazard_clock+1
 sta monkey_seen
 sta monkey_points
 sta spring_pending
 sta grace
 ldx #15
@reset:
 sta bag_taken,x
 dex
 bpl @reset
 lda #$80
 ldx stage_hurt
 beq :+
 lda #$50
:
 sta bonus+1
 lda #0
 sta bonus
 ; Five picks per show; later shows retain the hardest source schedule.
 jsr arcade_rank
 cmp #6
 bcc :+
 lda #5
:
 ldx demo
 beq :+
 lda #0
:
 sta rank
 jsr mech_init
 jsr mech_restore_checkpoint
 jsr mech_demo_reset
 lda #255
 sta hud_menu_cache
 sta hud_menu_cache+1
 rts
.endproc
spacings: .byte 128,120,112,104

.proc sys_hud
 jsr arcade_settings_hud
 ldy #26
 lda player
 clc
 adc #49
 sta (z_hud),y
 ldy #36
 lda lives
 jsr decimal_pair
 ldy #69
 lda #'R'
 sta (z_hud),y
 iny
 lda #'N'
 sta (z_hud),y
 iny
 lda #'D'
 sta (z_hud),y
 ldy #73
 lda round
 jsr decimal_pair
 lda mode
 beq @menu
 cmp #6
 bne @done
 ldy #89
 lda continue_secs
 clc
 adc #48
 sta (z_hud),y
 rts
@menu:
 lda difficulty
 asl
 asl
 ora players
 ldx back
 cmp hud_menu_cache,x
 beq @done
 sta hud_menu_cache,x
 lda #<menu_text
 sta z_src
 lda #>menu_text
 sta z_src+1
 ldy #80
 jsr hud_text
 lda players
 clc
 adc #48
 ldy #80
 sta (z_hud),y
 lda difficulty
 beq @done
 lda #<hard_text
 sta z_src
 lda #>hard_text
 sta z_src+1
 ldy #83
 jsr hud_text
@done:
 rts
.endproc
.proc decimal_pair
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
menu_text: .asciiz "1P NORM L/R:PLAYERS U/D:SKILL            "
hard_text: .asciiz "HARD"
