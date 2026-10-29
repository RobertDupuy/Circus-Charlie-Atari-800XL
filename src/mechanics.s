; Native bounded mechanics; arcade apparatus rules live in bank 29.
; All active work is bounded. No asset conversion or banked CPU interpreter.
.proc mech_reset
 lda #0
 ldx #0
@clear:
 sta $D900,x
 sta $DA00,x
 sta $DB00,x
 sta $DC00,x
 inx
 bne @clear
 rts
.endproc

.segment "MECHANICS"
.proc gfx_dma_table
 lda front
 asl
 asl
 asl
 asl
 asl
 ora #8
 tay
 ldx #8
@copy:
 lda $0E10,y
 sta $DCE0,x
 dey
 dex
 bpl @copy
 ldx front
 rts
.endproc

.segment "CODE"
.proc gfx_dma_prepare
 ldx act
 lda gfx_dma_opcode,x
 cmp #$F0
 beq :+
 rts
:
 lda #$3F
 sta $D500
 jmp sys_dma_prepare
.endproc
.proc gfx_dma_dispatch
 ldx act
 lda gfx_dma_opcode,x
 cmp #$F0
 beq :+
 ldx front
 rts
:
 jmp gfx_dma_table
.endproc
gfx_dma_opcode: .byte $D0,$F0,$F0,$D0,$F0,$F0
.segment "MECHANICS"

.proc mech_init
 lda #0
 ldx #0
@clear:
 sta $D900,x
 inx
 bne @clear
 sta first_hazard
 sta horse_finish
 sta release_guard
 sta f_rope_valid
 sta mech_pm_overflow
 sta mech_pm_peak
 lda act
 cmp #2
 bne :+
 lda water
 jeq fidelity_init_entry
 jmp water_init_entry
:
 cmp #1
 jeq fidelity_init_entry
 cmp #3
 jeq fidelity_init_entry
 cmp #4
 jeq fidelity_horse_init_entry
 cmp #5
 jeq apparatus_init_entry
 cmp #0
 jeq @arcadelion
 rts
@arcadelion:
 jmp lion_arcade_init
.endproc

.proc mech_tick
 rts
.endproc


.proc mech_spring_reward
 lda spring_pending
 cmp #3
 bcs :+
 inc spring_pending
:
 ldy spring_pending
 lda #0
 jmp add_points
.endproc




.proc mech_rope_point
 lda #$3D
 sta $D500
 jmp apparatus_point
.endproc

.proc mech_trapeze_tick
 lda #$3D
 sta $D500
 jmp apparatus_step
.endproc

.proc mech_rescue
 rts
.endproc

.proc mech_checkpoint_pointer
 lda #0
 sta z_ptr
 lda player
 clc
 adc #$DA
 sta z_ptr+1
 rts
.endproc
.proc mech_clear_checkpoint
 jsr mech_checkpoint_pointer
 ldy #0
 lda #0
 sta (z_ptr),y
 rts
.endproc
.proc mech_save_checkpoint
 jsr mech_checkpoint_pointer
 ldy #0
 lda #1
 sta (z_ptr),y
 iny
 lda act
 sta (z_ptr),y
 iny
 lda water
 sta (z_ptr),y
 iny
 lda world
 and #$C0
 sta z_tempword
 lda world+1
 sta z_tempword+1
 lda stage_end
 sec
 sbc #96
 sta z_pos
 lda stage_end+1
 sbc #0
 sta z_pos+1
 lda z_tempword
 sec
 sbc z_pos
 lda z_tempword+1
 sbc z_pos+1
 bmi :+
 lda z_pos
 sta z_tempword
 lda z_pos+1
 sta z_tempword+1
:
 lda z_tempword
 sta (z_ptr),y
 iny
 lda z_tempword+1
 sta (z_ptr),y
 iny
 lda scene_clock
 sta (z_ptr),y
 iny
 lda scene_clock+1
 sta (z_ptr),y
 iny
 lda hazard_clock
 sta (z_ptr),y
 iny
 lda hazard_clock+1
 sta (z_ptr),y
 iny
 lda current_ball
 sta (z_ptr),y
 iny
 lda held_rope
 sta (z_ptr),y
 iny
 lda tramp_index
 sta (z_ptr),y
 iny
 ldx #0
@balls:
 lda ball_lo,x
 sta (z_ptr),y
 iny
 inx
 cpx #32
 bne @balls
 ldx #0
@hazards:
 lda hazard_xlo,x
 sta (z_ptr),y
 iny
 inx
 cpx #32
 bne @hazards
 ldx #0
@rope:
 lda rope_phase,x
 sta (z_ptr),y
 iny
 inx
 cpx #48
 bne @rope
 ldx #0
