;=======================================================================
; data.asm - patterns, colours, sprites, strings
;=======================================================================

;-----------------------------------------------------------------------
; The wall: Inca dry stone masonry, 8 motifs of 16x16 px, each one a 2x2
; block of characters, 1 px of mortar all around (2 px between neighbours).
;
; Relief: the four quadrants of a stone are in four different colour
; groups.  The ink is black everywhere, only the face tone changes - light
; yellow on the upper half, dark red on the lower half - so every stone
; reads as lit from above.  Hence the layout below: all eight top-left
; quadrants first, then all the top-rights, and so on, one colour group
; each.  Motif i is at CH_TILE+i and its quadrants are 8 characters apart.
;
; Drawing source (ASCII art): tools\tiles.py -> python tools\tiles.py --asm
tile_pat:
    ; ---- TL of every motif (one colour group) ----
    ; 0 liscia   plain block
    db %11111111,%10000000,%10000000,%10000000
    db %10000000,%10000000,%10000000,%10000001
    ; 1 greca    stepped fret
    db %11111111,%10000000,%10011111,%10011111
    db %10011000,%10011001,%10011001,%10011001
    ; 2 chakana  stepped cross
    db %11111111,%10000000,%10000001,%10000001
    db %10000111,%10000111,%10011111,%10011111
    ; 3 doppia H two stones stacked
    db %11111111,%10000000,%10000000,%10000000
    db %10000000,%10000000,%11111111,%11111111
    ; 4 doppia V two stones side by side
    db %11111111,%10000001,%10000001,%10000001
    db %10000001,%10000001,%10000001,%10000001
    ; 5 terrazza terrace
    db %11111111,%10000000,%10000000,%10000000
    db %10000000,%10000001,%10000001,%10011111
    ; 6 nicchia  trapezoidal niche
    db %11111111,%10000000,%10000111,%10000111
    db %10001100,%10001100,%10011000,%10011000
    ; 7 greca R  mirrored fret
    db %11111111,%10000000,%10011111,%10011111
    db %10011000,%10011111,%10011111,%10000001
    ; ---- TR of every motif (one colour group) ----
    ; 0 liscia   plain block
    db %11111111,%00000001,%00000001,%00000001
    db %00000001,%00000001,%00000001,%10000001
    ; 1 greca    stepped fret
    db %11111111,%00000001,%11111001,%11111001
    db %00011001,%11111001,%11111001,%10000001
    ; 2 chakana  stepped cross
    db %11111111,%00000001,%11100001,%11100001
    db %11111001,%11111001,%11111111,%11111111
    ; 3 doppia H two stones stacked
    db %11111111,%00000001,%00000001,%00000001
    db %00000001,%00000001,%11111111,%11111111
    ; 4 doppia V two stones side by side
    db %11111111,%10000001,%10000001,%10000001
    db %10000001,%10000001,%10000001,%10000001
    ; 5 terrazza terrace
    db %11111111,%00000001,%00000001,%00011111
    db %00011111,%11111111,%11111111,%11111111
    ; 6 nicchia  trapezoidal niche
    db %11111111,%00000001,%11111001,%11111001
    db %00001101,%00001101,%00000111,%00000111
    ; 7 greca R  mirrored fret
    db %11111111,%00000001,%11111001,%11111001
    db %00011001,%10011001,%10011001,%10011001
    ; ---- BL of every motif (one colour group) ----
    ; 0 liscia   plain block
    db %10000001,%10000000,%10000000,%10000000
    db %10000000,%10000000,%10000000,%11111111
    ; 1 greca    stepped fret
    db %10011001,%10011001,%10011001,%10011000
    db %10011111,%10011111,%10000000,%11111111
    ; 2 chakana  stepped cross
    db %10000111,%10000111,%10000001,%10000001
    db %10000000,%10000000,%10000000,%11111111
    ; 3 doppia H two stones stacked
    db %10000000,%10000000,%10000000,%10000000
    db %10000000,%10000000,%10000000,%11111111
    ; 4 doppia V two stones side by side
    db %10000001,%10000001,%10000001,%10000001
    db %10000001,%10000001,%10000001,%11111111
    ; 5 terrazza terrace
    db %10011111,%10000000,%10000000,%10000000
    db %10000000,%10000000,%10000000,%11111111
    ; 6 nicchia  trapezoidal niche
    db %10011000,%10011000,%10011111,%10011111
    db %10000000,%10000000,%10000000,%11111111
    ; 7 greca R  mirrored fret
    db %10000001,%10011111,%10011111,%10000000
    db %10011111,%10011111,%10000000,%11111111
    ; ---- BR of every motif (one colour group) ----
    ; 0 liscia   plain block
    db %10000001,%00000001,%00000001,%00000001
    db %00000001,%00000001,%00000001,%11111111
    ; 1 greca    stepped fret
    db %10000001,%11111001,%11111001,%00000001
    db %11111001,%11111001,%00000001,%11111111
    ; 2 chakana  stepped cross
    db %11111001,%11111001,%11100001,%11100001
    db %00000001,%00000001,%00000001,%11111111
    ; 3 doppia H two stones stacked
    db %00000001,%00000001,%00000001,%00000001
    db %00000001,%00000001,%00000001,%11111111
    ; 4 doppia V two stones side by side
    db %10000001,%10000001,%10000001,%10000001
    db %10000001,%10000001,%10000001,%11111111
    ; 5 terrazza terrace
    db %11111111,%00000001,%00000001,%00000001
    db %00000001,%00000001,%00000001,%11111111
    ; 6 nicchia  trapezoidal niche
    db %00000111,%00000111,%11111111,%11111111
    db %00000001,%00000001,%00000001,%11111111
    ; 7 greca R  mirrored fret
    db %10011001,%10011001,%10011001,%00011001
    db %11111001,%11111001,%00000001,%11111111

