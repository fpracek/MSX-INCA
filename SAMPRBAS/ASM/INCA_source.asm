; THE INCA WALL - compact MSX-DOS version in pure Z80 assembly (SamPr Basic, OPTION ASM)
; Take every red chakana of the level before the bar runs out; four guardians chase you. Cursor keys / joystick, space / fire.
; Screen 1, 16x16 sprites. Characters: 0-26 stones, 32-95 BIOS font, 96 blank, 104-107 chakana, 119 bar.
; Game states: 0 title, 1 ready, 2 play, 3 death, 5 game over.
;VAR st 0
;VAR tm 1
;VAR px 2
;VAR py 3
;VAR pvis 4
;VAR lives 5
;VAR lv 6
;VAR lvb 7
;VAR red 8
;VAR espd 9
;VAR frm 10
;VAR srot 11
;VAR step 12
;VAR tacc 13
;VAR bar 14
;VAR dirty 15
;VAR sc 16
;VAR seed 19
;VAR rc 21
;VAR rooms 22
;VAR en 42
;VAR sat 70
;VAR sv 91
;VAR t0 95
;VAR t1 96
;VAR t2 97
;VAR t3 98
start:
        ld a,1
        ld ix,5Fh
        call bios                       ; CHGMOD 1: screen 1 and the BIOS font
        ld a,0A2h
        call r1                         ; screen off, 16x16 sprites
        ld a,0F1h
        out (99h),a
        ld a,87h
        out (99h),a                     ; colours: white on black
        ld hl,_gdat                     ; stones (3 motifs, the four quarters in the groups 0 to 3), chakana, 2 sprites
        ld de,0
        ld bc,24
        call ldv
        ld de,64
        ld bc,24
        call ldv
        ld de,128
        ld bc,24
        call ldv
        ld de,192
        ld bc,24
        call ldv
        ld de,832
        ld bc,32
        call ldv
        ld de,14336
        ld bc,64
        call ldv
        ld hl,_ctab
        ld de,8192
        ld bc,16
        call ldv                        ; colour table, groups 0-15
        ld hl,8208
        ld bc,16
        ld a,0F1h
        call fil
        ld hl,768
        ld bc,64
        xor a
        call fil                        ; characters 96-103 blank
        ld hl,952
        ld bc,8
        ld a,255
        call fil                        ; character 119: the bar
        ld a,0D0h
        ld (@sat+20),a                  ; the sprite list ends after the fifth
        ld a,(0FFE8h)
        and 2
        ld a,141
        jr nz,2f
        ld a,169
2:      ld (@step),a                    ; frames per bar step: 90 s / 32
        ld a,(0FC9Eh)
        ld (@seed),a
        call title
mloop:  halt
        ld hl,@frm
        inc (hl)
        ld a,(@st)
        add a,a
        ld e,a
        ld d,0
        ld hl,_jt
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        ld de,mloop
        push de
        jp (hl)
_jt:    dw run0,run1,run2,run3,run3,run5

; ---- video and BIOS helpers
bios:   push ix                         ; CALSLT, IX = routine
        ld iy,(0FCC0h)
        call 1Ch
        pop ix
        ei
        ret
setw:   ld a,l                          ; VRAM write address HL
        out (99h),a
        ld a,h
        or 40h
        out (99h),a
        ret
setr:   ld a,l                          ; VRAM read address HL
        out (99h),a
        ld a,h
        out (99h),a
        ret
r1:     out (99h),a                     ; VDP register 1 = A
        ld a,81h
        out (99h),a
        ret
fil:    ld e,a                          ; fill HL, BC bytes with A
        call setw
1:      ld a,e
        out (98h),a
        dec bc
        ld a,b
        or c
        jr nz,1b
        ret
ldv:    ex de,hl                        ; copy HL -> VRAM DE, BC bytes
        call setw
        ex de,hl
1:      ld a,(hl)
        out (98h),a
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,1b
        ret
clr:    push bc                         ; blank a rectangle: HL, B rows, C bytes wide
        call setw
        ld b,c
        ld a,96
2:      out (98h),a
        djnz 2b
        pop bc
        ld de,32
        add hl,de
        djnz clr
        ret
putblk: push hl                         ; 2x2 characters at HL: D, D+C, D+2C, D+3C
        ld b,d
        call setw
        ld a,b
        out (98h),a
        add a,c
        out (98h),a
        add a,c
        ld b,a
        ld de,32
        add hl,de
        call setw
        ld a,b
        out (98h),a
        add a,c
        out (98h),a
        pop hl
        ret
baddr:  ld a,d                          ; HL = screen address of the 16x16 block row D, column E
        rrca
        rrca
        ld l,a
        and 3
        ld h,a
        ld a,l
        and 0C0h
        ld l,a
        ld a,e
        add a,a
        or l
        ld l,a
        ld de,6144
        add hl,de
        ret
