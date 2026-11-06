;=======================================================================
; hud.asm - score, lives, level readout, timer bar, game clock
;=======================================================================

; HL = BCD amount (0100h = 100 points)
add_score:
    ld a,(score+2)
    ld b,a                      ; the top BCD byte counts ten thousands
    ld de,score
    ld a,(de)
    add a,l
    daa
    ld (de),a
    inc de
    ld a,(de)
    adc a,h
    daa
    ld (de),a
    inc de
    ld a,(de)
    adc a,0
    daa
    ld (de),a

    ; if that byte moved, the score just crossed a multiple of 10000.
    ; No single award is worth 10000, so it can only ever cross one.
    ld a,(score+2)
    cp b
    call nz,award_life

    call chk_hiscore
    ld a,1
    ld (hud_dirty),a
    ret

; one free life every 10000 points, but only up to the usual three
award_life:
    ld a,(lives)
    cp 3
    ret nc
    inc a
    ld (lives),a
    ld hl,sfx_extra
    jp sfx_play_hi              ; must not be trampled by the coin roll

chk_hiscore:
    ld a,(score+2)
    ld b,a
    ld a,(hiscore+2)
    cp b
    jr c,.copy
    ret nz
    ld a,(score+1)
    ld b,a
    ld a,(hiscore+1)
    cp b
    jr c,.copy
    ret nz
    ld a,(score+0)
    ld b,a
    ld a,(hiscore+0)
    cp b
    ret nc
.copy:
    ld hl,score
    ld de,hiscore
    ld bc,3
    ldir
    ret

;-----------------------------------------------------------------------
hud_flush:
    ld a,(hud_dirty)
    or a
    ret z
    xor a
    ld (hud_dirty),a
    call hud_build
    ld hl,VR_NAME+ROW_HUD*PF_W
    ld de,hud_buf
    ld bc,PF_W
    jp ldirvm

hud_build:
    ld hl,hud_buf
    ld de,hud_buf+1
    ld bc,PF_W-1
    ld (hl),CH_BLANK
    ldir

    ; lives, as little icons
    ld a,(lives)
    or a
    jr z,.nolives
    cp 4
    jr c,.lok
    ld a,3
.lok:
    ld b,a
    ld hl,hud_buf
.llp:
    ld (hl),CH_LIFE
    inc hl
    djnz .llp
.nolives:

    ld hl,hud_buf+4
    ld de,score
    call put_bcd6

    ld hl,hud_buf+11
    ld (hl),'H'+ASC2CH
    inc hl
    ld (hl),'I'+ASC2CH

    ld hl,hud_buf+14
    ld de,hiscore
    call put_bcd6

    ld hl,hud_buf+22
    ld (hl),'L'+ASC2CH
    inc hl
    ld (hl),'V'+ASC2CH

    ld a,(level)                ; the counter can outrun two digits
    cp 100
    jr c,.lvok
    ld a,99
.lvok:
    call bin2bcd
    ld hl,hud_buf+25
    jp put_bcd1

; HL = dest, DE -> 3 byte little endian BCD -> 6 digits
put_bcd6:
    inc de
    inc de
    ld b,3
.lp:
    push bc
    ld a,(de)
    call put_bcd1
    inc hl
    dec de
    pop bc
    djnz .lp
    ret

; A = BCD byte -> 2 digits at (HL), HL left on the second one
put_bcd1:
    push af
    rrca
    rrca
    rrca
    rrca
    and 00Fh
    add a,'0'+ASC2CH
    ld (hl),a
    inc hl
    pop af
    and 00Fh
    add a,'0'+ASC2CH
    ld (hl),a
    ret

; A = 0..99 -> packed BCD
bin2bcd:
    ld b,0
.lp:
    cp 10
    jr c,.done
    sub 10
    inc b
    jr .lp
.done:
    ld c,a
    ld a,b
    rlca
    rlca
    rlca
    rlca
    or c
    ret

;-----------------------------------------------------------------------
; timer bar
bar_flush:
    ld a,(bar_dirty)
    or a
    ret z
    xor a
    ld (bar_dirty),a
    call bar_build
    ld hl,VR_COL+CH_BAR/8       ; colour group of the bar characters
    ld a,(bar_col)
    call wrtvrm
    ld hl,VR_NAME+ROW_BAR*PF_W
    ld de,bar_buf
    ld bc,PF_W
    jp ldirvm

bar_build:
    ; colour: green -> yellow -> red as the time runs out
    ld hl,(bar_px)
    ld a,h
    or a
    jr nz,.green
    ld a,l
    cp 129
    jr nc,.green
    cp 65
    jr nc,.yellow
    ld a,091h                   ; light red on black
    jr .setc
.yellow:
    ld a,0B1h                   ; light yellow on black
    jr .setc
.green:
    ld a,031h                   ; light green on black
.setc:
    ld (bar_col),a

    ld hl,(bar_px)
    ld a,l
    and 7
    ld c,a                      ; leftover pixels
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld b,l                      ; whole characters
    ld hl,bar_buf
    ld d,PF_W
    ld a,b
    or a
    jr z,.part
.flp:
    ld (hl),CH_BAR+7
    inc hl
    dec d
    djnz .flp
.part:
    ld a,c
    or a
    jr z,.rest
    ld a,d
    or a
    jr z,.rest
    ld a,c
    add a,CH_BAR-1
    ld (hl),a
    inc hl
    dec d
.rest:
    ld a,d
    or a
    ret z
    ld b,d
.rlp:
    ld (hl),CH_BLANK
    inc hl
    djnz .rlp
    ret

;-----------------------------------------------------------------------
; 90 seconds worth of ticks, full bar
timer_reset:
    ld a,GAME_SECS
    ld (secs_left),a
    ld a,(fps)
    ld (sec_frames),a
    ld e,a
    ld d,0
    ld hl,0
    ld b,GAME_SECS
.m:
    add hl,de
    djnz .m
    ld (tick_total),hl
    ld (tick_left),hl
    ld hl,0
    ld (bar_acc),hl
    ld hl,256
    ld (bar_px),hl
    ld a,1
    ld (bar_dirty),a
    ret

; one tick of the game clock.  Z set when the clock has run out.
timer_tick:
    ld hl,(tick_left)
    ld a,h
    or l
    ret z
    dec hl
    ld (tick_left),hl

    ld hl,sec_frames
    dec (hl)
    jr nz,.nosec
    ld a,(fps)
    ld (hl),a
    ld hl,secs_left
    ld a,(hl)
    or a
    jr z,.nosec
    dec (hl)
.nosec:
    ; Bresenham: exactly 256 bar pixels over the whole clock
    ld hl,(bar_acc)
    ld de,256
    add hl,de
    ld de,(tick_total)
    or a
    sbc hl,de
    jr nc,.step
    add hl,de
    ld (bar_acc),hl
    ld a,1                      ; not finished
    or a
    ret
.step:
    ld (bar_acc),hl
    ld hl,(bar_px)
    ld a,h
    or l
    jr z,.nopx
    dec hl
    ld (bar_px),hl
    ld a,1
    ld (bar_dirty),a
.nopx:
    ld a,1
    or a
    ret
