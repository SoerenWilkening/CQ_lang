#!/usr/bin/env python3
"""cmpll.py TAG... -- SUBJ.ll TWIN.ll [FN] : lower both with each binary tag, print the
verdict and the runtime/user call sequence of FN (default main), and whether the
subject's sequence equals the twin's under the same binary."""
import re
import subprocess
import sys

V = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp'
i = sys.argv.index('--')
tags, rest = sys.argv[1:i], sys.argv[i + 1:]
subj, twin = rest[0], rest[1]
fn = rest[2] if len(rest) > 2 else 'main'


def seq(tag, f):
    b = f'{V}/../frozen/cq-opt.main_aee8' if tag == 'main' else f'{V}/bin/cq-opt.{tag}'
    r = subprocess.run([b, '-passes=cq-lowering', '-S', f, '-o', '-'], capture_output=True, text=True)
    if r.returncode:
        e = [l for l in r.stderr.splitlines() if 'error' in l]
        return 'DECL ' + (e[0].split('error: ')[-1] if e else r.stderr[:120])
    m = re.search(r'^define [^\n]*@' + fn + r'\(.*?^}', r.stdout, re.S | re.M)
    calls = re.findall(r'call \S+ @([\w.]+)\(([^)]*)\)', m.group(0)) if m else []
    ssa = re.compile(r'%[\w.]+')
    return ' '.join(c + '(' + ssa.sub('%', a) + ')' for c, a in calls)


for t in tags:
    a, b = seq(t, subj), seq(t, twin)
    print(f'[{t}] {"IDENT" if a == b else "DIFF"}\n   S: {a}\n   T: {b}')
