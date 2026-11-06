;=======================================================================
; music.asm - three channel tune player, used by the title screen
;
; One stream per PSG channel, each a list of (note, frames) pairs.
;   note 0FFh = rest,  0FEh = loop back to the start of that stream
;   otherwise: high nibble = octaves above octave 3, low nibble = semitone
; Every note restarts the channel volume at its attack level and it decays
; one step every 4 frames down to the channel's sustain level, which is
; what gives the plucked charango / harp feel.
;
; The effect player owns channel A while the game runs, so the tune and the
; effects never share the PSG: mus_start takes it over, mus_stop hands it
; back.
;=======================================================================

; note byte helpers
O3 equ 000h
O4 equ 010h
O5 equ 020h
O6 equ 030h
nC  equ 0
nCS equ 1
nD  equ 2
nDS equ 3
nE  equ 4
nF  equ 5
nFS equ 6
nG  equ 7
nGS equ 8
nA  equ 9
nAS equ 10
nB  equ 11
REST equ 0FFh
LOOP equ 0FEh

; note lengths, at 18 frames to the beat
BEAT  equ 18
HALFB equ 9
BEAT2 equ 36
BEATH equ 27                    ; a beat and a half

;-----------------------------------------------------------------------
mus_start:
    xor a                       ; the tune takes the PSG over from the sfx
    ld (sfx_prio),a
    ld hl,0
    ld (sfx_ptr),hl

    ld hl,mus_a
    ld (mus_ptr+0),hl
    ld hl,mus_b
    ld (mus_ptr+2),hl
    ld hl,mus_c
    ld (mus_ptr+4),hl
    xor a
    ld (mus_wait+0),a
    ld (mus_wait+1),a
    ld (mus_wait+2),a
    ld (mus_vol+0),a
    ld (mus_vol+1),a
    ld (mus_vol+2),a

    ld a,7
    ld e,0B8h                   ; tone on all three channels, no noise
    call psg_wr
    ld a,1
    ld (mus_on),a
    ret

mus_stop:
    xor a
    ld (mus_on),a
    ld a,8
    ld e,0
    call psg_wr
    ld a,9
    ld e,0
    call psg_wr
    ld a,10
    ld e,0
    call psg_wr
    ld a,7
    ld e,0BEh                   ; back to effects on channel A alone
    jp psg_wr

;-----------------------------------------------------------------------
mus_tick:
    ld a,(mus_on)
    or a
    ret z
    ld b,0
.lp:
    push bc
    ld a,b
    call mus_chan
    pop bc
    inc b
    ld a,b
    cp 3
    jr nz,.lp
    ret

; A = channel 0..2
mus_chan:
    ld c,a
    ld b,0

    ld hl,mus_wait
    add hl,bc
    ld a,(hl)
    or a
    jr z,.newnote
    dec (hl)
    jr .decay

.newnote:
    ld hl,mus_ptr
    add hl,bc
    add hl,bc
    ld e,(hl)
    inc hl
    ld d,(hl)                   ; DE = stream position
    ld a,(de)
    cp LOOP
    jr nz,.gotnote
    ld hl,mus_head              ; rewind this stream
    add hl,bc
    add hl,bc
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld a,(de)
.gotnote:
    inc de
    push af                     ; the note
    ld a,(de)                   ; its length
    inc de
    ld hl,mus_wait
    add hl,bc
    ld (hl),a
    ld hl,mus_ptr
    add hl,bc
    add hl,bc
    ld (hl),e
    inc hl
    ld (hl),d
    pop af

    cp REST
    jr z,.rest

    call note_period            ; HL = period, BC kept
    ld a,c
    add a,a                     ; fine tune register of this channel
    ld e,l
    push hl
    push bc
    call psg_wr
    pop bc
    pop hl
    ld a,c
    add a,a
    inc a                       ; coarse tune register
    ld e,h
    push bc
    call psg_wr
    pop bc

    ld hl,mus_atk               ; restart the envelope
    add hl,bc
    ld a,(hl)
    ld hl,mus_vol
    add hl,bc
    ld (hl),a
    jr .decay

