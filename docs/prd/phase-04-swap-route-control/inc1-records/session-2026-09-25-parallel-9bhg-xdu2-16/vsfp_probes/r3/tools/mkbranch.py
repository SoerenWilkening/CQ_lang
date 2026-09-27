#!/usr/bin/env python3
"""mkbranch.py NAME... : for each r3p probe NAME (built by h.py into out/r3p__NAME.s1.ll),
write ll/NAME_branch.ll: the same linked module with the callee `@h`'s volatile-global
arm read DELETED, leaving a BRANCH-ONLY read of `a` (an empty diamond). `clang -O1`
deletes such a diamond, so this is IR-only; it is the one remaining route by which a
slot reaches the specializer's dead-slot record without the drop predicting it."""
import pathlib
import re
import sys

V = pathlib.Path(__file__).parent
for n in sys.argv[1:]:
    s = (V / f'out/r3p__{n}.s1.ll').read_text()
    m = re.search(r'^define [^\n]*@h\(.*?^}\n', s, re.S | re.M)
    assert m, n
    body = m.group(0)
    new = re.sub(r'^\s*%\d+ = load volatile i32, ptr @K[^\n]*\n', '', body, flags=re.M)
    assert new != body, n
    s = s.replace(body, new)
    (V / f'll/{n}_branch.ll').write_text(s)
    print('wrote', n)
