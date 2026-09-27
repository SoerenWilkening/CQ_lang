#!/usr/bin/env python3
"""mkgold5.py TAG [--write] : the round-5 e2e slice (bv) through the harness recipe
(clang -O1 per TU, llvm-link, cq-opt TAG, 2b, link, run with NO args as run_slice*.sh);
prints the verdict, 2b line, trace sha and the EXECUTABLE'S OWN exit code. --write stores the
golden from TAG's trace."""
import hashlib
import pathlib
import shutil
import subprocess
import sys

V = pathlib.Path(__file__).parent
sys.path.insert(0, str(V))
import h  # noqa: E402

E = h.W / 'tests/e2e'
D = V / 'e2e5'
D.mkdir(exist_ok=True)
n = 'slice_spec_dropped_arg_byval_slot'
shutil.copy(E / f'{n}.c', D / f'{n}.c')
shutil.copy(E / 'spec_dropped_arg_byval_lib.c', D / f'{n}.lib.c')
TAG = sys.argv[1]
s1, e = h.build('e2e5', n)
rc, msg, s2, err = h.opt(TAG, s1)
if rc:
    print(f'[{TAG}] DECL {msg}')
    raise SystemExit(0)
c, l = h.check2b(s2)
exe = pathlib.Path(str(s2) + '.exe')
subprocess.run([str(h.L / 'clang'), '-Wno-everything', str(s2), str(h.TPL), str(h.RT), '-o', str(exe)],
               capture_output=True)
r = subprocess.run([str(exe)], capture_output=True, text=True)
exe.unlink()
print(f'[{TAG}] ACC 2b={c} {l[-1][30:120] if l else ""} run rc={r.returncode} lines={len(r.stdout.splitlines())} '
      f'sha={hashlib.sha1(r.stdout.encode()).hexdigest()[:10]}')
if '--write' in sys.argv:
    (E / f'{n}.expected.log').write_text(r.stdout)
    print('wrote golden')
