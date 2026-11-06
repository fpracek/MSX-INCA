;=======================================================================
; THE KANJI WALL  -  MSX1 arcade, SCREEN 1, plain 32K cartridge ROM
;-----------------------------------------------------------------------
; The whole playfield is a wall papered with 16 kanji-like tiles.
; Player and enemies walk freely over it (8 directions, no map collision).
; Black patches are cut into the wall; inside them sit RED copies of the
; same kanji tiles: collect them all to clear the level.
; 90 seconds per level, shown as a draining bar; 3 lives.
; Level clear -> bar drains fast, +10 pts per second saved (coin roll).
;-----------------------------------------------------------------------
; Build: build.cmd   (sjasmplus)      Run: run.cmd  (openMSX)
;=======================================================================

    DEVICE NOSLOT64K

;---------------------------------------------------------------- BIOS
GTSTCK      equ 000D5h          ; A = stick number -> A = 0..8
GTTRIG      equ 000D8h          ; A = trigger number -> A = 0/255
CGTBL       equ 00004h          ; ptr to BIOS 8x8 character generator
MSXFREQ     equ 0002Bh          ; bit7: 0=60Hz 1=50Hz
JIFFY       equ 0FC9Eh
CSRSW       equ 0FCA9h          ; cursor display switch (keep it off)

;------------------------------------------------------------ hardware
VDP_DAT     equ 098h
VDP_ADR     equ 099h
PSG_ADR     equ 0A0h
PSG_DAT     equ 0A1h

;---------------------------------------------------------------- VRAM
VR_PAT      equ 00000h          ; pattern generator   (2048)
VR_NAME     equ 01800h          ; pattern name table  (768)
VR_SATR     equ 01B00h          ; sprite attributes   (128)
VR_COL      equ 02000h          ; colour table        (32)
VR_SPAT     equ 03800h          ; sprite patterns     (2048)

;------------------------------------------------------ character map
; colour on MSX1 SCREEN 1 is per group of 8 consecutive patterns
CH_BLANK    equ 000h            ; grp 0   : black on black
CH_TILE     equ 008h            ; grp 1-4 : 8 wall motifs x 4 chars, yellow
CH_RED      equ 028h            ; grp 5   : the chakana pickup, 4 chars, red
CH_BAR      equ 030h            ; grp 6   : 8 bar fill levels (colour varies)
CH_FONT     equ 038h            ; grp 7-14: ASCII 20h..5Fh (code = ascii+18h)
CH_LIFE     equ 078h            ; grp 15  : life icon, light yellow
ASC2CH      equ 018h            ; ascii -> character code offset
TILE_N      equ 8               ; number of wall motifs

;----------------------------------------------------------- geometry
PF_W        equ 32
PF_ROWS     equ 20              ; playfield rows 0..19
ROW_BAR     equ 21
ROW_HUD     equ 22
MAP_SIZE    equ PF_W*PF_ROWS

; the wall is built out of 16x16 blocks, i.e. 2x2 characters
BLK_W       equ PF_W/2          ; 16 blocks across
BLK_H       equ PF_ROWS/2       ; 10 blocks down

PL_XMAX     equ 240             ; sprite is 16 wide
PL_YMAX     equ 144             ; playfield is 160 px tall
P_SPEED     equ 2               ; player pixels per frame

START_X     equ 120
START_Y     equ 72

EN_COUNT    equ 4
EN_SPD0     equ 0A0h            ; level 1 enemy speed, 8.8 fixed (0.625 px/f)
EN_SPDINC   equ 010h
EN_SPDMAX   equ 0F0h

HIT_DIST    equ 12              ; bounding box half-overlap, both axes

GAME_SECS   equ 90
BONUS_MULT  equ 15              ; timer ticks burned per frame during bonus

SFX_PRIO_LEN equ 44             ; length of the extra life jingle, in frames

;------------------------------------------------------------- states
ST_TITLE    equ 0
ST_READY    equ 1
ST_PLAY     equ 2
ST_DIE      equ 3
ST_BONUS    equ 4
ST_OVER     equ 5

;=======================================================================
; RAM  (0C000h - safe on 16K machines; not written to the ROM image)
;=======================================================================
    ORG 0C000h

frame_cnt:  ds 1
rot:        ds 1                ; sprite plane rotation (0..4)
fps:        ds 1                ; 50 or 60
state:      ds 1
st_timer:   ds 2

