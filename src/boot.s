.setcpu "6502"
.segment "BOOT"
; Repeated at the same address in every bank: safe reset from any asset bank.
boot:
 sei
 cld
 lda #$20
 sta $D500
 jmp loader
loader:
 lda #0
 sta $D40E
 sta $D400
 sta $D20E
 sta $80
 sta $82
 lda #$80
 sta $81
 lda #$10
 sta $83
 ldx #32
 jsr copy
 lda #$A0
 sta $81
 lda #$70
 sta $83
 ldx #16
 jsr copy
 lda #$70
 sta $81
 lda #$30
 sta $83
 ldx #4
 jsr copy
 ; Stock 64K XL: expose RAM under OS and load its resident audio/menu code.
 lda #$FE
 sta $D301
 lda #$3E
 sta $D500
 lda #$80
 sta $81
 lda #$C0
 sta $83
 ldx #16
 jsr copy
 lda #$8F
 sta $81
 lda #$D8
 sta $83
 ldx #1
 jsr copy
 lda #$E0
 sta $83
 ldx #16
 jsr copy
 lda #$F0
 sta $83
 ldx #13
 jsr copy
 lda #$3A
 sta $D500
 lda #$9E
 sta $81
 lda #4
 sta $83
 ldx #2
 jsr copy
 ldx #191
@topclip:
 lda $A340,x
 sta $0E40,x
 dex
 cpx #255
 bne @topclip
 lda #$3E
 sta $D500
 jmp $1000
copy:
 ldy #0
@byte:
 lda ($80),y
 sta ($82),y
 iny
 bne @byte
 inc $81
 inc $83
 dex
 bne @byte
 rts
init:
 rts
.res $FA-(*-boot),$FF
.word boot
.byte 0,4
.word init
