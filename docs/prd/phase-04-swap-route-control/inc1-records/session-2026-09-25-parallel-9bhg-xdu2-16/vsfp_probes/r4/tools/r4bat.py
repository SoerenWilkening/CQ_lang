#!/usr/bin/env python3
"""r4bat.py TAG [JOBS] : the round-4 battery = the round-3 battery (r3bat.py's 176 rows:
round 2's 79 pairs + 5 singles, every r2A/r2B vsfp probe vs its twin) PLUS every probe of the
two round-3 reviews (r3A_vsfp in r4a/, r3B_vsfp in r4b/) against its hand-inlined or
fenv-intended twin: `<n>T.c` / `<n>F.c` / `<n>H.c` for C probes; for IR probes the reviewer's
named twin, else 'INL' (LLVM's inliner + instcombine/simplifycfg/adce on the probe — the -O1
twin of an IR-only callee). Verdicts are memoised per (tag, module); stage 1 is built once.
Writes r4bat_TAG.txt with a class count and the denominator."""
import collections
import concurrent.futures as cf
import hashlib
import pathlib
import re
import shutil
import subprocess
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

TAG = sys.argv[1]
JOBS = int(sys.argv[2]) if len(sys.argv) > 2 else 6

# ---- part 1: reuse r3bat.py's job derivation (exec its top half)
src = (V / 'r3bat.py').read_text()
cut = src.index('# Stage 1 is built ONCE')
ns = {'__file__': str(V / 'r3bat.py')}
sys.argv = [sys.argv[0], TAG]
exec(compile(src[:cut], 'r3bat_head', 'exec'), ns)
jobs = [(f'{d}/{s}.c', f'{d}/{t}.c') for d, s, t in ns['jobs']]
singles = [f'{d}/{s}.c' for d, s in ns['singles']]

# ---- part 2: the round-3 reviews' probes
IRTWIN = {'n5_nested': 'r4a/n5T.ll', 'g1b': 'r4a/g1F.c', 'g1c': 'r4a/g1F.c', 's1b': 'r4a/s1T.c',
          'wboolb': 'r4a/wBoolT.c', 'e2b': 'r4a/e2T.c', 'f1b': 'r4a/f1T.c', 'f2b': 'r4a/f2T.c',
          'fpfloatb': 'r4a/fpfloatT.c', 'fplongdb': 'r4a/fplongdT.c', 'l2b': 'r4a/l2T.c',
          'd1b': 'r4a/d1T.c', 'u1': 'r4b/u1T.ll', 'u2': 'r4b/u2T.ll', 'e1': 'r4b/e1T.ll'}
for d in ('r4a', 'r4b'):
    cs = {p.stem for p in (V / d).glob('*.c') if not p.name.endswith('.lib.c')}
    for n in sorted(cs):
        if re.fullmatch(r'.*[TFH]', n) and n[:-1] in cs:
            continue
        if n in ('wBoolT',):
            continue
        tw = next((f'{d}/{n}{s}.c' for s in ('T', 'F', 'H') if n + s in cs), None)
        if n == 'wBool':
            tw = f'{d}/wBoolT.c'
        if n == 'd3':
            tw = f'{d}/d4T.c' if False else None  # d3 differs from d4 (measure order); no twin — oracle single
        if tw:
            jobs.append((f'{d}/{n}.c', tw))
        else:
            singles.append(f'{d}/{n}.c')
    for p in sorted((V / d).glob('*.ll')):
        n = p.stem
        if n.endswith('T') and n != 'e1T' or n in ('n5T', 'e1T', 'u1T', 'u2T'):
            continue
        if n.endswith('.s1') or n.endswith('.O1'):
            continue
        jobs.append((f'{d}/{p.name}', IRTWIN.get(n, 'INL')))


# ---- stage 1, built once
def stage1(p):
    if p == 'INL':
        return None, 'INL'
    q = V / p
    if q.suffix == '.c':
        return h.build(q.parent.name, q.stem)
    dst = h.O / f'{q.parent.name}__{q.stem}.s1.ll'
    shutil.copy(q, dst)
    return dst, ''


