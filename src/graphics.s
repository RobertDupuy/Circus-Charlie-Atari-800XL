; Bold Arcade: palette scheduling, compact character objects and PM accents.
.proc gfx_stage_setup
 jsr complete_stage
 lda #0
 sta tramp_font_adjust+1
 lda #<prepare_pm
 ldx #>prepare_pm
 ldy act
 cpy #2
 bne :+
 ldy water
 bne :+
 lda #<tramp_prepare_entry
 ldx #>tramp_prepare_entry
:
 sta render_frame::pm_prepare_dispatch+1
 stx render_frame::pm_prepare_dispatch+2
 lda #2
 sta row_band+17
 sta row_band+18
 sta row_band+19
 jsr gfx_schedule
 lda #32
 ldx act
 bne :+
 lda #35
:
 cpx #4
 bcc :+
 lda #27
:
 sta gfx_reserve
 sta gfx_reserve+1
 sta gfx_reserve+2
 lda #20
 cpx #0
 bne :+
 lda #28
:
 sta gfx_reserve+2
 cpx #4
 bne :+
 lda #12
 sta gfx_reserve+2
:
 cpx #3
 bne :+
 lda #0
 sta gfx_reserve+2
:
 lda #$26
 sta $D500
 ldx #0
@palette_map:
 txa
 ldy pal
 beq :+
 lda $AC00,x
:
 sta $FD00,x
 inx
 bne @palette_map
 ldx #44
@copy:
 lda gfx_palette_default,x
 sta gfx_bg,x
 dex
 bpl @copy
 ldx #8
 lda #0
@clear:
 sta gfx_stripe,x
 dex
 bpl @clear
 ; Colour changes stay on the DLI boundaries without extra WSYNC stalls.
 lda act
 cmp #1
 beq @high
 cmp #5
 bne @water
@high:
 ldx #4
@air:
 lda #0
 sta gfx_bg,x
 lda #$2E
 sta gfx_pf2,x
 lda #$86
 sta gfx_pf3,x
 dex
 bpl @air
 lda #0
 sta gfx_bg+5
 sta gfx_stripe+5
 lda #$AA
 sta gfx_pf2+5
 lda #$2E
 sta gfx_pf3+5
 lda #$68
 sta gfx_bg+6
 lda #$0E
 sta gfx_pf2+6
@water:
 lda act
 cmp #2
 bne @not_tramp
 lda #$2E
 sta gfx_pf2
 sta gfx_pf2+1
 lda #$86
 sta gfx_pf3
 sta gfx_pf3+1
@not_tramp:
 lda act
 bne :+
 lda #$0E
 sta gfx_pf1+4
 sta gfx_pf1+5
 sta gfx_pf1+6
 lda #$C4
 sta gfx_bg+7
:
 lda act
 cmp #1
 beq :+
 cmp #5
 beq :+
 lda #$C6
 sta gfx_bg+5
 lda #$C4
 sta gfx_bg+6
 sta gfx_bg+7
:
 lda water
 beq @convert
 lda #$98
 sta gfx_bg+7
 lda #$AE
 sta gfx_pf3+7
@convert:
 lda pal
 beq @pm
 ldx #44
@pal:
 lda gfx_bg,x
 tay
 lda $AC00,y
 sta gfx_bg,x
 dex
 bpl @pal
@pm:
 ldx #2
@pmloop:
 lda gfx_pm_native,x
 ldy pal
 beq :+
 tay
 lda $AC00,y
:
 sta gfx_pm_colours,x
 dex
 bpl @pmloop
 jsr gfx_load_alt_bg
 rts
.endproc

.proc gfx_font_table
 ldx front
 lda font_high,x
 sta $DC80
 sta $DC81
 sta $DC82
 clc
 adc #4
 sta $DC83
 sta $DC84
 sta $DC85
 adc #4
.if ::ARCADE_CHOOSER
 ldy mode
 cpy #7
 beq :+
.endif
 ldy act
 cpy #3
 bne :+
 lda frame_ballfont,x
:
 sta $DC87
 sec
adjust:
 sbc #0
 sta $DC86
 lda #$30
 sta $DC88
 jmp gfx_dma_dispatch
.endproc
tramp_font_adjust = gfx_font_table::adjust

; A is already saved by NMI. Keep the ordinary entry short enough to
; reach WSYNC even at the busiest ANTIC character/PM DMA boundary.
.proc gfx_dli_entry
 txa
 pha
 ldx dli_index
 sta $D40A
colours:
 lda $DC80,x
 sta $D409
palette:
 lda gfx_bg,x
 sta $D01A
 lda gfx_pf2,x
 sta $D018
 lda gfx_pf3,x
 sta $D019
 lda gfx_pf1,x
 sta $D017
 ; Change player DMA after the boundary scanline's PM fetch. Moving this
 ; ahead of WSYNC can freeze the previous nonzero player latch as a long
 ; vertical stripe. The staged bands include three blank guard scanlines.
 ; CPX leaves Z clear for normal bands; the patched branch selects gating.
 cpx #9
gfx_dma_branch = *
 bne :+
 lda $DCE0,x
 sta $D400
 lsr
 lsr
 and #2
 sta $D01D
:
sound:
 lda gfx_field
 beq regular_next
 lda lion_dli_next,x
 jmp next_index
regular_next:
 lda gfx_dli_next,x
