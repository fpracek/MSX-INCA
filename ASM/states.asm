;=======================================================================
; states.asm - title, ready, play, death, bonus count, game over
;=======================================================================

MSG_ROW     equ 10

sprites_off:
    ld a,0D0h
    ld (sat_buf),a
    ret

;-----------------------------------------------------------------------
; Messages punch a hole exactly their own size: the font group is white on
; black, so the characters bring their own black box with them and the
; wall around them is left alone.
; DE = 0 terminated string, A = column
msg_show:
    ld (msg_col),a
    push de
    ld c,0
.len:
    ld a,(de)
    or a
    jr z,.gotlen
    inc c
    inc de
    jr .len
.gotlen:
    ld a,c
    ld (msg_len),a
    pop de
    ld a,(msg_col)
    ld l,a
    ld h,0
    ld bc,VR_NAME+MSG_ROW*PF_W
    add hl,bc
    jp print

; put back just those characters, straight from the map
msg_hide:
    ld a,(msg_len)
    or a
    ret z
    ld c,a
    ld b,0
    push bc                     ; length
    ld a,(msg_col)
    ld c,a
    ld b,MSG_ROW
    call map_addr
    ex de,hl                    ; DE = map source
    ld a,(msg_col)
    ld l,a
    ld h,0
    push de
    ld de,VR_NAME+MSG_ROW*PF_W
    add hl,de                   ; HL = VRAM destination
    pop de
    pop bc
    call ldirvm
    xor a
    ld (msg_len),a
    ret

;---------------------------------------------------------------- title
title_enter:
    call screen_off
    ld hl,VR_NAME
    ld bc,768
    ld a,CH_BLANK
    call filvrm

    ; two decorative bands of masonry
    ld a,2
    call wall_band
    ld a,19
    call wall_band

    ld hl,VR_NAME+6*PF_W+9
    ld de,txt_title
    call print
    ld hl,VR_NAME+9*PF_W+3
    ld de,txt_help1
    call print
    ld hl,VR_NAME+11*PF_W+6
    ld de,txt_help2
    call print
    ld hl,VR_NAME+13*PF_W+5
    ld de,txt_help3
    call print
    ld hl,VR_NAME+16*PF_W+10
    ld de,txt_hi
    call print
    ld hl,VR_NAME+16*PF_W+14
    ld de,hiscore
    call print_hi
    ld hl,VR_NAME+23*PF_W+7
    ld de,txt_copy
    call print

    call sprites_off
    ld a,ST_TITLE
    ld (state),a
    ld hl,0
    ld (st_timer),hl
    call screen_on
    jp mus_start

; A = top row of a 16 pixel tall band of random stones.  The upper halves
; go on that row and the lower halves on the next, so the blocks stay whole.
wall_band:
    ld (tmp_y),a
    ld hl,band_buf              ; top halves of BLK_W random stones
    ld b,BLK_W
.pick:
    push bc
    push hl
    ld c,TILE_N
    call rnd_lt
    pop hl
    pop bc
    add a,CH_TILE
    ld (hl),a
    inc hl
    add a,8                     ; TR quadrant is 8 characters along
    ld (hl),a
    inc hl
    djnz .pick

    ld hl,band_buf              ; the bottom quadrants are another 16 along
    ld de,band_buf+PF_W
    ld b,PF_W
.lower:
    ld a,(hl)
    add a,16
    ld (de),a
    inc hl
    inc de
    djnz .lower

    ld a,(tmp_y)
    call row_addr
    ld de,band_buf
    ld bc,PF_W
    call ldirvm
    ld a,(tmp_y)
    inc a
    call row_addr
    ld de,band_buf+PF_W
    ld bc,PF_W
    jp ldirvm

; HL = VRAM, DE -> 3 byte BCD
print_hi:
    push hl
    ld hl,hud_buf
    call put_bcd6
    pop hl
    ld de,hud_buf
    ld bc,6
    jp ldirvm

st_title_run:
    call mus_tick
    ld hl,(st_timer)
    inc hl
    ld (st_timer),hl
    ld a,l
    and 01Fh
    jr nz,.notog
    ld a,l
    and 020h
    ld de,txt_help3
    jr z,.show
    ld de,txt_blank
.show:
    ld hl,VR_NAME+13*PF_W+5
    call print
