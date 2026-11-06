;=======================================================================
; level.asm - RNG, procedural level layout, map drawing, pickups
;=======================================================================

; A = pseudo random byte, preserves BC/DE/HL
rnd:
    push hl
    ld hl,(rng_seed)
    ld a,h
    rra
    ld a,l
    rra
    xor h
    ld h,a
    ld a,l
    rra
    ld a,h
    rra
    xor l
    ld l,a
    xor h
    ld h,a
    ld (rng_seed),hl
    ld a,h
    pop hl
    ret

; C = limit (1..255) -> A = 0..limit-1     (random * limit / 256)
rnd_lt:
    call rnd
    ld e,c
    ld d,0
    ld c,a
    ld hl,0
    ld b,8
.lp:
    add hl,hl
    rlc c
    jr nc,.sk
    add hl,de
.sk:
    djnz .lp
    ld a,h
    ret

;-----------------------------------------------------------------------
; row,col -> map index.  B = row, C = col -> HL = map + row*32 + col
map_addr:
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld e,c
    ld d,0
    add hl,de
    ld de,map
    add hl,de
    ret

;-----------------------------------------------------------------------
; B = block row, C = block column -> HL = map pointer of the block's top
; left character.  BC comes back untouched.
blk_addr:
    push bc
    ld a,b
    add a,a
    ld b,a                      ; character row
    ld a,c
    add a,a
    ld c,a                      ; character column
    call map_addr
    pop bc
    ret

;-----------------------------------------------------------------------
; stamp one 16x16 wall stone into the map.  Its four quadrants live in
; four different colour groups, so they are 8 characters apart.
; B = block row, C = block column, A = base character of the motif
put_wall:
    ld (tmp_c),a
    call blk_addr
    ld a,(tmp_c)
    ld (hl),a                   ; TL
    add a,8
    inc hl
    ld (hl),a                   ; TR
    add a,8
    ld de,PF_W-1
    add hl,de
    ld (hl),a                   ; BL
    add a,8
    inc hl
    ld (hl),a                   ; BR
    ret

; same, for the chakana: it is a single colour, so its four characters are
; consecutive
put_red:
    ld (tmp_c),a
    call blk_addr
    ld a,(tmp_c)
    ld (hl),a
    inc a
    inc hl
    ld (hl),a
    inc a
    ld de,PF_W-1
    add hl,de
    ld (hl),a
    inc a
    inc hl
    ld (hl),a
    ret

;-----------------------------------------------------------------------
; Build the layout for the current level.
;  1) build the wall out of random 16x16 stone motifs
;  2) carve 3..5 black rooms, on the block grid so no stone is cut in half
;  3) drop the red chakanas inside those rooms
; The generator is never re-seeded per level: the RNG just keeps running,
; so the levels never repeat and none of them costs a byte of ROM.  The
; seed is taken once per game, in game_start, from when the player pressed
; the trigger - two runs are never the same.
gen_level:
    ; --- the wall ---
    ld b,0
.brow:
    ld c,0
.bcol:
    push bc
    ld c,TILE_N
    call rnd_lt
    add a,CH_TILE               ; motif base character
    pop bc
    push bc
    call put_wall
    pop bc
    inc c
    ld a,c
    cp BLK_W
    jr nz,.bcol
    inc b
    ld a,b
    cp BLK_H
    jr nz,.brow

    ; --- rooms ---
    ld c,3
    call rnd_lt
    add a,3                     ; 3..5 rooms
    ld (room_cnt),a
    ld b,a
    ld ix,room_tab
.rooms:
    push bc
    call carve_room
    pop bc
    ld de,4
    add ix,de
    djnz .rooms

    ; --- chakanas ---
    ld a,(level)
    add a,4
    cp 10
    jr c,.nred
    ld a,9
.nred:
    ld (red_left),a
    ld b,a
.reds:
    push bc
    call place_red
    pop bc
    djnz .reds
    ret

;-----------------------------------------------------------------------
; carve one black room, IX -> its 4 byte record (all in blocks)
carve_room:
    ld c,3
    call rnd_lt
    add a,2                     ; w = 2..4 blocks
    ld (tmp_w),a
    ld c,2
    call rnd_lt
    add a,2                     ; h = 2..3 blocks
    ld (tmp_h),a

    ld a,(tmp_w)
    ld c,a
    ld a,BLK_W-1
    sub c
    ld c,a
    call rnd_lt
    inc a                       ; x = 1..15-w
    ld (tmp_x),a

    ld a,(tmp_h)
    ld c,a
    ld a,BLK_H-1
    sub c
    ld c,a
    call rnd_lt
    inc a                       ; y = 1..9-h
    ld (tmp_y),a

    ld a,(tmp_x)
    ld (ix+0),a
    ld a,(tmp_y)
    ld (ix+1),a
    ld a,(tmp_w)
    ld (ix+2),a
    ld a,(tmp_h)
    ld (ix+3),a

    ; blank the rectangle, in characters
    ld a,(tmp_y)
    add a,a
    ld b,a
    ld a,(tmp_h)
    add a,a
    ld c,a