@passed:
 lda passed,x
 sta (z_ptr),y
 iny
 inx
 cpx #16
 bne @passed
 ldx #0
@fidelity:
 lda f_direction,x
 sta (z_ptr),y
 iny
 inx
 cpx #44
 bne @fidelity
 lda act
 cmp #4
 jeq apparatus_save_horse
 cmp #5
 jeq apparatus_save_rope
 ; Only Act 1 owns the lion block. Do not branch on the preceding CMP #5:
 ; that skipped this save for every lion death, then restored an empty block.
 cmp #0
 bne @saved
 ldx #0
@lion:
 lda $D900,x
 sta (z_ptr),y
 iny
 inx
 cpx #64
 bne @lion
@saved:
 rts
.endproc
.proc mech_restore_checkpoint
 lda #0
 sta resume_pending
 lda stage_hurt
 jeq @done
 lda mode
 jeq @done
 jsr mech_checkpoint_pointer
 ldy #0
 lda (z_ptr),y
 jeq @done
 iny
 lda (z_ptr),y
 cmp act
 jne @done
 iny
 lda (z_ptr),y
 cmp water
 jne @done
 iny
 lda (z_ptr),y
 sta world
 iny
 lda (z_ptr),y
 sta world+1
 iny
 lda (z_ptr),y
 sta scene_clock
 iny
 lda (z_ptr),y
 sta scene_clock+1
 iny
 lda (z_ptr),y
 sta hazard_clock
 iny
 lda (z_ptr),y
 sta hazard_clock+1
 iny
 lda (z_ptr),y
 sta current_ball
 iny
 lda (z_ptr),y
 sta held_rope
 iny
 lda (z_ptr),y
 sta tramp_index
 iny
 ldx #0
@balls:
 lda (z_ptr),y
 sta ball_lo,x
 iny
 inx
 cpx #32
 bne @balls
 ldx #0
@hazards:
 lda (z_ptr),y
 sta hazard_xlo,x
 iny
 inx
 cpx #32
 bne @hazards
 ldx #0
@rope:
 lda (z_ptr),y
 sta rope_phase,x
 iny
 inx
 cpx #48
 bne @rope
 ldx #0
@passed:
 lda (z_ptr),y
 sta passed,x
 iny
 inx
 cpx #16
 bne @passed
 ldx #0
@fidelity:
 lda (z_ptr),y
 sta f_direction,x
 iny
 inx
 cpx #44
 bne @fidelity
 lda act
 cmp #5
 jeq apparatus_restore_rope
 cmp #4
 bne :+
 jsr apparatus_restore_horse
 jmp horse_resume_entry
:
 lda act
 bne @minimum
 ldx #0
@lion:
 lda (z_ptr),y
 sta $D900,x
 iny
 inx
 cpx #64
 bne @lion
 lda #0
 sta lion_frac
 sta lion_phase
 sta lion_direction
 sta lion_goal
 sta lion_buffer
@minimum:
 lda act
 cmp #1
 beq @arcade_resume
 cmp #3
 bne @legacy_minimum
@arcade_resume:
 jmp fidelity_resume_entry
@legacy_minimum:
 lda world+1
 bne @support
 lda world
 cmp #60
 bcs @support
 lda #60
 sta world
@support:
 lda act
 cmp #2
 beq @tramp
 cmp #5
 beq @trapeze
 jmp @finish
@tramp:
 lda water
 jeq tramp_resume_entry
 jmp water_resume_entry
@trapeze:
 ldx held_rope
 jsr mech_rope_point
 lda z_pos
 sta world
 lda z_pos+1
 sta world+1
@finish:
 lda #90
 sta grace
 inc checkpoint_restores
 jsr update_camera
@done:
 rts
.endproc



.proc mech_rope_draw
 jmp apparatus_draw
.endproc
; Run-length input packets: duration (1..255), joystick/fire byte.
.proc mech_demo_reset
 lda #$3F
 sta $D500
 jsr scene_id
 asl
 tax
 lda $9000,x
 sta demo_cursor
 lda $9001,x
 sta demo_cursor+1
 lda #0
 sta demo_remaining
 rts
.endproc
.proc mech_demo_input
 lda #$3F
 sta $D500
 lda demo_remaining
 bne @input
 lda demo_cursor
 sta z_ptr
 lda demo_cursor+1
 sta z_ptr+1
 ldy #0
 lda (z_ptr),y
 sta demo_remaining
 iny
 lda (z_ptr),y
 sta demo_value
 lda demo_cursor
 clc
 adc #2
 sta demo_cursor
 bcc @input
 inc demo_cursor+1
@input:
 dec demo_remaining
 lda demo_value
 and #15
 sta z_joy
 lda demo_value
 and #$80
 sta z_fire
 rts