.notog:
    ld hl,(st_timer)            ; ignore a trigger still held from before
    ld a,h
    or a
    jr nz,.armed
    ld a,l
    cp 40
    ret c
.armed:
    call read_trig
    or a
    ret z
    ; fall through
game_start:
    call mus_stop               ; hand the PSG back to the effects
    xor a
    ld (score+0),a
    ld (score+1),a
    ld (score+2),a
    ld a,3
    ld (lives),a
    ld a,1
    ld (level),a

    ; seed the level generator from the moment the trigger was pressed, so
    ; no two games get the same sequence of layouts
    ld hl,(JIFFY)
    ld a,(frame_cnt)
    xor h
    ld h,a
    ld a,h
    or l
    jr nz,.seeded
    ld hl,0A55Ah                ; the LFSR must never start at zero
.seeded:
    ld (rng_seed),hl
    jp level_start

;----------------------------------------------------------------- level
level_start:
    call screen_off
    call gen_level
    call draw_level
    call actors_reset
    call timer_reset
    call screen_on
    ld a,1
    ld (hud_dirty),a
    ld (bar_dirty),a
    ld hl,sfx_start
    call sfx_play
ready_enter:
    ld de,txt_ready
    ld a,13
    call msg_show
    ld a,ST_READY
    ld (state),a
    ld hl,80
    ld (st_timer),hl
    jp sat_build

st_ready_run:
    call sat_build
    ld hl,(st_timer)
    dec hl
    ld (st_timer),hl
    ld a,h
    or l
    ret nz
    call msg_hide
    ld a,ST_PLAY
    ld (state),a
    ret

;------------------------------------------------------------------ play
st_play_run:
    call player_update
    call enemies_update
    call check_pickup
    call sat_build

    ld a,(red_left)
    or a
    jr z,.cleared

    call timer_tick
    jr z,.timeup

    call check_hit
    ret nc
    jp die_enter

.timeup:
    jp die_enter

.cleared:
    ld a,ST_BONUS
    ld (state),a
    ld hl,0
    ld (st_timer),hl
    ret

;----------------------------------------------------------------- death
die_enter:
    ld a,ST_DIE
    ld (state),a
    ld hl,110
    ld (st_timer),hl
    ld hl,sfx_death
    jp sfx_play

st_die_run:
    ld a,(frame_cnt)
    and 004h
    jr z,.hide
    ld a,1
    jr .setv
.hide:
    xor a
.setv:
    ld (p_vis),a
    call sat_build

    ld hl,(st_timer)
    dec hl
    ld (st_timer),hl
    ld a,h
    or l
    ret nz

    ld a,1
    ld (p_vis),a
    ld hl,lives
    ld a,(hl)
    or a
    jr z,.over
    dec (hl)
    ld a,1
    ld (hud_dirty),a
    ld a,(lives)
    or a
    jr z,.over
    call actors_reset
    jp ready_enter
.over:
    xor a
    ld (lives),a
    ld a,1
    ld (hud_dirty),a
    call sprites_off
    ld de,txt_over
    ld a,11
    call msg_show
    ld a,ST_OVER
    ld (state),a
    ld hl,180
    ld (st_timer),hl
    ld hl,sfx_over
    jp sfx_play

st_over_run:
    call sprites_off
    ld hl,(st_timer)
    dec hl
    ld (st_timer),hl
    ld a,h
    or l
    ret nz
    jp title_enter

;------------------------------------------------------- time bonus roll
st_bonus_run:
    call sat_build
    ld b,BONUS_MULT
.lp:
    push bc
    ld a,(secs_left)
    ld (bonus_prev),a
    call timer_tick
    ld a,(secs_left)
    ld c,a
    ld a,(bonus_prev)
    cp c
    jr z,.same
    ld hl,0010h                 ; +10 per second saved
    call add_score
    ld hl,sfx_coin
    call sfx_play
.same:
    pop bc
    djnz .lp

    ld hl,(tick_left)
    ld a,h
    or l
    ret nz

    ; next level.  The counter only feeds the difficulty ramp (which caps
    ; long before this) and the readout, so stopping it at 255 costs
    ; nothing: the layouts keep coming, they are never re-derived from it.
    ld hl,level
    ld a,(hl)
    inc a
    jr z,.nolvl                 ; wrapped past 255, leave it there
    ld (hl),a
.nolvl:
    jp level_start
