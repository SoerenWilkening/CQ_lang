#!/usr/bin/env python3
"""Stage the round-5 C probes into fx/ as r5_<k> (+ .lib.c) with their stage-1 modules."""
import pathlib
import shutil
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

C = [('r5a', 'bv'), ('r5a', 'bvn2'), ('r5a', 'pn'), ('r5b', 's4_pragma_bss'), ('r5b', 's2_pragma_val'),
     ('r5b', 'g_as')]
for d, k in C:
    shutil.copy(V / d / f'{k}.c', V / 'fx' / f'r5_{k}.c')
    lib = V / d / f'{k}.lib.c'
    tgt = V / 'fx' / f'r5_{k}.lib.c'
    if lib.exists():
        shutil.copy(lib, tgt)
    elif tgt.exists():
        tgt.unlink()
    s1, e = h.build(d, k)
    if not s1:
        raise SystemExit(f'{k}: {e}')
    shutil.copy(s1, V / 'fx' / f'r5_{k}.s1.ll')
print('staged', len(C))
