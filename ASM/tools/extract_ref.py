"""Extract the 14 kanji glyphs from tiles.png into 8x8 MSX SCREEN 1 patterns.

The source is a 147x44 gold-relief strip: 2 rows x 7 glyphs, 21x22 px each.
Pipeline: luminance threshold -> 3x3 median denoise -> per-glyph area
downsample to 8x8 -> per-glyph threshold chosen to hit a target ink ratio.
"""
import sys
from PIL import Image

SRC = r"E:\TEMP\tiles.png"
COLS, ROWS = 7, 2


def lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def load_mask(thr, denoise=True):
    im = Image.open(SRC).convert("RGB")
    w, h = im.size
    px = im.load()
    m = [[1 if lum(px[x, y]) > thr else 0 for x in range(w)] for y in range(h)]
    if denoise:
        n = [row[:] for row in m]
        for y in range(h):
            for x in range(w):
                s = 0
                c = 0
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w:
                            s += m[yy][xx]
                            c += 1
                n[y][x] = 1 if s * 2 > c else 0
        m = n
    return m, w, h


def downsample(mask, x0, y0, cw, ch, target):
    cov = []
    for gy in range(8):
        row = []
        for gx in range(8):
            xa, xb = x0 + cw * gx // 8, x0 + cw * (gx + 1) // 8
            ya, yb = y0 + ch * gy // 8, y0 + ch * (gy + 1) // 8
            xb, yb = max(xb, xa + 1), max(yb, ya + 1)
            n = (xb - xa) * (yb - ya)
            s = sum(mask[y][x] for y in range(ya, yb) for x in range(xa, xb))
            row.append(s / n)
        cov.append(row)
    flat = sorted((c for r in cov for c in r), reverse=True)
    want = max(1, min(64, int(round(64 * target))))
    thr = max(flat[want - 1], 0.10)
    return [[1 if cov[y][x] >= thr else 0 for x in range(8)] for y in range(8)]


def extract(pix_thr, target, denoise=True):
    mask, w, h = load_mask(pix_thr, denoise)
    cw, ch = w // COLS, h // ROWS
    return [downsample(mask, c * cw, r * ch, cw, ch, target)
            for r in range(ROWS) for c in range(COLS)]


def preview(tiles, path, zoom=18):
    per = 8
    rows = (len(tiles) + per - 1) // per
    prev = Image.new("RGB", (per * 9 * zoom, rows * 9 * zoom), (0, 0, 0))
    p = prev.load()
    for i, t in enumerate(tiles):
        ox, oy = (i % per) * 9 * zoom, (i // per) * 9 * zoom
        for y in range(8):
            for x in range(8):
                col = (200, 200, 200) if t[y][x] else (16, 16, 16)
                for dy in range(zoom):
                    for dx in range(zoom):
                        p[ox + x * zoom + dx, oy + y * zoom + dy] = col
    prev.save(path)


def emit(tiles):
    out = []
    for i, t in enumerate(tiles):
        out.append("    ; %02d" % i)
        for half in (0, 4):
            out.append("    db " + ",".join(
                "%" + "".join(str(v) for v in t[half + k]) for k in range(4)))
    return "\n".join(out)


if __name__ == "__main__":
    if "--sweep" in sys.argv:
        for pt in (140, 155, 170, 185):
            for tg in (0.35, 0.45):
                tiles = extract(pt, tg)
                preview(tiles, r"E:\TEMP\Claude\sweep_%d_%d.png" % (pt, tg * 100))
        print("sweep saved")
    else:
        pt = float(sys.argv[1]) if len(sys.argv) > 1 else 160
        tg = float(sys.argv[2]) if len(sys.argv) > 2 else 0.40
        tiles = extract(pt, tg)
        if "--asm" in sys.argv:
            print(emit(tiles))
        else:
            preview(tiles, r"E:\TEMP\Claude\tiles_8x8.png")
            for i, t in enumerate(tiles):
                print("tile %02d" % i)
                for row in t:
                    print("  " + "".join("#" if v else "." for v in row))