next_index:
 sta dli_index
 cpx #1
 bne end
 lda pcm_active
 bne end
 ; Only audio and the extra lion shade interrupts use Y. Saving it here
 ; keeps the longer DMA-gated path inside the scanline budget as well.
 tya
 pha
 cld
 jsr audio_tick
 pla
 tay
end:
 pla
 tax
 pla
 rti
; Only the lion has extra shade interrupts; its separate entry keeps
; this dispatch out of the other acts' scanline-critical path.
lion_entry:
 txa
 pha
 ldx dli_index
 cpx #9
 bcs field
 lda $DC80,x
 sta $D409
 sta $D40A
 jmp palette
field:
 tya
 pha
 lda lion_field_colour-9,x
 tay
 lda $FD00,y
 sta $D40A
 sta $D01A
 pla
 tay
 jmp sound
.endproc
gfx_lion_dli_entry = gfx_dli_entry::lion_entry
lion_dli_next: .byte 1,2,3,4,9,11,7,8,8,10,5,6
; Extra lion boundaries agree with the three shades on the regular bands.
lion_field_colour: .byte $C8,$C6,$C4

.proc gfx_tag_hero
 lda sprite_x
 sta gfx_hero_x
 lda sprite_y
 sta gfx_hero_y
 lda sprite_pose
 sta gfx_hero_pose
 lda #1
 sta gfx_hero_valid
 rts
.endproc

.proc gfx_hero_overlay
 lda gfx_hero_valid
 jeq @done
 lda water
 jne @done
 lda act
 cmp #3
 beq @active
 cmp #5
 jne @done
@active:
 lda #$26
 sta $D500
 lda gfx_hero_pose
 cmp #8
 jcs @prepared ; Prepared victory poses have their colours in the playfield.
 tax
 sta z_tmp
 asl
 clc
 adc z_tmp
 asl
 asl
 sta z_src
 lda #$AE
 sta z_src+1
 txa
 tax
 lda gfx_overlay_lo,x
 sta z_pmdata
 lda gfx_overlay_hi,x
 sta z_pmdata+1
 lda #3
 ldx act
 cpx #3
 bne :+
 lda #0
:
 sta gfx_target_player
 lda back
 asl
 asl
 asl
 asl
 asl
 clc
 adc gfx_target_player
 sta z_savedx
 lda back
 asl
 asl
 clc
 adc gfx_target_player
 sta z_pmnum
 lda #1
 sta z_iter
 lda z_pmdata
 clc
 adc #48
 sta z_pmdata
 bcc @player
 inc z_pmdata+1
@player:
 ldy z_iter
 lda (z_src),y
 clc
 adc gfx_hero_x
 adc #48
 ldy z_savedx
 sta $0E00,y
 ldx z_iter
 lda gfx_pm_colours,x
 sta $0E0C,y
 lda #0
 sta $0E08,y
 lda z_iter
 clc
 adc #6
 tay
 lda (z_src),y
 sta gfx_overlay_height
 tya
 sec
 sbc #3
 tay
 lda (z_src),y
 clc
 adc gfx_hero_y
 clc
 adc #40
 sta gfx_overlay_y
 ldx back
 lda pm_high,x
 clc
 adc #4
 adc gfx_target_player
 sta z_pm+1
 ldx z_pmnum
 lda pm_old_h,x
 beq @clean
 sta z_tmp2
 lda pm_old_y,x
 sta z_pm
 lda pm_old_h,x
 cmp gfx_overlay_height
 bne @fullclear
 lda gfx_overlay_y
 sec
 sbc z_pm
 beq @clean
 bcc @up
 cmp z_tmp2
 bcc @range
 lda z_tmp2
 bne @range
@up:
 eor #$FF
 clc
 adc #1
 cmp z_tmp2
 bcc :+
 lda z_tmp2
:
 sta z_tmp
 lda z_pm
 clc
 adc z_tmp2
 sec
 sbc z_tmp
 sta z_pm
 lda z_tmp
 jmp @range
@fullclear:
 lda z_tmp2
@range:
 tay
 dey
 lda #0
@erase:
 sta (z_pm),y
 dey
 bpl @erase
@clean:
 lda gfx_overlay_y
 sta z_pm
 ldx z_pmnum
 sta pm_old_y,x
 lda gfx_overlay_height
 sta pm_old_h,x
 tay
 dey
@copy:
 lda (z_pmdata),y
 sta (z_pm),y
 dey
 bpl @copy
@done:
 rts
@prepared:
 ; Balls reserve player zero for Charlie's ordinary colour overlay. Hide
 ; that previous pose when the victory colours move into the playfield.
 lda back
 asl
 asl
 asl
 asl
 asl
 tay
 lda #0
 sta $0E00,y
 rts
.endproc

.proc gfx_visible
 lda sprite_xhi
 beq @right
 cmp #255
 bne @no
 lda sprite_x
 cmp #224
 bcc @no
 clc
 rts
@right:
 lda sprite_x
 cmp #160
 rts
@no:
 sec
 rts
.endproc

.proc gfx_lion_obstacles
 jmp lion_arcade_draw
.endproc

.proc gfx_monkeys
 lda #0
 sta z_hazard
 sta z_obj
