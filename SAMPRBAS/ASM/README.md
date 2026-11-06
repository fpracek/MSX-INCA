# THE INCA WALL - compact assembly version (`OPTION ASM`, MSX-DOS .COM)

The second way of using SamPr Basic: a file whose first line is `OPTION ASM` is pure Z80 assembly, assembled by QASM.OVL and made into a `.COM`
by the same compiler, editor (Tab, F5) and debugger-free workflow as the BASIC programs. Here it is the whole game: title, wall with random stones and
black rooms, level + 4 chakanas, four guardians (chase / chase on the longer axis / bounce / sweep), 90 seconds per level with the bar, 3 lives, levels
that get faster, BIOS font for the texts, 16x16 sprites, BIOS keyboard/joystick (cursor keys, joystick 1, SPACE / fire).

It is **compact** on purpose: the whole block must fit in the inline assembler (about 1900 bytes of machine code, graphics included), so compared with
the original ROM and with the [BASIC version](../BASIC) it has 3 stone motifs instead of 8, two sprite frames instead of four, no music or sound, no hi score,
bonus or extra life, and the guardians move whole pixels on some frames (speed 4/8 to 7/8 pixel per frame) instead of 4.4 fixed point.

| File | |
|---|---|
| `INCA.COM` | the compiled program: copy it to an MSX-DOS disk and run `INCA` |
| `INCA.SPB` | the source for SamPr Basic (`OPTION ASM`, generated, see below) |
| `INCA_source.asm` | the readable source: comments, numeric local labels (`1:`, `jr nz,1b`), variables as `@name`, macros `TXT` and `GFX` |
| `gen.py` | turns `INCA_source.asm` into `INCA.SPB` |
| `gfx.bin` | 192 bytes: 3 stone motifs (4 quarters each), the chakana and one sprite pattern of the player and of the guardians, taken from the original ROM |

## Why a generator
QASM.OVL has no local labels, keeps at most 64 symbols per block and counts every label, and the source must stay under 12.5 KB (comments included) after the
bytes are written as text. So `gen.py` (it needs [sjasmplus](https://github.com/z00m128/sjasmplus) to learn the length of every instruction) writes:
* every numeric local label as a relative jump `jr nz,$-7`;
* every label starting with `_` (data and tables) as `previous_real_label+offset`;
* every variable `@name` as `v+offset`, and the macros `TXT row,col,"text"` (screen address + text) and `GFX` (the bytes of `gfx.bin`);
* no comments, no indentation, hex numbers as decimal when shorter.

Set `SJASMPLUS` to the sjasmplus executable (or have it in the PATH) and run `python gen.py` to rebuild `INCA.SPB`.

## Build with SamPr Basic
Open `INCA.SPB` in the editor and press F5. This program needs more room than the first releases give an assembler block (the output buffer of QASM.OVL
was 7936 characters, enough for about 1600 bytes): **SamPr Basic 1.4.1 or newer**, or the `QASM.OVL` of the development tree (`VARS equ 9400h`, `TMP equ VARS+0800h`,
8960 characters), is needed to compile it. The prebuilt `INCA.COM` runs anywhere.