.endproc
; All six original acts now use arcade schedules, not the legacy tables.
; Extra helpers use the unused half of the already resident XL page block.
.segment "XL"
; Ropes are disjoint fixed-Y cells, drawn before Charlie. The prepared bytes
; already contain the arena background, so no old-glyph read or mask is needed.
.proc draw_rope_cells
 rts
.endproc

crowd_high_mod:
 .repeat 256,I
 .byte (I*64) .mod 40
 .endrepeat
.segment "MECHANICS"


.segment "MECHANICS"
arcade_tramp_lo: .byte 52,118,184,244,54,120,180,246,56,116,182,248,52,118,184,244,54,120,180,246,56,116,182,248,52
arcade_tramp_hi: .byte 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6

.segment "XL"
; Share the row budget with the handlebar renderer's ROM bank. The caller
; selects the crowd bank next, so there is no bank to restore here.
.proc rope_glyph_budget
 lda act
 bne @other
 ; The scrolling Lion anchor is cell-aligned: its nine approved poses use
 ; at most 26 cells in that phase (28 in the three shifted goal phases).
 ; Reserving the actual phase leaves room for both hidden reward objects.
 lda world
 sec
 sbc camera
 and #3
 beq @aligned_lion
 lda #28
 bne @lion_budget
@aligned_lion:
 lda #26
@lion_budget:
 sta gfx_reserve
 sta gfx_reserve+1
 sta gfx_reserve+2
 rts
@other:
 cmp #4
 bne :+
 jmp horse_glyph_budget
:
 cmp #5
 bne @done
 lda #$3C
 sta $D500
 jmp complete_rope_budget
@done:
 rts
.endproc
.segment "MECHANICS"

.proc apparatus_init_entry
 jsr apparatus_load_atlas
 lda #$3D
 sta $D500
 jsr apparatus_init
 lda #$3F
 sta $D500
 rts
.endproc
.proc apparatus_points_entry
 jsr add_points
 lda #$3D
 sta $D500
 rts
.endproc
.proc apparatus_hurt_entry
 jsr hurt
 lda #$3D
 sta $D500
 rts
.endproc
.proc apparatus_load_atlas
 lda #$27
 sta $D500
 lda $8EB1
 sta r_atlas
 lda $8EB2
 sta r_atlas+1
 lda $8EB0
 ora #$20
 sta r_atlas_bank
 lda #$3D
 sta $D500
 lda #<r_cache_positive
 sta z_src
 lda #>r_cache_positive
 sta z_src+1
 lda #0
 sta z_dst
 lda #$78
 sta z_dst+1
 ldx #2
 jsr copy_pages
 lda #<r_cache_negative
 sta z_src
 lda #>r_cache_negative
 sta z_src+1
 lda #0
 sta z_dst
 lda #$7E
 sta z_dst+1
 ldx #2
 jsr copy_pages
 lda r_atlas
 sta z_tmp
 lda r_atlas+1
 sta z_tmp2
 ldx #0
@atlas:
 lda z_tmp
 sta $7400,x
 lda z_tmp2
 sta $7600,x
 lda z_tmp
 clc
 adc #8
 sta z_tmp
 bcc :+
 inc z_tmp2
:
 inx
 bne @atlas
@atlas2:
 lda z_tmp
 sta $7500,x
 lda z_tmp2
 sta $7700,x
 lda z_tmp
 clc
 adc #8
 sta z_tmp
 bcc :+
 inc z_tmp2
:
 inx
 bne @atlas2
 ldx #0
@reverse:
 txa
 sta z_tmp
 lda #0
 ldy #4
@pair:
 asl
 asl
 sta z_tmp2
 lda z_tmp
 and #3
 ora z_tmp2
 sta z_tmp2
 lsr z_tmp
 lsr z_tmp
 lda z_tmp2
 dey
 bne @pair
 sta $7A00,x
 inx
 bne @reverse
 rts
.endproc

.segment "XL"
.proc apparatus_restore_common
 lda #$20
 sta $D500
 lda #0
 sta z_src
 sta z_dst
 lda #$A0
 sta z_src+1
 lda #$70
 sta z_dst+1
 ldx #16
 jmp copy_pages
.endproc

; Exact-angle rope tiles: cached full cells and bounded end-cell clipping.
.segment "MECHANICS"
.proc apparatus_draw
 lda r_first
 sta r_draw_index
@rope:
 ldx r_draw_index
 lda r_goal_ready
 beq :+
 cpx r_goal_rope
 beq :+
 jcs @next