.rowlp:
    push bc
    ld a,(tmp_x)
    add a,a
    ld c,a
    call map_addr               ; B = character row already in B
    ld a,(tmp_w)
    add a,a
    ld b,a
.collp:
    ld (hl),CH_BLANK
    inc hl
    djnz .collp
    pop bc
    inc b
    dec c
    jr nz,.rowlp
    ret

;-----------------------------------------------------------------------
; drop one chakana on a free block inside a random room
place_red:
    ld b,12                     ; give up after a few tries
.try:
    push bc
    ld a,(room_cnt)
    ld c,a
    call rnd_lt
    add a,a
    add a,a
    ld e,a
    ld d,0
    ld hl,room_tab
    add hl,de                   ; HL -> room record

    ld c,(hl)                   ; block x
    inc hl
    ld b,(hl)                   ; block y
    inc hl
    push bc
    ld c,(hl)                   ; w
    inc hl
    ld a,(hl)
    ld (tmp_h),a                ; h
    call rnd_lt
    ld (tmp_x),a                ; dx
    ld a,(tmp_h)
    ld c,a
    call rnd_lt
    ld (tmp_y),a                ; dy
    pop bc

    ld a,(tmp_x)
    add a,c
    ld c,a                      ; block column
    ld a,(tmp_y)
    add a,b
    ld b,a                      ; block row

    call blk_addr               ; is that block still empty?
    ld a,(hl)
    or a
    jr nz,.next                 ; another chakana is already there

    ld a,CH_RED
    call put_red
    pop bc
    ret
.next:
    pop bc
    djnz .try
    ; could not place it: keep the counter honest
    ld hl,red_left
    dec (hl)
    ret

;-----------------------------------------------------------------------
; push the map to VRAM and clear the three bottom rows
draw_level:
    ld hl,VR_NAME
    ld de,map
    ld bc,MAP_SIZE
    call ldirvm
    ld hl,VR_NAME+MAP_SIZE
    ld bc,PF_W
    ld a,CH_BLANK
    call filvrm
    ld hl,VR_NAME+(ROW_HUD+1)*PF_W
    ld bc,PF_W
    ld a,CH_BLANK
    jp filvrm

;-----------------------------------------------------------------------
; Map collision hook.  Right now the whole wall is walkable, so this
; always says "free".  Flip it to test for CH_BLANK to make the black
; patches solid (or lethal) without touching the movement code.
;   B = row, C = col -> carry set = blocked
map_solid:
    or a
    ret

;-----------------------------------------------------------------------
; is the player standing on a chakana?  collect the whole 16x16 block if so
check_pickup:
    ld a,(py)
    add a,8
    srl a
    srl a
    srl a
    cp PF_ROWS
    ret nc
    ld b,a
    ld a,(px)
    add a,8
    srl a
    srl a
    srl a
    ld c,a
    call map_addr
    ld a,(hl)
    cp CH_RED
    ret c
    cp CH_RED+4
    ret nc

    ; collected: snap to the block origin and wipe all four characters
    ld a,b
    and 0FEh
    ld b,a
    ld a,c
    and 0FEh
    ld c,a
    call clear_block

    ld hl,red_left
    dec (hl)
    ld hl,0100h                 ; +100 points
    call add_score
    ld hl,sfx_pick
    jp sfx_play

; blank one 16x16 block in the map and on screen.
; B = character row (even), C = character column (even)
clear_block:
    call map_addr
    ld (hl),CH_BLANK
    inc hl
    ld (hl),CH_BLANK
    ld de,PF_W-1
    add hl,de
    ld (hl),CH_BLANK
    inc hl
    ld (hl),CH_BLANK
    ; same two rows in VRAM
    ld de,map+PF_W+1
    or a
    sbc hl,de                   ; HL = index of the top left character
    ld de,VR_NAME
    add hl,de
    push hl
    ld bc,2
    ld a,CH_BLANK
    call filvrm
    pop hl
    ld de,PF_W
    add hl,de
    ld bc,2
    ld a,CH_BLANK
    jp filvrm
