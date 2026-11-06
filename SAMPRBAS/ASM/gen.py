#!/usr/bin/env python3
"""Turns the readable assembly source (INCA_source.asm) into INCA.SPB, a SamPr Basic 'OPTION ASM' file.

The SamPr inline assembler (QASM.OVL) keeps at most 64 symbols and has no local labels, so this tool does the bookkeeping:
  * numeric local labels  '1:' / 'jr nz,1b' / 'jr 1f'  become  'jr nz,$-7'  (relative to the instruction itself)
  * labels that start with '_' become  'base+offset'  where base is the nearest real label before them
  * '@name' is a variable of the data area (the ';VAR name offset' lines), written as 'v+offset'
  * 'TXT row,col,"text"' and 'GFX' are macros (screen address of a text, packed graphics)
  * 'a : b : c' on one line is split into one statement per line, comments are dropped
The offsets are taken from a sjasmplus assembly of the same text (it knows every instruction length)."""
import os, re, subprocess, sys, tempfile
SJ = os.environ.get('SJASMPLUS', 'sjasmplus')          # the sjasmplus executable
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'INCA_source.asm')
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'INCA.SPB')


def enc(b):
    b = bytes(b) + bytes((-len(b)) % 3)
    out = ''
    for i in range(0, len(b), 3):
        x, y, z = b[i:i + 3]
        v = (x << 16) | (y << 8) | z
        out += ''.join(chr(48 + ((v >> s) & 63)) for s in (18, 12, 6, 0))
    return out


def gfx_lines():
    """gfx.bin: 3 stone motifs (the four quarters as groups of 3 characters), the chakana and the first sprite of the player and of the guardians"""
    d = open(os.path.join(HERE, 'gfx.bin'), 'rb').read()
    return ['db ' + ','.join(str(x) for x in d[i:i + 16]) for i in range(0, len(d), 16)], len(d)


def split_stmts(line):
    parts, cur, q = [], '', False
    i = 0
    while i < len(line):
        c = line[i]
        if c == '"':
            q = not q
        if c == ';' and not q:
            break
        if not q and line[i:i + 3] == ' : ':
            parts.append(cur.strip()); cur = ''; i += 3; continue
        cur += c
        i += 1
    parts.append(cur.strip())
    return [p for p in parts if p]


