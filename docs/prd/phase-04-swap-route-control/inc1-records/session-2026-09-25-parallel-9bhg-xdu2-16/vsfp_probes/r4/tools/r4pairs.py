#!/usr/bin/env python3
"""r4pairs.py TAG PAIR... : PAIR = SUBJ:TWIN, each a path (relative to vsfp/) to a .c
(built with its .lib.c by h.build's recipe) or a stage-1 .ll, or TWIN = 'INL' meaning
"the subject with every user callee inlined by LLVM's own inliner + instcombine /
simplifycfg / adce" (the -O1-style hand-inlined twin of an IR-only probe). Runs both
through cq-opt.TAG, 2b STRICT + CENSUS, link, run with args 5 7; prints the class and
the census, denominator last. RC is the true cq-opt exit code (no pipes)."""
import pathlib
import re
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import h  # noqa: E402

V = h.V
O = h.O
TAG = sys.argv[1]


def stage1(p):
    p = V / p
    if p.suffix == '.c':
        s1, e = h.build(p.parent.name, p.stem)
        return s1, e
    dst = O / f'{p.parent.name}__{p.stem}.s1.ll'
    shutil.copy(p, dst)
    return dst, ''


def inline_twin(s1):
    out = pathlib.Path(str(s1).replace('.s1.ll', '.INL.s1.ll'))
    r = subprocess.run([str(h.L / 'opt'), '-S', '-inline-threshold=100000',
                        '-passes=cgscc(inline),function(instcombine<no-verify-fixpoint>,simplifycfg,adce),globaldce',
                        str(s1), '-o', str(out)], capture_output=True, text=True)
    if r.returncode:
        return None, 'INLFAIL ' + r.stderr[-200:]
    return out, ''


def verdict(s1):
    rc, msg, s2, err = h.opt(TAG, s1)
    if rc:
        return {'v': 'DECL' if rc == 1 else f'RC{rc}', 'msg': msg or err.strip()[-100:], 'rc': rc}
    c, l = h.check2b(s2)
    x, tr = h.linkrun(s2, ('5', '7'))
    m = re.search(r'(\d+) template rail mint\(s\) of which (\d+) left dirty', l[-1] if l else '')
    return {'v': 'ACC', 'trace': tr, 'warn': sum(1 for q in err.splitlines() if 'warning:' in q),
            'cen': f'dirty={m.group(2)}/{m.group(1)}' if m else '?', '2b': c}


n = 0
for pr in sys.argv[2:]:
    s, t = pr.split(':')
    s1, e = stage1(s)
    if not s1:
        print(f'[{TAG}] {s}: BUILD {e[:120]}')
        continue
    t1, e2 = inline_twin(s1) if t == 'INL' else stage1(t)
    if not t1:
        print(f'[{TAG}] {t}: BUILD {e2[:120]}')
        continue
    a, b = verdict(s1), verdict(t1)
    if a['v'] == b['v'] == 'ACC':
        c = 'TRACE-IDENT' if a['trace'] == b['trace'] else 'TRACE-DIFF'
    elif a['v'] == b['v']:
        c = 'DECL-SAME' if a['msg'].split(': ')[-1] == b['msg'].split(': ')[-1] else 'DECL-DIFFSTR'
    else:
        c = 'VERDICT-DIFF'
    n += 1
    print(f"[{TAG}] {pathlib.Path(s).name} vs {pathlib.Path(t).name if t != 'INL' else 'INL'}: {c} | "
          f"S={a['v']} {a.get('msg','')[-70:]} w={a.get('warn','')} {a.get('cen','')} 2b={a.get('2b','')} | "
          f"T={b['v']} {b.get('msg','')[-50:]} w={b.get('warn','')} {b.get('cen','')}")
print(f'pairs={n}')