rnd:    push bc                         ; random byte: linear congruence mixed with the refresh register
        ld a,(@seed)
        ld b,a
        add a,a
        add a,a
        add a,b
        inc a
        ld (@seed),a
        ld b,a
        ld a,r
        xor b
        pop bc
        ret
rn:     ld c,a                          ; A = random number 0..A-1
        call rnd
1:      cp c
        ret c
        sub c
        jr 1b
pbyte:  push af                         ; two BCD digits of A
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,48
        out (98h),a
        pop af
        and 15
        add a,48
        out (98h),a
        ret
pstr:   ld a,(hl)                       ; text up to 0 at the VRAM write pointer
        inc hl
        or a
        ret z
        out (98h),a
        jr pstr
prt:    ld e,(hl)                       ; records of (screen address, text, 0) up to address 0
        inc hl
        ld d,(hl)
        inc hl
        ld a,d
        or e
        ret z
        ex de,hl
        call setw
        ex de,hl
        call pstr
        jr prt
ad:     sub c                           ; A = |A - C|
        ret nc
        neg
        ret
sgn:    cp c                            ; A = sign of (A - C): 1, 0 or 255
        ld a,0
        ret z
        inc a
        ret nc
        ld a,0FFh
        ret
trig:   xor a                           ; A <> 0 when the space bar or the fire button are pressed
        ld ix,0D8h
        call bios
        or a
        ret nz
        ld a,1
        ld ix,0D8h
        jp bios
stick:  xor a                           ; A = direction 0..8 (cursors, then joystick 1)
        ld ix,0D5h
        call bios
        or a
        ret nz
        ld a,1
        ld ix,0D5h
        jp bios

; ---- title
title:  ld a,0A2h
        call r1
        ld hl,6144
        ld bc,768
        ld a,96
        call fil
        ld hl,_tx
        call prt
        ld hl,6912
        call setw
        ld a,0D0h
        out (98h),a                     ; no sprites
        xor a
        ld (@st),a
        ld (@tm),a
        ld a,0E2h
        jp r1
run0:   ld hl,@tm
        inc (hl)
        jr nz,1f
        dec (hl)
1:      ld a,(hl)
        cp 40
        ret c
        call trig
        or a
        ret z
        ld a,3                          ; new game
        ld (@lives),a
        ld a,1
        ld (@lv),a
        ld (@lvb),a
        xor a
        ld hl,@sc
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a

; ---- a new level (screen off while it is built)
lvlst:  ld a,0A2h
        call r1
        ld hl,6144
        ld b,160
1:      push bc                         ; the wall: 16x10 random stones
        ld a,3
        call rn
        ld d,a
        ld c,8
        call putblk
        pop bc
        inc hl
        inc hl
        ld a,b
        dec a
        and 15
        jr nz,2f
        ld de,32
        add hl,de
2:      djnz 1b
        ld hl,6784
        ld bc,128
        ld a,96
        call fil                        ; the lower 4 character rows are for the status
        ld a,3
        call rn
        add a,3
        ld (@rc),a                      ; 3 to 5 black rooms
        ld b,a
        ld hl,@rooms
3:      push bc
        push hl
        ld a,3
        call rn
        add a,2
        ld d,a                          ; width 2..4
        ld a,2
        call rn
        add a,2
        ld e,a                          ; height 2..3
        ld a,15
        sub d
        call rn
        inc a
        ld b,a                          ; x
        ld a,9
        sub e
        call rn
        inc a
        ld c,a                          ; y
        pop hl
        ld (hl),b
        inc hl
        ld (hl),c
        inc hl
        ld (hl),d
        inc hl
        ld (hl),e
        inc hl
        push hl
        ld a,d
        add a,a
        ld d,a
        ld a,e
        add a,a
        ld e,a
        push de
        ld d,c
        ld e,b
        call baddr
        pop bc
        ld a,b
        ld b,c
        ld c,a                          ; B rows, C bytes
        call clr
        pop hl
        pop bc
        djnz 3b
        ld a,(@lv)                      ; chakanas: level + 4, at most 9
        add a,4
        cp 10
        jr c,4f
        ld a,9
4:      ld (@red),a
        ld (@t0),a
5:      ld a,12
        ld (@t1),a
6:      ld a,(@rc)
        call rn
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,@rooms
        add hl,de
        ld de,@sv
        ld bc,4
        ldir
        ld a,(@sv+2)
        call rn
        ld hl,@sv
        add a,(hl)
        ld e,a
        ld a,(@sv+3)
        call rn
        ld hl,@sv+1
        add a,(hl)
        ld d,a
        call baddr
        call setr
        in a,(98h)
        cp 96
        jr nz,7f                        ; taken already: try again
        ld d,104
        ld c,1
        call putblk
        jr 8f
