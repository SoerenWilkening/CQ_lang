#!/usr/bin/env python3
"""Stage the round-4 C probes into fx/ as r4_<k> (+ .lib.c) with their stage-1 modules
(h.build's run_slice_multi recipe)."""
import pathlib
import shutil
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

C = [('r4b', 'u5'), ('r4b', 'u3'), ('r4b', 'u4'), ('r4b', 'u6'), ('r4c', 'sect')]
for d, k in C:
    shutil.copy(V / d / f'{k}.c', V / 'fx' / f'r4_{k}.c')
    lib = V / d / f'{k}.lib.c'
    tgt = V / 'fx' / f'r4_{k}.lib.c'
    if lib.exists():
        shutil.copy(lib, tgt)
    elif tgt.exists():
        tgt.unlink()
    s1, e = h.build(d, k)
    if not s1:
        raise SystemExit(f'{k}: {e}')
    shutil.copy(s1, V / 'fx' / f'r4_{k}.s1.ll')
print('staged', len(C))