def main():
    lines = open(SRC, encoding='utf-8').read().split('\n')
    var = {}
    stmts = []                                # (kind, text): kind 'lab', 'ins'
    for ln in lines:
        m = re.match(r';VAR\s+(\w+)\s+(\d+)', ln)
        if m:
            var[m.group(1)] = int(m.group(2))
            continue
        for st in split_stmts(ln):
            # a label in front of an instruction
            while True:
                m = re.match(r'^(\d|[A-Za-z_]\w*):\s*(.*)$', st)
                if not m:
                    break
                stmts.append(('lab', m.group(1)))
                st = m.group(2).strip()
                if not st:
                    break
            if st:
                stmts.append(('ins', st))
    # macros and variables
    out = []
    glen = 0
    for kind, st in stmts:
        if kind == 'ins':
            m = re.match(r'TXT\s+(\d+),(\d+),(".*")$', st)
            if m:
                out.append(('ins', 'dw %d' % (6144 + int(m.group(1)) * 32 + int(m.group(2)))))
                out.append(('ins', 'db %s,0' % m.group(3)))
                continue
            if st == 'GFX':
                gl, glen = gfx_lines()
                out += [('ins', g) for g in gl]
                continue
            st = re.sub(r'@(\w+)', lambda m: 'v+%d' % var[m.group(1)], st)
            out.append(('ins', st))
        else:
            out.append((kind, st))
    # stage 1: every numeric label gets a unique name, every reference too
    s1, cnt = [], 0
    numdefs = []                              # list of (index in s1 label list, number)
    refs = []                                 # (ref id, tgt label id)
    deflist = {}                              # number -> list of def ids in order
    items = []                                # final items: ('lab', name) / ('ins', text, refinfo)
    defid = 0
    # first pass: assign ids to numeric definitions
    nd = []
    for kind, st in out:
        if kind == 'lab' and st.isdigit():
            nd.append((len(items), int(st), defid)); items.append(('numlab', int(st), defid)); defid += 1
        else:
            items.append((kind, st))
    # resolve references
    res = []
    for idx, it in enumerate(items):
        if it[0] != 'ins':
            res.append(it); continue
        st = it[1]
        m = re.search(r'\b(\d)([bf])\b(?![^"]*"[^"]*$)', st)
        if m and not st.startswith('db') and not st.startswith('dw'):
            n, d = int(m.group(1)), m.group(2)
            tgt = None
            if d == 'b':
                for j in range(idx - 1, -1, -1):
                    if items[j][0] == 'numlab' and items[j][1] == n:
                        tgt = items[j][2]; break
            else:
                for j in range(idx + 1, len(items)):
                    if items[j][0] == 'numlab' and items[j][1] == n:
                        tgt = items[j][2]; break
            assert tgt is not None, st
            res.append(('insref', st, m.group(0), tgt, len(refs)))
            refs.append(tgt)
        else:
            res.append(it)
    # emit stage-1 source for sjasmplus
    src1 = ['        org 100h']
    for it in res:
        if it[0] == 'lab':
            src1.append(it[1] + ':')
        elif it[0] == 'numlab':
            src1.append('N%d:' % it[2])
        elif it[0] == 'ins':
            src1.append('        ' + it[1])
        else:
            src1.append('R%d:' % it[4])
            src1.append('        ' + it[1].replace(it[2], 'N%d' % it[3]))
    d = tempfile.mkdtemp()
    p1 = os.path.join(d, 'a.asm')
    open(p1, 'w').write('\n'.join(src1) + '\n')
    r = subprocess.run([SJ, '--sym=' + os.path.join(d, 'a.sym'), '--raw=' + os.path.join(d, 'a.bin'), p1], capture_output=True, text=True)
    if 'error' in r.stdout.lower().replace('errors: 0', ''):
        print(r.stdout); sys.exit(1)
    sym = {}
    for l in open(os.path.join(d, 'a.sym')):
        m = re.match(r'(\w+):\s*EQU\s+0x([0-9A-Fa-f]+)', l)
        if m:
            sym[m.group(1)] = int(m.group(2), 16)
    size = len(open(os.path.join(d, 'a.bin'), 'rb').read())
    if os.environ.get('SYMS'):
        for k_, v_ in sorted(sym.items(), key=lambda kv: kv[1]):
            if not re.match(r'[NR]\d+$', k_): print('%04X %s' % (v_ - 0x100, k_))
    # real labels (not starting with '_'), in source order
    real = [it[1] for it in res if it[0] == 'lab' and not it[1].startswith('_')]
    base_of, base = {}, None
    final = ['OPTION ASM', "' THE INCA WALL - all assembly (generated from INCA_source.asm by gen.py; see README)"]
    nreal = 0
    for it in res:
        if it[0] == 'lab':
            if not it[1].startswith('_'):
                base = it[1]; nreal += 1
            base_of[it[1]] = base
    base = None
    def virt(text):
        def rep(m):
            nm = m.group(0)
            if nm in base_of and nm.startswith('_'):
                b = base_of[nm]
                off = sym[nm] - sym[b]
                return '%s+%d' % (b, off) if off else b
            return nm
        return re.sub(r'\b_\w+\b', rep, text)
    for it in res:
        if it[0] == 'lab':
            if not it[1].startswith('_'):
                final.append(it[1] + ':')
        elif it[0] == 'numlab':
            pass
        elif it[0] == 'ins':
            final.append(' ' + virt(it[1]))
        else:
            off = sym['N%d' % it[3]] - sym['R%d' % it[4]]
            if re.match(r'(jr|djnz)', it[1]) and not (-126 <= off <= 129):
                print('RANGE', off, it[1])
            tx = '$' if off == 0 else ('$%+d' % off)
            final.append(' ' + virt(it[1].replace(it[2], tx)))
    def dec(t):                           # shorter source: hex literals as decimal when shorter, no indentation, LF line ends
        def rep(m):
            v = str(int(m.group(1), 16))
            return v if len(v) < len(m.group(0)) else m.group(0)
        parts = re.split(r'("[^"]*")', t)
        return ''.join(p if p.startswith('"') else re.sub(r'\b([0-9][0-9A-Fa-f]*)[hH]\b', rep, p) for p in parts)
    final = [final[0]] + [dec(l.lstrip(' ')) for l in final[1:] if not l.startswith("'")]
    text = '\n'.join(final) + '\n'
    open(OUT, 'w', newline='').write(text)
    print('%d bytes of code, %d real labels, source %d bytes -> %s' % (size - 0, nreal, len(text), OUT))


main()
