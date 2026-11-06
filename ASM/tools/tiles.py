"""Wall artwork for THE INCA WALL.

Inca dry stone masonry, 8 motifs of 16x16 pixels, each one a 2x2 block of
SCREEN 1 characters.

Relief.  A SCREEN 1 character has exactly two colours and they are shared
by a whole group of 8 patterns, so one stone cannot hold a highlight, a
face and a shadow.  Instead the four quadrants of every stone live in four
DIFFERENT colour groups, and the ink stays black everywhere while the FACE
tone changes:

    TL -> CH_TILE+0  .. +7    light yellow face, black grooves   (lit)
    TR -> CH_TILE+8  .. +15   light yellow face, black grooves   (lit)
    BL -> CH_TILE+16 .. +23   dark red face,     black grooves   (shaded)
    BR -> CH_TILE+24 .. +31   dark red face,     black grooves   (shaded)

Every stone is therefore lit on its upper half and in shadow on its lower
half.  Motif i sits at CH_TILE+i, its quadrants 8 characters apart.

The shaded tone has to be dark red (6), not dark yellow (10): on a real
MSX 10 and 11 are almost the same brightness and the relief vanishes.

Geometry.  '#' is a groove cut into the stone, '.' is the stone face.
Mortar is 1 px on all four sides of a block, so between two neighbours it
adds up to a uniform 2 px.  Making it thicker on one side buys nothing:
the mortar of two adjacent stones is one continuous black line, so the
asymmetry is invisible - only the face tone can carry the relief.
"""
import sys
from PIL import Image

# 14x14 carved face; the tool adds the 2 px mortar on right and bottom
INTERIOR = [
("liscia   plain block", [
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
 "......##......",
 "......##......",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
]),
("greca    stepped fret", [
 "..............",
 "..##########..",
 "..##########..",
 "..##......##..",
 "..##..######..",
 "..##..######..",
 "..##..##......",
 "..##..##......",
 "..##..######..",
 "..##..######..",
 "..##..........",
 "..##########..",
 "..##########..",
 "..............",
]),
("chakana  stepped cross", [
 "..............",
 "......####....",
 "......####....",
 "....########..",
 "....########..",
 "..############",
 "..############",
 "....########..",
 "....########..",
 "......####....",
 "......####....",
 "..............",
 "..............",
 "..............",
]),
("doppia H two stones stacked", [
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
 "##############",
 "##############",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
]),
("doppia V two stones side by side", [
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
 "......##......",
]),
("terrazza terrace", [
 "..............",
 "..............",
 "..........####",
 "..........####",
 "......########",
 "......########",
 "..############",
 "..############",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
 "..............",
]),
("nicchia  trapezoidal niche", [
 "..............",
 "....########..",
 "....########..",
 "...##......##.",
 "...##......##.",
 "..##........##",
 "..##........##",
 "..##........##",
 "..##........##",
 "..############",
 "..############",
 "..............",
 "..............",
 "..............",
]),
("greca R  mirrored fret", [
 "..............",
 "..##########..",
 "..##########..",
 "..##......##..",
 "..######..##..",
 "..######..##..",
 "......##..##..",
 "......##..##..",
 "..######..##..",
 "..######..##..",
 "..........##..",
 "..##########..",
 "..##########..",
 "..............",
]),
]


def build(rows):
    """14x14 face -> 16x16 block with 1 px of mortar all around"""
    return ["#" * 16] + ["#" + r + "#" for r in rows] + ["#" * 16]


MOTIFS = [(n, build(r)) for n, r in INTERIOR]

# The pickup is a raised object lying in a black room, not part of the wall:
# solid ink on black, no mortar, always the same shape so it always reads.
COLLECT = ("chakana rossa  the pickup", [
 "................",
 "................",
 "......####......",
 "......####......",
 "....########....",
 "....########....",
 ".####......####.",
 ".####......####.",
 ".####......####.",
 ".####......####.",
 "....########....",
 "....########....",
 "......####......",
 "......####......",
 "................",
 "................",
])

