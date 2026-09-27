#!/usr/bin/env python3
"""mkgold6.py TAG [--write] : the round-6 e2e pair (mt1 slice, 2-TU, + its twin) through the
harness recipe (run with NO args, as run_slice*.sh); prints verdict, 2b census, the executable's
own exit code, line count, trace sha and TWIN-IDENT/TWIN-DIFF. --write stores both goldens."""
import hashlib
import pathlib
import shutil
import subprocess
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

E = h.W / 'tests/e2e'
D = V / 'e2e6'
D.mkdir(exist_ok=True)
SL = [('slice_spec_dropped_arg_musttail_inner', 'spec_dropped_arg_musttail_lib.c'),
      ('slice_spec_dropped_arg_musttail_inner_twin', None)]
TAG = sys.argv[1]
tr = {}
for n, lib in SL:
    shutil.copy(E / f'{n}.c', D / f'{n}.c')
    lp = D / f'{n}.lib.c'
    if lib:
        shutil.copy(E / lib, lp)
    elif lp.exists():
        lp.unlink()
    s1, e = h.build('e2e6', n)
    rc, msg, s2, err = h.opt(TAG, s1)
    if rc:
        print(f'[{TAG}] {n}: DECL {msg}')
        tr[n] = None
        continue
    c, l = h.check2b(s2)
    exe = pathlib.Path(str(s2) + '.exe')
    subprocess.run([str(h.L / 'clang'), '-Wno-everything', str(s2), str(h.TPL), str(h.RT), '-o', str(exe)],
                   capture_output=True)
    r = subprocess.run([str(exe)], capture_output=True, text=True)
    exe.unlink()
    tr[n] = r.stdout
    warn = sum(1 for q in err.splitlines() if 'warning:' in q)
    print(f'[{TAG}] {n}: ACC warn={warn} 2b={c} {l[-1][30:130] if l else ""} run rc={r.returncode} '
          f'lines={len(r.stdout.splitlines())} sha={hashlib.sha1(r.stdout.encode()).hexdigest()[:10]}')
    if '--write' in sys.argv:
        (E / f'{n}.expected.log').write_text(r.stdout)
a, b = tr[SL[0][0]], tr[SL[1][0]]
print('TWIN-IDENT' if a is not None and a == b else 'TWIN-DIFF')
