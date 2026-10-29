; Water schedules recovered from F61C. Coordinates use the port 3/4 X scale.
w_pedestal_lo: .byte 44,110,176,236,46,112,172,238,48,108,174,240,44,110,176,236,46,112,172,238,48,108,174,240,44
w_pedestal_hi: .byte 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6
w_schedule_0: .byte 0,3,3,130,130,130,2,2,2,1,1,2,130,130,130,2,2,2,2,1,0,2,1,0
w_schedule_1: .byte 2,2,2,2,2,2,1,1,130,1,2,1,1,2,1,1,2,1,2,130,0,2,130,0
w_schedule_2: .byte 1,2,1,2,1,2,130,130,130,1,1,3,130,130,130,1,1,3,1,130,0,1,130,0
w_schedule_3: .byte 2,3,2,2,2,3,130,130,130,1,1,1,1,1,1,1,1,1,130,130,0,130,130,0
w_schedule_4: .byte 1,2,1,130,130,130,1,1,2,1,1,2,1,1,2,1,2,1,3,3,0,3,3,0
w_schedule_5: .byte 130,130,3,130,3,130,130,3,130,1,3,1,2,1,2,1,2,1,0,3,3,130,130,0
w_schedule_lo: .byte <w_schedule_0,<w_schedule_1,<w_schedule_2,<w_schedule_3,<w_schedule_4,<w_schedule_5
w_schedule_hi: .byte >w_schedule_0,>w_schedule_1,>w_schedule_2,>w_schedule_3,>w_schedule_4,>w_schedule_5
