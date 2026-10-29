; Fixed RAM map. Main code/interrupts in RAM; helpers in ROM banks 0 and 31.
mode=$0600
act=$0601
round=$0602
lives=$0603
host_frames=$0604
presented=$0606
missed=$0608
render_busy=$060A
ready=$060B
request=$060C
front=$060D
back=$060E
phase=$060F
pal=$0610
pal_acc=$0611
input=$0612
fire_held=$0613
fire_prev=$0614
fire_latch=$0615
console_prev=$0616
select_latch=$0617
pause_latch=$0618
paused=$0619
loading=$061A
dli_index=$061B
active_font=$061C
fault=$061D
max_dirty=$061E
logic_steps=$061F
world=$0620
camera=$0622
height=$0624
velocity=$0626
jumping=$0627
jump_pixels=$0628
feet=$0629
anim_clock=$062A
scene_clock=$062C
mode_timer=$062E
timer_div=$062F
bonus=$0630
score=$0632
highscore=$0635
selected=$0638
need_stage=$0639
stage_hurt=$063A
current_ball=$063B
tramp_index=$063C
bounce_count=$063D
held_rope=$063E
flying=$063F
fly_dx=$0640
last_rope=$0641
previous_height=$0642
spring_hit=$0643
sound_fx=$0644
sound_age=$0645
music_tick=$0646
music_step=$0647
stage_end=$0648
sprite_x=$064A
sprite_xhi=$064B
sprite_y=$064C
sprite_pose=$064D
bg_count=$0650
free_glyph=$0653
dirty_count=$0656
pm_old_y=$0660
pm_old_h=$0668
pm_x=$0670
pm_y=$0674
pm_id=$0678
pm_color=$067C
pm_size=$0680
pm_hpos=$0684
finish_count=$0688
clear_count=$0689
last_present_host=$068A
max_interval=$068C
pm_missile_min=$068D
pm_missile_max=$068E
ball_lo=$0900
ball_hi=$0910
passed=$0920
; Dirty indices: four byte pages per buffer (16-bit offsets in separate arrays).
dirty_lo0=$0A00
dirty_hi0=$0B00
dirty_lo1=$0C00
dirty_hi1=$0D00
; Kernel private: $F0-$F7. Main code owns $80-$EF.
z_src=$80
z_dst=$82
z_tmp=$84
z_tmp2=$85
z_counter=$86
z_index=$87
z_value=$88
z_dx=$89
z_dy=$8A
z_num=$8B
z_pos=$8C
z_off=$8E
z_step=$90
z_joy=$91
z_fire=$92
z_kind=$93
z_base=$94
z_prev=$95
z_obj=$96
z_hazard=$97
z_flag=$98
z_s0=$99
z_s1=$9A
z_s2=$9B
z_map=$A0
z_fonts=$A2
z_dirtylo=$A3
z_dirtyhi=$A5
z_row=$A7
z_col=$A8
z_bank=$A9
z_rom=$AA
z_data=$AC
z_mask=$AE
z_bg=$B0
z_glyph=$B2
z_cell=$B4
z_band=$B6
z_left=$B7
z_cells=$B8
z_old=$B9
z_new=$BA
z_colorflag=$BB
z_pm=$BC
z_pmdata=$BE
z_pmnum=$C0
z_pmheight=$C1
z_shift=$C2
z_hud=$C3
z_savedx=$C5
z_iter=$C6
z_ropephase=$C7
z_ropeindex=$C8
z_target=$C9
z_ptr=$CA
z_tempword=$CC
z_counter2=$CE
z_body=$CF
z_prepared=$D0
z_irq=$F0
SCREEN0=$3800
SCREEN1=$3C00
BASEMAP=$3400
FONT0=$4000
FONT1=$4C00
PM0=$5800
PM1=$6000
HUD0=$6A00
HUD1=$6AA0
DIRECTORY_BANK=7
CHAR_STAND=0
CHAR_WALK1=1
CHAR_WALK2=2
CHAR_JUMP=3
CHAR_SWING1=4
CHAR_SWING2=5
CHAR_FALL=6
CHAR_ARMS=7
LION=8
HORSE=11
BALL=14
ROPE=18