@next:
 ldx z_hazard
 jsr get_hazard
 jsr screen_position
 lda #12
 jsr gfx_visible_width
 bcs @skip
 ldx z_hazard
 jsr monkey_height
 sta z_tmp
 lda #79
 sec
 sbc z_tmp
 sta sprite_y
 lda monkey_type,x
 asl
 asl
 clc
 adc #102
 sta z_tmp
 lda anim_clock
 lsr
 lsr
 and #3
 clc
 adc z_tmp
 sta sprite_pose
 jsr draw_stamp
 ; Brown monkeys already use the gold playfield colour. Reserve the four
 ; hardware accents for pink monkeys, so every close group stays visible.
 ldx z_hazard
 lda monkey_type,x
 beq @skip
 ldx z_obj
 cpx #4
 bcs @overflow
 lda sprite_x
 sta pm_x,x
 lda sprite_y
 sta pm_y,x
 lda anim_clock
 lsr
 lsr
 and #3
 clc
 adc #4
 sta pm_id,x
 lda #$2E
 ldy z_hazard
 lda monkey_type,y
 beq :+
 lda #$4E
 bne :++
:
 lda #$2E
:
 sta pm_color,x
 inc z_obj
 jmp @skip
@overflow:
 inc mech_pm_overflow
@skip:
 inc z_hazard
 lda z_hazard
 cmp #16
 bne @next
 rts
.endproc

.segment "CODE"
.proc gfx_trampolines
 jmp detail_tramp_entry
.endproc

.segment "XL"
.proc gfx_springs
 lda #0
 sta z_hazard
@next:
 ldx z_hazard
 lda h_width,x
 jeq @skip
 asl
 clc
 adc h_width,x
 sta z_tmp
 lda hazard_xlo,x
 sec
 sbc z_tmp
 sta z_pos
 lda hazard_xhi,x
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda z_tmp
 asl
 jsr gfx_visible_width
 jcs @skip
 ldx z_hazard
 lda horse_y,x
 sta sprite_y
 lda h_width,x
 asl
 clc
 adc #26
 sta sprite_pose
 lda sprite_x
 and #254
 sta sprite_x
 ; Both decks are supported by narrow legs reaching the arena floor.
 jsr gfx_spring_board
 ldx z_hazard
 lda horse_y,x
 sec
 sbc #128
 lsr
 lsr
 lsr
 tay
 clc
 adc #32
 sta gfx_cached_kind
 lda horse_leg_pose,y
 sta sprite_pose
 lda horse_y,x
 clc
 adc #16
 sta sprite_y
 inc sprite_x
 bne :+
 inc sprite_xhi
:
 jsr gfx_spring_leg
@skip:
 inc z_hazard
 lda z_hazard
 cmp #16
 jne @next
 rts
.endproc
.include "horse-legs.inc"
.segment "XL"
.proc horse_glyph_budget
 lda #12
 ldx mode
 cpx #3
 beq @fallen
 cpx #5
 beq @fallen
 cpx #6
 bne @store
@fallen:
 lda #16
@store:
 sta gfx_reserve+2
 rts
.endproc
.segment "GFX"
.proc gfx_spring_leg
 ; Draw both supports with independently clipped native columns.
 ldx z_hazard
 lda h_width,x
 asl
 clc
 adc h_width,x
 asl
 sec
 sbc #2
 sta gfx_rect_w
 lda #166
 sec
 sbc sprite_y
 sta gfx_rect_h
 jsr gfx_mark_rect
 ldx z_hazard
 lda h_width,x
 asl
 clc
 adc h_width,x
 asl
 sec
 sbc #3
 clc
 adc sprite_x
 sta z_left
 lda sprite_xhi
 adc #0
 tax
 lda z_left
 lsr
 lsr
 cpx #0
 beq :+
 ora #$C0
:
 sta z_tmp2
 ; Reuse the native directory's four subpixel slots for alignment/parity.
 ldx z_hazard
 lda h_width,x
 and #1
 sta z_left
 lda sprite_x
 and #254
 ora z_left
 sta sprite_x
 jsr gfx_native_cached
 rts
.endproc

.proc gfx_finish
 lda act
 bne :+
 jmp lion_arcade_finish_draw
:
 cmp #1
 bne :+
 lda #$20
 sta $D500
 jmp tightrope_finish_draw
:
 cmp #5
 bne :+
 jmp apparatus_finish_draw
:
 lda water
 bne @done
 lda act
 cmp #3
 beq @platform
 cmp #4
 beq @platform
 lda stage_end
 sta z_pos
 lda stage_end+1
 sta z_pos+1
 jsr screen_position
 jsr gfx_visible
 bcs @done
 jmp @soft
@platform:
 lda #$20
 sta $D500
 jmp ground_finish_draw
@soft:
 lda #11
 sta gfx_cached_kind
 jmp gfx_native_cached
@done:
 rts
.endproc

.proc gfx_water_dolphin
 lda pm_id,x
 sec
 sbc #17
 clc
 adc #112
 sta sprite_pose
 lda pm_y,x
 sta sprite_y
 jsr draw_stamp
 lda #$3C
 sta $D500
 rts
.endproc

gfx_pm_native: .byte $86,$AE,$0E
gfx_palette_default:
 .byte $46,$00,$68,$68,$C8,$C8,$C8,$C8,$00
 .byte $42,$42,$42,$42,$42,$42,$42,$42,$00
 .byte $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$0E
 .byte $AA,$AA,$0E,$0E,$2E,$2E,$2E,$2E,$00
 .byte $2E,$2E,$86,$86,$86,$86,$86,$86,$00
 .segment "CODE"
