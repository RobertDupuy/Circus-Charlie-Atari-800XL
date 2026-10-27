; The old foreground applause player stopped the entire animation.
; Victory now uses the interrupt-driven music stream. Retain a bounded no-op
; at the foreground entry, and free the unused sample bytes for Act 3 art.
pcm_pending=$06DB
pcm_active=$06DC
.proc pcm_play
 lda #0
 sta pcm_pending
 sta pcm_active
 rts
.endproc
.proc pcm_vbi
 jmp vbi::display_frozen
.endproc