.rest:
    ld hl,mus_vol
    add hl,bc
    ld (hl),0

.decay:
    ld hl,mus_vol
    add hl,bc
    ld a,(hl)
    or a
    jr z,.setvol
    ld d,a
    ld hl,mus_sus
    add hl,bc
    ld a,(hl)
    cp d
    jr nc,.setvol               ; already down at the sustain level
    ld a,(frame_cnt)
    and 3
    jr nz,.setvol
    ld hl,mus_vol
    add hl,bc
    dec (hl)
.setvol:
    ld hl,mus_vol
    add hl,bc
    ld e,(hl)
    ld a,c
    add a,8                     ; volume register of this channel
    jp psg_wr

;-----------------------------------------------------------------------
; A = note byte -> HL = PSG period.  Preserves BC.
note_period:
    push bc
    ld c,a
    and 00Fh
    add a,a
    ld e,a
    ld d,0
    ld hl,per_tab
    add hl,de
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a                      ; HL = the octave 3 period
    ld a,c
    rrca
    rrca
    rrca
    rrca
    and 00Fh
    jr z,.done
    ld b,a
.shift:
    srl h                       ; one octave up halves the period
    rr l
    djnz .shift
.done:
    pop bc
    ret

; octave 3, period = 1789772.5 / (16 * frequency)
per_tab:
    dw 855, 807, 762, 719, 679, 641, 605, 571, 539, 508, 480, 453

mus_head:
    dw mus_a, mus_b, mus_c
mus_atk:
    db 13, 12, 9                ; melody, bass, pad
mus_sus:
    db 11, 6, 7

;-----------------------------------------------------------------------
; A minor pentatonic, 24 beats round.  The melody keeps falling and the
; bass walks A - G - F - E, which is what makes it sound Andean.
;-----------------------------------------------------------------------
; channel A: the quena line
mus_a:
    db O5+nE,BEATH,  O5+nD,HALFB,  O5+nC,BEAT,   O5+nD,BEAT
    db O5+nC,BEAT,   O4+nA,BEAT2,  REST,BEAT
    db O5+nC,BEAT,   O5+nD,HALFB,  O5+nE,HALFB,  O5+nG,BEAT
    db O5+nE,BEAT2,  O5+nD,BEAT,   O5+nC,BEAT,   REST,BEAT
    db O5+nA,BEAT
    db O5+nG,HALFB,  O5+nE,HALFB,  O5+nD,BEAT,   O5+nC,BEAT
    db O4+nA,BEAT2,  O4+nE,HALFB,  O4+nG,HALFB,  O4+nA,BEAT
    db LOOP

; channel B: walking bass, one chord every four beats
mus_b:
    db O3+nA,BEAT, REST,HALFB, O3+nA,BEAT, REST,HALFB, O3+nA,BEAT
    db O3+nG,BEAT, REST,HALFB, O3+nG,BEAT, REST,HALFB, O3+nG,BEAT
    db O3+nF,BEAT, REST,HALFB, O3+nF,BEAT, REST,HALFB, O3+nF,BEAT
    db O3+nE,BEAT, REST,HALFB, O3+nE,BEAT, REST,HALFB, O3+nE,BEAT
    db O3+nA,BEAT, REST,HALFB, O3+nA,BEAT, REST,HALFB, O3+nA,BEAT
    db O3+nE,BEAT, REST,HALFB, O3+nE,BEAT, REST,HALFB, O3+nE,BEAT
    db LOOP

; channel C: one held chord tone under each bass chord
mus_c:
    db O4+nE,72
    db O4+nD,72
    db O4+nC,72
    db O3+nB,72
    db O4+nE,72
    db O3+nB,72
    db LOOP