gfx_overlay_lo:
 .repeat 17,I
 .byte <($B000+I*144)
 .endrepeat
gfx_overlay_hi:
 .repeat 17,I
 .byte >($B000+I*144)
 .endrepeat
.segment "GFX"
gfx_ball_flag_lo: .byte <$7E40,<$7EA0,<$7F00,<$7F60
gfx_ball_flag_hi: .byte >$7E40,>$7EA0,>$7F00,>$7F60

gfx_glyph_lo:
 .repeat 128,I
 .byte <(I*8-2)
 .endrepeat
gfx_glyph_hi:
 .repeat 128,I
 .byte >(I*8-2)
 .endrepeat

; Fixed-y hoops and platforms share immutable character patterns. Only screen
; codes and their dirty addresses change as they move. No glyph copy is needed.
.segment "CODE"
.proc gfx_resident
 txa
 pha
 lda #0
 ldx act
 beq :+
 lda #1
 cpx #2
 beq :+
 lda #2
:
 sta gfx_cached_kind
 pla
 tax
 jmp gfx_cached_select
.endproc

.proc gfx_cached_select
 txa
 pha
 ldx gfx_cached_kind
 lda gfx_cached_w,x
 sta gfx_rect_w
 lda gfx_cached_h,x
 sta gfx_rect_h
 lda gfx_cached_y,x
 sta sprite_y
 jsr gfx_mark_rect
 pla
 tax
 lda sprite_xhi
 bne @slow
 lda gfx_cached_kind
 cmp #16
 beq @narrow
 cmp #7
 bcs @wide
@narrow:
 lda sprite_x
 cmp #140
 bcs @slow
 jmp gfx_native_cached
@wide:
 ; Horse's clipped right edge is repaired by gfx_horse after native stores.
 lda gfx_cached_kind
 cmp #10
 bcc @native
 lda sprite_x
 cmp #129
 bcs @slow
@native:
 jmp gfx_native_cached
@slow:
 lda gfx_cached_kind
 cmp #31
 beq @native
 cmp #10
 beq @native
 cmp #0
 beq @edge
 cmp #3
 beq @edge
 cmp #4
 beq @edge
 cmp #16
 beq @edge
 cmp #17
 bne @fallback
@edge:
 jmp gfx_native_edge
@fallback:
 txa
 pha
 tya
 pha
 lda #$34
 sta $D500
 lda gfx_cached_kind
 asl
 asl
 sta z_tmp
 lda sprite_x
 and #3
 ora z_tmp
 sta z_tmp
 asl
 sta z_ptr
 lda #0
 rol
 sta z_ptr+1
 lda z_ptr
 clc
 adc z_tmp
 sta z_ptr
 lda z_ptr+1
 adc #$83
 sta z_ptr+1
 lda z_ptr
 clc
 adc #$80
 sta z_ptr
 bcc :+
 inc z_ptr+1
:
 ldy #0
 lda (z_ptr),y
 pha
 iny
 lda (z_ptr),y
 sta z_rom
 iny
 lda (z_ptr),y
 sta z_rom+1
 pla
 sta $D500
 ldy #0
 lda (z_rom),y
 sta z_cells
 beq @empty
 inc z_rom
 bne :+
 inc z_rom+1
:
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
 adc #0
 sta z_off+1
 ora z_map+1
 sta z_cell+1
 ldy #2
 lda (z_rom),y
 ldy #0
 sta (z_cell),y
@next:
 lda z_rom
 clc
 adc #3
 sta z_rom
 bcc :+
 inc z_rom+1
:
 dec z_cells
 bne @cell
@empty:
 pla
 tay
 pla
 tax
 rts
.endproc

.segment "GFX"
; Actor headers and glyph bytes are separate. Reserve a small fixed range for
; Charlie, publish its screen codes, copy contiguous glyph runs, then mask only
; the cells that actually intersect scenery or another object.
.proc gfx_draw_hero
 lda z_cells
 jeq @done
 lda #16
 ldx sprite_pose
 cpx #84
 bcs @lion_size
 cpx #0
 beq @dance_size
 cpx #5
 beq @dance_size
 sta gfx_rect_w
 lda #38
 bne @height_size
@dance_size:
 lda #24
 sta gfx_rect_w
 lda #40
 bne @height_size
@lion_size:
 lda #24
 sta gfx_rect_w
 lda #32
@height_size:
 sta gfx_rect_h
 jsr gfx_mark_rect
 ldy #0
 lda (z_rom),y
 clc
 adc z_rom
 sta gfx_pixels
 lda z_rom+1
 adc #0
 sta gfx_pixels+1
 iny
 lda (z_rom),y
 sta gfx_dense_w
 iny
 lda (z_rom),y
 sta gfx_dense_h
 lda z_rom
 clc
 adc #3
 sta z_rom
 bcc :+
 inc z_rom+1
:
 lda #0
 sta gfx_dense_row
 sta gfx_cell_index
 sta gfx_mask_count
 sta gfx_dense_clip
 lda sprite_xhi
 bne @clip
 lda sprite_x
 cmp #128
 bcc @init0
