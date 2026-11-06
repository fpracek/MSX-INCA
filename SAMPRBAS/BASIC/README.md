# THE INCA WALL - SamPr Basic version (MSX-DOS .COM)

The whole game in BASIC, compiled to Z80 machine code by [SamPr Basic](https://github.com/fpracek/MSX-SAMPRBASIC) (the compiler runs on the MSX itself,
or from the VS Code extension). Same game as the assembly original in [`../../ASM`](../../ASM): the 16x10 wall of random 16x16 stones, 3-5 black rooms,
level + 4 red chakanas, four guardians with four behaviours (chase, chase on the longer axis, bounce, sweep) at 4.4 fixed point speed, 90 seconds
a level with the shrinking bar, 3 lives, free life every 10000 points, bonus for the seconds saved, the title tune on the three PSG channels and the sound effects.

| File | |
|---|---|
| `INCABAS.SPB` | the source (11.4 KB: the DOS compiler takes 12.5 KB, so the comments are kept to a minimum) |
| `INCABAS_commented.txt` | the same program with comments and indentation (does not fit in the compiler as it is) |
| `INCABAS.COM` | the compiled program: copy it to an MSX-DOS disk and run `INCABAS` |

Controls: cursor keys or joystick 1, SPACE / fire to start.

## Build
Open `INCABAS.SPB` in the SamPr Basic editor and press F5, or compile it with the VS Code extension (SamPr Basic 1.4.0 or newer).

## Notes
* The graphics (stones, chakana, bar, life icon, sprites) and the tune are stored in `DATA` strings, 6 bits per character, and decoded at start: they are
  the bytes of the original ROM, so the picture is identical.
* A DOS program has 100 names (variables, constants, arrays, labels): the state is in small arrays and there is only one `GOSUB` per job.
* `PUT SPRITE` costs about 430 us, so the five sprite planes are written once per frame and rotate on every frame like in the original (five sprites on a
  line flicker instead of one vanishing for good).

## ROM cartridge version (`ROM/`)
The same game as an ASCII8 cartridge (`OPTION TARGET ROM_ASCII8`). A ROM program has less room in its first segment than a DOS one, so the routines of the
`GOSUB` program became `SUB`s spread over three segments (`INCAR001`-`INCAR003.SPB`) and segment 0 (`INCAR000.SPB`) keeps the `DATA` and the main loop.
The variables are shared with `SHARED`; the game, graphics, tune and sound effects are the same. These sources have comments and indentation (a multi-file
cartridge is not limited by the 12.5 KB of the DOS compiler).

| File | |
|---|---|
| `ROM/INCAR000.SPB` .. `INCAR003.SPB` | the sources, one file per segment |
| `ROM/INCAR.ROM` | the cartridge, 64 KB (the compiler output of 40 KB padded with zeros, for flash cartridges): `openmsx -cart INCAR.ROM -romtype ASCII8` |

To rebuild: open `INCAR000.SPB` in SamPr Basic and press F5 (SamPr Basic 1.4.1 or newer).

## No BIN of this version
A BIN program for MSX-BASIC (`OPTION TARGET BIN`) is loaded at 8400h and has about 19 KB up to the data RAM at D000h: the runtime takes 11 KB and this game
needs about 12 KB of code, so it does not fit. The compact assembly version in [`../ASM/BIN`](../ASM/BIN) does.
