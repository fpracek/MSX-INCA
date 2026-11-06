;=======================================================================
; sound.asm - tiny PSG effect player on channel A
; script step = 4 bytes: frames, period lo, period hi, volume
;               frames = 0 -> end of effect
;=======================================================================

psg_wr:                         ; A = register, E = value
    out (PSG_ADR),a
    ld a,e
    out (PSG_DAT),a
    ret

psg_init:
    ld a,7
    ld e,0BEh                   ; port B out, noise off, tone on channel A
    call psg_wr
    ld a,8
    ld e,0
    call psg_wr
    ld a,9
    ld e,0
    call psg_wr
    ld a,10
    ld e,0
    jp psg_wr

; HL -> effect script.  Refused while a protected effect is still playing.
sfx_play:
    ld a,(sfx_prio)
    or a
    ret nz
    ld (sfx_ptr),hl
    xor a
    ld (sfx_wait),a
    ret

; same, but nothing may interrupt it until it has had its say
sfx_play_hi:
    ld (sfx_ptr),hl
    xor a
    ld (sfx_wait),a
    ld a,SFX_PRIO_LEN
    ld (sfx_prio),a
    ret

sfx_tick:
    ld a,(sfx_prio)
    or a
    jr z,.nolock
    dec a
    ld (sfx_prio),a
.nolock:
    ld a,(sfx_wait)
    or a
    jr z,.next
    dec a
    ld (sfx_wait),a
    ret
.next:
    ld hl,(sfx_ptr)
    ld a,h
    or l
    ret z
    ld a,(hl)                   ; frames
    or a
    jr z,.stop
    dec a
    ld (sfx_wait),a
    inc hl

    xor a                       ; R0 fine tune
    ld e,(hl)
    inc hl
    call psg_wr
    ld a,1                      ; R1 coarse tune
    ld e,(hl)
    inc hl
    call psg_wr
    ld a,8                      ; R8 channel A volume
    ld e,(hl)
    inc hl
    call psg_wr

    ld (sfx_ptr),hl
    ret
.stop:
    ld a,8
    ld e,0
    call psg_wr
    ld hl,0
    ld (sfx_ptr),hl
    ret

;-----------------------------------------------------------------------
; period = 1789773 / (16 * freq)

sfx_pick:                       ; red tile collected: short rising blip
    db 2, 112,0, 13
    db 2,  84,0, 13
    db 3,  56,0, 12
    db 0,0,0,0

sfx_coin:                       ; bonus roll: the classic two note ching
    db 2, 113,0, 14
    db 4,  85,0, 13
    db 0,0,0,0

sfx_start:                      ; level start
    db 4, 213,0, 12
    db 4, 169,0, 12
    db 4, 142,0, 12
    db 8, 107,0, 13
    db 0,0,0,0

sfx_death:                      ; falling wail
    db 4, 107,0, 14
    db 4, 135,0, 14
    db 4, 169,0, 13
    db 4, 213,0, 13
    db 4, 254,0, 12
    db 4, 100,1, 12
    db 6, 200,1, 11
    db 8,  44,2, 10
    db 0,0,0,0

sfx_over:
    db 10, 107,0, 13
    db 10, 142,0, 13
    db 10, 179,0, 13
    db 30, 213,0, 12
    db 0,0,0,0

; extra life: a rising arpeggio, loud and long enough to be unmistakable
; even in the middle of the end of level coin roll
sfx_extra:
    db 4, 214,0, 15             ; C5
    db 4, 170,0, 15             ; E5
    db 4, 143,0, 15             ; G5
    db 4, 107,0, 15             ; C6
    db 4,  85,0, 15             ; E6
    db 4,  71,0, 15             ; G6
    db 4,  85,0, 15
    db 14, 53,0, 15             ; C7
    db 0,0,0,0
