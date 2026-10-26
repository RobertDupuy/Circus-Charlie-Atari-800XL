; Retained reference player and payload test. Normal gameplay/celebrations
; never queue pcm_pending: this foreground player would freeze animation.
; Intermission-only 4-bit DAC playback. Foreground pauses; ANTIC keeps displaying
; the completed playfield. Normal DMA/DLIs retain its colours and fonts.
; No timer IRQ or PCM
; cost is added to gameplay. PAL/NTSC line clocks differ by less than one percent.
pcm_pending=$06DB
pcm_active=$06DC
pcm_block=$06DD
pcm_count=$06DE
pcm_byte=$06DF
pcm_clock=$06E0
.proc pcm_play
 lda pcm_pending
 jeq @return
 lda #0
 sta pcm_pending
 sta pcm_block
 sta $D201
 sta $D203
 sta $D205
 sta $D208
 lda #131
 ldx pal
 beq :+
 lda #156
:
 sta pcm_sample_wrap+1
 lda host_frames
 sta pcm_clock
 lda #1
 sta pcm_active
@vblank:
 lda host_frames
 cmp pcm_clock
 beq @vblank
 lda $D500
 pha
 lda $D40B
 sta pcm_clock
@block:
 ldx pcm_block
 lda pcm_bank,x
 sta $D500
 lda pcm_lo,x
 sta z_src
 lda pcm_hi,x
 sta z_src+1
 lda pcm_size,x
 sta pcm_count
 ldy #0
@byte:
 lda (z_src),y
 sta pcm_byte
 lsr
 lsr
 lsr
 lsr
 ora #$10
 tax
 jsr pcm_sample
 lda pcm_byte
 and #15
 ora #$10
 tax
 jsr pcm_sample
 iny
 cpy pcm_count
 bne @byte
 inc pcm_block
 lda pcm_block
 cmp #PCM_BLOCKS
 bcc @block
 pla
 sta $D500
 lda #0
 sta $D207
 sta pcm_active
 ; The frozen display already owns GRACTL/DMACTL; retain its current band.
 lda #0
 ; Discard the clear fanfare stream so it does not resume after applause.
 sta a_bank
 sta a_bank+1
 ldx #8
@silence:
 sta a_music,x
 dex
 bpl @silence
@return:
 rts
.endproc

.proc pcm_vbi
 ; Keep the completed scene and congratulations visible during applause.
 ; No simulation or rendering runs while the sample stream is playing.
 jmp vbi::display_frozen
.endproc

.segment "MECHANICS"
.proc pcm_sample
 ; Keep the original two-scanline timeline even when a DLI spans a sample
 ; boundary. Catch up immediately instead of accumulating playback drift.
@wait:
 lda $D40B
 cmp pcm_clock
 beq @wait
 inc pcm_clock
 lda pcm_clock
::pcm_sample_wrap:
 cmp #131
 bcc :+
 lda #0
 sta pcm_clock
:
 stx $D207
 rts
.endproc
.segment "XL"