@clip:
 inc gfx_dense_clip
@init0:
 ; A nonempty prepared header is always nonzero. Select the clip branch
 ; once per actor instead of loading the same clip flag in every cell.
 ; The opcode is in writable native RAM, like the copy operands below.
 lda #$D0
 ldx gfx_dense_clip
 beq :+
 lda #$F0
:
 sta @clip_test
 lda #0
 ldx #2
@init:
 sta gfx_range_end,x
 lda #255
 sta gfx_range_start,x
 lda #0
 dex
 bpl @init
 jsr trapeze_clip_top
@row:
 lda z_row
 clc
 adc gfx_dense_row
 cmp #22
 jcs @rowsdone
 tay
 lda row_band,y
 sta z_band
 tax
 lda gfx_range_start,x
 cmp #255
 bne :+
 lda gfx_cell_index
 sta gfx_range_start,x
:
 lda bg_count,x
 sec
 sbc gfx_range_start,x
 sec
 sbc #1
 sta gfx_hero_base
 lda row_lo,y
 clc
 adc z_col
 sta z_cell
 lda row_hi,y
 adc sprite_xhi
 clc
 adc z_map+1
 sta z_cell+1
 ldy #0
@cell:
 lda (z_rom),y
 beq @next
 sta gfx_sprite_alt
@clip_test:
 bne @visible
 tya
 clc
 adc z_col
 cmp #40
 bcs @skipglyph
@visible:
 lda (z_cell),y
 sta z_old
 lda gfx_sprite_alt
 and #$BF
 clc
 adc gfx_hero_base
 sta (z_cell),y
 lda z_old
 and #127
 beq @skipglyph
 bit gfx_sprite_alt
 bvs @skipglyph
 ldx gfx_mask_count
 lda gfx_cell_index
 sta $DD00,x
 lda z_old
 sta $DD40,x
 lda z_band
 sta $DD80,x
 lda gfx_sprite_alt
 sta $DDC0,x
 inc gfx_mask_count
@skipglyph:
 inc gfx_cell_index
@next:
 iny
 cpy gfx_dense_w
 bne @cell
 ldx z_band
 lda gfx_cell_index
 sta gfx_range_end,x
 lda z_rom
 clc
 adc gfx_dense_w
 sta z_rom
 bcc :+
 inc z_rom+1
:
 inc gfx_dense_row
 lda gfx_dense_row
 cmp gfx_dense_h
 jne @row
@rowsdone:
 lda #0
 sta z_band
@band:
 ldx z_band
 lda gfx_range_start,x
 cmp #255
 jeq @bandnext
 sta z_tmp
 tay
 lda glyph_lo,y
 clc
 adc gfx_pixels
 sta z_src
 lda glyph_hi,y
 adc gfx_pixels+1
 sta z_src+1
 lda bg_count,x
 tay
 lda glyph_lo,y
 sta z_dst
 lda glyph_hi,y
 ora band_font,x
 sta z_dst+1
 lda gfx_range_end,x
 sec
 sbc z_tmp
 jeq @bandnext
 tax
 ldy #0
 lda z_src
 sta @read0+1
 sta @read1+1
 sta @read2+1
 sta @read3+1
 sta @read4+1
 sta @read5+1
 sta @read6+1
 sta @read7+1
 lda z_src+1
 sta @read0+2
 sta @read1+2
 sta @read2+2
 sta @read3+2
 sta @read4+2
 sta @read5+2
 sta @read6+2
 sta @read7+2
 lda z_dst
 sta @write0+1
 sta @write1+1
 sta @write2+1
 sta @write3+1
 sta @write4+1
 sta @write5+1
 sta @write6+1
 sta @write7+1
 lda z_dst+1
 sta @write0+2
 sta @write1+2
 sta @write2+2
 sta @write3+2
 sta @write4+2
 sta @write5+2
 sta @write6+2
 sta @write7+2
@copy:
@read0:
 lda $FFFF,y
@write0:
 sta $FFFF,y
 iny
@read1:
 lda $FFFF,y
@write1:
 sta $FFFF,y
 iny
@read2:
 lda $FFFF,y
@write2:
 sta $FFFF,y
 iny
@read3:
 lda $FFFF,y
@write3:
 sta $FFFF,y
 iny
@read4:
 lda $FFFF,y
@write4:
 sta $FFFF,y
 iny
@read5:
 lda $FFFF,y
@write5:
 sta $FFFF,y
 iny
@read6:
 lda $FFFF,y
@write6:
 sta $FFFF,y
 iny
@read7:
 lda $FFFF,y
@write7:
 sta $FFFF,y
 iny
 tya
 bne :+
 inc @read0+2
 inc @write0+2
 inc @read1+2
 inc @write1+2
 inc @read2+2
 inc @write2+2
 inc @read3+2
 inc @write3+2
 inc @read4+2
 inc @write4+2
 inc @read5+2
 inc @write5+2
 inc @read6+2
 inc @write6+2
 inc @read7+2
 inc @write7+2
:
 dex
 bne @copy
@bandnext:
 inc z_band
 lda z_band
 cmp #3
 jne @band
 jsr apparatus_blend_prepare
 lda #0
 sta gfx_cell_index
