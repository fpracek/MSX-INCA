;=======================================================================
; vdp.asm - direct port VDP access (no BIOS: some machines have a buggy
;           FILVRM/LDIRVM, see the HB-55P issue found on Sam.Pr Miner)
;=======================================================================

; A = value, B = register
wrtvdp:
    di
    out (VDP_ADR),a
    ld a,b
    or 080h
    out (VDP_ADR),a
    ei
    ret

; HL = VRAM address, set up for writing
setwrt:
    ld a,l
    di
    out (VDP_ADR),a
    ld a,h
    or 040h
    out (VDP_ADR),a
    ei
    ret

; HL = VRAM address, DE = source, BC = count
ldirvm:
    call setwrt
.lp:
    ld a,(de)
    out (VDP_DAT),a
    inc de
    dec bc
    ld a,b
    or c
    jr nz,.lp
    ret

; HL = VRAM address, BC = count, A = byte
; (keep the byte in E: popping AF would restore the flags of the counter test)
filvrm:
    ld e,a
    call setwrt
    ld a,e
.lp:
    out (VDP_DAT),a
    dec bc
    ld a,b
    or c
    ld a,e
    jr nz,.lp
    ret

; HL = VRAM address, A = byte
wrtvrm:
    push af
    call setwrt
    pop af
    out (VDP_DAT),a
    ret

;-----------------------------------------------------------------------
; SCREEN 1, 16x16 sprites, display off
vdp_setup:
    ld hl,vdp_regs
    ld b,0
.lp:
    ld a,(hl)
    push hl
    push bc
    call wrtvdp
    pop bc
    pop hl
    inc hl
    inc b
    ld a,b
    cp 8
    jr nz,.lp
    ret

vdp_regs:
    db 000h                     ; R0 graphic 1
    db 0A2h                     ; R1 16K, display OFF, IE on, 16x16 sprites
    db VR_NAME/400h             ; R2
    db VR_COL/40h               ; R3
    db VR_PAT/800h              ; R4
    db VR_SATR/80h              ; R5
    db VR_SPAT/800h             ; R6
    db 001h                     ; R7 black border

screen_on:
    ld a,0E2h
    ld b,1
    jp wrtvdp

screen_off:
    ld a,0A2h
    ld b,1
    jp wrtvdp

;-----------------------------------------------------------------------
; upload every pattern, colour and sprite
gfx_upload:
    ; blank patterns 00..07
    ld hl,VR_PAT
    ld bc,8*8
    xor a
    call filvrm

    ; 8 wall motifs, 4 characters each
    ld hl,VR_PAT+CH_TILE*8
    ld de,tile_pat
    ld bc,TILE_N*4*8
    call ldirvm

    ; the chakana pickup, 4 characters in its own (red) colour group
    ld hl,VR_PAT+CH_RED*8
    ld de,red_pat
    ld bc,4*8
    call ldirvm

    ; timer bar fills
    ld hl,VR_PAT+CH_BAR*8
    ld de,bar_pat
    ld bc,8*8
    call ldirvm

    ; ASCII 20h..5Fh from the BIOS font at 30h..6Fh
    ld hl,(CGTBL)
    ld de,020h*8
    add hl,de
    ex de,hl
    ld hl,VR_PAT+CH_FONT*8
    ld bc,64*8
    call ldirvm

    ; life icon at 70h
    ld hl,VR_PAT+CH_LIFE*8
    ld de,life_pat
    ld bc,8
    call ldirvm

    ; colour table
    ld hl,VR_COL
    ld de,col_tab
    ld bc,32
    call ldirvm

    ; sprite patterns
    ld hl,VR_SPAT
    ld de,spr_pat
    ld bc,spr_pat_end-spr_pat
    call ldirvm

    ; empty sprite attribute table
    ld hl,VR_SATR
    ld bc,128
    ld a,0D0h
    call filvrm

    ; clear the name table
    ld hl,VR_NAME
    ld bc,768
    ld a,CH_BLANK
    jp filvrm

;-----------------------------------------------------------------------
; HL = VRAM addr, DE = 0-terminated ASCII string
print:
    call setwrt
.lp:
    ld a,(de)
    or a
    ret z
    add a,ASC2CH
    out (VDP_DAT),a
    inc de
    jr .lp

; HL = VRAM addr, DE = string, centred over 32 columns is up to the caller
; row -> VRAM address helper:  A = row  ->  HL = VR_NAME + row*32
row_addr:
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,VR_NAME
    add hl,de
    ret

;-----------------------------------------------------------------------
; push the 5 visible sprites out, rotating their planes so that the
; 5-sprites-on-one-line case flickers fairly instead of hiding one for good
sat_flush:
    ld hl,sat_buf
    ld de,VR_SATR
    ex de,hl
    ld bc,24
    jp ldirvm
