; Arcade title: resident lettering, procedural particles and two-player choice.
; The compressed static picture occupies only unused tightrope font slots.
title_clock=$D900
title_colour=$D901
title_gold=$D902
title_red=$D903
title_x=$0F00
title_y=$0F20
title_wait=$0F40
.segment "CODE"
.proc title_init
 jsr setup_lists
 ; Blank footer scans avoid carrying a field palette into hires text.
 lda #$70
 sta $681E
 sta $681F
 sta $691E
 sta $691F
 lda #0
 sta $6820
 sta $6821
 sta $6920
 sta $6921
 lda #$22
 sta $D500
 lda #$10
 sta z_src
 lda #$80
 sta z_src+1
 lda #0
 sta z_dst
 lda #$40
 sta z_dst+1
 jsr title_unpack
 lda #0
 sta z_src
 sta z_dst
 lda #$4C
 sta z_src+1
 lda #$34
 sta z_dst+1
 ldx #4
 jsr copy_pages
 lda #$40
 sta z_src+1
 lda #$4C
 sta z_dst+1
 ldx #12
 jsr copy_pages
 lda #32
 ldx #0
@hud:
 sta HUD0,x
 sta HUD1,x
 inx
 cpx #160
 bne @hud
 lda #0
 sta title_clock
 ldx #63
@pm:
 sta $0E00,x
 dex
 bpl @pm
 ldx #31
@star:
 lda #80
 sta title_x,x
 sta title_y,x
 txa
 asl
 sta title_wait,x
 dex
 bpl @star
 lda $FD2E
 sta title_gold
 lda $FD46
 sta title_red
 rts
.endproc
.segment "TITLE"
.proc title_unpack
@packet:
 jsr title_byte
 beq @done
 bmi @run
 sta z_counter
@literal:
 jsr title_byte
 jsr title_store
 dec z_counter
 bne @literal
 beq @packet
@run:
 and #127
 sta z_counter
 jsr title_byte
 sta z_value
@repeat:
 lda z_value
 jsr title_store
 dec z_counter
 bne @repeat
 beq @packet
@done:
 rts
.endproc
.proc title_store
 ldy #0
 sta (z_dst),y
 inc z_dst
 bne :+
 inc z_dst+1
:
 rts
.endproc
.proc title_byte
 ldy #0
 lda (z_src),y
 pha
 inc z_src
 bne @done
 inc z_src+1
 lda z_src+1
 cmp #$84
 bne :+
 lda #$C0
 sta z_src
 lda #$85
 sta z_src+1
:
 lda z_src+1
 cmp #$88
 bne @map_tail
 lda #$78
 sta z_src
 jmp @done
@map_tail:
 cmp #$8C
 bne @done
 lda #$70
 sta z_src
 lda #$8F
 sta z_src+1
@done:
 pla
 rts
.endproc
.proc title_dli
 txa
 pha
 tya
 pha
 cld
 ldx dli_index
 lda $DC80,x
 sta $D409
 ; Publish every field colour before the wait. The first tent-pole pixel
 ; can otherwise use the HUD palette for one scanline at some IRQ phases.
 lda title_gold
 sta $D016
 lda title_colour
 sta $D017
 lda #0
 sta $D01A
 lda title_red
 cpx #8
 bcc :+
 lda #0
:
 tay
 sty $D018
 sta $D40A
 inc dli_index
 cpx #1
 bne :+
 jsr audio_tick
:
 pla
 tay
 pla
 tax
 pla
 rti
.endproc
.segment "CODE"
.proc title_render
 ldx back
 lda screen_high,x
 sta z_map+1
 sta z_dst+1
 lda #0
 sta z_map
 sta z_dst
 sta z_src
 lda #$34
 sta z_src+1
 ldx #4
 jsr copy_pages
 inc title_clock
 lda title_clock
 lsr
 lsr
 lsr
 and #7
 tax
 lda title_colours,x
 tay
 lda $FD00,y
 sta title_colour
 ldx #31
@star:
 lda title_wait,x
 beq @move
 dec title_wait,x
 jmp @next
@move:
 lda title_x,x
 clc
 adc title_dx,x
 sta title_x,x
 cmp #160
 bcs @restart
 lda title_y,x
 clc
 adc title_dy,x
 sta title_y,x
 cmp #176
 bcs @restart
 stx z_index
 lsr
 lsr
 lsr
 tay
 lda row_lo,y
 sta z_pos
 lda row_hi,y
 ora #$34
 sta z_pos+1
 lda title_x,x
 lsr
 lsr
 tay
 lda (z_pos),y
 bne @next
 lda z_pos+1
 and #3
 ora z_map+1
 sta z_pos+1
 lda title_y,x
 and #6
 sta z_tmp
 lda title_x,x
 and #2
 lsr
 ora z_tmp
 clc
 adc #120
 sta z_tmp
 txa
 and #7
 bne @small
 lda title_clock
 and #3
 cmp #3
 bne :+
 lda #1
:
 clc
 adc #117
 sta z_tmp
@small:
 lda z_tmp
 sta (z_pos),y
 jmp @next
@restart:
 lda #80
 sta title_x,x
 sta title_y,x
 txa
 and #31
 clc
 adc #32
 sta title_wait,x
@next:
 dex
 bmi :+
 jmp @star
:
 ; A cycling sparkle marks the selected player count.
 lda z_map+1
 clc
 adc #2
 sta z_pos+1
 lda #<680
 sta z_pos
 ldy #2
 lda players
 cmp #2
 bne :+
 ldy #20
:
 lda #118
 sta (z_pos),y
 rts
.endproc
.segment "XL"
title_dx: .byte 0,1,1,2,2,3,3,4,4,3,3,2,2,1,1,0,0,255,255,254,254,253,253,252,252,253,253,254,254,255,255,0
title_dy: .byte 252,252,253,253,254,254,255,255,0,1,1,2,2,3,3,4,4,4,3,3,2,2,1,1,0,255,255,254,254,253,253,252
title_colours: .byte $0E,$2E,$4E,$6E,$8E,$AE,$CE,$EE