# real MSX1 palette entries, so the preview does not lie about the contrast
MSX = {1: (0, 0, 0), 3: (116, 208, 125), 6: (185, 94, 81), 7: (101, 219, 239),
       9: (255, 137, 125), 10: (204, 195, 94), 11: (222, 208, 135),
       13: (183, 102, 181), 15: (255, 255, 255)}

# light from above: upper half of every stone lit, lower half in shadow
FACE = {"TL": 11, "TR": 11, "BL": 6, "BR": 6}
GROOVE = MSX[1]
RED = MSX[9]


def bits(rows):
    return [[1 if c == '#' else 0 for c in r] for r in rows]


def quad(rows):
    return [[[bits(rows)[oy + y][ox + x] for x in range(8)] for y in range(8)]
            for oy in (0, 8) for ox in (0, 8)]


def face(x, y):
    q = ("TL", "TR", "BL", "BR")[(1 if y >= 8 else 0) * 2 + (1 if x >= 8 else 0)]
    return MSX[FACE[q]]


def preview(path, zoom=10):
    per = 4
    nrows = (len(MOTIFS) + per - 1) // per
    im = Image.new("RGB", (per * 18 * zoom, nrows * 18 * zoom), (24, 24, 24))
    p = im.load()
    for i, (name, rows) in enumerate(MOTIFS):
        b = bits(rows)
        ox, oy = (i % per) * 18 * zoom, (i // per) * 18 * zoom
        for y in range(16):
            for x in range(16):
                col = GROOVE if b[y][x] else face(x, y)
                for dy in range(zoom):
                    for dx in range(zoom):
                        p[ox + x * zoom + dx, oy + y * zoom + dy] = col
    im.save(path)


def wall(path, zoom=3, bw=16, bh=10):
    import random
    random.seed(3)
    im = Image.new("RGB", (bw * 16 * zoom, bh * 16 * zoom), GROOVE)
    p = im.load()
    room = {(4, 3), (5, 3), (6, 3), (4, 4), (5, 4), (6, 4),
            (10, 6), (11, 6), (10, 7), (11, 7)}
    red = {(5, 3), (11, 6)}
    for by in range(bh):
        for bx in range(bw):
            if (bx, by) in room and (bx, by) not in red:
                continue
            pick = (bx, by) in red
            b = bits(COLLECT[1] if pick else
                     MOTIFS[random.randrange(len(MOTIFS))][1])
            for y in range(16):
                for x in range(16):
                    if pick:
                        if not b[y][x]:
                            continue
                        col = RED
                    else:
                        col = GROOVE if b[y][x] else face(x, y)
                    for dy in range(zoom):
                        for dx in range(zoom):
                            p[(bx * 16 + x) * zoom + dx,
                              (by * 16 + y) * zoom + dy] = col
    im.save(path)


def emit_wall():
    """all 8 TL patterns, then all 8 TR, then BL, then BR: one colour group each"""
    out = []
    for qi, tag in enumerate(("TL", "TR", "BL", "BR")):
        out.append("    ; ---- %s of every motif (one colour group) ----" % tag)
        for i, (name, rows) in enumerate(MOTIFS):
            pat = quad(rows)[qi]
            out.append("    ; %d %s" % (i, name))
            for half in (0, 4):
                out.append("    db " + ",".join(
                    "%" + "".join(str(v) for v in pat[half + k]) for k in range(4)))
    return "\n".join(out)


def emit_red():
    out = []
    for tag, pat in zip(("TL", "TR", "BL", "BR"), quad(COLLECT[1])):
        out.append("    ; %s" % tag)
        for half in (0, 4):
            out.append("    db " + ",".join(
                "%" + "".join(str(v) for v in pat[half + k]) for k in range(4)))
    return "\n".join(out)


if __name__ == "__main__":
    if "--asm" in sys.argv:
        print(emit_wall())
        print(emit_red())
    else:
        preview(r"E:\TEMP\Claude\inca_tiles.png")
        wall(r"E:\TEMP\Claude\inca_wall.png")
        print("ok")
