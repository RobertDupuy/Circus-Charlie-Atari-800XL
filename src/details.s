; Bank 17: presentation shared by all six acts. Call through resident wrappers.
.proc detail_dispatch
 cpx #8
 jeq detail_draw
 cpx #9
 jeq detail_hud
 cpx #10
 jeq detail_hurt
 cpx #11
 jeq detail_death
 cpx #12
 jeq detail_trampolines
 jmp detail_signs
.endproc

.proc detail_draw
 jsr complete_draw
 lda act
 cmp #4
 beq :+
 jsr detail_signs
:
 lda act
 cmp #2
 bne @done
 lda water
 bne @done
 lda mode
 cmp #3
 bne @done
 lda tramp_death_reason
 cmp #4
 bne @done
 lda world
 sec
 sbc #12
 sta z_pos
 lda world+1
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda #0
 sta sprite_y
 lda #111
 sta sprite_pose
 jmp complete_stamp
@done:
 rts
.endproc

.proc detail_hud
 lda mode
 cmp #3
 bne @write
 lda act
 cmp #2
 bne @write
 lda water
 bne @write
 ldx tramp_death_reason
 bne @reason
 lda bonus
 ora bonus+1
 bne @write
 ldx #5
@reason:
 dex
 lda detail_death_text_lo,x
 sta z_src
 lda detail_death_text_hi,x
 sta z_src+1
@write:
 ldy #80
 jmp hud_text
.endproc

detail_death_text_lo: .byte <detail_miss_text,<detail_fire_text,<detail_blade_text,<detail_roof_text,<detail_timeout_text
detail_death_text_hi: .byte >detail_miss_text,>detail_fire_text,>detail_blade_text,>detail_roof_text,>detail_timeout_text
detail_miss_text: .asciiz "MISSED THE TRAMPOLINE!                   "
detail_fire_text: .asciiz "HIT THE FIRE!                           "
detail_blade_text: .asciiz "HIT THE BLADE!                          "
detail_roof_text: .asciiz "TOO HIGH! HEAD THROUGH THE BIG TOP       "
detail_timeout_text: .asciiz "TIME IS UP!                             "

.proc detail_hurt
 lda jump_pixels
 pha
 jsr detail_hurt_call
 pla
 sta jump_pixels
 lda #0
 sta tramp_death_age
 rts
.endproc

.proc detail_death
 lda act
 cmp #2
 bne @other
 lda water
 bne @done
 inc tramp_death_age
 lda tramp_death_age
 cmp #16
 bcc @done
 lda jump_pixels
 beq @floor
 sec
 sbc #3
 bcs :+
 lda #0
:
 sta jump_pixels
 rts
@floor:
 lda death_drop
 cmp #34
 bcs @done
 inc death_drop
 inc death_drop
 rts
@other:
 ldx act
 lda #30
 cpx #3
 beq @fall
 lda #14
 cpx #4
 bne @done
@fall:
 cmp death_drop
 beq @done
 bcc @done
 inc death_drop
 inc death_drop
@done:
 rts
.endproc

.proc detail_lion_bird
 ; Approach from the left, hover above Charlie, then fly away.
 lda world
 sec
 sbc camera
 sec
 sbc #20
 sta detail_bird_x
 lda clear_elapsed
 cmp #64
 bcs @hover
 eor #255
 clc
 adc #65
 sta z_tmp
 lda detail_bird_x
 sec
 sbc z_tmp
 sta detail_bird_x
 jmp @draw
@hover:
 cmp #160
 bcc @draw
 sec
 sbc #160
 asl
 clc
 adc detail_bird_x
 sta detail_bird_x
@draw:
 lda detail_bird_x
 sta sprite_x
 lda #0
 ldx detail_bird_x
 cpx #192
 bcc :+
 lda #255
:
 sta sprite_xhi
 lda #64
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
 ; The bird carries the sack below its beak. Its blue dollar sign is
 ; prepared in palette-4 cells, separate from the gold bird feathers.
 lda detail_bird_x
 clc
 adc #16
 sta sprite_x
 lda #0
 ldx sprite_x
 cpx #192
 bcc :+
 lda #255
:
 sta sprite_xhi
 lda #80
 sta sprite_y
 lda #94
 sta sprite_pose
 jsr complete_stamp
 lda clear_elapsed
 cmp #64
 bcc @done
 cmp #144
 bcs @done
 ; Ten visible drops hit the dancing Charlie, at the scoring cadence.
 and #7
 asl
 asl
 clc
 adc #96
 sta sprite_y
 lda world
 sec
 sbc camera
 sec
 sbc #4
 sta sprite_x
 lda #0
 sta sprite_xhi
 lda #8
 sta sprite_pose
 jmp complete_stamp