band_font=$06A0
hud_cached_act=$06A3
hud_cached_mode=$06A5
hud_cached_pause=$06A7
ball_cached_phase=$06A9
demo=$06AB
frame_ballfont=$06AC
water=$06AE
tramp_clears=$06AF
water_pm_peak=$06B0
water_pm_overflow=$06B1
water_hits=$06B2
water_bags=$06B3
WATER_TRAMP=93
WATER_BAG=94
WATER_FINISH=95
; C64 gameplay baseline. Independent player records are 16 bytes each.
players=$06B4
player=$06B5
difficulty=$06B6
rank=$06B7
next_extra=$06B8
continue_ticks=$06B9
continue_secs=$06BB
menu_prev=$06BC
monkey_seen=$06BD
monkey_points=$06BE
spring_pending=$06BF
hazard_clock=$06C0
resume_pending=$06C2
resume_world=$06C3
resume_clock=$06C5
resume_hazard=$06C7
resume_ball=$06C9
resume_rope=$06CA
grace=$06CB
extra_awards=$06CC
bag_awards=$06CD
combo_awards=$06CE
skip_awards=$06CF
hud_menu_cache=$06D0
player_records=$0800
; Hidden-reward state, independent for each player's interrupted course.
; The old unused resume_balls alias occupied this otherwise unreferenced area.
hidden_records=$0840 ; Two 32-byte player records.
hidden_state=$08C0
hidden_life=$08C0 ; Original $220A: dormant / armed / spawned / collected.
hidden_doll=$08C1 ; Original $220B: dormant / released / collected.
hidden_failed=$08C2 ; Original $220C: missed money hoop or a lost life.
hidden_sides=$08C4 ; Original hoop +9 flags captured at takeoff.
hidden_pot_jump=$08C8
hidden_doll_y=$08CA ; Source 8.8 coordinates, little endian.
hidden_doll_v=$08CC
hidden_doll_frame=$08CE
hidden_pot=$08CF
hidden_doll_active=$08D0
hidden_clear_hi=$08D1
hidden_pot_live=$08D2 ; 0 ahead, 1 tracked, 2 retired/lost with the life.
hidden_art=$08F8
hidden_command=$08F9
hidden_index=$08FA
hidden_tmp=$08FB
hidden_delta=$08FC
bag_taken=$0930
pot_passed=$093C
hazard_xlo=$0940
hazard_xhi=$0950
pot_xlo=$0960
pot_xhi=$0964

; Executable-audited mechanics. Upper XL RAM; no display-buffer overlap.
hoop_type=$D910
monkey_type=$D920
monkey_jump=$D930
monkey_under=$D940
horse_y=$D950
rope_type=$D960
rope_phase=$D970
rope_wait=$D980
rope_adjust=$D990
rope_xlo=$D9A0
rope_xhi=$D9B0
support_xlo=$D9C0
support_xhi=$D9D0
support_active=$D9E0
rope_got=$D9F0
checkpoint_records=$DA00
horse_finish=$DC00
leap_events=$DC01
rescue_events=$DC02
mech_index=$DC03
rope_pose=$DC04
release_guard=$DC05
mech_pm_overflow=$DC06
checkpoint_restores=$DC07
mech_tmp=$DC08
mech_tmp2=$DC09
mech_timer_limit=$DC0A
mech_pm_peak=$DC0B

demo_cursor=$DC10
demo_remaining=$DC12
demo_value=$DC13

first_hazard=$DC14
bag_screen_x=$DC15
pm_copy_limit=$DC16

; Bold Arcade rendering state, separate from audited simulation state.
gfx_hero_x=$DC20
gfx_hero_y=$DC21
gfx_hero_pose=$DC22
gfx_hero_valid=$DC23
gfx_sprite_alt=$DC24
gfx_pm_colours=$DC25
gfx_ball_flags=$D2
gfx_bg=$DC40
gfx_pf0=$DC49
gfx_pf1=$DC52
gfx_pf2=$DC5B
gfx_pf3=$DC64
gfx_stripe=$DC6D
gfx_opaque=$DC28
gfx_range_start=$DC90
gfx_range_end=$DC93
gfx_reserve=$DC96
gfx_mask_count=$DC99
gfx_pixels=$D4
gfx_cell_index=$D6
gfx_stamp_lo=$D7
gfx_stamp_hi=$D8
gfx_stamp_row=$D9

gfx_cached_kind=$DA
gfx_hero_base=$DB

gfx_overlay_height=$DC2A
gfx_overlay_y=$DC2B

gfx_rect_count=$DCC0
gfx_rect_w=$DC2C
gfx_rect_h=$DC2D
gfx_rect_col=$DC2E
gfx_rect_index=$DC2F
gfx_rect_limit=$DC30
z_rect=$DC

gfx_alt_ready=$DCC2
gfx_alt_base=$DCD0

gfx_target_player=$DC31
gfx_pm_limit=$DC32

gfx_dense_w=$DE
gfx_dense_h=$DF
gfx_dense_row=$E0
gfx_dense_clip=$E1