:
 lda r_pivot_lo,x
 sec
 sbc camera
 sta sprite_x
 lda r_pivot_hi,x
 sbc camera+1
 sta sprite_xhi
 lda sprite_xhi
 beq @visible
 cmp #255
 jne @next
 lda sprite_x
 cmp #208
 jcc @next
@visible:
 lda sprite_xhi
 bne @left
 lda sprite_x
 cmp #208
 jcs @next
@left:
 lda r_cycle,x
 and #1
 sta r_draw_sign
 beq @boundsright
 lda sprite_xhi
 jmi @next
 lda sprite_x
 sec
 sbc r_dxhi,x
 sta z_tmp
 lda sprite_xhi
 sbc #0
 bmi @boundsok
 jne @next
 lda z_tmp
 cmp #160
 jcs @next
 jmp @boundsok
@boundsright:
 lda sprite_xhi
 bmi @fromleft
 jne @next
 lda sprite_x
 cmp #160
 jcs @next
 jmp @boundsok
@fromleft:
 lda sprite_x
 clc
 adc r_dxhi,x
 lda sprite_xhi
 adc #0
 jmi @next
@boundsok:
 lda sprite_x
 and #3
 sta z_tmp
 lda r_draw_sign
 beq @positive
 lda #3
 sec
 sbc z_tmp
 sta z_tmp
 lda #51
 sec
 sbc z_tmp
 sta r_draw_max
 sec
 sbc r_dxhi,x
 sta r_draw_min
 lda sprite_x
 sec
 sbc r_draw_max
 sta r_draw_left
 lda #51
 sta r_draw_max
 jmp @extent
@positive:
 lda #0
 sta r_draw_min
 lda z_tmp
 clc
 adc r_dxhi,x
 sta r_draw_max
 lda sprite_x
 sec
 sbc z_tmp
 sta r_draw_left
@extent:
 lda r_dyhi,x
 sta r_draw_bottom
 ; Directory index = angle * 16 + sub-cell alignment * 4.
 lda #0
 sta z_ptr+1
 lda r_angle,x
 asl
 rol z_ptr+1
 asl
 rol z_ptr+1
 asl
 rol z_ptr+1
 asl
 rol z_ptr+1
 sta z_ptr
 lda z_tmp
 asl
 asl
 ora z_ptr
 sta z_ptr
 lda z_ptr+1
 clc
 adc #$89
 sta z_ptr+1
 lda #$27
 sta $D500
 ldy #0
 lda (z_ptr),y
 ora #$20
 sta z_bank
 iny
 lda (z_ptr),y
 sta z_rom
 iny
 lda (z_ptr),y
 sta z_rom+1
 lda z_bank
 sta $D500
 ldx r_draw_index
 lda r_length,x
 sec
 sbc #32
 lsr
 lsr
 tay
 lda (z_rom),y
 pha
 and #3
 sta r_draw_partial
 pla
 lsr
 lsr
 sta r_draw_full
 lda z_rom
 clc
 adc #8
 sta z_rom
 bcc :+
 inc z_rom+1
:
 jsr apparatus_record_addresses
 lda r_draw_left
 lsr
 lsr
 sta r_draw_basecol
 lda r_draw_left
 cmp #208
 bcc :+
 lda r_draw_basecol
 ora #$C0
 sta r_draw_basecol
:
 lda r_draw_min
 lsr
 lsr
 sta r_draw_mincol
 lda r_draw_max
 lsr
 lsr
 sta r_draw_maxcol
 lda r_draw_bottom
 and #7
 sta r_draw_lastline
 lda r_draw_bottom
 lsr
 lsr
 lsr
 sta r_draw_bottomrow
 lda r_draw_sign
 beq @endright
 lda r_draw_min
 and #3
 tax
 lda r_keep_right,x
 sta r_draw_endmask
 lda #$7E
 bne @cachepage
@endright:
 lda r_draw_max
 and #3
 eor #3
 tax
 lda r_keep_left,x
 sta r_draw_endmask
 lda #$78
@cachepage:
 sta r_draw_cachepage
 lda #0
 sta r_draw_offset
 lda r_draw_full
 sta r_draw_count
 beq :+
 jsr apparatus_draw_full
:
 lda r_draw_partial
 sta r_draw_count
 beq :+
 jsr apparatus_draw_cells
:
 jsr rope_bar_entry
@next:
 inc r_draw_index
 lda r_draw_index
 cmp r_limit
 jcc @rope
 jmp apparatus_draw_supports
.endproc
.proc apparatus_draw_cells
cell:
 ldx r_draw_offset
record_row = *
 lda r_record+1,x
 sta r_draw_row
 cmp r_draw_bottomrow
 jcc rowvisible
 jeq rowvisible
 jmp next
