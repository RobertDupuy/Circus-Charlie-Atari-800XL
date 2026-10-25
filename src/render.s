.proc render_frame
 lda mode
 bne :+
 jmp title_render
:
 ldx back
 lda screen_high,x
 sta z_map+1
 lda #0
 sta z_map
 lda font_high,x
 sta z_fonts
 sta band_font
 clc
 adc #4
 sta band_font+1
 adc #4
 sta band_font+2
 txa
 asl
 clc
 adc #$0A
 sta z_dirtylo+1
 adc #1
 sta z_dirtyhi+1
 lda #0
 sta z_dirtylo
 sta z_dirtyhi
 jsr gfx_restore_rects
 ldx back
 ; Restore only cells touched the last time this buffer was used.
 lda dirty_count,x
 beq @restored
 sta z_num
 lda z_dirtylo+1
 sta @restore_lo+2
 lda z_dirtyhi+1
 sta @restore_hi+2
 lda z_map+1
 eor #$34
 sta @screen_page+1
 ldx z_num
@restore:
 dex
@restore_lo:
 lda dirty_lo0,x
 tay
@restore_hi:
 lda dirty_hi0,x
 ora #$34
 sta @read_cell+2
@screen_page:
 eor #$0C
 sta @write_cell+2
@read_cell:
 lda $3400,y
@write_cell:
 sta $3800,y
 cpx #0
 bne @restore
@restored:
 ldx back
 lda #0
 sta dirty_count,x
 sta z_num
 jsr rope_glyph_budget
 lda mode
 cmp #4
 bne :+
 lda act
 bne @other_clear
 lda #30
 sta gfx_reserve+1
 jmp @clear_budget_done
@other_clear:
 cmp #5
 bne :+
 lda #0
 sta gfx_reserve
 sta gfx_reserve+1
 sta gfx_reserve+2
:
@clear_budget_done:
 ldx #2
@resetpool:
 lda bg_count,x
 clc
 adc gfx_reserve,x
 sta free_glyph,x
 dex
 bpl @resetpool
 lda #0
 sta gfx_hero_valid
 jsr scroll_crowd
 ldx #3
@hide:
 lda #255
 sta pm_id,x
 lda #0
 sta pm_x,x
 sta pm_y,x
 sta pm_size,x
 lda #$0E
 sta pm_color,x
 dex
 bpl @hide
 jsr draw_scene
 jsr draw_finish
 jsr fidelity_clear_text_entry
 jsr complete_draw_entry
pm_prepare_dispatch:
 jsr prepare_pm
 jsr gfx_hero_overlay
 jsr gfx_dma_prepare
 jsr draw_hud
 ldx back
 lda z_num
 sta dirty_count,x
 cmp max_dirty
 bcc :+
 sta max_dirty
:
 rts
.endproc

.proc scroll_crowd
 lda camera
 lsr
 lsr
 sta z_shift
 ldx camera+1
 lda crowd_high_mod,x
 clc
 adc z_shift
@mod:
 cmp #40
 bcc @got
 sbc #40
 bcs @mod
@got:
 tax
 lda act
 cmp #1
 beq @high
 cmp #5
 beq @trapeze
 lda #$32
 bne @bank
@high:
 lda #$33
@bank:
 sta $D500
 lda back
 bne @bufferB
 jmp $A000
@bufferB:
 jmp $A800
@trapeze:
 lda #$33
 sta $D500
 lda back
 bne @trapB
 jmp $B000
@trapB:
 jmp $B800
.endproc

.proc draw_stamp
 txa
 pha
 tya
 pha
 lda #0
 sta z_prepared
 lda #$27
 sta $D500
 lda sprite_y
 and #7
 asl
 asl
 sta z_tmp
 lda sprite_x
 and #3
 asl
 asl
 asl
 asl
 asl
 ora z_tmp
 sta z_ptr
 lda sprite_pose
 lsr
 php
 clc
 adc #$80
 sta z_ptr+1
 plp
 bcc :+
 lda z_ptr
 ora #$80
 sta z_ptr