@done:
 rts
.endproc

.proc detail_signs
 lda #0
 sta detail_fast_try
 lda act
 bne :+
 lda mode
 cmp #4
 jne @done ; The cached Act 1 approach boards are drawn with its hazards.
:
 ; Usually the previous marker remains on screen. Reuse its world
 ; anchor; rescan only when it leaves the view or the stage changes.
 lda detail_sign_index
 cmp #20
 bcs @reset
 inc detail_fast_try
 jmp @search
@reset:
 lda #0
 sta detail_fast_try
 lda stage_end
 sec
 sbc #8
 sta detail_sign_world
 lda stage_end+1
 sbc #0
 sta detail_sign_world+1
 lda #0
 sta detail_sign_index
@search:
 lda detail_sign_world
 sec
 sbc camera
 sta sprite_x
 lda detail_sign_world+1
 sbc camera+1
 sta sprite_xhi
 beq @right
 bmi @left
 jmp @next
@right:
 lda sprite_x
 cmp #160
 bcs @next
 jmp detail_sign_board
@left:
 cmp #255
 bne @done
 lda sprite_x
 cmp #241
 bcc @done
 jmp detail_sign_board
@next:
 lda detail_fast_try
 bne @reset
 ; Trapeze selects its final landing platform during play. Its approach
 ; boards stay fixed; GOAL follows the actual platform once selected.
 lda act
 cmp #5
 bne @subtract
 lda detail_sign_index
 bne @subtract
 lda #<1192
 sta detail_sign_world
 lda #>1192
 sta detail_sign_world+1
@subtract:
 lda detail_sign_world
 sec
 sbc #192
 sta detail_sign_world
 lda detail_sign_world+1
 sbc #0
 sta detail_sign_world+1
 bcc @done
 inc detail_sign_index
 lda detail_sign_index
 cmp #20
 bcc @search
@done:
 lda detail_fast_try
 jne @reset
 ldx back
 lda #255
 sta sign_cache_label,x
 rts
.endproc

.proc detail_sign_board
 lda #2
 sta z_band
 lda #21
 sta z_row
 lda act
 cmp #4
 bne :+
 lda #1
 sta z_band
 lda #10 ; Horse boards hang along the back edge of the track.
 sta z_row
:
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 sta detail_sign_col
 lda act
 cmp #5
 beq @fixed
 cmp #2
 bne :+
 lda water
 beq @fixed
 lda #2
:
 cmp #3
 bne @ordinary
 ; Reserve the last four codes of each private rolling-ball font pool.
 lda ball_merge_limit
 jmp @pool
@fixed:
 ; Main trampolines and trapeze use fewer than 100 bottom-font codes,
 ; including fall poses. Keep four stable codes clear of those actors.
 lda #124
 jmp @pool
@ordinary:
 ldx z_band
 lda free_glyph,x
 cmp #125
 bcc :+
 inc fault
 rts
:
 pha
 clc
 adc #4
 sta free_glyph,x
 pla
@pool:
 sta detail_sign_glyph
 lda #0
 sta sign_copy
 ldx back
 lda sign_cache_label,x
 cmp detail_sign_index
 bne @copy
 lda sign_cache_base,x
 cmp detail_sign_glyph
 bne @copy
 ldy z_band
 lda band_font,y
 cmp sign_cache_font,x
 beq @cached
@copy:
 inc sign_copy
@cached:
 lda detail_sign_index
 sta sign_cache_label,x
 lda detail_sign_glyph
 sta sign_cache_base,x
 ldy z_band
 lda band_font,y
 sta sign_cache_font,x
 lda detail_sign_index
 .repeat 3
 lsr
 .endrepeat
 sta z_rom+1
 lda detail_sign_index
 .repeat 5
 asl
 .endrepeat
 clc
 adc #<detail_sign_tiles
 sta z_rom
 lda z_rom+1
 adc #>detail_sign_tiles
 sta z_rom+1
 lda #0
 sta detail_sign_cell
@cell:
 lda sign_copy
 beq @map
 ldx detail_sign_glyph
 lda glyph_lo,x
 sta z_glyph
 lda glyph_hi,x
 ldy z_band
 ora band_font,y
 sta z_glyph+1
 ldy #7