rowvisible:
record_column = *
 lda r_record,x
 and #15
 sta r_draw_col
 lda r_draw_sign
 beq :+
 lda #12
 sec
 sbc r_draw_col
 sta r_draw_col
:
 lda r_draw_col
 cmp r_draw_mincol
 jcc next
 cmp r_draw_maxcol
 bcc :+
 beq :+
 jmp next
:
 clc
 adc r_draw_basecol
 cmp #40
 jcs next
 sta z_left
 ldy r_draw_row
 lda row_lo,y
 clc
 adc z_left
 sta z_cell
 sta z_off
 lda row_hi,y
 adc #0
 sta z_off+1
 ora z_map+1
 sta z_cell+1
record_id = *
 lda r_record+2,x
 sta r_draw_id
record_flags = *
 lda r_record,x
 and #128
 asl
 lda #0
 rol
 sta r_draw_id+1
 lda #255
 sta r_draw_mask
 lda r_draw_sign
 beq rightedge
 lda r_draw_col
 cmp r_draw_mincol
 bne maskready
 beq endmask
rightedge:
 lda r_draw_col
 cmp r_draw_maxcol
 bne maskready
endmask:
 lda r_draw_endmask
 sta r_draw_mask
maskready:
 lda r_draw_mask
 cmp #255
 jne allocate
 lda r_draw_row
 cmp r_draw_bottomrow
 bcc cached
 lda r_draw_lastline
 cmp #7
 bne allocate
cached:
 lda r_draw_cachepage
 clc
 adc r_draw_id+1
 sta cache_read+2
 ldx r_draw_id
cache_read:
 lda $7800,x
 cmp #255
 beq allocate
 ldy #0
 sta (z_cell),y
 jmp dirty
allocate:
 lda r_atlas_bank
 sta $D500
 lda free_glyph
 cmp #128
 jcs overflow
 inc free_glyph
 ldy #0
 sta (z_cell),y
 tax
 lda glyph_lo,x
 sta z_glyph
 lda glyph_hi,x
 ora band_font
 sta z_glyph+1
 lda r_draw_id+1
 clc
 adc #$74
 sta atlaslo+2
 adc #2
 sta atlashi+2
 ldx r_draw_id
atlaslo:
 lda $7400,x
 sta z_data
atlashi:
 lda $7600,x
 sta z_data+1
 lda r_draw_mask
 cmp #255
 jne partial
 lda r_draw_row
 asl
 asl
 asl
 clc
 adc #7
 cmp r_draw_bottom
 bcc whole
 beq whole
 jmp partial
whole:
 lda r_draw_sign
 bne mirror
 .repeat 8,I
 ldy #I
 lda (z_data),y
 sta (z_glyph),y
 .endrepeat
 jmp dirty
mirror:
 .repeat 8,I
 ldy #I
 lda (z_data),y
 tax
 lda $7A00,x
 sta (z_glyph),y
 .endrepeat
 jmp dirty
partial:
 lda r_draw_row
 asl
 asl
 asl
 sta r_draw_top
 lda r_draw_row
 beq :+
 jsr rope_partial_fast
 jmp dirty
:
 ldy #0
byte:
 lda (z_data),y
 ldx r_draw_sign
 beq :+
 tax
 lda $7A00,x
:
 and r_draw_mask
 sta z_tmp
 tya
 clc
 adc r_draw_top
 cmp r_draw_bottom
 bcc within
 beq within
 lda #0
 sta z_tmp
within:
 lda r_draw_row
 bne store
 tya
 beq gold
 cmp #2
 bne store
 lda r_draw_mask
 eor #255
 and #$AA
 ora z_tmp
 sta z_tmp
 jmp store
gold:
 lda r_draw_mask
 eor #255
 ora z_tmp
 sta z_tmp
store:
 lda z_tmp
 sta (z_glyph),y
 iny
 cpy #8
 bne byte
dirty:
 lda z_bank
 sta $D500
 ldy z_num
 lda z_off
 sta (z_dirtylo),y
 lda z_off+1
 sta (z_dirtyhi),y
 inc z_num
 jmp next
overflow:
 inc fault
next:
 lda r_draw_offset
 clc
 adc #3
 sta r_draw_offset
 dec r_draw_count
 jne cell
 rts
.endproc
r_keep_right: .byte 255,63,15,3
r_keep_left: .byte 255,252,240,192
.segment "GFX"
.segment "XL"
.proc apparatus_draw_supports
 lda #0
 sta r_draw_index