@mask:
 ldx gfx_cell_index
 cpx gfx_mask_count
 jeq @done
 lda $DD80,x
 sta z_band
 tay
 lda $DD40,x
 sta z_colorflag
 and #$7F
 tax
 lda glyph_lo,x
 sta z_bg
 lda glyph_hi,x
 ora band_font,y
 sta z_bg+1
 ldx gfx_cell_index
 lda $DD00,x
 sec
 sbc gfx_range_start,y
 clc
 adc bg_count,y
 tax
 lda glyph_lo,x
 sta z_glyph
 lda glyph_hi,x
 ora band_font,y
 sta z_glyph+1
 ldx gfx_cell_index
 lda $DDC0,x
 eor z_colorflag
 jmi @alt
@normalmask:
 lda r_blend_enabled
 beq @ordinary_mask
 ldx gfx_cell_index
 lda $DD00,x
 asl
 tay
 lda (z_ptr),y
 sta z_tempword
 iny
 lda (z_ptr),y
 beq @ordinary_mask
 sta z_tempword+1
 jsr apparatus_blend
 jmp @masknext
@ordinary_mask:
 .repeat 8,I
 ldy #I
 lda (z_glyph),y
 tax
 lda $FC00,x
 beq :+
 and (z_bg),y
 ora (z_glyph),y
 sta (z_glyph),y
:
 .endrepeat
 jmp @masknext
@alt:
 lda z_colorflag
 jsr gfx_alt_bg
 bcc @alt_slow
 jmp @normalmask
@alt_slow:
 .repeat 8,I
 ldy #I
 lda (z_glyph),y
 tax
 lda $FC00,x
 beq :+
 sta z_value
 lda (z_bg),y
 tax
 lda $7C00,x
 and z_value
 ora (z_glyph),y
 sta (z_glyph),y
:
 .endrepeat
@masknext:
 inc gfx_cell_index
 jmp @mask
@done:
 rts
.endproc

.proc gfx_native_cached
 txa
 pha
 tya
 pha
 lda #$34
 sta $D500
 lda gfx_cached_kind
 asl
 asl
 asl
 sta z_tmp
 lda sprite_x
 and #3
 asl
 ora z_tmp
 ora back
 sta z_tmp
 lda #0
 sta z_ptr+1
 lda z_tmp
 asl
 rol z_ptr+1
 clc
 adc z_tmp
 sta z_ptr
 lda z_ptr+1
 adc #$80
 ldx gfx_cached_kind
 cpx #32
 bcc :+
 clc
 adc #3
:
 sta z_ptr+1
 ldy #0
 lda (z_ptr),y
 pha
 iny
 lda (z_ptr),y
 sta z_rom
 iny
 lda (z_ptr),y
 sta z_rom+1
 pla
 sta $D500
 lda sprite_x
 lsr
 lsr
 ldy sprite_xhi
 beq :+
 ora #$C0
:
 tax
 ldy z_num
 jsr @call
 sty z_num
 pla
 tay
 pla
 tax
 rts
@call:
 jmp (z_rom)
.endproc



.proc gfx_horse
 lda sprite_x
 cmp #160
 bcs @done
 and #3
 cmp #1
 bne @slow
 lda sprite_pose
 sec
 sbc #4
 sta gfx_cached_kind
 jsr gfx_cached_select
 lda sprite_x
 cmp #129
 bcc @done
 lda #$3C
 sta $D500
 jmp complete_horse_edge
@done:
 rts
@slow:
 jmp draw_stamp
.endproc

.segment "AUX"
.proc gfx_visible_width
 ldx sprite_xhi
 beq @right
 cpx #255
 bne @no
 eor #255
 clc
 adc #1
 cmp sprite_x
 bcs @no
 clc
 rts
@right:
 lda sprite_x
 cmp #160
 rts
@no:
 sec
 rts
.endproc
.segment "GFX"

.segment "CODE"
.segment "CODE"
.segment "MECHANICS"
gfx_cached_w: .byte 16,24,16,16,16,8,8,30,30,30,32,32,32,32,32,32,16,32,16,16,16,16,16,16,16,32,32,16,16,16,16,24,1,1,1
gfx_cached_h: .byte 72,48,10,24,24,28,28,32,32,32,48,48,4,4,4,4,56,11,8,8,8,8,8,8,8,4,10,32,32,32,32,48,22,14,6
gfx_cached_y: .byte 72,128,164,142,142,138,138,134,134,134,128,128,164,164,164,164,72,155,168,168,168,168,168,168,168,64,164,144,144,144,144,128,144,152,160

.segment "AUX"
.proc gfx_mark_rect
 ; z_rom and the stamp's pixel/band state are preserved.
 lda sprite_x
 and #3
 clc
 adc gfx_rect_w
 adc #3
 lsr
 lsr
 sta gfx_rect_w
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq @right
 cpx #255
 jne @done
 ora #$C0
 clc
 adc gfx_rect_w
 jcc @done
 jeq @done
 sta gfx_rect_w
 lda #0
@right:
 cmp #40
 jcs @done
 sta gfx_rect_col
 clc
 adc gfx_rect_w
 cmp #41
 bcc :+
 lda #40
 sec
 sbc gfx_rect_col
 sta gfx_rect_w
:
 lda sprite_y
 and #7
 clc
 adc gfx_rect_h
 adc #7
 lsr
 lsr
 lsr
 sta gfx_rect_h
 lda sprite_y
 lsr
 lsr
 lsr
 cmp #22
 jcs @done
 tax
 clc
 adc gfx_rect_h
 cmp #23
 bcc :+
 txa
 eor #255
 clc
 adc #23
 sta gfx_rect_h
