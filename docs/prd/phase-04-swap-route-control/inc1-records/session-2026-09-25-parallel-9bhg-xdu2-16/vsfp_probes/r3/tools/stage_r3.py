#!/usr/bin/env python3
"""Stage the round-3 probe sources + their stage-1 modules into fx/ as r3_<k> (built with
h.py's run_slice_multi recipe), and build the twins' stage-1 too."""
import pathlib
import shutil
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

KEYS = ['stale3a', 'stale3b', 'stale3c', 'stale4', 'loop2', 'k1', 'g13A', 'g9A', 'k19', 'eqphi']
TWINS = ['eqphiT', 'k19F', 'k8F', 'k24F', 'k5F', 'k3F', 'k1T', 'gTA', 'stale3cT', 'stale3aT', 'stale3bT', 'loop2T']
for k in KEYS:
    shutil.copy(V / 'r3p' / f'{k}.c', V / 'fx' / f'r3_{k}.c')
    lib = V / 'r3p' / f'{k}.lib.c'
    tgt = V / 'fx' / f'r3_{k}.lib.c'
    if lib.exists():
        shutil.copy(lib, tgt)
    elif tgt.exists():
        tgt.unlink()
    s1, e = h.build('r3p', k)
    if not s1:
        raise SystemExit(f'{k}: {e}')
    shutil.copy(s1, V / 'fx' / f'r3_{k}.s1.ll')
for t in TWINS:
    s1, e = h.build('r3p', t)
    if not s1:
        raise SystemExit(f'{t}: {e}')
print('staged', len(KEYS), 'twins', len(TWINS))