@next:
 ldx r_draw_index
 lda r_drum_xhi,x
 bmi @skip
 lda r_drum_xlo,x
 clc
 adc r_arc_x
 sta z_pos
 lda r_drum_xhi,x
 adc r_arc_x+1
 sta z_pos+1
 lda z_pos
 sec
 sbc #112
 sta z_pos
 lda z_pos+1
 sbc #0
 sta z_pos+1
 ; Keep the drawing conversion local; the atlas uses other cartridge banks.
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
 jsr screen_position
 lda #32
 jsr gfx_visible_width
 bcs @skip
 lda #26
 sta gfx_cached_kind
 jsr gfx_cached_select
@skip:
 inc r_draw_index
 lda r_draw_index
 cmp #3
 bcc @next
 rts
.endproc


.segment "GFX"
.proc apparatus_finish_draw
 lda back
 asl
 asl
 asl
 asl
 asl
 tay
 lda #0
 sta $0E00,y
 sta $0E01,y
 sta $0E02,y
 sta $0E03,y
 sta $0E08,y
 sta $0E09,y
 sta $0E0A,y
 sta $0E0B,y
 lda r_goal_ready
 beq @done
 lda stage_end
 sec
 sbc #16
 sta z_pos
 lda stage_end+1
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda mode
 cmp #4
 bne :+
 lda #72
 sta sprite_x
 lda #0
 sta sprite_xhi
:
 lda #32
 jsr gfx_visible_width
 bcs @done
 lda back
 asl
 asl
 asl
 asl
 asl
 tay
 lda $FD2E
 sta $0E0C,y
 sta $0E0D,y
 ldx #1
@leg:
 lda sprite_x
 clc
 adc leg_offsets,x
 cmp #160
 bcs @legnext
 clc
 adc #48
 sta $0E00,y
@legnext:
 iny
 dex
 bpl @leg
 lda #25
 sta gfx_cached_kind
 jmp gfx_cached_select
@done:
 rts
.endproc

.segment "MECHANICS"
leg_offsets: .byte 24,4

.proc fidelity_spring_points
 lda #$3D
 sta $D500
 jsr horse_arcade_points
 lda #$3D
 sta $D500
 rts
.endproc

.segment "XL"
.proc apparatus_save_horse
 ldx #0
@copy:
 lda horse_y,x
 sta (z_ptr),y
 iny
 inx
 cpx #32
 bne @copy
 ldx #0
@states:
 lda h_state,x
 sta (z_ptr),y
 iny
 inx
 cpx #8
 bne @states
 rts
.endproc
.proc apparatus_restore_horse
 ldx #0
@copy:
 lda (z_ptr),y
 sta horse_y,x
 iny
 inx
 cpx #32
 bne @copy
 ldx #0
@states:
 lda (z_ptr),y
 sta h_state,x
 iny
 inx
 cpx #8
 bne @states
 rts
.endproc
.proc apparatus_save_rope
 ldx r_first
@rope:
 .repeat 5,I
 lda r_amplitude+I*32,x
 sta (z_ptr),y
 iny
 .endrepeat
 inx
 cpx r_limit
 bcc @rope
 ldx #0
@got:
 lda r_got,x
 sta (z_ptr),y
 iny
 inx
 cpx #32
 bne @got
 ; Reuse the irrelevant ball/hazard checkpoint area for trapeze state.
 ldy #12
 ldx #0
@arcade:
 lda r_arc_x,x
 sta (z_ptr),y
 iny
 inx
 cpx #38
 bne @arcade
 rts
.endproc
.proc apparatus_restore_rope
 lda #0
 ldx #31
@clear:
 sta r_active,x
 lda #255
 sta r_angle,x
 lda #0
 dex
 bpl @clear
 ldx r_first
@rope:
 .repeat 5,I
 lda (z_ptr),y
 sta r_amplitude+I*32,x
 iny
 .endrepeat
 lda #1
 sta r_active,x
 inx
 cpx r_limit
 bcc @rope
 ldx #0
@got:
 lda (z_ptr),y
 sta r_got,x
 iny
 inx
 cpx #32
 bne @got
 ldy #12
 ldx #0
@arcade:
 lda (z_ptr),y
 sta r_arc_x,x
 iny
 inx
 cpx #38
 bne @arcade
 lda #$3D
 sta $D500
 jsr apparatus_resume
 jsr update_camera
 inc checkpoint_restores
 lda #$3F
 sta $D500
 rts
.endproc
.segment "MECHANICS"

.proc apparatus_draw_full
 lda #0
 ldx r_draw_sign
 beq :+
 lda #255
:
 sta column_xor+1
 lda r_draw_basecol
 cpx #0
 beq :+
 clc
 adc #13
:
 sta column_add+1
 lda r_draw_cachepage
 sta cache_read+2
 clc
 adc #1
 sta cache_high+2
cell:
 ldx r_draw_offset
record_column = *
 lda r_record,x
 and #15
column_xor:
 eor #0
 clc