gfx_logic_prepared=$DCC4

gfx_dli_next=$DC76
gfx_rect_uniform=$DC33

; Arcade Act 1: horizontal coordinates are 3/4 arcade pixels, 16.8 fixed point.
lion_frac=$D900
lion_phase=$D901
lion_direction=$D902
lion_gap=$D903
lion_wave=$D905
lion_bias=$D906
lion_lastgap=$D907
lion_ringfrac=$D908
lion_active=$D90C
lion_potfrac=$D914
lion_potlo=$D91D
lion_pothi=$D926
lion_potpaid=$D92F
lion_potcount=$D938
lion_velocity_lo=$D939
lion_velocity_hi=$D93A
lion_relative_lo=$D93B
lion_relative_hi=$D93C
lion_goal=$D93D
lion_buffer=$D93E
lion_buffer_direction=$D93F

; Arcade controls and object schedules (not display memory).
f_direction=$0970
f_fraction=$0971
f_phase=$0972
f_counter=$0973
f_sequence=$0974
f_rank=$0976
f_idle=$0977
f_scroll=$0978
f_velocity=$097A
f_previous=$097C
f_spawned=$097E
f_moved=$097F
f_object_fraction=$D950
f_active=$D960
f_object_speed=$D970
f_serial=$D980
f_last_serial=$0980
f_ball_count=$0981
f_monkey_skip=$0982
f_clear_hold=$0983

f_tramp_arc=$0984

f_horse_v=$0985
f_horse_h=$0987

f_rope_valid=$098C
f_rope_x=$0990
f_rope_y=$0994

; Arcade horse stream. Values overlap only mutually exclusive apparatus state.
h_width=$D960
h_opening=$0989
h_slot=$098A
h_first_spawn=$0998
h_speed=$098B
; Arcade trapeze: 32 positions; only five nearby pendulums are simulated.
r_pivot_lo=$0F00
r_pivot_hi=$0F20
r_length=$0F40
r_amplitude=$0F60
r_phase=$0F80
r_fraction=$0FA0
r_cycle=$0FC0
r_age=$0FE0
r_dxlo=$D900
r_dxhi=$D920
r_dylo=$D940
r_dyhi=$D960
r_angle=$D980
r_active=$D9A0
r_got=$D9C0
r_center=$098D
r_first=$098E
r_limit=$098F
r_pump=$0989
r_depth=$0985
r_vertical=$0987
r_old_depth=$098A
r_start_index=$098B
; Legacy operand base only: apparatus_record_addresses redirects all readers
; to ROM before use. $0E40-$0EFF now holds the resident top-clipping helpers.
r_record=$0E80
r_hist_xfrac=$0910
r_hist_xlo=$0914
r_hist_xhi=$0918
r_depth_page=$0918 ; Signed extension of r_depth; X history never used this byte.
r_hist_yfrac=$091C
r_hist_yhi=$0920
; Renderer workspace, separate from simulation and interrupt state.
r_draw_index=$09A0
r_draw_sign=$09A1
r_draw_left=$09A2
r_draw_top=$09A3
r_draw_bottom=$09A4
r_draw_min=$09A5
r_draw_max=$09A6
r_draw_count=$09A7
r_draw_offset=$09A8
r_draw_col=$09A9
r_draw_row=$09AA
r_draw_id=$09AB
r_draw_mask=$09AD
r_draw_x=$09AE
r_goal_rope=$099A
r_goal_ready=$099B

r_atlas=$09B0
r_atlas_bank=$09B2

r_draw_basecol=$09B3
r_draw_mincol=$09B4
r_draw_maxcol=$09B5
r_draw_endmask=$09B6
r_draw_bottomrow=$09B7
r_draw_lastline=$09B8
r_draw_cachepage=$09B9

r_draw_partial=$09BA
r_draw_full=$09BB

r_blend_enabled=$09BC

r_spring_code=$09BD

; Act 3 state shares apparatus-only RAM; no interrupts use it.
t_bag_taken=$0900 ; 25 site flags; full block is saved per player on a loss.
t_active=$D900
t_timer=$D920
t_anim=$D940
t_remaining=$D960
t_proj_kind=$0F00
t_proj_owner=$0F10
t_proj_phase=$0F20
t_proj_xlo=$0F30
t_proj_xhi=$0F40
t_proj_y=$0F50
t_proj_frac=$0F60
t_period=$099C
t_actor=$099D
t_slot=$099E
t_kind=$099F
t_draw=$09C0
t_sequence=$09C1
t_projectiles=$DC07