score:      ds 3                ; 6 digit BCD, little endian
hiscore:    ds 3
lives:      ds 1
level:      ds 1
red_left:   ds 1

secs_left:  ds 1
sec_frames: ds 1
tick_left:  ds 2
tick_total: ds 2
bar_acc:    ds 2
bar_px:     ds 2                ; 0..256
bar_drawn:  ds 2
bar_col:    ds 1

rng_seed:   ds 2

px:         ds 1
py:         ds 1
p_anim:     ds 1
p_frame:    ds 1
p_vis:      ds 1                ; 0 = hidden (death flash)

en_x:       ds EN_COUNT*2       ; 8.8 fixed
en_y:       ds EN_COUNT*2
en_dx:      ds EN_COUNT         ; 1 / 0 / 0FFh
en_dy:      ds EN_COUNT
en_type:    ds EN_COUNT
en_spd:     ds 1
e_idx:      ds 1                ; enemy being updated
e_adx:      ds 1                ; |player - enemy| on each axis
e_ady:      ds 1
e_dif:      ds 1
mv_max:     ds 1
bonus_prev: ds 1

hud_dirty:  ds 1
bar_dirty:  ds 1
msg_col:    ds 1                ; span of the message currently on screen,
msg_len:    ds 1                ; so only those characters get put back

sat_buf:    ds 32
hud_buf:    ds 32
bar_buf:    ds 32
band_buf:   ds PF_W*2           ; two character rows of decorative masonry

room_tab:   ds 8*4              ; x,y,w,h
room_cnt:   ds 1
tmp_x:      ds 1
tmp_y:      ds 1
tmp_w:      ds 1
tmp_h:      ds 1
tmp_c:      ds 1

sfx_ptr:    ds 2
sfx_wait:   ds 1
sfx_prio:   ds 1                ; frames a protected effect cannot be cut off

mus_on:     ds 1                ; title tune, three channels
mus_ptr:    ds 6
mus_wait:   ds 3
mus_vol:    ds 3

map:        ds MAP_SIZE

ram_end:

;=======================================================================
; ROM
;=======================================================================
    ORG 04000h

    db "AB"
    dw rom_init
    dw 0                        ; STATEMENT
    dw 0                        ; DEVICE
    dw 0                        ; TEXT
    dw 0,0,0                    ; reserved

;-----------------------------------------------------------------------
rom_init:
    di
    ld sp,0F380h

    xor a
    ld (CSRSW),a                ; no blinking cursor in the ISR

    call vdp_setup
    call gfx_upload
    call psg_init

    ; clear the whole RAM block
    ld hl,frame_cnt
    ld de,frame_cnt+1
    ld bc,ram_end-frame_cnt-1
    ld (hl),0
    ldir

    ; frame rate
    ld a,(MSXFREQ)
    and 080h
    ld a,60
    jr z,.f60
    ld a,50
.f60:
    ld (fps),a

    ld hl,01234h
    ld (rng_seed),hl

    ei
    call title_enter

;-----------------------------------------------------------------------
main:
    call wait_vbl

    ; ---- all VRAM traffic first, right after the vblank ----
    call sat_flush
    call bar_flush
    call hud_flush

    ; ---- then the logic ----
    call sfx_tick
    ld hl,frame_cnt
    inc (hl)

    ld a,(state)
    add a,a
    ld e,a
    ld d,0
    ld hl,state_tbl
    add hl,de
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    call jphl
    jp main

jphl:
    jp (hl)

state_tbl:
    dw st_title_run             ; ST_TITLE
    dw st_ready_run             ; ST_READY
    dw st_play_run              ; ST_PLAY
    dw st_die_run               ; ST_DIE
    dw st_bonus_run             ; ST_BONUS
    dw st_over_run              ; ST_OVER

;-----------------------------------------------------------------------
wait_vbl:
    ld hl,JIFFY
    ld a,(hl)
.w: cp (hl)
    jr z,.w
    ret

    include "vdp.asm"
    include "level.asm"
    include "actors.asm"
    include "hud.asm"
    include "sound.asm"
    include "music.asm"
    include "states.asm"
    include "data.asm"

;-----------------------------------------------------------------------
    SAVEBIN "build/kanji.rom", 04000h, 08000h
