#!/bin/bash
# RED-HALF BY BINARY: run each fixture's own RUN line(s) against the chosen cq-opt.
# A fixture is NON-VACUOUS iff it PASSES on the subject and FAILS on the ORACLE.
LLVM=/usr/local/opt/llvm@19/bin
export PATH="$LLVM:$PATH"
BIN="$1"; shift
for f in "$@"; do
  script=$(mktemp); : > "$script"
  python3 - "$f" "$BIN" "$LLVM" >> "$script" <<'PY'
import sys,re
f,b,llvm=sys.argv[1],sys.argv[2],sys.argv[3]
lines=[]; cont=""
for l in open(f):
    l=l.rstrip('\n')
    m=re.match(r'^;\s*RUN:\s?(.*)$', l)
    if not m: continue
    t=m.group(1)
    if t.endswith('\\'):
        cont += t[:-1]; continue
    lines.append(cont+t); cont=""
for t in lines:
    t=t.replace('%cq-opt', b+'/ir-pass/cq-opt').replace('%cq-pass', b+'/ir-pass/libCQPass.so')
    t=t.replace('%filecheck', llvm+'/FileCheck').replace('%s', f)
    print(t)
PY
  if bash "$script" >/dev/null 2>&1; then echo "PASS $(basename $f)"; else echo "FAIL $(basename $f)"; fi
  rm -f "$script"
done
