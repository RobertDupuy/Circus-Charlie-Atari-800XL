; Reserve Charlie's visible rows, including his lower fall/death position.
; His prepared jump, swing and fall silhouettes use at most 25 cells in a
; font band. The old 5*6 bounding rectangle wasted five scarce top glyphs.
.proc complete_rope_budget
 lda #0
 sta gfx_reserve
 sta gfx_reserve+1
 sta gfx_reserve+2
 lda #128
 sec
 sbc jump_pixels
 ldx mode
 cpx #3
 beq @fallen
 cpx #5
 beq @fallen
 cpx #6
 bne @top
@fallen:
 clc
 adc death_drop
@top:
 jsr trapeze_clip_budget
 bcs @done
 tax
 cpx #64
 bcs :+
 lda trapeze_top_budget,x
 ; The attached swing pose needs at most 21 cells. Reserving the jump
 ; pose's 25 can leave no glyph for a nearby rope at a high swing.
 cmp #22
 bcc @reserve
 ldy mode
 cpy #2
 bne @reserve
 ldy jumping
 bne @reserve
 lda #21
@reserve:
 sta gfx_reserve
:
 txa
 clc
 adc #37
 cmp #64
 bcc @done
 sta z_tmp
 cpx #136
 bcs :+
 lda #25
 sta gfx_reserve+1
:
 lda z_tmp
 cmp #136
 bcc @done
 lda #25
 sta gfx_reserve+2
@done:
 rts
.endproc
.include "trapeze-budget.inc"
; The native pony writer may spill at most seven cells into the next row
; when leaving the right edge. Restore those otherwise empty left-field cells
; immediately. This keeps the final cropped departure on the fast path.
.proc complete_horse_edge
 lda #<(17*40)
 sta z_src
 sta z_dst
 lda #>(BASEMAP+17*40)
 sta z_src+1
 lda z_map+1
 clc
 adc #>(17*40)
 sta z_dst+1
 ldx #5
@row:
 ldy #7
@copy:
 lda (z_src),y
 sta (z_dst),y
 dey
 bpl @copy
 lda z_src
 clc
 adc #40
 sta z_src
 sta z_dst
 bcc :+
 inc z_src+1
 inc z_dst+1
:
 dex
 bne @row
 rts
.endproc
; Draw while the rope's screen coordinates are still available, avoiding
; another world/camera pass over the off-screen apparatus.
.proc complete_rope_bar_endpoint
 ldx r_draw_index
 lda r_draw_sign
 beq @right
 lda #0
 sec
 sbc r_dxlo,x
 lda sprite_x
 sbc r_dxhi,x
 sta sprite_x
 lda sprite_xhi
 sbc #0
 jmp @position
@right:
 lda sprite_x
 clc
 adc r_dxhi,x
 sta sprite_x
 lda sprite_xhi
 adc #0
@position:
 sta sprite_xhi
 lda sprite_x
 sec
 sbc #2
 sta sprite_x
 bcs :+
 dec sprite_xhi
:
 lda r_draw_bottom
 sta sprite_y
 lda #5
 jsr gfx_visible_width
 bcs @done
 jmp complete_rope_bar_draw
@done:
 rts
.endproc
; A grip changes one scanline in two cells. Reuse the rope's
; existing private endpoint glyph whenever possible; copy a background
; glyph only for the small portion of the bar extending beyond the rope.
.proc complete_rope_bar_draw
 lda sprite_x
 and #3
 sta z_shift
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 sta z_col
 lda sprite_y
 and #7
 sta z_savedx
 lda sprite_y
 lsr
 lsr
 lsr
 sta z_row
@cell:
 ldx z_shift
 lda rope_bar_masks,x
 jeq @done
 sta z_body
 lda z_col
 cmp #40
 jcs @next
 ldy z_row
 clc
 adc row_lo,y
 sta z_cell
 lda row_hi,y
 adc #0
 sta z_off+1
 ora z_map+1
 sta z_cell+1
 ldy #0
 lda (z_cell),y
 sta z_colorflag
 and #127
 sta z_old
 cmp bg_count
 bcs @reuse
 lda free_glyph
 cmp #128
 jcs @overflow
 inc free_glyph
 sta z_new
 ldy z_num
 lda z_cell
 sta (z_dirtylo),y
 lda z_off+1
 sta (z_dirtyhi),y
 inc z_num
 lda z_new