def inl(s1):
    out = pathlib.Path(str(s1).replace('.s1.ll', '.INL.s1.ll'))
    r = subprocess.run([str(h.L / 'opt'), '-S', '-inline-threshold=100000',
                        '-passes=cgscc(inline),function(instcombine<no-verify-fixpoint>,simplifycfg,adce),globaldce',
                        str(s1), '-o', str(out)], capture_output=True, text=True)
    return (out, '') if r.returncode == 0 else (None, 'INLFAIL')


S1 = {}
for p in sorted({x for j in jobs for x in j if x != 'INL'} | set(singles)):
    S1[p] = stage1(p)
for s, t in jobs:
    if t == 'INL' and S1[s][0]:
        S1[s + '#INL'] = inl(S1[s][0])


def verdict(tag, key):
    s1, e = S1[key]
    if not s1:
        return {'v': 'BUILD', 'msg': e[:80]}
    rc, msg, s2, err = h.opt(tag, s1)
    if rc:
        return {'v': 'DECL' if rc == 1 else f'RC{rc}', 'msg': msg or err.strip()[-80:]}
    c, l = h.check2b(s2)
    x, tr = h.linkrun(s2, ('5', '7'))
    m = re.search(r'(\d+) template rail mint\(s\) of which (\d+) left dirty', l[-1] if l else '')
    return {'v': 'ACC', 'trace': tr, 'warn': sum(1 for q in err.splitlines() if 'warning:' in q),
            'cen': f'dirty={m.group(2)}/{m.group(1)}' if m else '?'}


keys = sorted({(TAG, s) for s, _ in jobs} | {(TAG, t if t != 'INL' else s + '#INL') for s, t in jobs}
              | {(TAG, s) for s in singles} | {('main', s) for s in singles})
with cf.ThreadPoolExecutor(JOBS) as ex:
    VD = dict(zip(keys, ex.map(lambda k: verdict(*k), keys)))

lines = []
for s, t in jobs:
    a = VD[(TAG, s)]
    b = VD[(TAG, t if t != 'INL' else s + '#INL')]
    if a['v'] == b['v'] == 'ACC':
        c = 'TRACE-IDENT' if a['trace'] == b['trace'] else 'TRACE-DIFF'
    elif a['v'] == b['v'] == 'DECL':
        c = 'DECL-SAME' if a['msg'].split(': ')[-1] == b['msg'].split(': ')[-1] else 'DECL-DIFFSTR'
    elif a['v'] == b['v']:
        c = 'SAME-' + a['v']
    else:
        c = 'VERDICT-DIFF'
    lines.append(f"[{TAG}] {s} vs {t}: {c} | S={a['v']} {a.get('msg','')[-60:]} w={a.get('warn','')} {a.get('cen','')} | "
                 f"T={b['v']} {b.get('msg','')[-50:]} w={b.get('warn','')} {b.get('cen','')}")
for s in singles:
    a, b = VD[('main', s)], VD[(TAG, s)]
    same = a['v'] == b['v'] and (a.get('trace') == b.get('trace') if a['v'] == 'ACC'
                                 else a.get('msg', '').split(': ')[-1] == b.get('msg', '').split(': ')[-1])
    lines.append(f"[{TAG}] single {s}: {'ORACLE-SAME' if same else 'ORACLE-DIFF'} | main: {a['v']} {a.get('msg','')[-60:]} | {TAG}: {b['v']} {b.get('msg','')[-60:]}")
cnt = collections.Counter(re.search(r': (\S+) \|', l).group(1) for l in lines)
with open(V / f'r4bat_{TAG}.txt', 'w') as o:
    o.write('\n'.join(lines) + '\n')
    o.write(f'denominator={len(lines)} (pairs {len(jobs)}, singles {len(singles)})\n')
    for k, v in sorted(cnt.items()):
        o.write(f'{v:5d} {k}\n')
print(f'denominator={len(lines)} (pairs {len(jobs)}, singles {len(singles)})')
for k, v in sorted(cnt.items()):
    print(f'{v:5d} {k}')