7:      ld hl,@t1
        dec (hl)
        jr nz,6b
        ld hl,@red
        dec (hl)                        ; no room found: one chakana less
8:      ld hl,@t0
        dec (hl)
        jr nz,5b
        call actors
        xor a
        ld (@tacc),a
        ld a,32
        ld (@bar),a
        ld a,3
        ld (@dirty),a
        ld a,0E2h
        call r1
ready:  ld a,1
        ld (@st),a
        ld a,80
        ld (@tm),a
        jp sprites
actors: ld a,120                        ; player and guardians in their starting places
        ld (@px),a
        ld a,72
        ld (@py),a
        ld a,1
        ld (@pvis),a
        ld hl,_etab
        ld de,@en
        ld bc,20
        ldir
        ld a,(@lv)                      ; speed: 4 + level - 1 frames out of 8, at most 7
        add a,3
        cp 8
        jr c,1f
        ld a,7
1:      ld (@espd),a
        ret

; ---- play
run1:   call sprites
        ld hl,@tm
        dec (hl)
        ret nz
        ld a,2
        ld (@st),a
        ret
run2:   call stick
        or a
        jr z,1f
        ld e,a
        ld d,0
        ld hl,_dtab
        add hl,de
        add hl,de
        ld b,(hl)
        inc hl
        ld c,(hl)
        ld a,(@px)
        ld d,b
        ld e,240
        call mva
        ld (@px),a
        ld a,(@py)
        ld d,c
        ld e,144
        call mva
        ld (@py),a
1:      call enemies
        call pick
        call sprites
        ld a,(@red)
        or a
        jr nz,2f
        ld hl,@lv                       ; level done
        inc (hl)
        ld a,(@lvb)
        add a,1
        daa
        ld (@lvb),a
        jp lvlst
2:      ld hl,@tacc                     ; the clock: one bar step every `step` frames
        inc (hl)
        ld a,(@step)
        cp (hl)
        jr nz,5f
        ld (hl),0
        ld hl,@bar
        dec (hl)
        ld hl,@dirty
        set 0,(hl)
        ld a,(@bar)
        or a
        jr z,die
5:      ld hl,@en
        ld b,4
3:      ld a,(@px)
        ld c,a
        ld a,(hl)
        call ad
        cp 12
        jr nc,4f
        inc hl
        inc hl
        ld a,(@py)
        ld c,a
        ld a,(hl)
        call ad
        cp 12
        jr nc,6f
die:    ld a,3
        ld (@st),a
        ld a,110
        ld (@tm),a
        ret
4:      inc hl
        inc hl
6:      inc hl
        inc hl
        inc hl
        djnz 3b
        ret
mva:    add a,d                         ; A + delta D, kept in 0..E
        cp e
        ret c
        ret z
        ld a,e
        bit 7,d
        ret z
        xor a
        ret
enemies: ld a,(@frm)                    ; guardians: 0 chases, 1 chases on the longer axis, 2 bounces, 3 sweeps
        and 7
        ld hl,@espd
        cp (hl)
        ret nc                          ; they move on some frames only: speed = (espd + 1) / 8 pixel per frame
        ld hl,@en
        ld b,0
1:      ld a,b
        cp 2
        jr z,6f
        ld c,(hl)
        ld a,(@px)
        call sgn
        ld (@t0),a
        ld a,(@px)
        call ad
        ld (@t2),a
        inc hl
        inc hl
        ld c,(hl)
        ld a,(@py)
        call sgn
        ld (@t1),a
        ld a,(@py)
        call ad
        ld (@t3),a
        dec hl
        dec hl
        ld a,b
        cp 1
        jr nz,3f
        ld a,(@t2)
        ld c,a
        ld a,(@t3)
        cp c
        jr c,2f
        xor a
        ld (@t0),a
        jr 5f
2:      xor a
        ld (@t1),a
        jr 5f
3:      cp 3
        jr nz,5f
        ld a,(@frm)
        and 64
        jr z,5f
        ld a,(@t0)
        neg
        ld (@t0),a
5:      inc hl
        ld a,(@t0)
        ld (hl),a
        inc hl
        inc hl
        ld a,(@t1)
        ld (hl),a
        dec hl
        dec hl
        dec hl
6:      ld d,240
        call axis
        inc hl
        ld d,144
        call axis
        inc hl
        inc hl
        inc b
        ld a,b
        cp 4
        jr nz,1b
        ret
axis:   ld a,(hl)                       ; HL = (position, direction), D = limit: moves one pixel, bounces at the edges
        inc hl
        add a,(hl)
        ld c,a
        ld a,d
        cp c
        jr c,1f
        dec hl
        ld (hl),c
        inc hl
        ret