:
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
 iny
 lda (z_ptr),y
 sta z_cells
 lda z_bank
 sta $D500
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
 lda sprite_pose
 cmp #8
 bcc ds_hero
 cmp #84
 bcc ds_regular
 cmp #93
 bcs ds_regular
ds_hero:
 jsr gfx_draw_hero
 jmp ds_done
ds_regular:
 lda z_prepared
 beq ds_begin_cells
 jsr draw_rope_cells
 jmp ds_done
ds_begin_cells:
 lda #255
 sta gfx_stamp_row
 lda z_cells
 jeq ds_done
ds_cell:
 ldy #0
 lda (z_rom),y
 sta gfx_sprite_alt
 and #$1F
 clc
 adc z_col
 cmp #40
 jcs ds_next
 sta z_left
 iny
 lda (z_rom),y
spring_row_anchor = *
ds_spring_row:
 tax
 lda gfx_sprite_alt
 and #32
 beq ds_spring_plain
 txa
 lsr
 lsr
 clc
spring_cache_base_anchor = *
ds_spring_cache_base:
 adc #47
 sta r_spring_code
 txa
 and #3
 jmp ds_spring_row_done
ds_spring_plain:
 lda #0
 sta r_spring_code
 txa
ds_spring_row_done:
 clc
 adc z_row
 cmp #22
 jcs ds_next
 cmp gfx_stamp_row
ds_reuse_row:
 beq ds_cached_row
 sta gfx_stamp_row
 tay
 lda row_band,y
 sta z_band
 lda row_lo,y
 sta gfx_stamp_lo
 lda row_hi,y
 sta gfx_stamp_hi
ds_cached_row:
 lda gfx_stamp_lo
 clc
 adc z_left
 sta z_cell
 lda gfx_stamp_hi
 adc #0
 sta z_off+1
 ora z_map+1
 sta z_cell+1
 ldy #0
 lda (z_cell),y
 sta z_colorflag
 and #$7F
 sta z_old
spring_cache_anchor = *
ds_spring_cache:
 lda z_old
 bne ds_spring_fallback
 lda r_spring_code
 beq ds_spring_fallback
 ldx z_band
 beq ds_spring_fallback
 cpx #1
 bne ds_spring_bottom
 sec
spring_mid_adjust_anchor = *
ds_spring_mid_adjust:
 sbc #37
 jmp ds_spring_store
ds_spring_bottom:
spring_bottom_limit_anchor = *
ds_spring_bottom_limit:
 cmp #87
 bcs ds_spring_fallback
ds_spring_store:
 bit gfx_sprite_alt
 bpl ds_spring_normal
 ora #128
ds_spring_normal:
 ldy #0
 sta (z_cell),y
 ldy z_num
 lda z_cell
 sta (z_dirtylo),y
 lda z_off+1
 sta (z_dirtyhi),y
 inc z_num
 jmp ds_next
spring_fallback_anchor = *
ds_spring_fallback:
 lda z_old
 ldx z_band
 cmp bg_count,x
 bcc ds_allocate
 sta z_new
 jmp ds_pointers
ds_allocate:
 lda free_glyph,x
 cmp #128
 jcs ds_overflow
 sta z_new
 inc free_glyph,x
 ldy z_num
 lda z_cell
 sta (z_dirtylo),y
 lda z_off+1
 sta (z_dirtyhi),y
 inc z_num
ds_pointers:
 ldy #0
 lda gfx_sprite_alt
 and #$80
 ora z_new
 sta (z_cell),y
 ldx z_band
 lda band_font,x
 sta z_bg+1
 sta z_glyph+1
 ldx z_new
 lda gfx_glyph_lo,x
 sta z_glyph
 lda gfx_glyph_hi,x
 ora z_glyph+1
 sta z_glyph+1
 bit gfx_sprite_alt
 jvs ds_blank
 lda z_old
 jeq ds_blank
 tax
 lda gfx_glyph_lo,x
 sta z_bg
 lda gfx_glyph_hi,x
 ora z_bg+1
 sta z_bg+1
 lda z_colorflag
 eor gfx_sprite_alt
 bpl ds_normal
 lda z_old
 jsr gfx_alt_bg
 jcc ds_cyan
 lda z_bg
 sec
 sbc #2
 sta z_bg
 lda z_bg+1
 sbc #0
 sta z_bg+1