t_first=$09C3
t_end=$09C4
t_pm_count=$09C5
t_pm_owner=$0F80
t_pm_slot=$0F90
t_pm_bottom=$0FA0

; Candidate completion state. Water shares the act-specific $D900 page.
w_active=$D900
w_xlo=$D910
w_xhi=$D920
w_xfrac=$D930
w_y=$D940
w_vel_lo=$D950
w_vel_hi=$D960
w_phase=$D970
w_limit=$D980
w_bounces=$D990
w_special=$D9A0
w_cursor=$09D0
w_index=$09D1
w_schedule=$09D2
w_pair=$09D4
w_kind=$09D5
w_last_x=$09D6
w_spawned=$09D8
w_pose=$09D9
gfx_field=$06E3
clear_elapsed=$06E4
clear_reward=$06E5
clear_bird=$06E6
clear_prize=$06E7
finish_pony=$06E8
reward_flags=$06E9
secret_jumps=$06EA
reward_chain=$06EB

r_freeze=$09EF

secret_visible=$06EC
secret_world=$06ED
secret_height=$06EF
secret_age=$09E0
secret_paid=$09E1

money_chain=$06F0


; Isolated show progression and optional arcade menu state.
show_cycle=$06F1
death_drop=$06F2
resume_steps=$06F3
continue_deadline=$06F4
ball_merge_limit=$06F6
player_cycles=$0820
player_started=$0822

; Persistent failure cause, independent of the reused apparatus pages.
tramp_death_reason=$06F7
tramp_death_age=$06F8
; Presentation scratch only; never read by interrupts or gameplay.
detail_sign_end=$09F0
detail_sign_world=$09F2
detail_sign_index=$09F4
detail_sign_col=$09F5
detail_sign_glyph=$09F6
detail_sign_cell=$09F7
detail_bird_x=$09F8
detail_bag_offset=$09F9

; A sign's four glyphs persist in its buffer until a different board/pool
; uses them. The other screen never writes these private codes.
sign_cache_label=$06F9
sign_cache_base=$06FB
sign_cache_font=$06FD
sign_copy=$06FF
detail_fast_try=$09FA
clear_text_cache=$09FB ; Private top-font base, one per display buffer.
detail_prize_first=$09FD
detail_prize_last=$09FE

; Act 6 simulation uses arcade pixels; only the drawing coordinates are scaled.
r_raw_pivot_lo=$0200
r_raw_pivot_hi=$0220
r_raw_dxlo=$0240
r_raw_dxhi=$0260
r_arc_x=$0280
r_arc_frac=$0282
r_arc_goal=$0283
r_catch_block=$0285
r_launch_wait=$0286
r_hist_index=$0287
r_next_vx=$0288
r_next_vy=$028A
r_drum_xlo=$0290
r_drum_xhi=$0293
r_drum_first=$0296
r_temp_x=$0298
r_temp_y=$029A

r_arc_joy=$029C

r_drum_frac=$029D
r_goal_screen=$02A0
r_goal_frac=$02A2
r_prev_x=$02A3

; Page two is free after the cartridge disables the Atari OS.
r_logic_host=$02B0
r_clock_fraction=$02B2
r_elapsed_fields=$02B5

; Horse KONAMI-1 state, one parallel array per original descriptor field.
h_state=$0F00
h_delay=$0F10
h_build=$0F20
h_src_height=$0F30
h_draw_scroll=$0F40
h_screen=$0F50
h_deck=$0F60
h_goal_phase=$0999
h_goal_build=$099A
h_goal_scroll=$099B
h_goal_x=$099C
h_contact=$099D
h_source_low=$099E
h_body=$099F

; Dolphin bonus source-space state (act-specific fidelity checkpoint bytes).
w_hero_x=$0980
w_hero_y=$0981
w_hero_v=$0982
w_hero_phase=$0984
w_hero_limit=$0985
w_hero_state=$0987
w_prizes=$0988
w_raw_x=$D930

; Tightrope source-space state; scalar bytes participate in fidelity checkpoints.
k_x=$0980
k_subx=$0981
k_left_clock=$0982
k_frame=$0983
k_state=$0985
k_first=$0986
k_skip=$0987
k_brown=$0988
k_pink=$0989
k_reward_slot=$098A
k_awards=$098B
k_mx=$0F20
k_frac=$0F28
k_my=$0F30
k_state_m=$0F38
k_phase=$0F40
k_under=$0F48
k_wait=$0F50

k_idle=$098C
k_fire_pending=$098E

; Rolling Balls source-space state (exclusive with other acts).
b_x=$0940
b_align=$0950
b_hero_x=$0982
b_first=$0985
b_idle_spawn=$0984


