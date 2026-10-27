; Fixed display lists and small lookup tables. All large graphics live in ROM.
dl_template:
 .byte $70,$70,$42,<HUD0,>HUD0,$82,$44,<SCREEN0,>SCREEN0
 .repeat 21,I
  .if I=1 .or I=5 .or I=6 .or I=7 .or I=11 .or I=15 .or I=18 .or I=20
   .byte $84
  .else
   .byte $04
  .endif
 .endrepeat
 .byte $42,<(HUD0+80),>(HUD0+80),$02,$41,$00,$68
dl_template_end:
dl_high: .byte $68,$69
screen_high: .byte $38,$3C
font_high: .byte $40,$4C
pm_high: .byte $58,$60
hud_lo: .byte <HUD0,<HUD1
hud_hi: .byte >HUD0,>HUD1
row_lo:
 .repeat 22,I
 .byte <(I*40)
 .endrepeat
row_hi:
 .repeat 22,I
 .byte >(I*40)
 .endrepeat
row_band:
 .repeat 22,I
 .if I<8
 .byte 0
 .elseif I<17
 .byte 1
 .else
 .byte 2
 .endif
 .endrepeat
crowd_offset_lo:
 .repeat 40,I
 .byte <($9000+I*160)
 .endrepeat
crowd_offset_hi:
 .repeat 40,I
 .byte >($9000+I*160)
 .endrepeat
pm_pattern_lo:
 .repeat 21,I
 .byte <($7400+I*96)
 .endrepeat
pm_pattern_hi:
 .repeat 21,I
 .byte >($7400+I*96)
 .endrepeat
missile_masks: .byte $03,$0C,$30,$C0
initial_ball_lo:
 .repeat 16,I
 .byte <(60+I*48)
 .endrepeat
initial_ball_hi:
 .repeat 16,I
 .byte >(60+I*48)
 .endrepeat
hazard_lo:
 .repeat 16,I
 .byte <(150+I*128)
 .endrepeat
hazard_hi:
 .repeat 16,I
 .byte >(150+I*128)
 .endrepeat
pot_lo: .byte <214,<470,<726,<982
pot_hi: .byte >214,>470,>726,>982
tramp_lo:
 .repeat 16,I
 .byte <(52+I*64)
 .endrepeat
tramp_hi:
 .repeat 16,I
 .byte >(52+I*64)
 .endrepeat
rope_lo:
 .repeat 9,I
 .byte <(80+I*96)
 .endrepeat
rope_hi:
 .repeat 9,I
 .byte >(80+I*96)
 .endrepeat
hurdle_y: .byte 122,90,110,82
.if 0 ; Build-time HUD templates; these strings need no duplicate RAM copy.
hud_label: .asciiz "PTS 000000   TOP 000000  P1   LIVES 0"
.endif
footer_controls: .asciiz "STICK: MOVE  FIRE: JUMP  OPTION: PAUSE"
.if 0
act0: .asciiz "1 FIRE HOOPS      BONUS"
act1: .asciiz "2 TIGHTROPE       BONUS"
act2: .asciiz "3 TRAMPOLINES     BONUS"
act3: .asciiz "4 ROLLING BALLS   BONUS"
act4: .asciiz "5 HORSE RIDING    BONUS"
act5: .asciiz "6 TRAPEZE         BONUS"
act6: .asciiz "3 WATER DOLPHINS  BONUS"
.endif
mode_messages: .word title_text,intro_text,play_text,death_text,clear_text,over_text,continue_text,choose_text,complete_text
title_text: .asciiz "CIRCUS CHARLIE  FIRE: START SELECT: 1/2P "
intro_text: .asciiz "GET READY!                              "
play_text: .byte 0
death_text: .asciiz "OUCH! TRY AGAIN                         "
clear_text: .asciiz "GREAT!             FAROUT!             "
over_text: .asciiz "GAME OVER                             "
continue_text: .asciiz "CONTINUE 5 FIRE:YES SELECT:NO           "
pause_text: .asciiz "PAUSED - OPTION TO CONTINUE             "
act_messages: .word help0,help1,help2,help3,help4,help5,help6
help0: .asciiz "JUMP THROUGH HOOPS AND OVER FIRE POTS"
help1: .asciiz "JUMP THE MONKEYS - PURPLE ONES LEAP!"
help2: .asciiz "HIGH: MARKED BAGS / 4TH: BIG TOP!"
help3: .asciiz "JUMP TO THE NEXT BALL BEFORE THEY TOUCH"
help4: .asciiz "L/R: PACE - FIRE: JUMP, ALSO AT FINISH"
help5: .asciiz "L/R: SWING - FIRE: RELEASE AND CATCH"
help6: .asciiz "DODGE DOLPHINS - THREE BOUNCES MAX"

glyph_lo:
 .repeat 128,I
 .byte <(I*8)
 .endrepeat
glyph_hi:
 .repeat 128,I
 .byte >(I*8)
 .endrepeat

ball_glyph_base: .byte 2,26,50,74

title_controls: .asciiz "FIRE/START:PLAY SEL:1/2P OPT:DEMO      "
demo_controls: .asciiz "DEMO - FIRE RETURNS TO TITLE            "

hud_template_lo:
 .repeat 7,I
 .byte <($A800+I*160)
 .endrepeat
hud_template_hi:
 .repeat 7,I
 .byte >($A800+I*160)
 .endrepeat

ball_font_high: .byte $48,$54,$6C,$70

choose_text: .byte 0
complete_text: .byte 0