column_add:
 adc #0
 cmp #40
 jcs next
 sta z_left
record_row = *
 lda r_record+1,x
 tay
 lda row_lo,y
 clc
 adc z_left
 sta z_cell
 sta z_off
 lda row_hi,y
 adc #0
 sta z_off+1
 ora z_map+1
 sta z_cell+1
 ; Select the cached page directly from the prepared ID's ninth bit.
 ; The full atlas address is needed only on the uncommon uncached path.
record_id = *
 ldy r_record+2,x
record_flags = *
 lda r_record,x
 bmi high_id
cache_read:
 lda $7800,y
 jmp cached
high_id:
cache_high:
 lda $7900,y
cached:
 cmp #255
 beq allocate
 ldy #0
 sta (z_cell),y
 jmp dirty
allocate:
alloc_id = *
 lda r_record+2,x
 sta r_draw_id
alloc_flags = *
 lda r_record,x
 and #128
 asl
 lda #0
 rol
 sta r_draw_id+1
 lda r_atlas_bank
 sta $D500
 lda free_glyph
 cmp #128
 jcs overflow
 inc free_glyph
 ldy #0
 sta (z_cell),y
 tax
 lda glyph_lo,x
 sta z_glyph
 lda glyph_hi,x
 ora band_font
 sta z_glyph+1
 lda r_draw_id+1
 clc
 adc #$74
 sta atlaslo+2
 adc #2
 sta atlashi+2
 ldx r_draw_id
atlaslo:
 lda $7400,x
 sta z_data
atlashi:
 lda $7600,x
 sta z_data+1
 lda r_draw_sign
 bne mirror
 .repeat 8,I
 ldy #I
 lda (z_data),y
 sta (z_glyph),y
 .endrepeat
 jmp dirty
mirror:
 .repeat 8,I
 ldy #I
 lda (z_data),y
 tax
 lda $7A00,x
 sta (z_glyph),y
 .endrepeat
dirty:
 lda z_bank
 sta $D500
 ldy z_num
 lda z_off
 sta (z_dirtylo),y
 lda z_off+1
 sta (z_dirtyhi),y
 inc z_num
 jmp next
overflow:
 inc fault
next:
 lda r_draw_offset
 clc
 adc #3
 sta r_draw_offset
 dec r_draw_count
 jne cell
 rts
.endproc

.proc apparatus_blend
 ; Spill compositors use a tagged address in the unused presentation-bank
 ; tail. Return to the directory bank before the next glyph lookup.
 bit z_tempword+1
 bmi @call
 lda z_tempword+1
 eor #$C0
 sta z_tempword+1
 lda #$31
 sta $D500
 jsr @call
 lda #$27
 sta $D500
 rts
@call:
 jmp (z_tempword)
.endproc
.segment "LIONGFX"
.proc apparatus_blend_prepare
 lda #0
 sta r_blend_enabled
 lda gfx_mask_count
 beq @done
 lda gfx_hero_x
 and #3
 bne @done
 lda gfx_hero_pose
 cmp #84
 bcs @lion
 cmp #2
 bne :+
 lda gfx_hero_y
 and #7
 cmp #2
 bne @done
 ldx #32
 bne @lookup
:
 cmp #3
 beq @jump
 cmp #4
 bne @done
 lda #8
 bne @variant
@jump:
 lda #0
@variant:
 sta z_tmp
 lda gfx_hero_y
 and #7
 ora z_tmp
 asl
 tax
@lookup:
 lda #$27
 sta $D500
 lda $9600,x
 sta z_ptr
 lda $9601,x
 sta z_ptr+1
 inc r_blend_enabled
@done:
 rts
@lion:
 cmp #93
 bcs @done
 sec
 sbc #84
 asl
 asl
 asl
 sta z_tmp
 lda gfx_hero_y
 and #7
 ora z_tmp
 asl
 tax
 lda #$32
 sta $D500
 lda $8701,x
 beq @done ; Walking, clipped or unsupported variants use the generic merge.
 sta z_ptr+1
 lda $8700,x
 sta z_ptr
 inc r_blend_enabled
 rts
.endproc
.segment "MECHANICS"

; The six crowd rows are rebuilt before objects on every frame. Do not erase
; those same cells a second time when restoring a trapeze actor rectangle.
.segment "XL"
.proc apparatus_clip_rect
 txa
 clc
 adc gfx_rect_h
 and #127
 cmp #14
 bcc @keep
 sta z_tmp
 cpx #19
 bcs @keep
 cpx #13
 bcs @inside
 stx z_tmp
 lda #13
 sec
 sbc z_tmp
 sta gfx_rect_h
 bne @keep
@inside:
 lda z_tmp
 cmp #20
 bcs @tail
 sec
 rts