ds_normal:
 .repeat 8,I
 ldy #(I+2)
 lda (z_rom),y
 tax
 lda $FC00,x
 and (z_bg),y
 ora (z_rom),y
 sta (z_glyph),y
 .endrepeat
 jmp ds_next
ds_blank:
 .repeat 8,I
 ldy #(I+2)
 lda (z_rom),y
 sta (z_glyph),y
 .endrepeat
 jmp ds_next
ds_cyan:
 .repeat 8,I
 ldy #(I+2)
 lda (z_bg),y
 tax
 lda $7C00,x
 sta z_value
 lda (z_rom),y
 tax
 lda $FC00,x
 and z_value
 ora (z_rom),y
 sta (z_glyph),y
 .endrepeat
 jmp ds_next
ds_overflow:
 inc fault
ds_next:
 lda #10
 clc
 adc z_rom
 sta z_rom
 bcc :+
 inc z_rom+1
:
 dec z_cells
 jne ds_cell
ds_done:
 pla
 tay
 pla
 tax
 rts
.endproc

.proc prepare_pm
 lda #4
 sta gfx_pm_limit
 lda back
 asl
 asl
 sta z_pmnum
 lda back
 asl
 asl
 asl
 asl
 asl
 sta z_savedx
 lda water
 bne @all
 lda act
 beq @all
 cmp #2
 beq @all
 cmp #5
 jeq @none
 cmp #1
 beq @all
 lda z_pmnum
 clc
 adc #3
 sta z_pmnum
 lda z_savedx
 clc
 adc #3
 sta z_savedx
 ldx #3
 bne @player
@all:
 ldx #0
@player:
 stx z_iter
 lda back
 tay
 lda pm_high,y
 clc
 adc #4
 adc z_iter
 sta z_pm+1
 lda #0
 sta z_pm
 ldx z_pmnum
 lda pm_old_h,x
 beq @new
 ; A same-sized replacement at the same Y overwrites the complete old player.
 ; Avoid erasing then redrawing fixed-height hoops, monkeys and platforms.
 sta z_tmp
 ldx z_iter
 lda pm_id,x
 cmp #255
 beq @erase
 tay
 lda $7D80,y
 ldy act
 bne :+
 lda #72
:
 cmp z_tmp
 bne @erase
 lda pm_y,x
 clc
 adc #40
 ldx z_pmnum
 cmp pm_old_y,x
 beq @new
 sec
 sbc pm_old_y,x
 bcc @partial_up
 cmp z_tmp
 bcs @erase
 tay
 lda pm_old_y,x
 sta z_pm
 jmp @partial
@partial_up:
 eor #255
 clc
 adc #1
 cmp z_tmp
 bcs @erase
 sta z_value
 lda pm_old_y,x
 clc
 adc z_tmp
 sec
 sbc z_value
 sta z_pm
 ldy z_value
@partial:
 dey
 lda #0
 jmp @clear
@erase:
 ldx z_pmnum
 lda pm_old_h,x
 tay
 dey
 lda pm_old_y,x
 sta z_pm
 lda #0
@clear:
 sta (z_pm),y
 dey
 bpl @clear
@new:
 ldx z_iter
 ldy z_savedx
 lda #0
 sta $0E00,y
 sta $0E04,y
 sta $0E08,y
 lda pm_color,x
 tax
 lda $FD00,x
 sta $0E0C,y
 ldx z_iter
 lda pm_id,x
 cmp #255
 jeq @hidden
 tax
 lda $7D80,x
 ldy act
 bne :+
 lda #72
:
 sta z_pmheight
 lda pm_pattern_lo,x
 sta z_pmdata
 lda pm_pattern_hi,x
 sta z_pmdata+1
 lda $7DA0,x
 ldy act
 bne :+
 lda #1
