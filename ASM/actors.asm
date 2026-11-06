;=======================================================================
; actors.asm - player, enemies, sprite table building, collisions
;=======================================================================

;----------------------------------------------------------------- input
; cursor keys (stick 0) or joystick port 1, whichever is pushed
read_stick:
    xor a
    call GTSTCK
    or a
    ret nz
    ld a,1
    jp GTSTCK

read_trig:
    xor a
    call GTTRIG
    or a
    ret nz
    ld a,1
    jp GTTRIG

;---------------------------------------------------------------- player
actors_reset:
    ld a,START_X
    ld (px),a
    ld a,START_Y
    ld (py),a
    xor a
    ld (p_anim),a
    ld (p_frame),a
    inc a
    ld (p_vis),a

    ; enemies to the four corners, one behaviour each
    ld hl,en_start
    ld b,0
.lp:
    push bc
    ld c,b
    ld b,0
    ld e,(hl)                   ; x
    inc hl
    ld d,(hl)                   ; y
    inc hl
    push hl

    ld hl,en_x
    add hl,bc
    add hl,bc
    ld (hl),0
    inc hl
    ld (hl),e
    ld hl,en_y
    add hl,bc
    add hl,bc
    ld (hl),0
    inc hl
    ld (hl),d
    ld hl,en_dx
    add hl,bc
    ld (hl),1
    ld hl,en_dy
    add hl,bc
    ld (hl),1
    ld hl,en_type
    add hl,bc
    ld a,c
    ld (hl),a                   ; enemy i gets behaviour i

    pop hl
    pop bc
    inc b
    ld a,b
    cp EN_COUNT
    jr nz,.lp

    ; speed grows with the level
    ld a,(level)
    dec a                       ; sets Z on level 1; the LDs below keep it
    ld b,a
    ld a,EN_SPD0
    jr z,.spdset
.spdlp:
    add a,EN_SPDINC
    jr c,.clamp
    cp EN_SPDMAX
    jr c,.next
.clamp:
    ld a,EN_SPDMAX
.next:
    djnz .spdlp
.spdset:
    ld (en_spd),a
    ret

en_start:
    db 8,8
    db 232,8
    db 8,136
    db 232,136

;-----------------------------------------------------------------------
player_update:
    call read_stick
    or a
    ret z

    ld e,a
    ld d,0
    ld hl,dir_dx
    add hl,de
    ld c,(hl)
    ld hl,dir_dy
    add hl,de
    ld b,(hl)

    ; horizontal
    ld a,c
    or a
    jr z,.nox
    ld a,(px)
    bit 7,c
    jr nz,.left
    add a,P_SPEED
    cp PL_XMAX+1
    jr c,.stx
    ld a,PL_XMAX
    jr .stx
.left:
    sub P_SPEED
    jr nc,.stx
    xor a
.stx:
    ld (px),a
.nox:
    ; vertical
    ld a,b
    or a
    jr z,.noy
    ld a,(py)
    bit 7,b
    jr nz,.up
    add a,P_SPEED
    cp PL_YMAX+1
    jr c,.sty
    ld a,PL_YMAX
    jr .sty
.up:
    sub P_SPEED
    jr nc,.sty
    xor a
.sty:
    ld (py),a
.noy:
    ; walk animation
    ld hl,p_anim
    inc (hl)
    ld a,(hl)
    and 008h
    jr z,.f0
    ld a,1
.f0:
    ld (p_frame),a
    ret

dir_dx: db 0, 0, 1, 1, 1, 0,-1,-1,-1
dir_dy: db 0,-1,-1, 0, 1, 1, 1, 0,-1

;---------------------------------------------------------------- enemies
enemies_update:
    xor a
.lp:
    push af
    call enemy_one
    pop af
    inc a
    cp EN_COUNT
    jr nz,.lp
    ret

enemy_one:                      ; A = enemy index
    ld (e_idx),a
    ld c,a
    ld b,0
    ld hl,en_type
    add hl,bc
    ld a,(hl)

    cp 2
    jr z,.move                  ; bouncer keeps its own heading

    push af
    call en_face
    pop af

    cp 1
    jr nz,.t3
    call en_axis_only
    jr .move
.t3:
    cp 3
    jr nz,.move
    ld a,(frame_cnt)
    and 040h
    jr z,.move
    ld a,(e_idx)                ; sweeping chaser: invert X now and then
    ld c,a
    ld b,0
    ld hl,en_dx
    add hl,bc
    ld a,(hl)
    neg
    ld (hl),a

.move:
    ld a,(e_idx)
    ld c,a
    ld b,0
    ; ---- X ----
    ld hl,en_dx
    add hl,bc
    ld e,(hl)                   ; dir
    ld hl,en_x
    add hl,bc
    add hl,bc
    push bc
    ld a,(en_spd)
    ld b,a
    ld c,e
    ld a,PL_XMAX
    call move_axis
    pop bc
    jr nc,.ydo
    call bounce_x
.ydo:
    ; ---- Y ----
    ld a,(e_idx)
    ld c,a
    ld b,0
    ld hl,en_dy
    add hl,bc
    ld e,(hl)
    ld hl,en_y
    add hl,bc
    add hl,bc
    push bc
    ld a,(en_spd)
    ld b,a
    ld c,e
    ld a,PL_YMAX
    call move_axis
    pop bc
    ret nc
    ; fall through
bounce_y:
    ld a,(e_idx)
    ld c,a
    ld b,0
    ld hl,en_dy
    add hl,bc
    ld a,(hl)
    neg
    ld (hl),a
    ret

bounce_x:
    push bc
    ld a,(e_idx)
    ld c,a
    ld b,0
    ld hl,en_dx
    add hl,bc
    ld a,(hl)
    neg
    ld (hl),a
    pop bc
    ret

