#!/usr/bin/env python3
"""r3bat.py TAG [JOBS] : the round-3 battery.
  part 1 — the round-2 battery's 79 pairs + 5 singles (r1A/r1B vsfp, r2A_9bhg F-9C-1, hgwx),
           verbatim from r2bat.sh (dir r2src);
  part 2 — EVERY probe of the two round-2 reviews (r2A_vsfp stale*/loop*/threepred, r2B_vsfp
           k*/d*/e*/f*/g*/m_*/r1b_*/v16b; dir r3p), each against its hand-inlined or
           fenv-intended twin (F > T suffix; g*A → gTA, g*B → gTB; stale4/stale5 →
           stale3cT; k19v → k19F; r1b_v08* → r1b_v08T; m_* → m_*H), or — no twin — its
           ORACLE verdict/trace (ORACLE-SAME / ORACLE-DIFF).
Writes r3bat_TAG.txt: one line per pair, then the denominator and class counts."""
import collections
import concurrent.futures as cf
import hashlib
import pathlib
import re
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

TAG = sys.argv[1]
JOBS = int(sys.argv[2]) if len(sys.argv) > 2 else 6

# part 1: the r2bat.sh pairs, parsed from the script itself (one source of truth).
bat = (V / 'r2bat.sh').read_text()
block = bat.split('PAIRS="', 1)[1].split('"', 1)[0]
jobs = [('r2src', s, t) for s, t in (l.split() for l in block.splitlines() if l.strip())]
singles = [('r2src', s) for s in re.search(r'for s in ([^;]+); do', bat).group(1).split()]

# part 2: every r3p subject.
names = sorted(p.stem for p in (V / 'r3p').glob('*.c') if not p.name.endswith('.lib.c'))
nameset = set(names)
def is_twin(n):
    if n in ('gTA', 'gTB', 'b15T', 'r1b_b15T', 'r1b_v08T', 'k11H'):
        return True
    if re.fullmatch(r'.*H', n) and n[:-1] in nameset:
        return True
    return (n.endswith('F') or n.endswith('T')) and n[:-1] in nameset
explicit = {'k11': 'k11H', 'stale4': 'stale3cT', 'stale5': 'stale3cT', 'k19v': 'k19F', 'r1b_v08': 'r1b_v08T',
            'r1b_v08b': 'r1b_v08T', 'm_n4': 'm_n4H', 'm_s_f64': 'm_s_f64H'}
for n in names:
    if is_twin(n):
        continue
    t = explicit.get(n)
    if t is None and re.fullmatch(r'g\d+A', n):
        t = 'gTA'
    if t is None and re.fullmatch(r'g\d+B', n):
        t = 'gTB'
    if t is None and n + 'F' in nameset:
        t = n + 'F'
    if t is None and n + 'T' in nameset:
        t = n + 'T'
    if t:
        jobs.append(('r3p', n, t))
    else:
        singles.append(('r3p', n))

# Stage 1 is built ONCE per (dir, name), sequentially, before any parallel work: the
# harness writes shared out/<dir>__<name>.s1.ll files, so two jobs building the same
# twin concurrently would race (the stage-2 outputs are per-tag and do not).
_built = {}
_orig_build = h.build
for key in sorted({(d, s) for d, s, _ in jobs} | {(d, t) for d, _, t in jobs} | set(singles)):
    _built[key] = _orig_build(*key)
h.build = lambda d, b: _built[(d, b)]

# Every (tag, dir, name) verdict is computed ONCE (the stage-2 file and the linked
# executable are named per (name, tag), so two concurrent verdicts of one twin race).
_keys = sorted({(TAG, d, s) for d, s, _ in jobs} | {(TAG, d, t) for d, _, t in jobs}
               | {(TAG, d, s) for d, s in singles} | {('main', d, s) for d, s in singles})
with cf.ThreadPoolExecutor(JOBS) as _ex:
    _V = dict(zip(_keys, _ex.map(lambda k: h.verdict(*k), _keys)))
h.verdict = lambda tag, d, b: _V[(tag, d, b)]

def pair(j):
    d, s, t = j
    rs = h.verdict(TAG, d, s)
    rt = h.verdict(TAG, d, t)
    if rs['v'] == 'ACC' and rt['v'] == 'ACC':
        c = 'TRACE-IDENT' if rs['trace'] == rt['trace'] else 'TRACE-DIFF'
    elif rs['v'] == rt['v'] == 'DECL':
        c = 'DECL-SAME' if rs.get('msg') == rt.get('msg') else 'DECL-DIFFSTR'
    else:
        c = 'VERDICT-DIFF'
    def cen(r):
        m = re.search(r'(\d+) template rail mint\(s\) of which (\d+) left dirty', r.get('2bl', ''))
        return f"dirty={m.group(2)}/{m.group(1)}" if m else ''
    return (f"{d}/[{TAG}] {s} vs {t}: {c} | S={rs['v']} {rs.get('msg','')[-70:]} w={rs.get('warn','')} {cen(rs)}"
            f" | T={rt['v']} {rt.get('msg','')[-50:]} w={rt.get('warn','')} {cen(rt)}")

def single(j):
    d, s = j
    a = h.verdict('main', d, s)
    b = h.verdict(TAG, d, s)
    ah = hashlib.sha1(a.get('trace', '').encode()).hexdigest()[:12]
    bh = hashlib.sha1(b.get('trace', '').encode()).hexdigest()[:12]
    same = a['v'] == b['v'] and (ah == bh if a['v'] == 'ACC' else a.get('msg', '').split(': ')[-1] == b.get('msg', '').split(': ')[-1])
    c = 'ORACLE-SAME' if same else 'ORACLE-DIFF'
    return f"{d}/[{TAG}] single {s}: {c} | main: {a['v']} {a.get('msg','')[-70:]} | {TAG}: {b['v']} {b.get('msg','')[-70:]}"

lines = []
with cf.ThreadPoolExecutor(JOBS) as ex:
    lines += list(ex.map(pair, jobs))
    lines += list(ex.map(single, singles))
cnt = collections.Counter()
for l in lines:
    m = re.search(r'(TRACE-IDENT|TRACE-DIFF|DECL-SAME|DECL-DIFFSTR|VERDICT-DIFF|ORACLE-SAME|ORACLE-DIFF|TOOLFAIL)', l)
    cnt[m.group(1) if m else 'UNPARSED'] += 1
with open(V / f'r3bat_{TAG}.txt', 'w') as o:
    for l in lines:
        o.write(l + '\n')
    o.write(f'denominator={len(lines)} (pairs {len(jobs)}, singles {len(singles)})\n')
    for k, v in sorted(cnt.items()):
        o.write(f'{v:5d} {k}\n')
print(f'denominator={len(lines)} (pairs {len(jobs)}, singles {len(singles)})')
for k, v in sorted(cnt.items()):
    print(f'{v:5d} {k}')