:
 ldy z_savedx
 sta $0E08,y
 ldx z_iter
 lda pm_x,x
 clc
 adc #48
 sta $0E00,y
 lda pm_y,x
 clc
 adc #40
 sta z_pm
 ldx z_pmnum
 sta pm_old_y,x
 lda z_pmheight
 sta pm_old_h,x
 lda act
 bne @standardcopy
 jsr gfx_copy_hoop_pm
 jmp @copied
@standardcopy:
 lda z_pmheight
 and #$F8
 sta pm_copy_limit
 ldy #0
@block:
 cpy pm_copy_limit
 beq @tail
 .repeat 8
 lda (z_pmdata),y
 sta (z_pm),y
 iny
 .endrepeat
 jmp @block
@tail:
 cpy z_pmheight
 beq @copied
 lda (z_pmdata),y
 sta (z_pm),y
 iny
 jmp @tail
@copied:
 jmp @advance
@hidden:
 ldx z_pmnum
 lda #0
 sta pm_old_h,x
@advance:
 inc z_pmnum
 inc z_savedx
 ldx z_iter
 inx
 cpx gfx_pm_limit
 jne @player
@none:
 rts
.endproc

.proc draw_hud
 ldx back
 lda hud_lo,x
 sta z_hud
 lda hud_hi,x
 sta z_hud+1
 jsr scene_id
 sta z_target
 lda hud_cached_act,x
 cmp z_target
 bne @refresh
 lda hud_cached_mode,x
 cmp mode
 jne @message_refresh
 lda hud_cached_pause,x
 cmp paused
 jne @message_refresh
 jmp @numbers
@refresh:
 lda z_target
 sta hud_cached_act,x
 lda mode
 sta hud_cached_mode,x
 lda paused
 sta hud_cached_pause,x
 lda #$3F
 sta $D500
 ldx z_target
 lda hud_template_lo,x
 sta z_src
 lda hud_template_hi,x
 sta z_src+1
 ldy #0
@copy:
 .repeat 8
 lda (z_src),y
 sta (z_hud),y
 iny
 .endrepeat
 cpy #160
 bne @copy
 lda #<footer_controls
 sta z_src
 lda #>footer_controls
 sta z_src+1
 lda mode
 bne :+
 lda #<title_controls
 sta z_src
 lda #>title_controls
 sta z_src+1
:
 lda demo
 beq :+
 lda #<demo_controls
 sta z_src
 lda #>demo_controls
 sta z_src+1
:
 ldy #120
 jsr hud_text
 jmp @select_message
@message_refresh:
 ldx back
 lda mode
 sta hud_cached_mode,x
 lda paused
 sta hud_cached_pause,x
@select_message:
 lda paused
 beq @mode
 lda #<pause_text
 sta z_src
 lda #>pause_text
 sta z_src+1
 jmp @message
@mode:
 lda mode
 asl
 tax
 lda mode_messages,x
 sta z_src
 lda mode_messages+1,x
 sta z_src+1
 lda mode
 cmp #2
 bne @message
 jsr scene_id
 asl
 tax
 lda act_messages,x
 sta z_src
 lda act_messages+1,x
 sta z_src+1
@message:
 ldy #80
 jsr hud_text
@numbers:
 jsr gfx_hud_needed
 bcc @hud_done
 ldy #4
 ldx #2
@score:
 lda score,x
 jsr hud_bcd
 dex
 bpl @score
 ldy #17
 ldx #2
@high:
 lda highscore,x
 jsr hud_bcd
 dex
 bpl @high
 ldy #36
 lda lives
 clc
 adc #48
 sta (z_hud),y
 ldy #64
 lda bonus+1
 jsr hud_bcd
 lda bonus
 jsr hud_bcd
 jmp hud_rules_entry
@hud_done:
 rts
.endproc

.segment "GFX"
.proc hud_bcd
 pha
 lsr
 lsr
 lsr
 lsr
 clc
 adc #48
 sta (z_hud),y
 iny
 pla
 and #15
 clc
 adc #48
 sta (z_hud),y
 iny
 rts
.endproc
.segment "CODE"

.proc hud_text
 ; Null-terminated ASCII to HUD at Y. Preserve X.
 sty z_value
 ldy #0
