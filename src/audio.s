; 800XL resident sound engine. Two updates/refresh, no runtime synthesis.
; IRQ-private zero page only. Streams hold duration, mask, changed registers.
; A duration-zero packet is an explicit SIC link or a one-shot terminator.
a_ptrlo=$D800
a_ptrhi=$D802
a_bank=$D804
a_delay=$D806
a_music=$D810
a_effect=$D820
a_mode=$D830
a_act=$D831
a_hurry=$D832
a_cmd=$D833
a_ticks=$D834
a_effect_cmd=$D836
a_requests=$D837
za_ptr=$F2
za_mask=$F4
za_regs=$F6
za_stream=$F8
za_limit=$F9

.proc audio_init
 lda #0
 ldx #0
@clear:
 sta $D800,x
 inx
 cpx #$40
 bne @clear
 lda #255
 sta a_mode
 rts
.endproc

; A=catalogue index (0..10 music, 11..28 effects), X=stream.
.proc audio_start
 ldy pal
 beq :+
 clc
 adc #29
:
 tay
 lda audio_bank,y
 sta a_bank,x
 lda audio_lo,y
 sta a_ptrlo,x
 lda audio_hi,y
 sta a_ptrhi,x
 lda #1
 sta a_delay,x
 rts
.endproc

.proc audio_control
 lda paused
 jne @done
 lda mode
 cmp a_mode
 bne @change
 lda act
 cmp a_act
 beq @event
@change:
 lda act
 sta a_act
 lda mode
 sta a_mode
 lda #0
 sta a_hurry
 sta a_bank+1
 sta sound_fx
 lda mode
 beq @selection
 cmp #7
 beq @selection
 cmp #6
 beq @selection
 cmp #3
 beq @death
 cmp #5
 beq @death
 cmp #4
 beq @clear
 cmp #8
 beq @clear
 ldx act
 lda stage_music,x
 sta a_cmd
 ldx #0
 jsr audio_start
 lda mode
 cmp #1
 jne @done
 lda #$4C
 jne @effect
@selection:
 lda #10
 bne @music
@death:
 lda #4
 ldx #0
 jsr audio_start
 lda #$4F
 jne @effect
@clear:
 lda #8
 sta f_clear_hold
 lda #9
@music:
 sta a_cmd
 ldx #0
 jsr audio_start
 jmp @done
@event:
 lda f_clear_hold
 beq :+
 dec f_clear_hold
 bne :+
 lda #1
 sta pcm_pending
:
 lda mode
 cmp #2
 bne @pending
 lda a_hurry
 bne @pending
 lda bonus+1
 cmp #$10
 bcs @pending
 inc a_hurry
 ldx act
 lda hurry_music,x
 sta a_cmd
 ldx #0
 jsr audio_start
@pending:
 lda audio_request
 beq :+
 ldy #0
 sty audio_request
 jmp @effect
:
 lda sound_fx
 jeq @done
 ldy #0
 sty sound_fx
 cmp #1
 beq @jump
 cmp #2
 jeq @done
 cmp #3
 jeq @done
 cmp #4
 beq @extra
 lda a_bank+1
 beq :+
 lda a_effect_cmd
 cmp #$50
 jeq @done
:
 lda #$49
 jne @effect
@jump:
 ; A reward jingle takes priority over subsequent jump sounds.
 lda a_bank+1
 beq :+
 lda a_effect_cmd
 cmp #$49
 jeq @done
 cmp #$50
 jeq @done
:
 ldx act
 lda jump_effect,x
 jne @effect
@extra:
 lda #$50
@effect:
 sta a_effect_cmd
 inc a_requests
 sec
 sbc #$36
 ldx #1
 jsr audio_start
@done:
 rts
.endproc
stage_music: .byte 0,1,2,1,0,3
hurry_music: .byte 5,6,7,6,5,8
jump_effect: .byte $47,$44,$45,$44,$4B,$44

.proc audio_tick
 inc a_ticks
 bne :+
 inc a_ticks+1
:
 lda paused
 bne @quiet
 lda $D500
 pha
 ldx #0
 jsr audio_stream
 ldx #1
 jsr audio_stream
 pla
 sta $D500
 lda a_music+0
 sta $D200
 lda a_music+1
 sta $D201
 lda a_music+2
 sta $D202
 lda a_music+3
 sta $D203
 lda a_bank+1
 beq @music
 lda a_effect+0
 sta $D204
 lda a_effect+1
 sta $D205
 lda a_effect+2
 sta $D206
 lda a_effect+3
 sta $D207
 lda a_effect+4
 sta $D208
 rts
@music:
 lda a_music+4
 sta $D204
 lda a_music+5
 sta $D205
 lda a_music+6
 sta $D206
 lda a_music+7
 sta $D207
 lda a_music+8
 sta $D208
 rts
@quiet:
 lda #0
 sta $D201
 sta $D203
 sta $D205
 sta $D207
 rts
.endproc

.proc audio_stream
 lda a_bank,x
 jeq @done
 dec a_delay,x
 jne @done
 stx za_stream
 sta $D500
 lda a_ptrlo,x
 sta za_ptr
 lda a_ptrhi,x
 sta za_ptr+1
 ldy #0
 lda (za_ptr),y
 bne @packet
 ; Link packets cannot chain: packer guarantees a data packet at destination.
 iny
 lda (za_ptr),y
 sta a_bank,x
 jeq @done
 pha
 iny
 lda (za_ptr),y
 pha
 iny
 lda (za_ptr),y
 sta za_ptr+1
 pla
 sta za_ptr
 pla
 sta $D500
 ldy #0
 lda (za_ptr),y
@packet:
 cmp #$80
 and #$7F
 sta a_delay,x
 lda #0
 rol
 sta za_mask+1
 ldy #1
 lda (za_ptr),y
 sta za_mask
 iny
 cpx #0
 bne @effect
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+0
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+1
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+2
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+3
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+4
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+5
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+6
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+7
:
 lsr za_mask+1
 bcc :+
 lda (za_ptr),y
 iny
 sta a_music+8
:
 jmp @advance
@effect:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_effect+0
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_effect+1
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_effect+2
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_effect+3
:
 lsr za_mask
 bcc :+
 lda (za_ptr),y
 iny
 sta a_effect+4
:
@advance:
 tya
 clc
 adc za_ptr
 ldx za_stream
 sta a_ptrlo,x
 lda za_ptr+1
 adc #0
 sta a_ptrhi,x
@done:
 rts
.endproc
.include "audio_directory.inc"