1:      ld a,(hl)
        neg
        ld (hl),a
        ret
pick:   ld a,(@py)                      ; chakana under the player's centre?
        add a,8
        rrca
        rrca
        rrca
        and 31
        ld d,a
        cp 20
        ret nc
        ld a,(@px)
        add a,8
        rrca
        rrca
        rrca
        and 31
        ld e,a
        ld a,d
        rrca
        rrca
        rrca
        ld l,a
        and 31
        add a,18h
        ld h,a
        ld a,l
        and 0E0h
        or e
        ld l,a
        call setr
        in a,(98h)
        cp 104
        ret c
        cp 108
        ret nc
        res 0,l
        bit 0,d
        jr z,1f
        ld de,0FFE0h
        add hl,de
1:      ld d,96
        ld c,0
        call putblk
        ld hl,@red
        dec (hl)
        ld a,(@sc+1)                    ; score + 100 (BCD)
        add a,1
        daa
        ld (@sc+1),a
        ld a,(@sc+2)
        adc a,0
        daa
        ld (@sc+2),a
        ld hl,@dirty
        set 1,(hl)
        ret

; ---- sprites, bar and status line
sprites: ld hl,@sat                     ; sprite attributes into RAM: player, then the guardians
        ld a,(@py)
        dec a
        ld b,a
        ld a,(@pvis)
        or a
        ld a,b
        jr nz,1f
        ld a,0D1h
1:      ld (hl),a
        inc hl
        ld a,(@px)
        ld (hl),a
        inc hl
        ld (hl),0
        inc hl
        ld (hl),15
        inc hl
        ld de,@en
        ld b,4
2:      ld a,(de)
        ld c,a
        inc de
        inc de
        ld a,(de)
        dec a
        ld (hl),a
        inc hl
        ld (hl),c
        inc hl
        ld (hl),4
        inc hl
        inc de
        inc de
        ld a,(de)
        ld (hl),a
        inc hl
        inc de
        djnz 2b
        ld hl,6912                      ; the 5 sprites
        call setw
        ld hl,@sat
        ld b,21
4:      ld a,(hl)
        out (98h),a
        inc hl
        djnz 4b
6:      ld hl,@dirty
        bit 0,(hl)
        jr z,7f
        res 0,(hl)
        ld hl,6816                      ; the bar: one character per step
        call setw
        ld a,(@bar)
        ld c,a
        or a
        jr z,9f
        ld b,a
8:      ld a,119
        out (98h),a
        nop
        djnz 8b
9:      ld a,32
        sub c
        jr z,7f
        ld b,a
0:      ld a,96
        out (98h),a
        nop
        djnz 0b
7:      ld hl,@dirty
        bit 1,(hl)
        ret z
        res 1,(hl)
        ld hl,6848
        call setw
        ld hl,_hst
        call pstr
        ld a,(@lives)
        add a,48
        out (98h),a
        call pstr
        push hl
        ld hl,@sc+2
        ld b,3
        call 1f
        pop hl
        call pstr
        ld a,(@lvb)
        jp pbyte
1:      ld a,(hl)
        dec hl
        call pbyte
        djnz 1b
        ret

; ---- death and game over
run3:   ld a,(@frm)
        and 4
        rrca
        rrca
        ld (@pvis),a
        call sprites
        ld hl,@tm
        dec (hl)
        ret nz
        ld a,1
        ld (@pvis),a
        ld hl,@lives
        dec (hl)
        jr nz,1f
        ld hl,6912
        call setw
        ld a,0D0h
        out (98h),a
        ld hl,_gov
        call prt
        ld a,5
        ld (@st),a
        ld a,180
        ld (@tm),a
        ret
1:      call actors
        ld hl,@dirty
        set 1,(hl)
        jp ready
run5:   ld hl,@tm
        dec (hl)
        ret nz
        jp title

; ---- data
_dtab:  db 0,0,0,0FEh,2,0FEh,2,0,2,2,0,2,0FEh,2,0FEh,0,0FEh,0FEh
_etab:  db 8,1,8,1,13
        db 232,1,8,1,7
        db 8,1,136,1,3
        db 232,1,136,1,5
_ctab:  db 1Bh,1Bh,16h,16h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,91h,31h,0B1h
_hst:   db "LIFE ",0," SCORE ",0," LV ",0
_tx:    TXT 6,9,"THE INCA WALL"
        TXT 9,3,"TAKE ALL THE RED CHAKANAS"
        TXT 11,6,"AVOID THE GUARDIANS"
        TXT 13,5,"PUSH SPACE OR TRIGGER"
        dw 0
_gov:   TXT 10,11,"GAME OVER"
        dw 0
_gdat:  GFX
v:      ds 100
