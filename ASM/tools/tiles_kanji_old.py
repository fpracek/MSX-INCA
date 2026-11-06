"""Hand drawn 8x8 tiles for THE KANJI WALL.

The 14 glyphs of tiles.png (+ 2 recurring components) redrawn on a 7x7 body
with a 1px gutter right and bottom, so the wallpaper reads as separate
characters instead of merging into noise.
"""
import sys
from PIL import Image

G = [
 ("gao  高", ["...#...","#######",".#####.",".#...#.",".#####.",".#.#.#.",".#####."]),
 ("hao  号", [".#####.",".#...#.",".#####.","#######","....#..","...#...",".###..."]),
 ("jing 京", ["...#...","#######",".#####.",".#...#.",".#####.","..###..",".#.#.#."]),
 ("ming 明", ["###.###","#.#.#.#","###.###","#.#.#.#","###.###","#.#.#.#","###.#.#"]),
 ("feng 丰", ["...#...","#######","...#...",".#####.","...#...","#######","...#..."]),
 ("fan  樊", ["#.#.#.#",".#####.","#.#.#.#",".#####.","..###..",".#####.","##.#.##"]),
 ("shi  市", ["...#...","#######",".......",".#####.",".#.#.#.","...#...","..##..."]),
 ("lao  老", ["..#.#..","#######","..#.#..",".#####.",".#.....",".#.#..#","...#.##"]),
 ("yue  龠", ["..###..",".#...#.","#######","#.#.#.#","#######","#.#.#.#","#######"]),
 ("gang 崗", [".#.#.#.","#.#.#.#","#######",".#####.",".#.#.#.",".#####.",".#...#."]),
 ("cheng(呈)",[".#####.","#.###.#","#.#.#.#","#.###.#","#..#..#","#.###.#",".#####."]),
 ("er   爾", ["#######","#.#.#.#","#######","#.#.#.#","#######","##.#.##","..#.#.."]),
 ("wo   我", ["..#...#","..#.##.","######.","..#.#.#",".###.#.","..#.##.",".#.#..#"]),
 ("shi  示", [".#####.",".......","#######","...#...",".#.#.#.",".#.#.#.","#..#..#"]),
 ("tian 田", ["#######","#..#..#","#..#..#","#######","#..#..#","#..#..#","#######"]),
 ("shan 山", ["..#....","#.#...#","#.#...#","#.#...#","#.#...#","#.#...#","#######"]),
]

# pad the 7x7 body out to 8x8: gutter column on the right, gutter row below
TILES = [(n, [r + "." for r in rows] + ["........"]) for n, rows in G]


def bits(rows):
    return [[1 if c == '#' else 0 for c in r] for r in rows]


def preview(path, zoom=18):
    per = 8
    nrows = (len(TILES) + per - 1) // per
    im = Image.new("RGB", (per * 9 * zoom, nrows * 9 * zoom), (0, 0, 0))
    p = im.load()
    for i, (name, r) in enumerate(TILES):
        t = bits(r)
        ox, oy = (i % per) * 9 * zoom, (i // per) * 9 * zoom
        for y in range(8):
            for x in range(8):
                col = (215, 205, 150) if t[y][x] else (30, 26, 10)
                for dy in range(zoom):
                    for dx in range(zoom):
                        p[ox + x * zoom + dx, oy + y * zoom + dy] = col
    im.save(path)


def wall(path, zoom=4, w=32, h=20):
    import random
    random.seed(7)
    im = Image.new("RGB", (w * 8 * zoom, h * 8 * zoom), (0, 0, 0))
    p = im.load()
    for cy in range(h):
        for cx in range(w):
            t = bits(TILES[random.randrange(len(TILES))][1])
            for y in range(8):
                for x in range(8):
                    col = (204, 204, 204) if t[y][x] else (0, 0, 0)
                    for dy in range(zoom):
                        for dx in range(zoom):
                            p[(cx * 8 + x) * zoom + dx, (cy * 8 + y) * zoom + dy] = col
    im.save(path)


def emit():
    out = []
    for i, (name, r) in enumerate(TILES):
        out.append("    ; %02d  %s" % (i, name))
        for half in (0, 4):
            out.append("    db " + ",".join(
                "%" + "".join('1' if c == '#' else '0' for c in r[half + k])
                for k in range(4)))
    return "\n".join(out)


if __name__ == "__main__":
    if "--asm" in sys.argv:
        print(emit())
    else:
        preview(r"E:\TEMP\Claude\hand_tiles.png")
        wall(r"E:\TEMP\Claude\hand_wall.png")
        print("ok")