@tail:
 sec
 sbc #19
 sta gfx_rect_h
 ldx #19
@keep:
 clc
 rts
.endproc
.segment "MECHANICS"

 ; The row/cache hot path lives inline in draw_stamp, avoiding two calls per cell.
horse_cell_row=draw_stamp::spring_row_anchor
horse_cached_cell=draw_stamp::spring_cache_anchor
sprite_cache_base=draw_stamp::spring_cache_base_anchor
sprite_cache_mid_adjust=draw_stamp::spring_mid_adjust_anchor
sprite_cache_bottom_limit=draw_stamp::spring_bottom_limit_anchor

.segment "XL"
; Point the resident rope readers directly at their cartridge records.
; Cached cells need no ROM glyph fetch; uncached/end cells switch to the
; atlas briefly and restore z_bank. This removes a per-frame record copy.
.proc apparatus_record_addresses
 lda z_rom
 ldy z_rom+1
 sta apparatus_draw_cells::record_column+1
 sty apparatus_draw_cells::record_column+2
 sta apparatus_draw_cells::record_flags+1
 sty apparatus_draw_cells::record_flags+2
 sta apparatus_draw_full::record_column+1
 sty apparatus_draw_full::record_column+2
 sta apparatus_draw_full::record_flags+1
 sty apparatus_draw_full::record_flags+2
 sta apparatus_draw_full::alloc_flags+1
 sty apparatus_draw_full::alloc_flags+2
 clc
 adc #1
 bcc :+
 iny
:
 sta apparatus_draw_cells::record_row+1
 sty apparatus_draw_cells::record_row+2
 sta apparatus_draw_full::record_row+1
 sty apparatus_draw_full::record_row+2
 clc
 adc #1
 bcc :+
 iny
:
 sta apparatus_draw_cells::record_id+1
 sty apparatus_draw_cells::record_id+2
 sta apparatus_draw_full::record_id+1
 sty apparatus_draw_full::record_id+2
 sta apparatus_draw_full::alloc_id+1
 sty apparatus_draw_full::alloc_id+2
 rts
.endproc

.segment "MECHANICS"

; Arcade raster: (18.432 MHz / 3) / (384 * 264) = 2000/33 Hz.
; MAME corrected its former 60 Hz approximation in commit 8dad2bf5 (2025-06-16).
; Derive game time from elapsed TV fields,
; including fields missed by rendering, rather than one fixed batch per flip.
.segment "XL"
.proc apparatus_clock_reset
 lda host_frames
 sta r_logic_host
 lda host_frames+1
 sta r_logic_host+1
 rts
.endproc
.proc apparatus_game_clock
 ; Use the same snapshot for elapsed time and the next baseline. A VBI
 ; between two host-counter reads must not silently discard one TV field.
 ldx host_frames
 txa
 sec
 sbc r_logic_host
 sta r_elapsed_fields
 stx r_logic_host
 lda #0
 sta logic_steps
 lda r_elapsed_fields
 jeq @done
@field:
 inc logic_steps
 lda pal
 bne @pal
 ; NTSC: (2000/33) * (114 * 262) / 1789772.5 = 7964800/7874999.
 lda r_clock_fraction
 clc
 adc #<89801
 sta r_clock_fraction
 lda r_clock_fraction+1
 adc #>89801
 sta r_clock_fraction+1
 lda r_clock_fraction+2
 adc #^89801
 sta r_clock_fraction+2
 lda r_clock_fraction
 sec
 sbc #<7874999
 sta z_tempword
 lda r_clock_fraction+1
 sbc #>7874999
 sta z_tempword+1
 lda r_clock_fraction+2
 sbc #^7874999
 jmp @remainder
@pal:
 ; PAL: (2000/33) * (114 * 312) / 1773447 = 608000/500203.
 lda r_clock_fraction
 clc
 adc #<107797
 sta r_clock_fraction
 lda r_clock_fraction+1
 adc #>107797
 sta r_clock_fraction+1
 lda r_clock_fraction+2
 adc #^107797
 sta r_clock_fraction+2
 lda r_clock_fraction
 sec
 sbc #<500203
 sta z_tempword
 lda r_clock_fraction+1
 sbc #>500203
 sta z_tempword+1
 lda r_clock_fraction+2
 sbc #^500203
@remainder:
 bcc @next
 sta r_clock_fraction+2
 lda z_tempword
 sta r_clock_fraction
 lda z_tempword+1
 sta r_clock_fraction+1
 inc logic_steps
@next:
 dec r_elapsed_fields
 jne @field
@tick:
 jsr game_tick
 dec logic_steps
 bne @tick
@done:
 rts
.endproc

.segment "MECHANICS"
