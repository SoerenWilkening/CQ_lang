#!/usr/bin/env python3
"""r5run.py [TAG] : bd 91k9's repros (r4A bv / bvn2 / pn) — lowered, 2b, LINKED and RUN with
arg 5 on the ORACLE, round 4 (829769d9, kept copy) and round 5 (TAG); prints the executable's
own exit code (not a pipe's), trace lines, and each clone call's lowered text. The twin bvT.c too."""
import pathlib
import re
import subprocess
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

BINS = [('main', 'ORACLE'), ('r4keep', 'ROUND4'), (sys.argv[1] if len(sys.argv) > 1 else 'r5a', 'ROUND5')]
for name in ('bv', 'bvn2', 'pn', 'bvT'):
    s1, e = h.build('r5a', name)
    if not s1:
        print(name, 'BUILD', e[:100])
        continue
    for tag, label in BINS:
        rc, msg, s2, err = h.opt(tag, s1)
        if rc:
            print(f'{name:5s} {label:7s} opt rc={rc} {msg[-80:]}')
            continue
        c, l = h.check2b(s2)
        exe = pathlib.Path(str(s2) + '.exe')
        subprocess.run([str(h.L / 'clang'), '-Wno-everything', str(s2), str(h.TPL), str(h.RT), '-o', str(exe)],
                       capture_output=True)
        r = subprocess.run([str(exe), '5'], capture_output=True, text=True)
        exe.unlink()
        calls = re.findall(r'call i32 @(__cq_q_\w+)\(([^)]*)\)', s2.read_text())
        print(f'{name:5s} {label:7s} opt rc=0 2b={c} run rc={r.returncode} lines={len(r.stdout.splitlines())} '
              f'calls={[(f, a[:90]) for f, a in calls]}')
