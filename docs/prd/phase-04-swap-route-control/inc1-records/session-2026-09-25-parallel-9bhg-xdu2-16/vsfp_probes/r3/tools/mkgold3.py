#!/usr/bin/env python3
"""mkgold3.py TAG [--write] : build the four round-3 e2e slices through the harness recipe
(h.py: clang -O1 per TU, llvm-link, cq-opt TAG, 2b, link, run with NO args — as
run_slice*.sh), print verdict/census/trace-hash per slice and whether each subject's trace
equals its twin's; with --write, write the goldens from TAG's traces."""
import hashlib
import pathlib
import shutil
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

E = h.W / 'tests/e2e'
D = V / 'e2e3'
D.mkdir(exist_ok=True)
SL = [('slice_spec_dropped_arg_volatile_global', 'spec_dropped_arg_volatile_global_lib.c'),
      ('slice_spec_dropped_arg_volatile_global_twin', None),
      ('slice_volatile_arm_fold_repropagate', None),
      ('slice_volatile_arm_fold_repropagate_twin', None)]
TAG = sys.argv[1]
W = '--write' in sys.argv
tr = {}
for n, lib in SL:
    shutil.copy(E / f'{n}.c', D / f'{n}.c')
    lp = D / f'{n}.lib.c'
    if lib:
        shutil.copy(E / lib, lp)
    elif lp.exists():
        lp.unlink()
    r = h.verdict(TAG, 'e2e3', n, args=())
    t = r.get('trace', '')
    tr[n] = t
    print(f"[{TAG}] {n}: {r['v']} {r.get('msg','')[-80:]} w={r.get('warn','')} 2b={r.get('2b','')} {r.get('2bl','')[30:140]} lines={len(t.splitlines())} sha={hashlib.sha1(t.encode()).hexdigest()[:10]}")
    if W and r['v'] == 'ACC':
        (E / f'{n}.expected.log').write_text(t)
for a in ('slice_spec_dropped_arg_volatile_global', 'slice_volatile_arm_fold_repropagate'):
    print(a, 'TWIN-IDENT' if tr[a] and tr[a] == tr[a + '_twin'] else 'TWIN-DIFF')