@char:
 lda (z_src),y
 beq @done
 sty z_tmp2
 ldy z_value
 sta (z_hud),y
 inc z_value
 ldy z_tmp2
 iny
 bne @char
@done:
 ldy z_value
 rts
.endproc

.proc prepare_balls
 ; This four-row strip is cheap to restore in full. Ball cells never enter
 ; the dirty-cell list, and a phase font is shared by every visible ball.
 lda #<(17*40)
 sta z_src
 sta z_dst
 lda #>(BASEMAP+17*40)
 sta z_src+1
 lda z_map+1
 clc
 adc #>(17*40)
 sta z_dst+1
 ldy #159
@strip:
 lda (z_src),y
 sta (z_dst),y
 dey
 cpy #255
 bne @strip
 lda anim_clock
 lsr
 lsr
 and #3
 tax
 lda ball_font_high,x
 ldx back
 sta frame_ballfont,x
 lda anim_clock
 lsr
 lsr
 and #3
 tax
 lda gfx_ball_flag_lo,x
 sta gfx_ball_flags
 lda gfx_ball_flag_hi,x
 sta gfx_ball_flags+1
 rts
.endproc

.proc draw_ball
 ; Only 24 screen bytes per ball; all pixels are shared prepared ROM glyphs.
 lda sprite_x
 and #3
 tax
 lda ball_glyph_base,x
 sta z_new
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 sta z_col
 lda #17
 sta z_row
@row:
 ldx z_row
 lda row_lo,x
 sta z_cell
 lda row_hi,x
 clc
 adc z_map+1
 sta z_cell+1
 lda #0
 sta z_iter
@col:
 lda z_col
 clc
 adc z_iter
 cmp #40
 bcs @skip
 sta z_left
 lda z_new
 sec
 sbc #2
 tay
 lda (gfx_ball_flags),y
 ora z_new
 ldy z_left
 sta (z_cell),y
@skip:
 inc z_new
 inc z_iter
 lda z_iter
 cmp #6
 bne @col
 inc z_row
 lda z_row
 cmp #21
 bne @row
 rts
.endproc

.proc gfx_hud_needed
 lda back
 asl
 asl
 asl
 asl
 tax
 lda mode
 cmp #2
 beq @game
 lda #0
 sta $DCA0,x
 sec
 rts
@game:
 lda $DCA0,x
 beq @changed
 lda score
 cmp $DCA1,x
 bne @changed
 lda score+1
 cmp $DCA2,x
 bne @changed
 lda score+2
 cmp $DCA3,x
 bne @changed
 lda highscore
 cmp $DCA4,x
 bne @changed
 lda highscore+1
 cmp $DCA5,x
 bne @changed
 lda highscore+2
 cmp $DCA6,x
 bne @changed
 lda lives
 cmp $DCA9,x
 bne @changed
 lda round
 cmp $DCAA,x
 bne @changed
 lda player
 cmp $DCAB,x
 bne @changed
 lda bonus
 cmp $DCA7,x
 bne @bonus_only
 lda bonus+1
 cmp $DCA8,x
 bne @bonus_only
 clc
 rts
@bonus_only:
 ; The countdown changes much more often than the score/career fields.
 ; Update its four digits directly once all other fields match this buffer,
 ; leaving enough frame time for the taller hoop's additional overlap cells.
 lda bonus
 sta $DCA7,x
 lda bonus+1
 sta $DCA8,x
 ldy #64
 jsr hud_bcd
 lda bonus
 jsr hud_bcd
 clc
 rts
@changed:
 lda #1
 sta $DCA0,x
 lda score
 sta $DCA1,x
 lda score+1
 sta $DCA2,x
 lda score+2
 sta $DCA3,x
 lda highscore
 sta $DCA4,x
 lda highscore+1
 sta $DCA5,x
 lda highscore+2
 sta $DCA6,x
 lda bonus
 sta $DCA7,x
 lda bonus+1
 sta $DCA8,x
 lda lives
 sta $DCA9,x
 lda round
 sta $DCAA,x
 lda player
 sta $DCAB,x
 sec
 rts
.endproc