;-----------------------------------------------------------------------
; point enemy e_idx at the player and remember both axis distances
en_face:
    ld a,(e_idx)
    ld c,a
    ld b,0

    ld hl,en_x
    add hl,bc
    add hl,bc
    inc hl
    ld e,(hl)                   ; enemy x
    ld a,(px)
    push bc
    call sign_of                ; A = 1/0/0FFh, e_dif = distance
    pop bc
    ld hl,en_dx
    add hl,bc
    ld (hl),a
    ld a,(e_dif)
    ld (e_adx),a

    ld hl,en_y
    add hl,bc
    add hl,bc
    inc hl
    ld e,(hl)
    ld a,(py)
    push bc
    call sign_of
    pop bc
    ld hl,en_dy
    add hl,bc
    ld (hl),a
    ld a,(e_dif)
    ld (e_ady),a
    ret

; A = target, E = current -> A = direction, e_dif = |target-current|
sign_of:
    cp e
    jr z,.zero
    jr nc,.pos
    ld d,a
    ld a,e
    sub d
    ld (e_dif),a
    ld a,0FFh
    ret
.pos:
    ld d,a
    sub e
    ld (e_dif),a
    ld a,1
    ret
.zero:
    xor a
    ld (e_dif),a
    ret

; keep only the dominant axis for enemy e_idx
en_axis_only:
    ld a,(e_idx)
    ld c,a
    ld b,0
    ld a,(e_adx)
    ld e,a
    ld a,(e_ady)
    cp e
    jr nc,.keepy
    ld hl,en_dy
    add hl,bc
    ld (hl),0
    ret
.keepy:
    ld hl,en_dx
    add hl,bc
    ld (hl),0
    ret

;-----------------------------------------------------------------------
; HL -> 16 bit fixed position (lo,hi), B = speed, C = direction,
; A = max integer value.  Carry set on return if it was clamped.
move_axis:
    ld (mv_max),a
    ld a,c
    or a
    ret z
    ld e,(hl)
    inc hl
    ld d,(hl)                   ; DE = position, HL -> hi byte
    push hl
    ld h,0
    ld l,b
    bit 7,c
    jr z,.add
    ex de,hl
    or a
    sbc hl,de
    jr .st
.add:
    add hl,de
.st:
    ex de,hl                    ; DE = new position
    pop hl
    ld a,(mv_max)
    cp d
    jr nc,.ok
    bit 7,c
    jr nz,.lo
    ld d,a
    ld e,0
    jr .hit
.lo:
    ld d,0
    ld e,0
.hit:
    ld (hl),d
    dec hl
    ld (hl),e
    scf
    ret
.ok:
    ld (hl),d
    dec hl
    ld (hl),e
    or a
    ret

;-----------------------------------------------------------------------
; any enemy overlapping the player?  carry set = hit
check_hit:
    xor a
.lp:
    push af
    ld c,a
    ld b,0
    ld hl,en_x
    add hl,bc
    add hl,bc
    inc hl
    ld e,(hl)
    ld a,(px)
    call absdiff
    cp HIT_DIST
    jr nc,.miss

    pop af
    push af
    ld c,a
    ld b,0
    ld hl,en_y
    add hl,bc
    add hl,bc
    inc hl
    ld e,(hl)
    ld a,(py)
    call absdiff
    cp HIT_DIST
    jr nc,.miss
    pop af
    scf
    ret
.miss:
    pop af
    inc a
    cp EN_COUNT
    jr nz,.lp
    or a
    ret

; A, E -> A = |A-E|
absdiff:
    cp e
    jr nc,.ok
    ld d,a
    ld a,e
    sub d
    ret
.ok:
    sub e
    ret

;-----------------------------------------------------------------------
; build the sprite attribute buffer, rotating the plane order so that
; the "5 sprites on one scanline" case flickers instead of hiding one
sat_build:
    ld a,(rot)
    inc a
    cp 5
    jr c,.r
    xor a
.r:
    ld (rot),a
    ld c,a
    ld hl,sat_buf
    ld b,5
.lp:
    push bc
    ld a,c
    call obj_write
    pop bc
    inc c
    ld a,c
    cp 5
    jr c,.n
    ld c,0
.n:
    djnz .lp
    ld (hl),0D0h
    ret

obj_write:                      ; A = object, HL = dest (advanced by 4)
    or a
    jr nz,.enemy
    ld a,(p_vis)
    or a
    jr nz,.pvis
    ld (hl),200                 ; parked below the screen
    inc hl
    ld (hl),0
    inc hl
    ld (hl),0
    inc hl
    ld (hl),0
    inc hl
    ret
.pvis:
    ld a,(py)
    dec a
    ld (hl),a
    inc hl
    ld a,(px)
    ld (hl),a
    inc hl
    ld a,(p_frame)
    add a,a
    add a,a
    ld (hl),a
    inc hl
    ld (hl),15                  ; white: the wall is yellow, stay off it
    inc hl
    ret
.enemy:
    dec a
    push hl
    ld c,a
    ld b,0
    ld hl,en_y
    add hl,bc
    add hl,bc
    inc hl
    ld e,(hl)
    ld hl,en_x
    add hl,bc
    add hl,bc
    inc hl
    ld d,(hl)
    ld hl,en_col
    add hl,bc
    ld c,(hl)
    pop hl
    ld a,e
    dec a
    ld (hl),a
    inc hl
    ld (hl),d
    inc hl
    ld a,(frame_cnt)
    and 010h
    ld a,8
    jr z,.f0
    ld a,12
.f0:
    ld (hl),a
    inc hl
    ld (hl),c
    inc hl
    ret

; no red among these: red belongs to the chakanas alone
en_col: db 13,7,3,5
