#!/usr/bin/env python3
"""respell_compose.py FILE CALLEE IDX : the bd vsfp re-spell applied to a bd 9bhg
fixture in the COMPOSED tree (dead read in the callee + env-armed first RUN +
`CHECK-NOT: CQ_DEADARG_DBG` before the first default-prefix directive + a note)."""
import pathlib
import re
import subprocess
import sys

f, callee, idx = sys.argv[1], sys.argv[2], sys.argv[3]
p = pathlib.Path(f)
tmp = p.with_suffix(".tmp")
subprocess.run(["python3", str(pathlib.Path(__file__).parent / "respell.py"), str(p), str(tmp), callee, idx], check=True, capture_output=True)
L = tmp.read_text().split("\n")
tmp.unlink()
note = f"""; ⚠ bd test_C_libtooling-vsfp (composed with bd 9bhg) — RE-SPELLED: `@{callee}` ignored its
; parameter {idx}, and bd vsfp's `dropDeadCallArguments` replaces such an operand by a constant
; before `detectSpecializations`, so the original spelling is no Phase-6 site and this
; file's subject would be gone. The dead read `%vsfp.read` keeps the parameter used; the
; `CHECK-NOT: CQ_DEADARG_DBG` pins that the drop does not fire (CLAUDE.md L8)."""
L = [L[0]] + note.split("\n") + L[1:]
for i, l in enumerate(L):
    m = re.match(r"^; RUN: (not )?%cq-opt", l)
    if m:
        L[i] = l.replace("; RUN: ", "; RUN: env CQ_DEADARG_DBG=1 ", 1)
        break
else:
    raise SystemExit("no %cq-opt RUN line")
for i, l in enumerate(L):
    if re.match(r"^; CHECK(-[A-Z]+)?:", l):
        L.insert(i, "; CHECK-NOT: CQ_DEADARG_DBG")
        break
p.write_text("\n".join(L))
print("respelled", f)