:
 ; Uniform field/rigging rows need one source read per row.
 ldy act
 txa
 cmp gfx_uniform_first,y
 bcc @record
 clc
 adc gfx_rect_h
 cmp gfx_uniform_end,y
 bcc @checkwater
 bne @record
@checkwater:
 ldy water
 beq @uniform
 cmp #21
 bcs @record
@uniform:
 lda gfx_rect_h
 ora #$80
 sta gfx_rect_h
@record:
 lda act
 cmp #5
 bne :+
 jsr apparatus_clip_rect
 bcs @done
:
 lda #0
 sta z_rect
 lda back
 clc
 adc #$DE
 sta z_rect+1
 lda back
 tay
 lda gfx_rect_count,y
 tay
 lda row_lo,x
 clc
 adc gfx_rect_col
 sta (z_rect),y
 iny
 lda row_hi,x
 adc #0
 sta (z_rect),y
 iny
 lda gfx_rect_w
 sta (z_rect),y
 iny
 lda gfx_rect_h
 sta (z_rect),y
 iny
 tya
 ldx back
 sta gfx_rect_count,x
@done:
 rts
.endproc

.segment "MECHANICS"
gfx_uniform_first: .byte 9,0,9,9,9,0
gfx_uniform_end: .byte 22,13,22,17,22,13
.proc gfx_restore_rects
 lda #0
 sta z_rect
 lda back
 clc
 adc #$DE
 sta z_rect+1
 ldx back
 lda gfx_rect_count,x
 sta gfx_rect_limit
 lda #0
 sta gfx_rect_count,x
 sta gfx_rect_index
@rect:
 ldy gfx_rect_index
 cpy gfx_rect_limit
 jeq @done
 lda (z_rect),y
 sta z_src
 sta z_dst
 iny
 lda (z_rect),y
 ora #$34
 sta z_src+1
 and #3
 ora z_map+1
 sta z_dst+1
 iny
 lda (z_rect),y
 sta gfx_rect_w
 iny
 lda (z_rect),y
 sta gfx_rect_uniform
 and #$7F
 sta gfx_rect_h
 iny
 sty gfx_rect_index
 jsr lion_restore_ring_rect
 bcs @rect
 ldx gfx_rect_w
 lda @filllo-1,x
 sta @filljump+1
 lda @fillhi-1,x
 sta @filljump+2
@row:
 bit gfx_rect_uniform
 bmi @uniform
 ldy gfx_rect_w
 dey
@copy:
 lda (z_src),y
 sta (z_dst),y
 dey
 bpl @copy
 jmp @nextrow
@uniform:
 ldy #0
 lda (z_src),y
 ldy gfx_rect_w
 dey
@filljump:
 jmp @fill1
@fill13: sta (z_dst),y
 dey
@fill12: sta (z_dst),y
 dey
@fill11: sta (z_dst),y
 dey
@fill10: sta (z_dst),y
 dey
@fill9: sta (z_dst),y
 dey
@fill8: sta (z_dst),y
 dey
@fill7: sta (z_dst),y
 dey
@fill6: sta (z_dst),y
 dey
@fill5: sta (z_dst),y
 dey
@fill4: sta (z_dst),y
 dey
@fill3: sta (z_dst),y
 dey
@fill2: sta (z_dst),y
 dey
@fill1: sta (z_dst),y
@nextrow:
 lda z_src
 clc
 adc #40
 sta z_src
 sta z_dst
 bcc :+
 inc z_src+1
 inc z_dst+1
:
 dec gfx_rect_h
 bne @row
 jmp @rect
@done:
 rts
 .segment "CODE"
@filllo: .byte <@fill1,<@fill2,<@fill3,<@fill4,<@fill5,<@fill6,<@fill7,<@fill8,<@fill9,<@fill10,<@fill11,<@fill12,<@fill13
@fillhi: .byte >@fill1,>@fill2,>@fill3,>@fill4,>@fill5,>@fill6,>@fill7,>@fill8,>@fill9,>@fill10,>@fill11,>@fill12,>@fill13
.endproc
.segment "GFX"

.segment "MECHANICS"
.proc gfx_load_alt_bg
 lda #0
 sta gfx_alt_ready
 lda act
 cmp #3
 beq @done
 jsr scene_id
 asl
 asl
 asl
 clc
 adc #$80
 sta z_src+1
 lda #0
 sta z_src
 sta z_dst
 lda #$6C
 sta z_dst+1
 lda #$35
 sta $D500
 ldx #8
 jsr copy_pages
 ldx #8
@metadata:
 lda $6C00,x
 sta gfx_alt_base,x
 dex
 bpl @metadata
 inc gfx_alt_ready
@done:
 rts
.endproc

.proc gfx_alt_bg
 and #127
 tax
 lda gfx_alt_ready
 beq @no
 txa
 ldy z_band
 cmp gfx_alt_base+6,y
 bcs @no
 lda glyph_lo,x
 clc
 adc gfx_alt_base,y
 sta z_bg
 lda glyph_hi,x
 adc gfx_alt_base+3,y
 sta z_bg+1
 sec
 rts
@no:
 clc
 rts