;-----------------------------------------------------------------------
; The pickup: a chakana, 16x16, solid red on black and no mortar - it lies
; loose inside a black room rather than being part of the wall, and it is
; always the same shape so it always reads as "take me".
red_pat:
    ; TL
    db %00000000,%00000000,%00000011,%00000011
    db %00001111,%00001111,%01111000,%01111000
    ; TR
    db %00000000,%00000000,%11000000,%11000000
    db %11110000,%11110000,%00011110,%00011110
    ; BL
    db %01111000,%01111000,%00001111,%00001111
    db %00000011,%00000011,%00000000,%00000000
    ; BR
    db %00011110,%00011110,%11110000,%11110000
    db %11000000,%11000000,%00000000,%00000000

;-----------------------------------------------------------------------
; timer bar: 8 fill levels, 6 pixels tall
    MACRO BARPAT m?
    db 0, m?, m?, m?, m?, m?, m?, 0
    ENDM

bar_pat:
    BARPAT %10000000
    BARPAT %11000000
    BARPAT %11100000
    BARPAT %11110000
    BARPAT %11111000
    BARPAT %11111100
    BARPAT %11111110
    BARPAT %11111111

;-----------------------------------------------------------------------
life_pat:
    db %00111100,%01111110,%11011011,%11111111
    db %11011011,%01111110,%00111100,%00000000

;-----------------------------------------------------------------------
; SCREEN 1 colour table: one byte per group of 8 patterns
col_tab:
    db 011h                     ; 00-07 blank          black on black
    ; the wall: black grooves on a stone face, lit above and shaded below
    db 01Bh                     ; 08-0F stone TL       black on light yellow
    db 01Bh                     ; 10-17 stone TR       black on light yellow
    db 016h                     ; 18-1F stone BL       black on dark red
    db 016h                     ; 20-27 stone BR       black on dark red
    db 091h                     ; 28-2F chakana        light red on black
    db 031h                     ; 30-37 timer bar      (rewritten at runtime)
    db 0F1h,0F1h,0F1h,0F1h      ; 38-57 font
    db 0F1h,0F1h,0F1h,0F1h      ; 58-77 font
    db 0B1h                     ; 78-7F life icon      light yellow
    db 0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
    db 0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h

;-----------------------------------------------------------------------
; 16x16 sprites, stored the way the VDP wants them: the 16 rows of the
; left half first, then the 16 rows of the right half.
; The shape of each row is in the comment next to it.
spr_pat:
;--- sprite pattern 0 : player, frame A -------------------------------
    db 000h,007h,00Fh,019h,019h,01Fh,01Ch,00Fh    ; ........ .....### ....####
    db 007h,01Fh,03Fh,037h,037h,007h,00Ch,01Ch
    db 000h,0E0h,0F0h,098h,098h,0F8h,038h,0F0h
    db 0E0h,0F8h,0FCh,0ECh,0ECh,0E0h,030h,038h
;--- sprite pattern 4 : player, frame B (legs together) ---------------
    db 000h,007h,00Fh,019h,019h,01Fh,01Ch,00Fh
    db 007h,01Fh,03Fh,037h,037h,007h,00Eh,038h
    db 000h,0E0h,0F0h,098h,098h,0F8h,038h,0F0h
    db 0E0h,0F8h,0FCh,0ECh,0ECh,0E0h,070h,01Ch
;--- sprite pattern 8 : guardian, frame A -----------------------------
    db 000h,003h,00Fh,01Fh,03Dh,03Bh,07Fh,07Fh
    db 078h,07Dh,03Fh,03Fh,01Fh,00Dh,018h,030h
    db 000h,0C0h,0F0h,0F8h,0BCh,0DCh,0FEh,0FEh
    db 01Eh,0BEh,0FCh,0FCh,0F8h,0B0h,018h,00Ch
;--- sprite pattern 12 : guardian, frame B ----------------------------
    db 000h,003h,00Fh,01Fh,03Bh,03Dh,07Fh,07Fh
    db 078h,07Dh,03Fh,03Fh,01Fh,00Fh,00Ch,006h
    db 000h,0C0h,0F0h,0F8h,0DCh,0BCh,0FEh,0FEh
    db 01Eh,0BEh,0FCh,0FCh,0F8h,0F0h,030h,060h
spr_pat_end:

;-----------------------------------------------------------------------
txt_title:  db "THE INCA WALL",0
txt_help1:  db "TAKE ALL THE RED CHAKANAS",0
txt_help2:  db "AVOID THE GUARDIANS",0
txt_help3:  db "PUSH SPACE OR TRIGGER",0
txt_blank:  db "                     ",0
txt_hi:     db "HI",0
txt_copy:   db "(C) 2026 F.PRACEK",0
; shown through msg_show: the font is white on black, so the characters
; bring their own black box and only their own cells touch the wall
txt_ready:  db "READY!",0
txt_over:   db "GAME OVER",0
