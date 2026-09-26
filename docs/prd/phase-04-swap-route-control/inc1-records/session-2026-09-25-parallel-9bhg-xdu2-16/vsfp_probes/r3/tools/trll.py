#!/usr/bin/env python3
"""trll.py TAG DIR PAIR... : PAIR = subj.ll:twinname — run the hand-written stage-1 module
ll/<subj>.ll and the C twin DIR/<twinname>.c (+ .lib.c) through binary TAG, link, run with
args 5 7, and compare traces. Prints verdict, 2b census and the class; denominator last."""
import pathlib
import shutil
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import h  # noqa: E402

TAG, D = sys.argv[1], sys.argv[2]
n = 0
for pr in sys.argv[3:]:
    s, t = pr.split(':')
    src = h.V / 'll' / f'{s}.ll'
    s1 = h.O / f'LL__{s}.s1.ll'
    shutil.copy(src, s1)
    rc, msg, s2, err = h.opt(TAG, s1)
    if rc:
        sv = {'v': 'DECL', 'msg': msg}
    else:
        c, l = h.check2b(s2)
        x, tr = h.linkrun(s2, ('5', '7'))
        sv = {'v': 'ACC', 'trace': tr, '2bl': l[-1] if l else '', 'warn': sum(1 for q in err.splitlines() if 'warning:' in q)}
    tv = h.verdict(TAG, D, t)
    if sv['v'] == tv['v'] == 'ACC':
        cls = 'TRACE-IDENT' if sv['trace'] == tv['trace'] else 'TRACE-DIFF'
    elif sv['v'] == tv['v'] == 'DECL':
        cls = 'DECL-SAME' if sv['msg'].split(': ')[-1] == tv['msg'].split(': ')[-1] else 'DECL-DIFFSTR'
    else:
        cls = 'VERDICT-DIFF'
    n += 1
    print(f"[{TAG}] {s} vs {t}: {cls} | S={sv['v']} {sv.get('msg','')[-80:]} w={sv.get('warn','')} {sv.get('2bl','')[40:120]} | T={tv['v']} {tv.get('msg','')[-60:]} w={tv.get('warn','')}")
print(f'pairs={n}')