@reuse:
 tax
 ldy #0
 sta (z_cell),y
 lda glyph_lo,x
 sta z_glyph
 lda glyph_hi,x
 ora band_font
 sta z_glyph+1
 cpx z_old
 bne @copy
 bit z_colorflag
 bpl @stroke
@copy:
 lda z_old
 beq @blank
 tax
 lda glyph_lo,x
 sta z_bg
 lda glyph_hi,x
 ora band_font
 sta z_bg+1
 bit z_colorflag
 bmi @cyan
 .repeat 8,I
 ldy #I
 lda (z_bg),y
 sta (z_glyph),y
 .endrepeat
 jmp @stroke
@blank:
 .repeat 8,I
 ldy #I
 sta (z_glyph),y
 .endrepeat
 jmp @stroke
@cyan:
 ldy #7
@convert:
 lda (z_bg),y
 tax
 lda $7C00,x
 sta (z_glyph),y
 dey
 bpl @convert
@stroke:
 ldy z_savedx
 lda (z_glyph),y
 ora z_body
 sta (z_glyph),y
@next:
 inc z_col
 lda z_shift
 clc
 adc #4
 sta z_shift
 cmp #8
 jcc @cell
@done:
 rts
@overflow:
 inc fault
 rts
.endproc
rope_bar_masks: .byte $FF,$3F,$0F,$03,$C0,$F0,$FC,$FF
.segment "DETAILS"
; Final-course rules and presentation. Public entry wrappers restore their bank.
.proc complete_dispatch
 cpx #8
 jcs detail_dispatch
 cpx #0
 jeq complete_begin_entry
 cpx #1
 jeq complete_tick
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
 cpx #7
 jeq complete_money
 jmp detail_dispatch
.endproc

.segment "XL"
.proc complete_begin
 lda #0
 sta clear_elapsed
 sta clear_reward
 sta clear_bird
 sta clear_prize
 sta finish_pony
 lda stage_hurt
 eor #1
 sta clear_reward
 lda act
 beq @lion
 cmp #2
 beq @tramp
 cmp #3
 bne @done
 ; Settle both shoes onto the low Rolling Balls podium.
 lda #15
 bne @settle
@tramp:
 lda water
 bne @done
 ; Centre the victory dancer over the 32-pixel trampoline goal.
 lda #16
@settle:
 clc
 adc stage_end
 sta world
 lda stage_end+1
 adc #0
 sta world+1
 jmp update_camera
@lion:
 lda #11
 jsr hidden_entry
 lda #1
 sta lion_goal
 lda #11
 sta jump_pixels
 lda stage_end
 sta world
 lda stage_end+1
 sta world+1
 jsr update_camera
@done:
 rts
.endproc

.segment "DETAILS"
.proc complete_tick
 inc clear_elapsed
 lda act
 bne @horse
 lda #13
 jsr hidden_entry
@horse:
 lda act
 cmp #4
 jne @done
 lda finish_pony
 cmp #128
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
 sta tramp_death_reason
 sta tramp_death_age
 ; Stage setup clears the lost life's offset before restoring a checkpoint.
 sta death_drop
 lda #255
 sta sign_cache_label
 sta sign_cache_label+1
 sta detail_sign_index
 sta clear_text_cache
 sta clear_text_cache+1
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
 lda #0
 jmp hidden_entry
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
 jmp detail_points
.endproc

.proc complete_reverse
 lda #2
 jmp hidden_entry
.endproc

.proc complete_secrets
 jmp hidden_contact
.endproc

.proc complete_draw
 lda mode
 cmp #4
 beq @clear
 lda act
 jne @done
 lda secret_visible
 jeq @done
 lda #10
 jmp hidden_entry
@clear:
 lda act
 cmp #5
 jeq @kiss
 lda clear_bird
 jeq @done
 jmp detail_lion_bird
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
 jmp detail_points
.endproc