.endproc
.segment "GFX"

.segment "MECHANICS"
.proc gfx_game_steps
 lda #2
 sta logic_steps
 lda act
 bne @ordinary
 lda #1
 ldx pal
 beq :+
 lda #19
:
 clc
 adc pal_acc
 cmp #44
 bcc @lionacc
 sbc #44
 inc logic_steps
@lionacc:
 sta pal_acc
 jmp @steps
@ordinary:
 lda pal
 beq @steps
 lda pal_acc
 clc
 adc #2
 cmp #5
 bcc @acc
 sbc #5
 inc logic_steps
@acc:
 sta pal_acc
@steps:
 jsr game_tick
 dec logic_steps
 bne @steps
 rts
.endproc
.segment "GFX"

.segment "MECHANICS"
.proc gfx_schedule
 lda #0
 sta gfx_field
 ldx act
 lda gfx_dma_opcode,x
 sta gfx_dli_entry::gfx_dma_branch
 lda #$04
 sta $6811
 sta $6911
 sta $6813
 sta $6913
 sta $6816
 sta $6916
 ldx #8
@next:
 txa
 clc
 adc #1
 sta gfx_dli_next,x
 dex
 bpl @next
 lda #$84
 sta $680E
 sta $690E
 sta $6810
 sta $6910
 sta $6814
 sta $6914
 sta $681B
 sta $691B
 lda act
 bne :+
 inc gfx_field
 lda #$84
 sta $6811
 sta $6911
 sta $6813
 sta $6913
 sta $6816
 sta $6916
 rts
:
 cmp #1
 beq @done
 cmp #5
 bne @ground
 lda #$04
 sta $680E
 sta $690E
 sta $6810
 sta $6910
 lda #3
 sta gfx_dli_next+1
 lda #5
 sta gfx_dli_next+3
 rts
@ground:
 ; Three field shades reuse the existing font boundaries.
 lda water
 bne @done
 lda #$04
 sta $681B
 sta $691B
 lda #8
 sta gfx_dli_next+6
@done:
 rts
.endproc
.segment "GFX"

.segment "CODE"
.proc gfx_native_edge
 txa
 pha
 tya
 pha
 lda sprite_x
 and #63
 ldx back
 beq :+
 ora #64
:
 sta z_ptr
 ldx gfx_cached_kind
 lda gfx_edge_groups,x
 lsr
 sta z_ptr+1
 bcc :+
 lda z_ptr
 ora #128
 sta z_ptr
:
 lda z_ptr
 sta z_tmp
 lda z_ptr+1
 sta z_tmp2
 asl z_ptr
 rol z_ptr+1
 lda z_ptr
 clc
 adc z_tmp
 sta z_ptr
 lda z_ptr+1
 adc z_tmp2
 clc
 adc #$80
 sta z_ptr+1
 lda #$36
 sta $D500
 ldy #0
 lda (z_ptr),y
 pha
 iny
 lda (z_ptr),y
 sta z_rom
 iny
 lda (z_ptr),y
 sta z_rom+1
 pla
 sta $D500
 jsr @call
 pla
 tay
 pla
 tax
 rts
@call:
 jmp (z_rom)
.endproc
.segment "GFX"

.segment "CODE"
gfx_edge_groups: .byte 0,0,0,1,2,0,0,0,0,0,0,0,0,0,0,0,3,4
.proc gfx_copy_hoop_pm
 lda #$37
 sta $D500
 lda back
 asl
 asl
 clc
 adc z_iter
 asl
 tay
 lda $8000,y
 sta z_rom
 lda $8001,y
 sta z_rom+1
 ldx z_iter
 lda pm_id,x
 tax
 jmp (z_rom)
.endproc
.segment "GFX"

.segment "CODE"
.proc gfx_spring_board
 ldx z_hazard
 lda h_width,x
 asl
 clc
 adc h_width,x
 asl
 sta gfx_rect_w
 lda #16
 sta gfx_rect_h
 jsr gfx_mark_rect
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
 tay
 lda row_lo,y
 clc
 adc z_col
 sta z_cell
 lda row_hi,y
 adc #0
 ldx sprite_xhi
 beq :+
 sec
 sbc #1
:
 ora z_map+1
 sta z_cell+1
 lda z_cell
 clc
 adc #40
 sta z_bg
 lda z_cell+1
 adc #0
 sta z_bg+1
 lda #0
 ldx sprite_xhi
 beq :+
 lda z_col
 eor #255
 clc
 adc #1
:
 tay
 clc
 adc gfx_rect_w
 sta z_tmp2
@blank:
 lda (z_cell),y
 ora (z_bg),y
 bne @slow
 iny
 cpy z_tmp2
 bne @blank
 ldx z_hazard
 lda h_width,x
 sec
 sbc #2
 asl
 asl
 sta z_tmp
 lda sprite_x
 and #2
 ora z_tmp
 sta z_tmp
 lda sprite_y
 cmp #128
 bne :+
 inc z_tmp
:
 ldx z_tmp
 lda horse_board_lo,x
 sta z_rom
 lda horse_board_hi,x
 sta z_rom+1
 lda #HORSE_BOARD_BANK
 sta $D500
 ldx z_col
 jmp (z_rom)
@slow:
 jmp draw_stamp
.endproc
.segment "XL"
.include "horse-boards.inc"