@pixels:
 lda (z_rom),y
 sta (z_glyph),y
 dey
 bpl @pixels
@map:
 lda detail_sign_col
 cmp #40
 bcs @skip
 clc
 ldx z_row
 adc row_lo,x
 sta z_cell
 lda row_hi,x
 sta z_off+1
 clc
 adc z_map+1
 sta z_cell+1
 ldy z_num
 lda z_cell
 sta (z_dirtylo),y
 lda z_off+1
 sta (z_dirtyhi),y
 inc z_num
 lda detail_sign_glyph
 ora #128
 ldy #0
 sta (z_cell),y
@skip:
 lda z_rom
 clc
 adc #8
 sta z_rom
 bcc :+
 inc z_rom+1
:
 inc detail_sign_col
 inc detail_sign_glyph
 inc detail_sign_cell
 lda detail_sign_cell
 cmp #4
 bcc @cell
 rts
.endproc
.include "details-art.inc"
.proc detail_trampolines
 ; Three pedestals repeat every 192 pixels. Start one 64-pixel cell before
 ; the camera; this is always at or before the first visible pedestal.
 lda camera+1
 asl
 asl
 sta z_tmp
 lda camera
 .repeat 6
 lsr
 .endrepeat
 ora z_tmp
 beq :+
 sec
 sbc #1
:
 sta z_hazard
@next:
 ldx z_hazard
 lda arcade_tramp_lo,x
 sec
 sbc #4
 sta z_pos
 lda arcade_tramp_hi,x
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 bmi :+
 bne @prize
 lda sprite_x
 cmp #160
 bcs @prize
:
 lda #24
 jsr gfx_visible_width
 bcs @skip
 lda #1
 sta gfx_cached_kind
 jsr detail_cached
@skip:
 inc z_hazard
 lda z_hazard
 cmp #25
 bne @next
@prize:
 ldx tramp_index
 lda passed,x
 bne @done
 lda arcade_tramp_lo,x
 sta z_pos
 lda arcade_tramp_hi,x
 sta z_pos+1
 jsr screen_position
 lda #8
 jsr gfx_visible_width
 bcs @done
 lda sprite_x
 and #$FC
 sta sprite_x
 jmp detail_high_bag
@done:
 rts
.endproc

; The high bag always uses one of forty whole-cell positions. Copy its four
; masked glyphs directly; unlike the crowd-level water cache, this preserves
; the fixed big top underneath it at every camera position.
.proc detail_high_bag
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 sta detail_sign_col
 lda #0
 sta detail_sign_cell
 sta detail_bag_offset
@cell:
 lda detail_sign_cell
 and #1
 clc
 adc detail_sign_col
 cmp #40
 jcs @skip
 sta z_col
 lda detail_sign_cell
 lsr
 clc
 adc #1
 tax
 lda row_lo,x
 clc
 adc z_col
 sta z_cell
 lda z_map+1
 sta z_cell+1
 ldy z_num
 lda z_cell
 sta (z_dirtylo),y
 lda #0
 sta (z_dirtyhi),y
 inc z_num
 ldy #0
 lda (z_cell),y
 sta z_colorflag
 and #127
 sta z_old
 tax
 lda glyph_lo,x
 sta z_bg
 lda glyph_hi,x
 ora band_font
 sta z_bg+1
 ldx free_glyph
 inc free_glyph
 txa
 ora #128
 sta (z_cell),y
 lda glyph_lo,x
 sta z_glyph
 lda glyph_hi,x
 ora band_font
 sta z_glyph+1
 ldx detail_bag_offset
 lda z_old
 bne :+
 jsr detail_bag_blank
 jmp @skip
:
 bit z_colorflag
 bpl @gold
 .repeat 8,I
 ldy #I
 lda (z_bg),y
 and detail_bag_masks+I,x
 ora detail_bag_pixels+I,x
 sta (z_glyph),y
 .endrepeat
 jmp @skip
@gold:
 ldy #0
@convert:
 lda (z_bg),y
 tax
 lda $7C00,x
 ldx detail_bag_offset
 and detail_bag_masks,x
 ora detail_bag_pixels,x
 sta (z_glyph),y
 inc detail_bag_offset
 iny
 cpy #8
 bne @convert
 lda detail_bag_offset
 sec
 sbc #8
 sta detail_bag_offset
@skip:
 lda detail_bag_offset
 clc
 adc #8
 sta detail_bag_offset
 inc detail_sign_cell
 lda detail_sign_cell
 cmp #4
 jcc @cell
 rts
.endproc
